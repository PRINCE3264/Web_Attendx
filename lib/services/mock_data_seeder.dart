import 'package:intl/intl.dart';

import '../models/user_model.dart';
import '../models/attendance_model.dart';
import '../models/team_model.dart';
import '../models/break_model.dart';
import '../models/leave_model.dart';
import '../models/correction_model.dart';
import '../models/policy_model.dart';
import '../models/audit_log_model.dart';

class MockDataSeeder {
  static List<UserModel> getSeedUsers() {
    return [
      UserModel(
        userId: 'emp_01',
        name: 'Rahul Sharma',
        email: 'rahul.sharma@company.com',
        role: UserRole.employee,
        employeeId: 'EMP-1042',
        teamId: 'team_mobile',
        teamName: 'Mobile App Team',
        managerId: 'mgr_01',
        managerName: 'Vikram Mehta (TL)',
        department: 'Engineering',
        avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
        isActive: true,
      ),
      UserModel(
        userId: 'emp_02',
        name: 'Priya Patel',
        email: 'priya.patel@company.com',
        role: UserRole.employee,
        employeeId: 'EMP-1043',
        teamId: 'team_mobile',
        teamName: 'Mobile App Team',
        managerId: 'mgr_01',
        managerName: 'Vikram Mehta (TL)',
        department: 'Engineering',
        avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
        isActive: true,
      ),
      UserModel(
        userId: 'emp_03',
        name: 'Amit Verma',
        email: 'amit.verma@company.com',
        role: UserRole.employee,
        employeeId: 'EMP-1044',
        teamId: 'team_backend',
        teamName: 'Backend & Cloud Team',
        managerId: 'mgr_01',
        managerName: 'Vikram Mehta (TL)',
        department: 'Engineering',
        avatarUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150',
        isActive: true,
      ),
      UserModel(
        userId: 'emp_04',
        name: 'Sneha Reddy',
        email: 'sneha.reddy@company.com',
        role: UserRole.employee,
        employeeId: 'EMP-1045',
        teamId: 'team_mobile',
        teamName: 'Mobile App Team',
        managerId: 'mgr_01',
        managerName: 'Vikram Mehta (TL)',
        department: 'Design & UI',
        avatarUrl: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150',
        isActive: true,
      ),
      UserModel(
        userId: 'mgr_01',
        name: 'Vikram Mehta',
        email: 'vikram.mehta@company.com',
        role: UserRole.manager,
        employeeId: 'MGR-201',
        teamId: 'team_mobile',
        teamName: 'Engineering & Mobile Team',
        department: 'Engineering Management',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        isActive: true,
      ),
      UserModel(
        userId: 'hr_01',
        name: 'Ananya Deshmukh',
        email: 'hr.ananya@company.com',
        role: UserRole.hr,
        employeeId: 'HR-101',
        teamId: 'team_hr',
        teamName: 'Human Resources & People Ops',
        department: 'Human Resources',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        isActive: true,
      ),
      UserModel(
        userId: 'admin_01',
        name: 'Super Administrator',
        email: 'admin@company.com',
        role: UserRole.admin,
        employeeId: 'ADM-001',
        teamId: 'team_mgmt',
        teamName: 'Executive Leadership',
        department: 'Corporate Administration',
        avatarUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
        isActive: true,
      ),
    ];
  }

  static List<TeamModel> getSeedTeams() {
    return [
      TeamModel(
        teamId: 'team_mobile',
        name: 'Mobile App Engineering',
        managerId: 'mgr_01',
        managerName: 'Vikram Mehta',
        memberCount: 3,
      ),
      TeamModel(
        teamId: 'team_backend',
        name: 'Backend & Cloud Infrastructure',
        managerId: 'mgr_01',
        managerName: 'Vikram Mehta',
        memberCount: 1,
      ),
      TeamModel(
        teamId: 'team_hr',
        name: 'People Operations',
        managerId: 'hr_01',
        managerName: 'Ananya Deshmukh',
        memberCount: 1,
      ),
    ];
  }

