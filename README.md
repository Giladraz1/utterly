# Utterly

A floating microphone bubble for Android that lets you dictate into **any app's text field** — WhatsApp, Instagram, Tinder, browsers, anything with a keyboard — without switching keyboards.

## How it works

Utterly runs as an Android **Accessibility Service**. Once enabled, a small mic bubble floats over whatever app you're using:

1. Tap a text field in any app.
2. Tap the floating mic bubble.
3. Speak — your words are inserted right where your cursor is.
4. Drag the bubble anywhere it's in the way; long-press it to hide it.

Speech recognition uses Android's built-in `SpeechRecognizer`, so it supports whatever languages your device's speech recognition service supports.

## Setup

1. Install the APK (see [Releases](../../releases) for a ready-to-install build).
2. Open Utterly and grant:
   - **Microphone permission**
   - **Accessibility service** (Settings → Accessibility → Utterly)
3. Look for the mic bubble over any app.

## Building from source

```bash
flutter pub get
flutter build apk --debug
```

Requires Flutter and the Android SDK. See [pubspec.yaml](pubspec.yaml) for dependencies.

## Status

Early, actively evolving. Feedback and issues welcome.
