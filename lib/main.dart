import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const UtterApp());
}

class UtterApp extends StatelessWidget {
  const UtterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Utterly',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// Empty tag = follow the device language.
const _languages = <(String tag, String label)>[
  ('', 'Device language (auto)'),
  ('en-US', 'English (US)'),
  ('en-GB', 'English (UK)'),
  ('he-IL', 'עברית (Hebrew)'),
  ('fr-FR', 'Français (French)'),
  ('ro-RO', 'Română (Romanian)'),
  ('es-ES', 'Español (Spanish)'),
  ('pt-BR', 'Português (Brazil)'),
  ('de-DE', 'Deutsch (German)'),
  ('it-IT', 'Italiano (Italian)'),
  ('ru-RU', 'Русский (Russian)'),
  ('uk-UA', 'Українська (Ukrainian)'),
  ('ar-SA', 'العربية (Arabic)'),
  ('tr-TR', 'Türkçe (Turkish)'),
  ('pl-PL', 'Polski (Polish)'),
  ('nl-NL', 'Nederlands (Dutch)'),
  ('el-GR', 'Ελληνικά (Greek)'),
  ('hi-IN', 'हिन्दी (Hindi)'),
  ('ja-JP', '日本語 (Japanese)'),
  ('ko-KR', '한국어 (Korean)'),
  ('zh-CN', '中文 (Chinese, Mandarin)'),
];

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  static const _channel = MethodChannel('com.utter/accessibility');

  bool _accessibilityEnabled = false;
  PermissionStatus _micStatus = PermissionStatus.denied;
  bool _bubbleVisible = true;
  String _languageTag = '';

  String get _languageLabel =>
      _languages.firstWhere((l) => l.$1 == _languageTag, orElse: () => (_languageTag, _languageTag)).$2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final enabled = await _channel.invokeMethod<bool>('isAccessibilityServiceEnabled') ?? false;
    final micStatus = await Permission.microphone.status;
    final bubbleVisible = await _channel.invokeMethod<bool>('isBubbleVisible') ?? true;
    final languageTag = await _channel.invokeMethod<String>('getSpeechLanguage') ?? '';
    if (!mounted) return;
    setState(() {
      _accessibilityEnabled = enabled;
      _micStatus = micStatus;
      _bubbleVisible = bubbleVisible;
      _languageTag = languageTag;
    });
  }

  Future<void> _pickLanguage() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Speech language', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            for (final (tag, label) in _languages)
              ListTile(
                title: Text(label),
                trailing: tag == _languageTag ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, tag),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    await _channel.invokeMethod('setSpeechLanguage', {'tag': picked});
    if (!mounted) return;
    setState(() => _languageTag = picked);
  }

  Future<void> _openAccessibilitySettings() async {
    // Show the disclosure only when turning the service on; "Manage" goes straight to settings.
    if (!_accessibilityEnabled) {
      final agreed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Allow Utterly to use the Accessibility Service?'),
          content: const SingleChildScrollView(
            child: Text(
              'Utterly uses Android\'s Accessibility Service for two things only:\n\n'
              '• to show the mic button on top of other apps\n'
              '• to insert the text you dictate into the field you are using\n\n'
              'It does not read, store or share what is on your screen or what you type. '
              'Utterly has no internet access of its own.\n\n'
              'On the next screen, choose Installed apps > Utterly Voice Typing and turn it on. '
              'You can turn it off at any time in Settings > Accessibility.',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Not now')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Agree and continue')),
          ],
        ),
      );
      if (agreed != true) return;
    }
    await _channel.invokeMethod('openAccessibilitySettings');
  }

  Future<void> _setBubbleVisible(bool visible) async {
    await _channel.invokeMethod('setBubbleVisible', {'visible': visible});
    if (!mounted) return;
    setState(() => _bubbleVisible = visible);
  }

  Future<void> _requestMicPermission() async {
    if (_micStatus.isGranted) {
      await openAppSettings();
      return;
    }
    final status = await Permission.microphone.request();
    if (!mounted) return;
    setState(() => _micStatus = status);
    if (status.isPermanentlyDenied) await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final micGranted = _micStatus.isGranted;
    final allReady = _accessibilityEnabled && micGranted;

    return Scaffold(
      appBar: AppBar(title: const Text('Utterly')),
      body: RefreshIndicator(
        onRefresh: _refreshStatus,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: allReady ? Colors.green.shade50 : null,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      allReady ? Icons.check_circle : Icons.info_outline,
                      color: allReady ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        allReady
                            ? 'Utterly is ready. Look for the mic bubble over any app.'
                            : 'Finish setup below to start dictating into other apps.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _StatusTile(
              title: 'Accessibility service',
              subtitle: _accessibilityEnabled
                  ? 'Enabled — the mic bubble can appear over other apps.'
                  : 'Needed so Utterly can show a mic bubble and type into other apps.',
              granted: _accessibilityEnabled,
              buttonLabel: 'Open settings',
              onPressed: _openAccessibilitySettings,
            ),
            const SizedBox(height: 12),
            _StatusTile(
              title: 'Microphone permission',
              subtitle: micGranted
                  ? 'Granted — speech recognition can access the mic.'
                  : 'Needed so Utterly can hear what you say.',
              granted: micGranted,
              buttonLabel: 'Grant permission',
              onPressed: _requestMicPermission,
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Speech language'),
                subtitle: Text(_languageLabel),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickLanguage,
              ),
            ),
            if (_accessibilityEnabled) ...[
              const SizedBox(height: 12),
              Card(
                child: SwitchListTile(
                  title: const Text('Show mic bubble'),
                  subtitle: Text(
                    _bubbleVisible
                        ? 'Visible over other apps. Turn off or long-press the bubble to hide it.'
                        : 'Hidden. Turn back on to show the bubble again.',
                  ),
                  value: _bubbleVisible,
                  onChanged: _setBubbleVisible,
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'How to use',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Complete the two steps above.\n'
              '2. Open WhatsApp, Instagram, Tinder, or any app.\n'
              '3. Tap a text field, then tap the floating mic bubble.\n'
              '4. Speak — your words are inserted where you tapped.\n'
              '5. Drag the bubble anywhere it\'s in the way.',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final bool granted;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          granted ? Icons.check_circle : Icons.cancel,
          color: granted ? Colors.green : Colors.red,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: TextButton(onPressed: onPressed, child: Text(granted ? 'Manage' : buttonLabel)),
      ),
    );
  }
}
