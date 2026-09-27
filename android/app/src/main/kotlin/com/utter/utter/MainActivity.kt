package com.utter.utter

import android.content.Intent
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.utter/accessibility"
    private val prefsName = "utter_prefs"
    private val keyBubbleVisible = "bubble_visible"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAccessibilityServiceEnabled" -> result.success(isAccessibilityServiceEnabled())
                "openAccessibilitySettings" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(null)
                }
                "isBubbleVisible" -> {
                    val visible = getSharedPreferences(prefsName, MODE_PRIVATE)
                        .getBoolean(keyBubbleVisible, true)
                    result.success(visible)
                }
                "setBubbleVisible" -> {
                    val visible = call.argument<Boolean>("visible") ?: true
                    val service = UtterAccessibilityService.instance
                    if (service != null) {
                        service.setBubbleVisible(visible)
                    } else {
                        getSharedPreferences(prefsName, MODE_PRIVATE).edit()
                            .putBoolean(keyBubbleVisible, visible)
                            .apply()
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val expectedComponent = "$packageName/${UtterAccessibilityService::class.java.name}"
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        val splitter = TextUtils.SimpleStringSplitter(':')
        splitter.setString(enabledServices)
        while (splitter.hasNext()) {
            if (splitter.next().equals(expectedComponent, ignoreCase = true)) return true
        }
        return false
    }
}
