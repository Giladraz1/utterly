# Play Console forms — answers to paste or select

I could not see the live Console, so exact field names and options may differ. Verify each item there.

## 1. Accessibility API declaration (paste, English)

Core functionality:
Utterly is a voice-dictation tool. The user taps a floating microphone button, speaks, and the recognized text is inserted into the text field they are using in any other app (messaging, notes, email). It helps people who find typing slow or difficult, and it is also useful in everyday situations where hands are busy.

Why the Accessibility API is required:
(1) Utterly shows its microphone button on top of other apps using an accessibility overlay.
(2) When the user finishes speaking, it finds the currently focused text field in the other app and inserts the text there.
A normal app cannot display a control over other apps or insert text into another app's text field without this API.

What we do and do not do:
The service is used only to locate the focused text field and insert text the user dictated. We do not read, collect, store, or transmit screen content or anything the user types. The app has no internet permission and no analytics or ads. The service works only after the user turns it on in Android's Accessibility settings, and can be turned off at any time.

Do NOT mark the service as an "accessibility tool". Utterly is a general dictation app, and the manifest does not set isAccessibilityTool.

## 2. Data safety (select)
- Does the app collect or share any user data types? NO.
  Reason: Utterly has no internet permission, no analytics or ads, and stores only two local settings (bubble visible, speech language).
- Speech to text is done by the phone's own speech service, not by code in Utterly. I believe this means the app declares no audio collection, but I am not certain how Google evaluates this, so re-read the form's definition of "collect" before submitting.
- Privacy policy URL: https://giladraz1.github.io/utterly/privacy.html

## 3. App access (reviewers)
Instructions for the reviewer:
1. Open Utterly and tap "Grant permission" for the microphone.
2. Tap "Open settings" next to Accessibility service, choose Installed apps > Utterly Voice Typing, turn it on and confirm.
3. Open any app with a text field (for example Messages or Notes), tap the field, tap the floating mic button and speak. The text appears at the cursor.
No login or account is needed.

## 4. Other forms
- App category: Tools. Free. Contains ads: No.
- Target audience: 18+ is the safest choice. The privacy policy says the app is not directed at children under 13.
- Content rating questionnaire: a utility app with no violence, sexual content, user-generated content or purchases, so answer No throughout. Answer honestly in the Console.
- Government/financial/health/news app questions: No.

## 5. Open risks (my honest view)
- Google may question why the app needs the Accessibility API at all, because a keyboard (IME) could do dictation without it. The declaration above explains the overlay and the field insertion, but I do not know if the reviewer will accept it.
- Google's policy may require a clear in-app disclosure and consent screen BEFORE the user is sent to Accessibility settings. Utterly currently sends the user straight to settings with a short subtitle. I could not confirm the exact requirement, so check the policy text in the Console. Adding a disclosure screen is a code change and needs a new build and version code.
- A short demo video is likely required for the declaration (see video-script.md).