  static AttendancePolicyModel getSeedPolicy() {
    return AttendancePolicyModel(
      policyId: 'default_policy',
      officeStartTime: '09:30',
      gracePeriodMinutes: 15,
      lateThresholdTime: '09:45',
      minimumWorkingHours: 8.0,
      maxBreakMinutes: 60,
      isAutoClockOutEnabled: false,
      officeLatitude: 21.1986872,
      officeLongitude: 72.7965515,
      geofenceRadiusMeters: 500.0,
      officeName: 'Green Atria, Society, Anand Mahal Rd, beside Silver Park, in front of Sneh Sankul Wadi, Giriraj Society, Adajan, Surat, Gujarat 395009',
    );
  }

  static List<LeaveBalanceModel> getSeedLeaveBalances() {
    return [
      LeaveBalanceModel(
        employeeId: 'emp_01',
        casualTotal: 12,
        casualUsed: 2,
        sickTotal: 8,
        sickUsed: 1,
        earnedTotal: 15,
        earnedUsed: 3,
      ),
      LeaveBalanceModel(
        employeeId: 'emp_02',
        casualTotal: 12,
        casualUsed: 1,
        sickTotal: 8,
        sickUsed: 0,
        earnedTotal: 15,
        earnedUsed: 1,
      ),
      LeaveBalanceModel(
        employeeId: 'emp_03',
        casualTotal: 12,
        casualUsed: 4,
        sickTotal: 8,
        sickUsed: 2,
        earnedTotal: 15,
        earnedUsed: 0,
      ),
      LeaveBalanceModel(
        employeeId: 'emp_04',
        casualTotal: 12,
        casualUsed: 0,
        sickTotal: 8,
        sickUsed: 1,
        earnedTotal: 15,
        earnedUsed: 2,
      ),
    ];
  }

  static List<LeaveRequestModel> getSeedLeaveRequests() {
    final now = DateTime.now();
    return [
      LeaveRequestModel(
        leaveId: 'leave_01',
        employeeId: 'emp_02',
        employeeName: 'Priya Patel',
        employeeCode: 'EMP-1043',
        department: 'Engineering',
        leaveType: LeaveType.casual,
        startDate: now.add(const Duration(days: 2)),
        endDate: now.add(const Duration(days: 3)),
        totalDays: 2,
        reason: 'Family wedding event in hometown',
        status: LeaveStatus.pending,
      ),
      LeaveRequestModel(
        leaveId: 'leave_02',
        employeeId: 'emp_03',
        employeeName: 'Amit Verma',
        employeeCode: 'EMP-1044',
        department: 'Engineering',
        leaveType: LeaveType.sick,
        startDate: now.subtract(const Duration(days: 4)),
        endDate: now.subtract(const Duration(days: 4)),
        totalDays: 1,
        reason: 'Seasonal viral fever and medical checkup',
        status: LeaveStatus.approved,
        reviewedBy: 'mgr_01',
        reviewerName: 'Vikram Mehta (TL)',
        reviewedAt: now.subtract(const Duration(days: 4)),
      ),
    ];
  }

