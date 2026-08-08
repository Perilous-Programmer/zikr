import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zikr_timer/main.dart';

void main() {
  testWidgets('App renders and start button toggles to pause',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(ZikrApp(prefs: prefs));

    expect(find.text('Zikr Timer'), findsOneWidget);
    expect(find.textContaining('Start'), findsOneWidget);

    await tester.tap(find.textContaining('Start'));
    await tester.pump();
    expect(find.textContaining('Pause'), findsOneWidget);

    // Let one second elapse, then pause so the ticker is stopped.
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.textContaining('Pause'));
    await tester.pump();
    expect(find.textContaining('Resume'), findsOneWidget);
  });

  test('formatClock formats hours, minutes and seconds', () {
    expect(formatClock(0), '00:00');
    expect(formatClock(75), '01:15');
    expect(formatClock(3600), '1:00:00');
    expect(formatClock(-5), '00:00');
  });
}
