import 'package:flutter_test/flutter_test.dart';
import 'package:attendance/main.dart';

void main() {
  testWidgets('SmartAttendanceApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartAttendanceApp());
    await tester.pumpAndSettle();

    // Verify main components render
    expect(find.text('Welcome back,'), findsOneWidget);
    expect(find.text('30-Day Attendance Overview'), findsOneWidget);
  });
}
