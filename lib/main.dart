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

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  static const _channel = MethodChannel('com.utter/accessibility');

  bool _accessibilityEnabled = false;
  PermissionStatus _micStatus = PermissionStatus.denied;
  bool _bubbleVisible = true;

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
    if (!mounted) return;
    setState(() {
      _accessibilityEnabled = enabled;
      _micStatus = micStatus;
      _bubbleVisible = bubbleVisible;
    });
  }

  Future<void> _openAccessibilitySettings() async {
    await _channel.invokeMethod('openAccessibilitySettings');
  }

  Future<void> _setBubbleVisible(bool visible) async {
    await _channel.invokeMethod('setBubbleVisible', {'visible': visible});
    if (!mounted) return;
    setState(() => _bubbleVisible = visible);
  }

  Future<void> _requestMicPermission() async {
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
                  : 'Needed so Utter can show a mic bubble and type into other apps.',
              granted: _accessibilityEnabled,
              buttonLabel: 'Open settings',
              onPressed: _openAccessibilitySettings,
            ),
            const SizedBox(height: 12),
            _StatusTile(
              title: 'Microphone permission',
              subtitle: micGranted
                  ? 'Granted — speech recognition can access the mic.'
                  : 'Needed so Utter can hear what you say.',
              granted: micGranted,
              buttonLabel: 'Grant permission',
              onPressed: _requestMicPermission,
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
        trailing: granted ? null : TextButton(onPressed: onPressed, child: Text(buttonLabel)),
      ),
    );
  }
}