  static List<AttendanceCorrectionModel> getSeedCorrections() {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final df = DateFormat('yyyy-MM-dd');

    return [
      AttendanceCorrectionModel(
        correctionId: 'corr_01',
        attendanceId: 'emp_01_${df.format(yesterday)}',
        employeeId: 'emp_01',
        employeeName: 'Rahul Sharma',
        employeeCode: 'EMP-1042',
        date: df.format(yesterday),
        requestedClockIn: DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day,
          9,
          30,
        ),
        requestedClockOut: DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day,
          18,
          30,
        ),
        reason: 'Office biometric scanner sync glitch & mobile network outage during clock out.',
        status: CorrectionStatus.pending,
      ),
    ];
  }

  static List<AuditLogModel> getSeedAuditLogs() {
    final now = DateTime.now();
    return [
      AuditLogModel(
        logId: 'log_01',
        actorId: 'mgr_01',
        actorName: 'Vikram Mehta',
        actorRole: 'TL / Manager',
        actionType: 'TL_APPROVED',
        description: 'Approved clock-in attendance with photo verification for Sneha Reddy.',
        targetEntityId: 'emp_04',
        timestamp: now.subtract(const Duration(hours: 3)),
      ),
      AuditLogModel(
        logId: 'log_02',
        actorId: 'admin_01',
        actorName: 'Super Administrator',
        actorRole: 'Admin',
        actionType: 'POLICY_UPDATE',
        description: 'Updated grace period to 15 minutes and office start time to 09:30 AM.',
        targetEntityId: 'default_policy',
        oldValue: 'Grace: 10m',
        newValue: 'Grace: 15m',
        timestamp: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  static List<AttendanceModel> getSeedAttendanceHistory() {
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd');
    final todayStr = dateFormat.format(now);
    final List<AttendanceModel> records = [];

    // Today's records for TL review
    records.add(
      AttendanceModel(
        attendanceId: 'emp_02_$todayStr',
        employeeId: 'emp_02',
        employeeName: 'Priya Patel',
        employeeCode: 'EMP-1043',
        employeeAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
        teamId: 'team_mobile',
        teamName: 'Mobile App Team',
        date: todayStr,
        clockInTime: DateTime(now.year, now.month, now.day, 9, 15),
        clockInPhotoUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=600',
        status: AttendanceStatus.pending,
        timingStatus: TimingStatus.onTime,
        latitude: 28.6141,
        longitude: 77.2092,
        isWithinGeofence: true,
        distanceFromOfficeMeters: 35.0,
        location: 'HQ Office - Floor 3',
      ),
    );

    records.add(
      AttendanceModel(
        attendanceId: 'emp_03_$todayStr',
        employeeId: 'emp_03',
        employeeName: 'Amit Verma',
        employeeCode: 'EMP-1044',
        employeeAvatar: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150',
        teamId: 'team_backend',
        teamName: 'Backend & Cloud Team',
        date: todayStr,
        clockInTime: DateTime(now.year, now.month, now.day, 10, 10),
        clockInPhotoUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=600',
        status: AttendanceStatus.pending,
        timingStatus: TimingStatus.lateArrival,
        latitude: 28.6145,
        longitude: 77.2095,
        isWithinGeofence: true,
        distanceFromOfficeMeters: 75.0,
        location: 'HQ Office - Floor 4',
      ),
    );

    records.add(
      AttendanceModel(
        attendanceId: 'emp_04_$todayStr',
        employeeId: 'emp_04',
        employeeName: 'Sneha Reddy',
        employeeCode: 'EMP-1045',
        employeeAvatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150',
        teamId: 'team_mobile',
        teamName: 'Mobile App Team',
        date: todayStr,
        clockInTime: DateTime(now.year, now.month, now.day, 8, 55),
        clockInPhotoUrl: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=600',
        status: AttendanceStatus.approved,
        timingStatus: TimingStatus.onTime,
        approvedBy: 'mgr_01',
        approvedByName: 'Vikram Mehta (TL)',
        approvedAt: DateTime(now.year, now.month, now.day, 9, 5),
        totalBreakMinutes: 15,
        breaks: [
          BreakRecord(
            breakId: 'brk_01',
            type: BreakType.tea,
            startTime: DateTime(now.year, now.month, now.day, 11, 0),
            endTime: DateTime(now.year, now.month, now.day, 11, 15),
            durationMinutes: 15,
          ),
        ],
        latitude: 21.1986872,
        longitude: 72.7965515,
        isWithinGeofence: true,
        distanceFromOfficeMeters: 12.0,
        location: 'Green Atria, Surat Office',
      ),
    );

    // Generate past 30 days history for Rahul Sharma (emp_01)
    for (int i = 1; i <= 30; i++) {
      final pastDate = now.subtract(Duration(days: i));
      if (pastDate.weekday == DateTime.saturday ||
          pastDate.weekday == DateTime.sunday) {
        continue;
      }

      final dateStr = dateFormat.format(pastDate);

      if (i == 5) {
        records.add(
          AttendanceModel(
            attendanceId: 'emp_01_$dateStr',
            employeeId: 'emp_01',
            employeeName: 'Rahul Sharma',
            employeeCode: 'EMP-1042',
            teamId: 'team_mobile',
            teamName: 'Mobile App Team',
            date: dateStr,
            clockInTime: DateTime(
              pastDate.year,
              pastDate.month,
              pastDate.day,
              10,
              45,
            ),
            clockInPhotoUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=600',
            status: AttendanceStatus.rejected,
            timingStatus: TimingStatus.lateArrival,
            approvedBy: 'mgr_01',
            approvedByName: 'Vikram Mehta (TL)',
            approvedAt: DateTime(
              pastDate.year,
              pastDate.month,
              pastDate.day,
              11,
              0,
            ),
            rejectionReason: 'Blurry photo / Outside geofence radius',
          ),
        );
      } else if (i != 12 && i != 19) {
        final inHour = 9;
        final inMin = (i * 3) % 25;
        final outHour = 18;
        final outMin = (i * 4) % 30;

        final clockIn = DateTime(
          pastDate.year,
          pastDate.month,
          pastDate.day,
          inHour,
          inMin,
        );
        final clockOut = DateTime(
          pastDate.year,
          pastDate.month,
          pastDate.day,
          outHour,
          outMin,
        );
        final durationMin = clockOut.difference(clockIn).inMinutes;

        records.add(
          AttendanceModel(
            attendanceId: 'emp_01_$dateStr',
            employeeId: 'emp_01',
            employeeName: 'Rahul Sharma',
            employeeCode: 'EMP-1042',
            teamId: 'team_mobile',
            teamName: 'Mobile App Team',
            date: dateStr,
            clockInTime: clockIn,
            clockOutTime: clockOut,
            clockInPhotoUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=600',
            status: AttendanceStatus.completed,
            timingStatus: inMin > 15
                ? TimingStatus.gracePeriod
                : TimingStatus.onTime,
            approvedBy: 'mgr_01',
            approvedByName: 'Vikram Mehta (TL)',
            approvedAt: DateTime(
              pastDate.year,
              pastDate.month,
              pastDate.day,
              9,
              30,
            ),
            totalWorkMinutes: durationMin,
            totalBreakMinutes: 45,
            breaks: [
              BreakRecord(
                breakId: 'brk_${i}_1',
                type: BreakType.tea,
                startTime: DateTime(
                  pastDate.year,
                  pastDate.month,
                  pastDate.day,
                  11,
                  0,
                ),
                endTime: DateTime(
                  pastDate.year,
                  pastDate.month,
                  pastDate.day,
                  11,
                  15,
                ),
                durationMinutes: 15,
              ),
              BreakRecord(
                breakId: 'brk_${i}_2',
                type: BreakType.lunch,
                startTime: DateTime(
                  pastDate.year,
                  pastDate.month,
                  pastDate.day,
                  13,
                  30,
                ),
                endTime: DateTime(
                  pastDate.year,
                  pastDate.month,
                  pastDate.day,
                  14,
                  0,
                ),
                durationMinutes: 30,
              ),
            ],
            latitude: 21.1986872,
            longitude: 72.7965515,
            isWithinGeofence: true,
            distanceFromOfficeMeters: 18.0,
            location: 'Green Atria, Surat Office',
          ),
        );
      }
    }

    return records;
  }
}
