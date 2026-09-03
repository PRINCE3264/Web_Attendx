import 'package:flutter_test/flutter_test.dart';
import 'package:AttendX/main.dart';

void main() {
  testWidgets('SmartAttendanceApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartAttendanceApp());
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.byType(SmartAttendanceApp), findsOneWidget);
  });
}
