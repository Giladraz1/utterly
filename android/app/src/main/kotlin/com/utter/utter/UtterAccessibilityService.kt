package com.utter.utter

import android.accessibilityservice.AccessibilityService
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.PixelFormat
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.view.GestureDetector
import android.view.Gravity
import android.view.MotionEvent
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.ImageButton
import android.widget.Toast
import androidx.core.content.ContextCompat
import kotlin.math.abs

class UtterAccessibilityService : AccessibilityService() {

    companion object {
        private const val PREFS_NAME = "utter_prefs"
        private const val KEY_BUBBLE_VISIBLE = "bubble_visible"

        var instance: UtterAccessibilityService? = null
            private set
    }

    private var windowManager: WindowManager? = null
    private var bubbleView: ImageButton? = null
    private var layoutParams: WindowManager.LayoutParams? = null
    private var speechRecognizer: SpeechRecognizer? = null
    private var isListening = false

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        if (isBubbleVisiblePref()) addBubble()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}

    override fun onInterrupt() {
        stopListening()
    }

    override fun onDestroy() {
        super.onDestroy()
        if (instance == this) instance = null
        removeBubble()
        speechRecognizer?.destroy()
        speechRecognizer = null
    }

    private fun prefs() = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    private fun isBubbleVisiblePref(): Boolean = prefs().getBoolean(KEY_BUBBLE_VISIBLE, true)

    fun setBubbleVisible(visible: Boolean) {
        prefs().edit().putBoolean(KEY_BUBBLE_VISIBLE, visible).apply()
        if (visible) {
            addBubble()
        } else {
            stopListening()
            removeBubble()
        }
    }

    private fun addBubble() {
        if (bubbleView != null) return
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager

        val bubbleSizePx = (76 * resources.displayMetrics.density).toInt()
        val button = ImageButton(this)
        button.background = null
        button.scaleType = android.widget.ImageView.ScaleType.FIT_CENTER
        button.adjustViewBounds = true
        button.maxWidth = bubbleSizePx
        button.maxHeight = bubbleSizePx
        setBubbleTint(button, false)

        val overlayType = WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            overlayType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        )
        params.gravity = Gravity.TOP or Gravity.START
        params.x = 32
        params.y = 400

        var downX = 0f
        var downY = 0f
        var startX = 0
        var startY = 0
        var moved = false
        var longPressHandled = false
        val dragSlop = 16

        val gestureDetector = GestureDetector(this, object : GestureDetector.SimpleOnGestureListener() {
            override fun onLongPress(e: MotionEvent) {
                longPressHandled = true
                Toast.makeText(
                    this@UtterAccessibilityService,
                    "Utterly hidden — reopen the app to show it again",
                    Toast.LENGTH_SHORT
                ).show()
                setBubbleVisible(false)
            }
        })

        button.setOnTouchListener { view, event ->
            gestureDetector.onTouchEvent(event)
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    downX = event.rawX
                    downY = event.rawY
                    startX = params.x
                    startY = params.y
                    moved = false
                    longPressHandled = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    if (longPressHandled) return@setOnTouchListener true
                    val dx = (event.rawX - downX).toInt()
                    val dy = (event.rawY - downY).toInt()
                    if (abs(dx) > dragSlop || abs(dy) > dragSlop) moved = true
                    params.x = startX + dx
                    params.y = startY + dy
                    windowManager?.updateViewLayout(view, params)
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (!longPressHandled && !moved) view.performClick()
                    true
                }
                else -> false
            }
        }
        button.setOnClickListener { toggleListening(button) }

        windowManager?.addView(button, params)
        bubbleView = button
        layoutParams = params
    }

    private fun removeBubble() {
        bubbleView?.let { windowManager?.removeView(it) }
        bubbleView = null
    }

    private fun setBubbleTint(button: ImageButton, listening: Boolean) {
        button.setImageResource(if (listening) R.drawable.ic_mic_bubble_listening else R.drawable.ic_mic_bubble)
    }

    private fun toggleListening(button: ImageButton) {
        if (isListening) {
            stopListening()
            return
        }
        if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.RECORD_AUDIO)
            != PackageManager.PERMISSION_GRANTED
        ) {
            Toast.makeText(this, "Grant microphone permission in the Utter app first", Toast.LENGTH_LONG).show()
            return
        }
        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            Toast.makeText(this, "Speech recognition isn't available on this device", Toast.LENGTH_LONG).show()
            return
        }
        startListening(button)
    }

    private fun startListening(button: ImageButton) {
        speechRecognizer?.destroy()
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this).apply {
            setRecognitionListener(object : RecognitionListener {
                override fun onReadyForSpeech(params: Bundle?) {}
                override fun onBeginningOfSpeech() {}
                override fun onRmsChanged(rmsdB: Float) {}
                override fun onBufferReceived(buffer: ByteArray?) {}
                override fun onEndOfSpeech() {}

                override fun onError(error: Int) {
                    isListening = false
                    setBubbleTint(button, false)
                }

                override fun onResults(results: Bundle?) {
                    isListening = false
                    setBubbleTint(button, false)
                    val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    val text = matches?.firstOrNull()
                    Log.d("UtterDebug", "onResults spoken='$text'")
                    if (!text.isNullOrEmpty()) insertTextIntoFocusedField(text)
                }

                override fun onPartialResults(partialResults: Bundle?) {}
                override fun onEvent(eventType: Int, params: Bundle?) {}
            })
        }

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, false)
        }
        speechRecognizer?.startListening(intent)
        isListening = true
        setBubbleTint(button, true)
    }

    private fun stopListening() {
        speechRecognizer?.stopListening()
        isListening = false
        bubbleView?.let { setBubbleTint(it, false) }
    }

    private fun findNodeBfs(
        root: AccessibilityNodeInfo?,
        predicate: (AccessibilityNodeInfo) -> Boolean
    ): AccessibilityNodeInfo? {
        if (root == null) return null
        val queue = ArrayDeque<AccessibilityNodeInfo>()
        queue.add(root)
        while (queue.isNotEmpty()) {
            val current = queue.removeFirst()
            if (predicate(current)) return current
            for (i in 0 until current.childCount) {
                current.getChild(i)?.let { queue.add(it) }
            }
        }
        return null
    }

    private fun findEditableFocusedNode(root: AccessibilityNodeInfo?): AccessibilityNodeInfo? =
        findNodeBfs(root) { it.isFocused && it.isEditable }

    private fun insertTextIntoFocusedField(spoken: String) {
        val root = rootInActiveWindow
        val node: AccessibilityNodeInfo = root?.findFocus(AccessibilityNodeInfo.FOCUS_INPUT)
            ?: findEditableFocusedNode(root)
            ?: run {
                Toast.makeText(this, "Tap a text field first, then use the mic", Toast.LENGTH_SHORT).show()
                return
            }

        // Paste first: it inserts into the field's own real text buffer at the cursor, so the
        // field itself resolves empty-vs-hint state — unlike ACTION_SET_TEXT below, which requires
        // *us* to read "the current text" and some apps (WhatsApp's message box and search bar
        // included) hand back their placeholder as if it were real content when the field is empty.
        val inserted = pasteViaClipboard(node, spoken) || setNodeText(node, spoken)
        if (!inserted) {
            Toast.makeText(this, "Couldn't type into this field", Toast.LENGTH_SHORT).show()
        }
    }

    private fun pasteViaClipboard(node: AccessibilityNodeInfo, spoken: String): Boolean {
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val previousClip = clipboard.primaryClip
        clipboard.setPrimaryClip(ClipData.newPlainText("utterly", spoken))
        val pasted = node.performAction(AccessibilityNodeInfo.ACTION_PASTE)
        Handler(Looper.getMainLooper()).postDelayed({
            try {
                if (previousClip != null) clipboard.setPrimaryClip(previousClip)
            } catch (_: Exception) {
            }
        }, 3000)
        return pasted
    }

    // Fallback for fields that don't support ACTION_PASTE; reconstructs the full text.
    private fun setNodeText(node: AccessibilityNodeInfo, spoken: String): Boolean {
        // On an empty field, node.text often returns the placeholder (e.g. WhatsApp's "Message"
        // hint) instead of "" — isShowingHintText tells us that's not real content.
        val showingHint = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && node.isShowingHintText
        val existing = if (showingHint) "" else (node.text?.toString() ?: "")
        val start = if (node.textSelectionStart >= 0) node.textSelectionStart else existing.length
        val end = if (node.textSelectionEnd >= 0) node.textSelectionEnd else existing.length
        val safeStart = start.coerceIn(0, existing.length)
        val safeEnd = end.coerceIn(0, existing.length)

        val newText = existing.substring(0, minOf(safeStart, safeEnd)) +
            spoken +
            existing.substring(maxOf(safeStart, safeEnd))

        val arguments = Bundle()
        arguments.putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, newText)
        return node.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, arguments)
    }
}
