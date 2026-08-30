import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to seed all 17 Firestore Collections directly from the Flutter app.
class FirestoreSeederService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> seedAll17Collections({Function(String status)? onProgress}) async {
    onProgress?.call('1/17 Seeding Departments...');
    await _seedDepartments();

    onProgress?.call('2/17 Seeding Teams...');
    await _seedTeams();

    onProgress?.call('3/17 Seeding Office Locations...');
    await _seedOfficeLocations();

    onProgress?.call('4/17 Seeding Shifts...');
    await _seedShifts();

    onProgress?.call('5/17 Seeding Attendance Policies...');
    await _seedPolicies();

    onProgress?.call('6/17 Seeding Leave Types...');
    await _seedLeaveTypes();

    onProgress?.call('7/17 Seeding Holidays...');
    await _seedHolidays();

    onProgress?.call('8/17 Seeding Users...');
    await _seedUsers();

    onProgress?.call('9/17 Seeding Employees...');
    await _seedEmployees();

    onProgress?.call('10/17 Seeding Attendance Records...');
    await _seedAttendance();

    onProgress?.call('11/17 Seeding Approvals...');
    await _seedApprovals();

    onProgress?.call('12/17 Seeding Corrections...');
    await _seedCorrections();

    onProgress?.call('13/17 Seeding Leaves...');
    await _seedLeaves();

    onProgress?.call('14/17 Seeding Notifications...');
    await _seedNotifications();

    onProgress?.call('15/17 Seeding Reports...');
    await _seedReports();

    onProgress?.call('16/17 Seeding Audit Logs...');
    await _seedAuditLogs();

    onProgress?.call('17/17 Seeding App Settings...');
    await _seedAppSettings();

