import 'package:flutter_test/flutter_test.dart';

import 'package:utter/main.dart';

void main() {
  testWidgets('Home page shows setup status tiles', (WidgetTester tester) async {
    await tester.pumpWidget(const UtterApp());
    await tester.pump();

    expect(find.text('Utter'), findsOneWidget);
    expect(find.text('Accessibility service'), findsOneWidget);
    expect(find.text('Microphone permission'), findsOneWidget);
  });
}
