import 'package:flutter_test/flutter_test.dart';
import 'package:attendance/models/user_model.dart';
import 'package:attendance/models/attendance_model.dart';
import 'package:attendance/models/break_model.dart';
import 'package:attendance/models/leave_model.dart';
import 'package:attendance/services/report_service.dart';
import 'package:attendance/services/geofence_service.dart';
import 'package:attendance/services/auth_service.dart';
import 'package:attendance/core/permissions/role_model.dart';
import 'package:attendance/core/permissions/permission_service.dart';
import 'package:attendance/core/navigation/nav_menu_item.dart';
import 'package:attendance/core/navigation/role_menu_builder.dart';

void main() {
  group('Smart Attendance & Enterprise Modules Tests', () {
    final testUser = UserModel(
      userId: 'test_emp_01',
      name: 'Test Employee',
      email: 'test@company.com',
      role: UserRole.employee,
      employeeId: 'EMP-9999',
      teamId: 'team_dev',
      department: 'Engineering',
    );

    test('AttendanceModel with Breaks calculates Net Productive Duration', () {
      final clockIn = DateTime(2026, 8, 30, 9, 0);
      final clockOut = DateTime(2026, 8, 30, 18, 0); // 9 hours (540 mins gross)

      final record = AttendanceModel(
        attendanceId: 'test_att_01',
        employeeId: 'test_emp_01',
        employeeName: 'Test Employee',
        employeeCode: 'EMP-9999',
        teamId: 'team_dev',
        date: '2026-08-30',
        clockInTime: clockIn,
        clockOutTime: clockOut,
        totalBreakMinutes: 60, // 1 hour break
        breaks: [
          BreakRecord(
            breakId: 'b1',
            type: BreakType.tea,
            startTime: DateTime(2026, 8, 30, 11, 0),
            endTime: DateTime(2026, 8, 30, 11, 15),
            durationMinutes: 15,
          ),
          BreakRecord(
            breakId: 'b2',
            type: BreakType.lunch,
            startTime: DateTime(2026, 8, 30, 13, 0),
            endTime: DateTime(2026, 8, 30, 13, 45),
            durationMinutes: 45,
          ),
        ],
        status: AttendanceStatus.completed,
      );

      expect(record.grossDuration?.inMinutes, 540);
      expect(record.netWorkingDuration?.inMinutes, 480); // 8 hours net
      expect(record.formattedNetDuration, '8h 0m');
    });

    test('GeofenceService Haversine formula calculates accurate proximity distance', () {
      // Office: Connaught Place, New Delhi (28.6139, 77.2090)
      const officeLat = 28.6139;
      const officeLng = 77.2090;

      // User exactly at office
      final resExact = GeofenceService.verifyLocation(
        userLat: officeLat,
        userLng: officeLng,
        officeLat: officeLat,
        officeLng: officeLng,
        allowedRadiusMeters: 300.0,
      );

      expect(resExact.isWithinGeofence, true);
      expect(resExact.distanceMeters, 0.0);

      // User 5km away
      final resFar = GeofenceService.verifyLocation(
        userLat: 28.6500,
        userLng: 77.2500,
        officeLat: officeLat,
        officeLng: officeLng,
        allowedRadiusMeters: 300.0,
      );

      expect(resFar.isWithinGeofence, false);
      expect(resFar.distanceMeters > 300.0, true);
    });

    test('LeaveBalanceModel computes remaining days correctly', () {
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

    test('30-Day Report Calculation computes correct present & absent days', () {
      final now = DateTime.now();
      final List<AttendanceModel> history = [];

      for (int i = 1; i <= 15; i++) {
        final pastDate = now.subtract(Duration(days: i));
        history.add(
          AttendanceModel(
            attendanceId: 'rec_$i',
            employeeId: 'test_emp_01',
            employeeName: 'Test Employee',
            employeeCode: 'EMP-9999',
            teamId: 'team_dev',
            date: '${pastDate.year}-${pastDate.month.toString().padLeft(2, '0')}-${pastDate.day.toString().padLeft(2, '0')}',
            clockInTime: DateTime(pastDate.year, pastDate.month, pastDate.day, 9, 0),
            clockOutTime: DateTime(pastDate.year, pastDate.month, pastDate.day, 17, 30),
            totalWorkMinutes: 510,
            status: AttendanceStatus.completed,
          ),
        );
      }

      final report = ReportService.calculate30DayReport(
        employee: testUser,
        attendanceList: history,
        referenceDate: now,
      );

      expect(report.employeeId, 'test_emp_01');
      expect(report.presentDays, 15);
      expect(report.totalHoursWorked, (15 * 510) / 60.0);
    });

    test('AuthService handles Sign Up and duplicate email prevention', () async {
      final auth = AuthService();
      final user = await auth.signUpWithEmailAndPassword(
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

      // Duplicate registration should throw
      expect(
        () async => await auth.signUpWithEmailAndPassword(
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
      final resetCodeSent = await auth.sendPasswordResetEmail('rahul.sharma@company.com');
      expect(resetCodeSent, true);

      final resetSuccess = await auth.resetPassword(
        email: 'rahul.sharma@company.com',
        newPassword: 'newSecretPassword123',
      );
      expect(resetSuccess, true);
    });

    test('RBAC: RoleMenuBuilder generates strictly role-specific menus', () {
      final empMenu = RoleMenuBuilder.getMenuForRole(role: AppRole.employee);
      final tlMenu = RoleMenuBuilder.getMenuForRole(role: AppRole.tl);
      final hrMenu = RoleMenuBuilder.getMenuForRole(role: AppRole.hr);
      final adminMenu = RoleMenuBuilder.getMenuForRole(role: AppRole.admin);

      // Employee has 12 items including Clock In, History, Calendar, etc.
      expect(empMenu.any((m) => m.destination == NavDestinationKey.clockIn), true);
      expect(empMenu.any((m) => m.destination == NavDestinationKey.users), false);

      // TL has Team Attendance & Pending Approvals
      expect(tlMenu.any((m) => m.destination == NavDestinationKey.pendingApprovals), true);
      expect(tlMenu.any((m) => m.destination == NavDestinationKey.users), false);

      // HR has Reports, Teams, Departments, Shifts
      expect(hrMenu.any((m) => m.destination == NavDestinationKey.dailyReport), true);
      expect(hrMenu.any((m) => m.destination == NavDestinationKey.auditLogs), false);

      // Admin has full management menus (Users, Policies, Audit Logs, Geofencing)
      expect(adminMenu.any((m) => m.destination == NavDestinationKey.users), true);
      expect(adminMenu.any((m) => m.destination == NavDestinationKey.auditLogs), true);
      expect(adminMenu.any((m) => m.destination == NavDestinationKey.geofencing), true);
    });

    test('RBAC: PermissionService enforces capability and route restrictions', () {
      // Employee cannot approve attendance or access /admin/*
      expect(PermissionService.hasPermission(AppRole.employee, AppPermission.approveAttendance), false);
      expect(PermissionService.canAccessRoute(AppRole.employee, '/admin/settings'), false);
      expect(PermissionService.canAccessRoute(AppRole.employee, '/employee/dashboard'), true);

      // TL can approve attendance but cannot manage users or system settings
      expect(PermissionService.hasPermission(AppRole.tl, AppPermission.approveAttendance), true);
      expect(PermissionService.hasPermission(AppRole.tl, AppPermission.manageUsers), false);
      expect(PermissionService.canAccessRoute(AppRole.tl, '/tl/team-attendance'), true);
      expect(PermissionService.canAccessRoute(AppRole.tl, '/admin/users'), false);

      // HR can generate reports and view employees
      expect(PermissionService.hasPermission(AppRole.hr, AppPermission.generateAttendanceReports), true);
      expect(PermissionService.hasPermission(AppRole.hr, AppPermission.manageSystemSettings), false);

      // Admin has full capabilities
      expect(PermissionService.hasPermission(AppRole.admin, AppPermission.manageSystemSettings), true);
      expect(PermissionService.canAccessRoute(AppRole.admin, '/admin/audit-logs'), true);
    });
  });
}
