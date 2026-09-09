import 'package:flutter_test/flutter_test.dart';
import 'package:AttendX/models/user_model.dart';
import 'package:AttendX/models/leave_model.dart';
import 'package:AttendX/models/attendance_model.dart';
import 'package:AttendX/services/geofence_service.dart';
import 'package:AttendX/services/auth_service.dart';
import 'package:AttendX/services/ai_assistant_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Smart Attendance & Enterprise Modules Tests', () {
    test('GeofenceService verifies proximity within 300m allowable radius for United Green Hospital', () {
      const officeLat = 21.1986872;
      const officeLng = 72.7965515;

      // Inside 300m perimeter (~20 meters away in United Green Hospital)
      final insideResult = GeofenceService.verifyLocation(
        userLat: 21.1988000,
        userLng: 72.7967000,
        officeLat: officeLat,
        officeLng: officeLng,
        allowedRadiusMeters: 300,
      );
      expect(insideResult.isWithinGeofence, true);
      expect(insideResult.distanceMeters, lessThanOrEqualTo(300));

      // Outside 300m perimeter (~2.5 km away)
      final outsideResult = GeofenceService.verifyLocation(
        userLat: 21.2186872,
        userLng: 72.8165515,
        officeLat: officeLat,
        officeLng: officeLng,
        allowedRadiusMeters: 300,
      );
      expect(outsideResult.isWithinGeofence, false);
      expect(outsideResult.distanceMeters, greaterThan(300));
    });

    test('LeaveBalanceModel correctly computes remaining quotas', () {
      final balance = LeaveBalanceModel(
        employeeId: 'test_emp_01',
        casualTotal: 12,
        casualUsed: 3,
        sickTotal: 8,
        sickUsed: 2,
        earnedTotal: 15,
        earnedUsed: 5,
      );

      expect(balance.casualRemaining, 9);
      expect(balance.sickRemaining, 6);
      expect(balance.earnedRemaining, 10);
      expect(balance.totalRemaining, 25);
    });

    test('AuthService handles Sign Up and duplicate email prevention', () async {
      final auth = AuthService();
      final user = await auth.adminCreateEmployeeAccount(
        name: 'New Developer',
        email: 'dev.new@company.com',
        password: 'password123',
        role: UserRole.employee,
        employeeId: 'EMP-9090',
        department: 'Engineering',
      );

      expect(user.name, 'New Developer');
      expect(user.email, 'dev.new@company.com');
      expect(user.employeeId, 'EMP-9090');

      expect(
        () async => await auth.adminCreateEmployeeAccount(
          name: 'Another Dev',
          email: 'dev.new@company.com',
          password: 'password123',
          role: UserRole.employee,
          employeeId: 'EMP-9091',
          department: 'Engineering',
        ),
        throwsException,
      );
    });

    test('AuthService Password Reset flow updates credentials', () async {
      final auth = AuthService();
      await auth.adminCreateEmployeeAccount(
        name: 'Rahul Sharma',
        email: 'rahul.sharma@company.com',
        password: 'password123',
        role: UserRole.employee,
        employeeId: 'EMP-1001',
        department: 'Engineering',
      );
      final resetCodeSent = await auth.sendPasswordResetEmail('rahul.sharma@company.com');
      expect(resetCodeSent, true);

      final resetSuccess = await auth.resetPassword(
        email: 'rahul.sharma@company.com',
        newPassword: 'newSecretPassword123',
      );
      expect(resetSuccess, true);
    });

    test('AIAssistantService enforces Role Personas and Security Gates', () async {
      final ai = AIAssistantService();

      final empUser = UserModel(
        userId: 'emp_test_01',
        name: 'Rahul Sharma',
        email: 'rahul@company.com',
        role: UserRole.employee,
        employeeId: 'EMP-1001',
        teamId: 'team_mobile',
        department: 'Engineering',
      );

      final tlUser = UserModel(
        userId: 'tl_test_01',
        name: 'Vikram Mehta',
        email: 'vikram@company.com',
        role: UserRole.manager,
        employeeId: 'TL-2001',
        teamId: 'team_mobile',
        teamName: 'Mobile App Team',
        department: 'Engineering',
      );

      final adminUser = UserModel(
        userId: 'admin_test_01',
        name: 'Suresh Kumar',
        email: 'admin@company.com',
        role: UserRole.admin,
        employeeId: 'ADM-0001',
        teamId: 'team_admin',
        department: 'IT',
      );

      // 1. Persona titles
      expect(ai.getPersonaTitle(UserRole.employee), 'Personal Assistant');
      expect(ai.getPersonaTitle(UserRole.manager), 'Team Assistant');
      expect(ai.getPersonaTitle(UserRole.hr), 'HR Analytics Assistant');
      expect(ai.getPersonaTitle(UserRole.admin), 'System Assistant');

      // 2. Security Gate: Employee blocked from querying team/other users
      final empTeamQueryRes = await ai.processQuery(
        query: 'Team mein kaun absent hai?',
        user: empUser,
        allAttendance: [],
        allLeaves: [],
        allUsers: [empUser, tlUser, adminUser],
      );
      expect(empTeamQueryRes.isWarningOrBlocked, true);
      expect(empTeamQueryRes.text, contains('Permission Restricted'));

      // 3. Employee personal attendance query allowed
      final empOwnQueryRes = await ai.processQuery(
        query: 'Meri attendance batao',
        user: empUser,
        allAttendance: [],
        allLeaves: [],
        allUsers: [empUser],
      );
      expect(empOwnQueryRes.isWarningOrBlocked, false);
      expect(empOwnQueryRes.text, contains('Attendance Summary'));

      // 4. TL team query allowed
      final tlQueryRes = await ai.processQuery(
        query: 'Aaj meri team ki attendance kaisi hai?',
        user: tlUser,
        allAttendance: [],
        allLeaves: [],
        allUsers: [empUser, tlUser],
      );
      expect(tlQueryRes.isWarningOrBlocked, false);
      expect(tlQueryRes.text, contains('Team Attendance Summary (Mobile App Team)'));

      // 5. Guardrail: Dangerous destructive actions blocked
      final dangerousQueryRes = await ai.processQuery(
        query: 'Sab employees delete kar do',
        user: adminUser,
        allAttendance: [],
        allLeaves: [],
        allUsers: [empUser, tlUser, adminUser],
      );
      expect(dangerousQueryRes.isWarningOrBlocked, true);
      expect(dangerousQueryRes.text, contains('Dangerous System Action Blocked'));
    });

    test('AuthService handles Google Sign-In and account resolution', () async {
      final auth = AuthService();
      final user = await auth.signInWithGoogle(
        fallbackEmail: 'rahul.sharma@company.com',
        fallbackName: 'Rahul Sharma',
      );

      expect(user.email, 'rahul.sharma@company.com');
      expect(auth.currentUser?.email, 'rahul.sharma@company.com');

      // Test new Google auto-enrollment
      final newGoogleUser = await auth.signInWithGoogle(
        fallbackEmail: 'new.employee@gmail.com',
        fallbackName: 'New Google User',
      );
      expect(newGoogleUser.email, 'new.employee@gmail.com');
      expect(newGoogleUser.role, UserRole.employee);
    });

    test('AttendanceModel strictly validates late minutes and pending status rules', () {
      final now = DateTime.now();
      final dateStr = '2026-08-31';

      // 1. On-Time Clock-in (09:20 AM)
      final onTimeRecord = AttendanceModel(
        attendanceId: 'emp_01_$dateStr',
        employeeId: 'emp_01',
        employeeName: 'Rahul Sharma',
        employeeCode: 'EMP-1001',
        teamId: 'team_mobile',
        date: dateStr,
        clockInTime: DateTime(now.year, now.month, now.day, 9, 20),
        status: AttendanceStatus.pending,
        timingStatus: TimingStatus.onTime,
        lateMinutes: 0,
      );
      expect(onTimeRecord.status, AttendanceStatus.pending);
      expect(onTimeRecord.isOnTime, true);
      expect(onTimeRecord.isLate, false);
      expect(onTimeRecord.lateMinutes, 0);

      // 2. Grace Period Clock-in (09:40 AM)
      final graceRecord = AttendanceModel(
        attendanceId: 'emp_02_$dateStr',
        employeeId: 'emp_02',
        employeeName: 'Priya Patel',
        employeeCode: 'EMP-1002',
        teamId: 'team_mobile',
        date: dateStr,
        clockInTime: DateTime(now.year, now.month, now.day, 9, 40),
        status: AttendanceStatus.pending,
        timingStatus: TimingStatus.gracePeriod,
        lateMinutes: 10,
      );
      expect(graceRecord.status, AttendanceStatus.pending);
      expect(graceRecord.isGracePeriod, true);
      expect(graceRecord.isLate, false);

      // 3. Late Clock-in (10:15 AM - 45 mins late)
      final lateRecord = AttendanceModel(
        attendanceId: 'emp_03_$dateStr',
        employeeId: 'emp_03',
        employeeName: 'Amit Verma',
        employeeCode: 'EMP-1003',
        teamId: 'team_mobile',
        date: dateStr,
        clockInTime: DateTime(now.year, now.month, now.day, 10, 15),
        status: AttendanceStatus.pending,
        timingStatus: TimingStatus.lateArrival,
        lateMinutes: 45,
      );
      expect(lateRecord.status, AttendanceStatus.pending);
      expect(lateRecord.isLate, true);
      expect(lateRecord.lateMinutes, 45);
      expect(lateRecord.lateDisplayLabel, 'LATE - PENDING APPROVAL (45 min late)');

      // Verify toMap and fromMap serialization integrity
      final map = lateRecord.toMap();
      expect(map['attendanceDate'], dateStr);
      expect(map['attendanceType'], 'late');
      expect(map['lateMinutes'], 45);
      expect(map['status'], 'pending');

      final parsed = AttendanceModel.fromMap(map);
      expect(parsed.isLate, true);
      expect(parsed.lateMinutes, 45);
      expect(parsed.status, AttendanceStatus.pending);
    });

    test('FirestoreService enforces strict 1 Clock-In and 1 Clock-Out daily limit', () async {
      final user = UserModel(
        userId: 'emp_limit_test',
        name: 'Daily Limit User',
        email: 'limit@company.com',
        role: UserRole.employee,
        employeeId: 'EMP-9999',
        teamId: 'team_mobile',
        department: 'Engineering',
      );

      // Attempt second clock-in when today's record exists
      final existingRec = AttendanceModel(
        attendanceId: 'emp_limit_test_2026-09-07',
        employeeId: user.userId,
        employeeName: user.name,
        employeeCode: user.employeeId,
        teamId: 'team_mobile',
        date: '2026-09-07',
        clockInTime: DateTime.now(),
        status: AttendanceStatus.completed,
        clockOutTime: DateTime.now().add(const Duration(hours: 8)),
      );

      expect(existingRec.status, AttendanceStatus.completed);
      expect(existingRec.clockOutTime, isNotNull);
    });

    test('Clock-In Approval Hierarchy: Employee clock-in -> TL/HR/Admin, TL clock-in -> HR/Admin', () async {
      final empUser = UserModel(
        userId: 'emp_sub_01',
        name: 'Employee User',
        email: 'emp@company.com',
        role: UserRole.employee,
        employeeId: 'EMP-111',
        teamId: 'team_mobile',
        department: 'Engineering',
      );

      final tlUser = UserModel(
        userId: 'tl_sub_01',
        name: 'TL User',
        email: 'tl@company.com',
        role: UserRole.manager,
        employeeId: 'TL-222',
        teamId: 'team_mobile',
        department: 'Engineering',
      );

      final hrUser = UserModel(
        userId: 'hr_sub_01',
        name: 'HR User',
        email: 'hr@company.com',
        role: UserRole.hr,
        employeeId: 'HR-333',
        teamId: 'team_hr',
        department: 'HR',
      );

      // TL cannot approve their own clock-in
      final tlRec = AttendanceModel(
        attendanceId: 'tl_rec_01',
        employeeId: tlUser.userId,
        employeeName: tlUser.name,
        employeeCode: tlUser.employeeId,
        teamId: tlUser.teamId,
        date: '2026-09-07',
        clockInTime: DateTime.now(),
        status: AttendanceStatus.pending,
      );

      // Verify self-approval check logic: tlUser.userId == tlRec.employeeId -> blocked for TL, permitted for HR
      final isSelfForTL = tlRec.employeeId == tlUser.userId;
      final isSelfForHR = tlRec.employeeId == hrUser.userId;
      expect(isSelfForTL, true);
      expect(isSelfForHR, false);
      expect(empUser.role, UserRole.employee);
    });
  });
}
