import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_pulse/main.dart';

void main() {
  testWidgets('Splash screen rendering smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GuardianPulseApp());

    // Verify that the splash screen app name is rendered.
    expect(find.text('GUARDIAN PULSE'), findsOneWidget);
  });
}