    onProgress?.call('✅ All 17 Firestore Collections seeded successfully!');
  }

  Future<void> _seedDepartments() async {
    final batch = _firestore.batch();
    final depts = [
      {
        'departmentId': 'dept_eng',
        'name': 'Engineering & Technology',
        'code': 'ENG',
        'headOfDepartmentId': 'EMP-1001',
        'headOfDepartmentName': 'Dr. Anita Roy',
        'totalEmployees': 14,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'departmentId': 'dept_hr',
        'name': 'Human Resources & People Ops',
        'code': 'HR',
        'headOfDepartmentId': 'EMP-1003',
        'headOfDepartmentName': 'Pooja Verma',
        'totalEmployees': 5,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'departmentId': 'dept_ops',
        'name': 'Operations & Management',
        'code': 'OPS',
        'headOfDepartmentId': 'EMP-1004',
        'headOfDepartmentName': 'Rajesh Sharma',
        'totalEmployees': 6,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];
    for (var d in depts) {
      batch.set(_firestore.collection('departments').doc(d['departmentId'] as String), d);
    }
    await batch.commit();
  }

  Future<void> _seedTeams() async {
    final batch = _firestore.batch();
    final teams = [
      {
        'teamId': 'team_mobile',
        'name': 'Mobile Apps Team (Flutter)',
        'departmentId': 'dept_eng',
        'managerId': 'EMP-1002',
        'managerName': 'Vikram Mehta (TL)',
        'memberCount': 5,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'teamId': 'team_backend',
        'name': 'Backend & Cloud Infrastructure',
        'departmentId': 'dept_eng',
        'managerId': 'EMP-1002',
        'managerName': 'Vikram Mehta (TL)',
        'memberCount': 4,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];
    for (var t in teams) {
      batch.set(_firestore.collection('teams').doc(t['teamId'] as String), t);
    }
    await batch.commit();
  }

  Future<void> _seedOfficeLocations() async {
    final batch = _firestore.batch();
    final locs = [
      {
        'locationId': 'loc_hq_delhi',
        'name': 'AttendX HQ - Connaught Place',
        'address': 'Block B, Inner Circle, Connaught Place, New Delhi 110001',
        'geopoint': const GeoPoint(28.6139, 77.2090),
        'geofenceRadiusMeters': 300,
        'wifiBSSIDs': ['00:14:22:01:23:45'],
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'locationId': 'loc_tech_hub_bengaluru',
        'name': 'Tech Hub - Koramangala',
        'address': '80 Feet Rd, 4th Block, Koramangala, Bengaluru 560034',
        'geopoint': const GeoPoint(12.9352, 77.6245),
        'geofenceRadiusMeters': 250,
        'wifiBSSIDs': [],
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      }
    ];
    for (var l in locs) {
      batch.set(_firestore.collection('officeLocations').doc(l['locationId'] as String), l);
    }
    await batch.commit();
  }

  Future<void> _seedShifts() async {
    final batch = _firestore.batch();
    final shifts = [
      {
        'shiftId': 'shift_general',
        'name': 'General Day Shift (09:30 AM - 06:30 PM)',
        'startTime': '09:30',
        'endTime': '18:30',
        'gracePeriodMinutes': 15,
        'halfDayThresholdMinutes': 240,
        'fullDayThresholdMinutes': 480,
        'workDays': [1, 2, 3, 4, 5],
        'isNightShift': false,
      },
      {
        'shiftId': 'shift_morning',
        'name': 'Early Morning Shift (07:00 AM - 04:00 PM)',
        'startTime': '07:00',
        'endTime': '16:00',
        'gracePeriodMinutes': 10,
        'halfDayThresholdMinutes': 240,
        'fullDayThresholdMinutes': 480,
        'workDays': [1, 2, 3, 4, 5, 6],
        'isNightShift': false,
      }
    ];
    for (var s in shifts) {
      batch.set(_firestore.collection('shifts').doc(s['shiftId'] as String), s);
    }
    await batch.commit();
  }

  Future<void> _seedPolicies() async {
    final batch = _firestore.batch();
    final policies = [
      {
        'policyId': 'policy_standard',
        'name': 'Standard Corporate Policy',
        'requireSelfie': true,
        'requireGeofence': true,
        'requireTLApproval': true,
        'autoClockOutTime': '23:59',
        'maxBreakMinutesPerDay': 60,
        'consecutiveLatePenaltyDays': 3,
        'isDefault': true,
      }
    ];
    for (var p in policies) {
      batch.set(_firestore.collection('attendancePolicies').doc(p['policyId'] as String), p);
    }
    await batch.commit();
  }

  Future<void> _seedLeaveTypes() async {
    final batch = _firestore.batch();
    final types = [
      {
        'leaveTypeId': 'lt_casual',
        'name': 'Casual Leave',
        'code': 'CL',
        'annualQuota': 12,
        'carryForward': false,
        'isPaid': true,
        'isActive': true,
      },
      {
        'leaveTypeId': 'lt_sick',
        'name': 'Sick / Medical Leave',
        'code': 'SL',
        'annualQuota': 8,
        'carryForward': false,
        'isPaid': true,
        'isActive': true,
      },
      {
        'leaveTypeId': 'lt_earned',
        'name': 'Earned Leave',
        'code': 'EL',
        'annualQuota': 15,
        'carryForward': true,
        'isPaid': true,
        'isActive': true,
      }
    ];
    for (var lt in types) {
      batch.set(_firestore.collection('leaveTypes').doc(lt['leaveTypeId'] as String), lt);
    }
    await batch.commit();
  }

  Future<void> _seedHolidays() async {
    final batch = _firestore.batch();
    final holidays = [
      {
        'holidayId': 'hol_2026_republic_day',
        'name': 'Republic Day',
        'date': '2026-01-26',
        'year': 2026,
        'isOptional': false,
        'locationIds': ['ALL'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'holidayId': 'hol_2026_independence_day',
        'name': 'Independence Day',
        'date': '2026-08-15',
        'year': 2026,
        'isOptional': false,
        'locationIds': ['ALL'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'holidayId': 'hol_2026_diwali',
        'name': 'Diwali Festive Holiday',
        'date': '2026-11-08',
        'year': 2026,
        'isOptional': false,
        'locationIds': ['ALL'],
        'createdAt': FieldValue.serverTimestamp(),
      }
    ];
    for (var h in holidays) {
      batch.set(_firestore.collection('holidays').doc(h['holidayId'] as String), h);
    }
    await batch.commit();
  }

  Future<void> _seedUsers() async {
    final batch = _firestore.batch();
    final users = [
      {
        'userId': 'emp_01',
        'email': 'rahul.sharma@attendx.com',
        'name': 'Rahul Sharma',
        'role': 'employee',
        'employeeId': 'EMP-1024',
        'isActive': true,
        'avatarUrl': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'userId': 'mgr_01',
        'email': 'vikram.mehta@attendx.com',
        'name': 'Vikram Mehta (TL)',
        'role': 'manager',
        'employeeId': 'EMP-1002',
        'isActive': true,
        'avatarUrl': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'userId': 'hr_01',
        'email': 'pooja.verma@attendx.com',
        'name': 'Pooja Verma (HR)',
        'role': 'hr',
        'employeeId': 'EMP-1003',
        'isActive': true,
        'avatarUrl': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'userId': 'admin_01',
        'email': 'rajesh.sharma@attendx.com',
        'name': 'Rajesh Sharma (Admin)',
        'role': 'admin',
        'employeeId': 'EMP-1004',
        'isActive': true,
        'avatarUrl': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        'createdAt': FieldValue.serverTimestamp(),
      }
    ];
    for (var u in users) {
      batch.set(_firestore.collection('users').doc(u['userId'] as String), u);
    }
    await batch.commit();
  }

  Future<void> _seedEmployees() async {
    final batch = _firestore.batch();
    final employees = [
      {
        'employeeId': 'EMP-1024',
        'userId': 'emp_01',
        'fullName': 'Rahul Sharma',
        'workEmail': 'rahul.sharma@attendx.com',
        'phoneNumber': '+919876543210',
        'departmentId': 'dept_eng',
        'departmentName': 'Engineering & Technology',
        'teamId': 'team_mobile',
        'teamName': 'Mobile Apps Team (Flutter)',
        'managerId': 'EMP-1002',
        'managerName': 'Vikram Mehta (TL)',
        'shiftId': 'shift_general',
        'officeLocationId': 'loc_hq_delhi',
        'policyId': 'policy_standard',
        'avatarUrl': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        'leaveBalance': {'casual': 9, 'sick': 6, 'earned': 10},
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'employeeId': 'EMP-1002',
        'userId': 'mgr_01',
        'fullName': 'Vikram Mehta',
        'workEmail': 'vikram.mehta@attendx.com',
        'phoneNumber': '+919876543211',
        'departmentId': 'dept_eng',
        'departmentName': 'Engineering & Technology',
        'teamId': 'team_mobile',
        'teamName': 'Mobile Apps Team (Flutter)',
        'managerId': 'EMP-1001',
        'managerName': 'Dr. Anita Roy',
        'shiftId': 'shift_general',
        'officeLocationId': 'loc_hq_delhi',
        'policyId': 'policy_standard',
        'avatarUrl': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        'leaveBalance': {'casual': 12, 'sick': 8, 'earned': 15},
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      }
    ];
    for (var emp in employees) {
      batch.set(_firestore.collection('employees').doc(emp['employeeId'] as String), emp);
    }
    await batch.commit();
  }

  Future<void> _seedAttendance() async {
    final batch = _firestore.batch();
    final att = {
      'attendanceId': 'EMP-1024_2026-08-30',
      'employeeId': 'EMP-1024',
      'employeeName': 'Rahul Sharma',
      'employeeCode': 'EMP-1024',
      'employeeAvatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      'departmentId': 'dept_eng',
      'departmentName': 'Engineering & Technology',
      'teamId': 'team_mobile',
      'teamName': 'Mobile Apps Team (Flutter)',
      'managerId': 'EMP-1002',
      'shiftId': 'shift_general',
      'date': '2026-08-30',
      'clockInTime': DateTime.parse('2026-08-30T09:28:15Z'),
      'clockInPhotoUrl': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300',
      'clockInLocation': const GeoPoint(28.6139, 77.2090),
      'clockInAddress': 'Connaught Place, New Delhi',
      'clockInDistanceMeters': 14.5,
      'isWithinGeofence': true,
      'timingStatus': 'on_time',
      'lateMinutes': 0,
      'status': 'completed',
      'approvalStatus': 'approved',
      'approvedBy': 'EMP-1002',
      'approvedByName': 'Vikram Mehta (TL)',
      'totalBreakMinutes': 60,
      'clockOutTime': DateTime.parse('2026-08-30T18:35:00Z'),
      'totalWorkingHours': 9.11,
      'netWorkingHours': 8.11,
      'overtimeHours': 0.0,
      'isAutoClockOut': false,
      'hasCorrection': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    batch.set(_firestore.collection('attendance').doc('EMP-1024_2026-08-30'), att);
    await batch.commit();
  }

  Future<void> _seedApprovals() async {
    final batch = _firestore.batch();
    final appr = {
      'approvalId': 'appr_EMP-1024_2026-08-30',
      'attendanceId': 'EMP-1024_2026-08-30',
      'employeeId': 'EMP-1024',
      'employeeName': 'Rahul Sharma',
      'teamId': 'team_mobile',
      'managerId': 'EMP-1002',
      'date': '2026-08-30',
      'selfieUrl': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300',
      'distanceMeters': 14.5,
      'status': 'approved',
      'createdAt': FieldValue.serverTimestamp(),
    };
    batch.set(_firestore.collection('attendanceApprovals').doc('appr_EMP-1024_2026-08-30'), appr);
    await batch.commit();
  }

  Future<void> _seedCorrections() async {
    final batch = _firestore.batch();
    final corr = {
      'correctionId': 'corr_20260828_01',
      'attendanceId': 'EMP-1024_2026-08-28',
      'employeeId': 'EMP-1024',
      'employeeName': 'Rahul Sharma',
      'teamId': 'team_mobile',
      'managerId': 'EMP-1002',
      'date': '2026-08-28',
      'reason': 'Mobile network delay in lobby on clock-in.',
      'status': 'approved',
      'reviewedBy': 'EMP-1002',
      'createdAt': FieldValue.serverTimestamp(),
    };
    batch.set(_firestore.collection('attendanceCorrections').doc('corr_20260828_01'), corr);
    await batch.commit();
  }

  Future<void> _seedLeaves() async {
    final batch = _firestore.batch();
    final lv = {
      'leaveId': 'leave_20260905_01',
      'employeeId': 'EMP-1024',
      'employeeName': 'Rahul Sharma',
      'departmentId': 'dept_eng',
      'teamId': 'team_mobile',
      'managerId': 'EMP-1002',
      'leaveTypeId': 'lt_casual',
      'leaveTypeName': 'Casual Leave',
      'startDate': '2026-09-05',
      'endDate': '2026-09-07',
      'totalDays': 3,
      'reason': 'Attending family wedding ceremony.',
      'status': 'approved',
      'approvedBy': 'EMP-1002',
      'approvedByName': 'Vikram Mehta (TL)',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    batch.set(_firestore.collection('leaves').doc('leave_20260905_01'), lv);
    await batch.commit();
  }

  Future<void> _seedNotifications() async {
    final batch = _firestore.batch();
    final notifs = [
      {
        'notificationId': 'notif_01',
        'userId': 'emp_01',
        'title': 'Clock-In Approved 🟢',
        'message': 'Your clock-in for 30 Aug was approved by Vikram Mehta.',
        'type': 'approval',
        'entityId': 'EMP-1024_2026-08-30',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      }
    ];
    for (var n in notifs) {
      batch.set(_firestore.collection('notifications').doc(n['notificationId'] as String), n);
    }
    await batch.commit();
  }

  Future<void> _seedReports() async {
    final batch = _firestore.batch();
    final rep = {
      'reportId': 'rep_EMP-1024_202608',
      'reportType': 'monthly_employee',
      'targetScope': 'employee',
      'targetId': 'EMP-1024',
      'targetName': 'Rahul Sharma',
      'totalWorkingDays': 22,
      'presentDays': 21,
      'absentDays': 0,
      'leaveDays': 1,
      'lateDays': 1,
      'totalHoursWorked': 172.5,
      'averageHoursPerDay': 8.21,
      'attendancePercentage': 95.5,
      'generatedBy': 'system_cron',
      'createdAt': FieldValue.serverTimestamp(),
    };
    batch.set(_firestore.collection('reports').doc('rep_EMP-1024_202608'), rep);
    await batch.commit();
  }

  Future<void> _seedAuditLogs() async {
    final batch = _firestore.batch();
    final log = {
      'logId': 'log_01',
      'actorId': 'EMP-1002',
      'actorName': 'Vikram Mehta (TL)',
      'actorRole': 'manager',
      'actionType': 'APPROVE_ATTENDANCE',
      'targetCollection': 'attendance',
      'targetEntityId': 'EMP-1024_2026-08-30',
      'description': 'Vikram Mehta approved clock-in for Rahul Sharma.',
      'timestamp': FieldValue.serverTimestamp(),
    };
    batch.set(_firestore.collection('auditLogs').doc('log_01'), log);
    await batch.commit();
  }

  Future<void> _seedAppSettings() async {
    final batch = _firestore.batch();
    final s = {
      'settingKey': 'general',
      'companyName': 'AttendX Enterprise Global',
      'supportEmail': 'hr-support@attendx.com',
      'autoEmailReportsTo': ['pooja.verma@attendx.com', 'rajesh.sharma@attendx.com'],
      'allowMockLocation': false,
      'enforceBiometrics': true,
      'timeZone': 'Asia/Kolkata',
      'updatedAt': FieldValue.serverTimestamp(),
    };
    batch.set(_firestore.collection('appSettings').doc('general'), s);
    await batch.commit();
  }
}
