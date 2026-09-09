import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:AttendX/main.dart';

void main() {
  testWidgets('SmartAttendanceApp smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SmartAttendanceApp());
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SmartAttendanceApp), findsOneWidget);
  });
}
