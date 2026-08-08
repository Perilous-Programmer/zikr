import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zikr_timer/main.dart';

void main() {
  testWidgets('App renders and start/pause/resume flow works',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(ZikrApp(prefs: prefs));

    expect(find.text('Zikr Allah'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);

    await tester.ensureVisible(find.text('Start'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await tester.pump();

    // Let one second elapse, then pause so the ticker is stopped.
    await tester.pump(const Duration(seconds: 1));
    await tester.ensureVisible(find.text('Pause'));
    await tester.tap(find.text('Pause'));
    await tester.pump();
    expect(find.text('Resume'), findsOneWidget);
  });

  test('formatHMS always renders hh:mm:ss', () {
    expect(formatHMS(0), '00:00:00');
    expect(formatHMS(2704), '00:45:04');
    expect(formatHMS(3661), '01:01:01');
    expect(formatHMS(-5), '00:00:00');
  });

  test('formatClock formats hours, minutes and seconds', () {
    expect(formatClock(0), '00:00');
    expect(formatClock(75), '01:15');
    expect(formatClock(3600), '1:00:00');
  });
}
