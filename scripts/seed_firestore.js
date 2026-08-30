/**
 * AttendX - Firestore Enterprise Database Seeder
 * Populates ALL 17 Production Collections into Firestore:
 * 
 * 1. departments
 * 2. teams
 * 3. officeLocations
 * 4. shifts
 * 5. attendancePolicies
 * 6. leaveTypes
 * 7. holidays
 * 8. users
 * 9. employees
 * 10. attendance
 * 11. attendanceApprovals
 * 12. attendanceCorrections
 * 13. leaves
 * 14. notifications
 * 15. reports
 * 16. auditLogs
 * 17. appSettings
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
  // Uses Application Default Credentials (ADC) or serviceAccountKey.json if present
  try {
    const serviceAccount = require('./serviceAccountKey.json');
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: 'attendx-8b4c5'
    });
  } catch (e) {
    admin.initializeApp({
      projectId: 'attendx-8b4c5'
    });
  }
}

const db = admin.firestore();

async function seedAll17Collections() {
  console.log('====================================================');
  console.log('🚀 Starting AttendX Firestore Seeder for all 17 Collections');
  console.log('🎯 Project ID: attendx-8b4c5');
  console.log('====================================================\n');

  // 1. DEPARTMENTS
  console.log('📦 1/17 Seeding: departments ...');
  const departments = [
    {
      departmentId: 'dept_eng',
      name: 'Engineering & Technology',
      code: 'ENG',
      headOfDepartmentId: 'EMP-1001',
      headOfDepartmentName: 'Dr. Anita Roy',
      totalEmployees: 14,
      isActive: true,
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      departmentId: 'dept_hr',
      name: 'Human Resources & People Ops',
      code: 'HR',
      headOfDepartmentId: 'EMP-1003',
      headOfDepartmentName: 'Pooja Verma',
      totalEmployees: 5,
      isActive: true,
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      departmentId: 'dept_ops',
      name: 'Operations & Management',
      code: 'OPS',
      headOfDepartmentId: 'EMP-1004',
      headOfDepartmentName: 'Rajesh Sharma',
      totalEmployees: 6,
      isActive: true,
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      departmentId: 'dept_sales',
      name: 'Sales & Business Development',
      code: 'SALES',
      headOfDepartmentId: 'EMP-1005',
      headOfDepartmentName: 'Kunal Kapoor',
      totalEmployees: 8,
      isActive: true,
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      departmentId: 'dept_finance',
      name: 'Finance & Accounting',
      code: 'FIN',
      headOfDepartmentId: 'EMP-1006',
      headOfDepartmentName: 'Meera Nambiar',
      totalEmployees: 4,
      isActive: true,
      createdAt: admin.firestore.Timestamp.now()
    }
  ];
  for (const d of departments) {
    await db.collection('departments').doc(d.departmentId).set(d);
  }
  console.log('   ✅ Seeded ' + departments.length + ' departments');

  // 2. TEAMS
  console.log('📦 2/17 Seeding: teams ...');
  const teams = [
    {
      teamId: 'team_mobile',
      name: 'Mobile Apps Team (Flutter)',
      departmentId: 'dept_eng',
      managerId: 'EMP-1002',
      managerName: 'Vikram Mehta (TL)',
      memberCount: 5,
      isActive: true,
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      teamId: 'team_backend',
      name: 'Backend & Cloud Infrastructure',
      departmentId: 'dept_eng',
      managerId: 'EMP-1002',
      managerName: 'Vikram Mehta (TL)',
      memberCount: 4,
      isActive: true,
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      teamId: 'team_frontend',
      name: 'Web & UI/UX Engineering',
      departmentId: 'dept_eng',
      managerId: 'EMP-1002',
      managerName: 'Vikram Mehta (TL)',
      memberCount: 5,
      isActive: true,
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      teamId: 'team_hr_ops',
      name: 'Talent Acquisition & Payroll',
      departmentId: 'dept_hr',
      managerId: 'EMP-1003',
      managerName: 'Pooja Verma (HR)',
      memberCount: 3,
      isActive: true,
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      teamId: 'team_sales_enterprise',
      name: 'Enterprise Client Growth',
      departmentId: 'dept_sales',
      managerId: 'EMP-1005',
      managerName: 'Kunal Kapoor',
      memberCount: 4,
      isActive: true,
      createdAt: admin.firestore.Timestamp.now()
    }
  ];
  for (const t of teams) {
    await db.collection('teams').doc(t.teamId).set(t);
  }
  console.log('   ✅ Seeded ' + teams.length + ' teams');

  // 3. OFFICE LOCATIONS
  console.log('📦 3/17 Seeding: officeLocations ...');
  const officeLocations = [
    {
      locationId: 'loc_hq_delhi',
      name: 'AttendX HQ - Connaught Place',
      address: 'Block B, Inner Circle, Connaught Place, New Delhi 110001',
      geopoint: new admin.firestore.GeoPoint(28.6139, 77.2090),
      geofenceRadiusMeters: 300,
      wifiBSSIDs: ['00:14:22:01:23:45', 'c4:e9:84:10:92:aa'],
      isActive: true,
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      locationId: 'loc_tech_hub_bengaluru',
      name: 'Tech Hub - Koramangala',
      address: '80 Feet Rd, 4th Block, Koramangala, Bengaluru 560034',
      geopoint: new admin.firestore.GeoPoint(12.9352, 77.6245),
      geofenceRadiusMeters: 250,
      wifiBSSIDs: ['a0:04:60:44:81:bc'],
      isActive: true,
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      locationId: 'loc_mumbai_hub',
      name: 'Financial District Hub - BKC',
      address: 'G Block, Bandra Kurla Complex, Mumbai 400051',
      geopoint: new admin.firestore.GeoPoint(19.0660, 72.8687),
      geofenceRadiusMeters: 350,
      wifiBSSIDs: [],
      isActive: true,
      createdAt: admin.firestore.Timestamp.now()
    }
  ];
  for (const l of officeLocations) {
    await db.collection('officeLocations').doc(l.locationId).set(l);
  }
  console.log('   ✅ Seeded ' + officeLocations.length + ' office locations');

  // 4. SHIFTS
  console.log('📦 4/17 Seeding: shifts ...');
  const shifts = [
    {
      shiftId: 'shift_general',
      name: 'General Day Shift (09:30 AM - 06:30 PM)',
      startTime: '09:30',
      endTime: '18:30',
      gracePeriodMinutes: 15,
      halfDayThresholdMinutes: 240,
      fullDayThresholdMinutes: 480,
      workDays: [1, 2, 3, 4, 5],
      isNightShift: false
    },
    {
      shiftId: 'shift_morning',
      name: 'Early Morning Shift (07:00 AM - 04:00 PM)',
      startTime: '07:00',
      endTime: '16:00',
      gracePeriodMinutes: 10,
      halfDayThresholdMinutes: 240,
      fullDayThresholdMinutes: 480,
      workDays: [1, 2, 3, 4, 5, 6],
      isNightShift: false
    },
    {
      shiftId: 'shift_night',
      name: 'Overnight Production Shift (09:00 PM - 06:00 AM)',
      startTime: '21:00',
      endTime: '06:00',
      gracePeriodMinutes: 15,
      halfDayThresholdMinutes: 240,
      fullDayThresholdMinutes: 480,
      workDays: [1, 2, 3, 4, 5],
      isNightShift: true
    }
  ];
  for (const s of shifts) {
    await db.collection('shifts').doc(s.shiftId).set(s);
  }
  console.log('   ✅ Seeded ' + shifts.length + ' shifts');

  // 5. ATTENDANCE POLICIES
  console.log('📦 5/17 Seeding: attendancePolicies ...');
  const policies = [
    {
      policyId: 'policy_standard',
      name: 'Standard Corporate Policy',
      requireSelfie: true,
      requireGeofence: true,
      requireTLApproval: true,
      autoClockOutTime: '23:59',
      maxBreakMinutesPerDay: 60,
      consecutiveLatePenaltyDays: 3,
      isDefault: true
    },
    {
      policyId: 'policy_strict',
      name: 'High-Security Geofence Strict Policy',
      requireSelfie: true,
      requireGeofence: true,
      requireTLApproval: true,
      autoClockOutTime: '21:00',
      maxBreakMinutesPerDay: 45,
      consecutiveLatePenaltyDays: 2,
      isDefault: false
    },
    {
      policyId: 'policy_flexible',
      name: 'Flexible Work / Remote Policy',
      requireSelfie: false,
      requireGeofence: false,
      requireTLApproval: false,
      autoClockOutTime: '23:59',
      maxBreakMinutesPerDay: 90,
      consecutiveLatePenaltyDays: 5,
      isDefault: false
    }
  ];
  for (const p of policies) {
    await db.collection('attendancePolicies').doc(p.policyId).set(p);
  }
  console.log('   ✅ Seeded ' + policies.length + ' policies');

  // 6. LEAVE TYPES
  console.log('📦 6/17 Seeding: leaveTypes ...');
  const leaveTypes = [
    {
      leaveTypeId: 'lt_casual',
      name: 'Casual Leave',
      code: 'CL',
      annualQuota: 12,
      carryForward: false,
      isPaid: true,
      isActive: true
    },
    {
      leaveTypeId: 'lt_sick',
      name: 'Sick / Medical Leave',
      code: 'SL',
      annualQuota: 8,
      carryForward: false,
      isPaid: true,
      isActive: true
    },
    {
      leaveTypeId: 'lt_earned',
      name: 'Earned / Privilege Leave',
      code: 'EL',
      annualQuota: 15,
      carryForward: true,
      isPaid: true,
      isActive: true
    },
    {
      leaveTypeId: 'lt_maternity',
      name: 'Maternity Leave',
      code: 'ML',
      annualQuota: 180,
      carryForward: false,
      isPaid: true,
      isActive: true
    },
    {
      leaveTypeId: 'lt_paternity',
      name: 'Paternity Leave',
      code: 'PL',
      annualQuota: 15,
      carryForward: false,
      isPaid: true,
      isActive: true
    }
  ];
  for (const lt of leaveTypes) {
    await db.collection('leaveTypes').doc(lt.leaveTypeId).set(lt);
  }
  console.log('   ✅ Seeded ' + leaveTypes.length + ' leave types');

  // 7. HOLIDAYS (2026)
  console.log('📦 7/17 Seeding: holidays ...');
  const holidays = [
    {
      holidayId: 'hol_2026_republic_day',
      name: 'Republic Day',
      date: '2026-01-26',
      year: 2026,
      isOptional: false,
      locationIds: ['ALL'],
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      holidayId: 'hol_2026_holi',
      name: 'Holi Festival of Colors',
      date: '2026-03-04',
      year: 2026,
      isOptional: false,
      locationIds: ['ALL'],
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      holidayId: 'hol_2026_independence_day',
      name: 'Independence Day',
      date: '2026-08-15',
      year: 2026,
      isOptional: false,
      locationIds: ['ALL'],
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      holidayId: 'hol_2026_gandhi_jayanti',
      name: 'Mahatma Gandhi Jayanti',
      date: '2026-10-02',
      year: 2026,
      isOptional: false,
      locationIds: ['ALL'],
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      holidayId: 'hol_2026_diwali',
      name: 'Diwali Festive Holiday',
      date: '2026-11-08',
      year: 2026,
      isOptional: false,
      locationIds: ['ALL'],
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      holidayId: 'hol_2026_christmas',
      name: 'Christmas Day',
      date: '2026-12-25',
      year: 2026,
      isOptional: false,
      locationIds: ['ALL'],
      createdAt: admin.firestore.Timestamp.now()
    }
  ];
  for (const h of holidays) {
    await db.collection('holidays').doc(h.holidayId).set(h);
  }
  console.log('   ✅ Seeded ' + holidays.length + ' official holidays');

  // 8. USERS (Authentication & Role profiles)
  console.log('📦 8/17 Seeding: users ...');
  const users = [
    {
      userId: 'emp_01',
      email: 'rahul.sharma@attendx.com',
      name: 'Rahul Sharma',
      role: 'employee',
      employeeId: 'EMP-1024',
      isActive: true,
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      fcmToken: 'fcm_token_rahul_123',
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      userId: 'emp_02',
      email: 'priya.patel@attendx.com',
      name: 'Priya Patel',
      role: 'employee',
      employeeId: 'EMP-1025',
      isActive: true,
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      fcmToken: 'fcm_token_priya_456',
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      userId: 'emp_03',
      email: 'amit.verma@attendx.com',
      name: 'Amit Verma',
      role: 'employee',
      employeeId: 'EMP-1026',
      isActive: true,
      avatarUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150',
      fcmToken: 'fcm_token_amit_789',
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      userId: 'emp_04',
      email: 'sneha.reddy@attendx.com',
      name: 'Sneha Reddy',
      role: 'employee',
      employeeId: 'EMP-1027',
      isActive: true,
      avatarUrl: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150',
      fcmToken: 'fcm_token_sneha_321',
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      userId: 'mgr_01',
      email: 'vikram.mehta@attendx.com',
      name: 'Vikram Mehta (TL)',
      role: 'manager',
      employeeId: 'EMP-1002',
      isActive: true,
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      fcmToken: 'fcm_token_vikram_mgr',
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      userId: 'hr_01',
      email: 'pooja.verma@attendx.com',
      name: 'Pooja Verma (HR)',
      role: 'hr',
      employeeId: 'EMP-1003',
      isActive: true,
      avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
      fcmToken: 'fcm_token_pooja_hr',
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      userId: 'admin_01',
      email: 'rajesh.sharma@attendx.com',
      name: 'Rajesh Sharma (Admin)',
      role: 'admin',
      employeeId: 'EMP-1004',
      isActive: true,
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
      fcmToken: 'fcm_token_rajesh_admin',
      createdAt: admin.firestore.Timestamp.now()
    }
  ];
  for (const u of users) {
    await db.collection('users').doc(u.userId).set(u);
  }
  console.log('   ✅ Seeded ' + users.length + ' users across all 4 roles');

  // 9. EMPLOYEES
  console.log('📦 9/17 Seeding: employees ...');
  const employees = [
    {
      employeeId: 'EMP-1024',
      userId: 'emp_01',
      fullName: 'Rahul Sharma',
      workEmail: 'rahul.sharma@attendx.com',
      phoneNumber: '+919876543210',
      departmentId: 'dept_eng',
      departmentName: 'Engineering & Technology',
      teamId: 'team_mobile',
      teamName: 'Mobile Apps Team (Flutter)',
      managerId: 'EMP-1002',
      managerName: 'Vikram Mehta (TL)',
      shiftId: 'shift_general',
      officeLocationId: 'loc_hq_delhi',
      policyId: 'policy_standard',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      leaveBalance: { casual: 9, sick: 6, earned: 10 },
      status: 'active',
      joiningDate: admin.firestore.Timestamp.fromDate(new Date('2024-03-01')),
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      employeeId: 'EMP-1025',
      userId: 'emp_02',
      fullName: 'Priya Patel',
      workEmail: 'priya.patel@attendx.com',
      phoneNumber: '+919876543214',
      departmentId: 'dept_eng',
      departmentName: 'Engineering & Technology',
      teamId: 'team_mobile',
      teamName: 'Mobile Apps Team (Flutter)',
      managerId: 'EMP-1002',
      managerName: 'Vikram Mehta (TL)',
      shiftId: 'shift_general',
      officeLocationId: 'loc_hq_delhi',
      policyId: 'policy_standard',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      leaveBalance: { casual: 11, sick: 8, earned: 14 },
      status: 'active',
      joiningDate: admin.firestore.Timestamp.fromDate(new Date('2024-05-15')),
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      employeeId: 'EMP-1026',
      userId: 'emp_03',
      fullName: 'Amit Verma',
      workEmail: 'amit.verma@attendx.com',
      phoneNumber: '+919876543215',
      departmentId: 'dept_eng',
      departmentName: 'Engineering & Technology',
      teamId: 'team_backend',
      teamName: 'Backend & Cloud Infrastructure',
      managerId: 'EMP-1002',
      managerName: 'Vikram Mehta (TL)',
      shiftId: 'shift_general',
      officeLocationId: 'loc_hq_delhi',
      policyId: 'policy_standard',
      avatarUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150',
      leaveBalance: { casual: 7, sick: 4, earned: 8 },
      status: 'active',
      joiningDate: admin.firestore.Timestamp.fromDate(new Date('2023-11-01')),
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      employeeId: 'EMP-1027',
      userId: 'emp_04',
      fullName: 'Sneha Reddy',
      workEmail: 'sneha.reddy@attendx.com',
      phoneNumber: '+919876543216',
      departmentId: 'dept_eng',
      departmentName: 'Engineering & Technology',
      teamId: 'team_frontend',
      teamName: 'Web & UI/UX Engineering',
      managerId: 'EMP-1002',
      managerName: 'Vikram Mehta (TL)',
      shiftId: 'shift_general',
      officeLocationId: 'loc_tech_hub_bengaluru',
      policyId: 'policy_standard',
      avatarUrl: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150',
      leaveBalance: { casual: 10, sick: 7, earned: 12 },
      status: 'active',
      joiningDate: admin.firestore.Timestamp.fromDate(new Date('2024-01-10')),
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      employeeId: 'EMP-1002',
      userId: 'mgr_01',
      fullName: 'Vikram Mehta',
      workEmail: 'vikram.mehta@attendx.com',
      phoneNumber: '+919876543211',
      departmentId: 'dept_eng',
      departmentName: 'Engineering & Technology',
      teamId: 'team_mobile',
      teamName: 'Mobile Apps Team (Flutter)',
      managerId: 'EMP-1001',
      managerName: 'Dr. Anita Roy',
      shiftId: 'shift_general',
      officeLocationId: 'loc_hq_delhi',
      policyId: 'policy_standard',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      leaveBalance: { casual: 12, sick: 8, earned: 15 },
      status: 'active',
      joiningDate: admin.firestore.Timestamp.fromDate(new Date('2023-01-15')),
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      employeeId: 'EMP-1003',
      userId: 'hr_01',
      fullName: 'Pooja Verma',
      workEmail: 'pooja.verma@attendx.com',
      phoneNumber: '+919876543212',
      departmentId: 'dept_hr',
      departmentName: 'Human Resources & People Ops',
      teamId: 'team_hr_ops',
      teamName: 'Talent Acquisition & Payroll',
      managerId: 'EMP-1004',
      managerName: 'Rajesh Sharma',
      shiftId: 'shift_general',
      officeLocationId: 'loc_hq_delhi',
      policyId: 'policy_standard',
      avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
      leaveBalance: { casual: 10, sick: 7, earned: 12 },
      status: 'active',
      joiningDate: admin.firestore.Timestamp.fromDate(new Date('2023-06-01')),
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      employeeId: 'EMP-1004',
      userId: 'admin_01',
      fullName: 'Rajesh Sharma',
      workEmail: 'rajesh.sharma@attendx.com',
      phoneNumber: '+919876543213',
      departmentId: 'dept_ops',
      departmentName: 'Operations & Management',
      teamId: 'team_hr_ops',
      teamName: 'Executive Management',
      managerId: 'EMP-1004',
      managerName: 'Self',
      shiftId: 'shift_general',
      officeLocationId: 'loc_hq_delhi',
      policyId: 'policy_standard',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
      leaveBalance: { casual: 12, sick: 8, earned: 15 },
      status: 'active',
      joiningDate: admin.firestore.Timestamp.fromDate(new Date('2022-01-01')),
      createdAt: admin.firestore.Timestamp.now()
    }
  ];
  for (const emp of employees) {
    await db.collection('employees').doc(emp.employeeId).set(emp);
  }
  console.log('   ✅ Seeded ' + employees.length + ' employee corporate profiles');

  // 10. ATTENDANCE
  console.log('📦 10/17 Seeding: attendance ...');
  const attendanceList = [
    {
      attendanceId: 'EMP-1024_2026-08-30',
      employeeId: 'EMP-1024',
      employeeName: 'Rahul Sharma',
      employeeCode: 'EMP-1024',
      employeeAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      departmentId: 'dept_eng',
      departmentName: 'Engineering & Technology',
      teamId: 'team_mobile',
      teamName: 'Mobile Apps Team (Flutter)',
      managerId: 'EMP-1002',
      shiftId: 'shift_general',
      date: '2026-08-30',
      clockInTime: admin.firestore.Timestamp.fromDate(new Date('2026-08-30T09:28:15Z')),
      clockInPhotoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300',
      clockInLocation: new admin.firestore.GeoPoint(28.6139, 77.2090),
      clockInAddress: 'Connaught Place, New Delhi',
      clockInDistanceMeters: 14.5,
      isWithinGeofence: true,
      timingStatus: 'on_time',
      lateMinutes: 0,
      status: 'completed',
      approvalStatus: 'approved',
      approvedBy: 'EMP-1002',
      approvedByName: 'Vikram Mehta (TL)',
      approvedAt: admin.firestore.Timestamp.fromDate(new Date('2026-08-30T09:40:00Z')),
      rejectedBy: null,
      rejectedByName: null,
      rejectedAt: null,
      rejectionReason: null,
      managerComments: 'Selfie and office GPS verified.',
      breaks: [
        {
          breakId: 'brk_1',
          type: 'tea',
          startTime: admin.firestore.Timestamp.fromDate(new Date('2026-08-30T11:15:00Z')),
          endTime: admin.firestore.Timestamp.fromDate(new Date('2026-08-30T11:30:00Z')),
          durationMinutes: 15
        },
        {
          breakId: 'brk_2',
          type: 'lunch',
          startTime: admin.firestore.Timestamp.fromDate(new Date('2026-08-30T13:30:00Z')),
          endTime: admin.firestore.Timestamp.fromDate(new Date('2026-08-30T14:15:00Z')),
          durationMinutes: 45
        }
      ],
      totalBreakMinutes: 60,
      clockOutTime: admin.firestore.Timestamp.fromDate(new Date('2026-08-30T18:35:00Z')),
      clockOutPhotoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300',
      clockOutLocation: new admin.firestore.GeoPoint(28.6140, 77.2091),
      totalWorkingHours: 9.11,
      netWorkingHours: 8.11,
      overtimeHours: 0.0,
      isAutoClockOut: false,
      hasCorrection: false,
      correctionId: null,
      createdAt: admin.firestore.Timestamp.fromDate(new Date('2026-08-30T09:28:15Z')),
      updatedAt: admin.firestore.Timestamp.fromDate(new Date('2026-08-30T18:35:00Z'))
    },
    {
      attendanceId: 'EMP-1025_2026-08-30',
      employeeId: 'EMP-1025',
      employeeName: 'Priya Patel',
      employeeCode: 'EMP-1025',
      employeeAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      departmentId: 'dept_eng',
      departmentName: 'Engineering & Technology',
      teamId: 'team_mobile',
      teamName: 'Mobile Apps Team (Flutter)',
      managerId: 'EMP-1002',
      shiftId: 'shift_general',
      date: '2026-08-30',
      clockInTime: admin.firestore.Timestamp.fromDate(new Date('2026-08-30T09:50:00Z')),
      clockInPhotoUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=300',
      clockInLocation: new admin.firestore.GeoPoint(28.6141, 77.2092),
      clockInAddress: 'Connaught Place, New Delhi',
      clockInDistanceMeters: 35.0,
      isWithinGeofence: true,
      timingStatus: 'late',
      lateMinutes: 20,
      status: 'approved',
      approvalStatus: 'approved',
      approvedBy: 'EMP-1002',
      approvedByName: 'Vikram Mehta (TL)',
      approvedAt: admin.firestore.Timestamp.fromDate(new Date('2026-08-30T10:00:00Z')),
      breaks: [],
      totalBreakMinutes: 0,
      clockOutTime: null,
      totalWorkingHours: 0,
      netWorkingHours: 0,
      overtimeHours: 0,
      isAutoClockOut: false,
      hasCorrection: false,
      createdAt: admin.firestore.Timestamp.fromDate(new Date('2026-08-30T09:50:00Z')),
      updatedAt: admin.firestore.Timestamp.fromDate(new Date('2026-08-30T10:00:00Z'))
    },
    {
      attendanceId: 'EMP-1026_2026-08-30',
      employeeId: 'EMP-1026',
      employeeName: 'Amit Verma',
      employeeCode: 'EMP-1026',
      employeeAvatar: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150',
      departmentId: 'dept_eng',
      departmentName: 'Engineering & Technology',
      teamId: 'team_backend',
      teamName: 'Backend & Cloud Infrastructure',
      managerId: 'EMP-1002',
      shiftId: 'shift_general',
      date: '2026-08-30',
      clockInTime: admin.firestore.Timestamp.fromDate(new Date('2026-08-30T09:35:00Z')),
      clockInPhotoUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=300',
      clockInLocation: new admin.firestore.GeoPoint(28.6138, 77.2089),
      clockInAddress: 'Connaught Place, New Delhi',
      clockInDistanceMeters: 22.0,
      isWithinGeofence: true,
      timingStatus: 'grace_period',
      lateMinutes: 5,
      status: 'pending',
      approvalStatus: 'pending',
      breaks: [],
      totalBreakMinutes: 0,
      clockOutTime: null,
      totalWorkingHours: 0,
      netWorkingHours: 0,
      overtimeHours: 0,
      isAutoClockOut: false,
      hasCorrection: false,
      createdAt: admin.firestore.Timestamp.fromDate(new Date('2026-08-30T09:35:00Z')),
      updatedAt: admin.firestore.Timestamp.fromDate(new Date('2026-08-30T09:35:00Z'))
    }
  ];
  for (const a of attendanceList) {
    await db.collection('attendance').doc(a.attendanceId).set(a);
  }
  console.log('   ✅ Seeded ' + attendanceList.length + ' attendance tracking records');

  // 11. ATTENDANCE APPROVALS
  console.log('📦 11/17 Seeding: attendanceApprovals ...');
  const approvals = [
    {
      approvalId: 'appr_EMP-1024_2026-08-30',
      attendanceId: 'EMP-1024_2026-08-30',
      employeeId: 'EMP-1024',
      employeeName: 'Rahul Sharma',
      teamId: 'team_mobile',
      managerId: 'EMP-1002',
      date: '2026-08-30',
      selfieUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300',
      distanceMeters: 14.5,
      status: 'approved',
      reviewedAt: admin.firestore.Timestamp.fromDate(new Date('2026-08-30T09:40:00Z')),
      rejectionReason: null,
      createdAt: admin.firestore.Timestamp.fromDate(new Date('2026-08-30T09:28:15Z'))
    },
    {
      approvalId: 'appr_EMP-1026_2026-08-30',
      attendanceId: 'EMP-1026_2026-08-30',
      employeeId: 'EMP-1026',
      employeeName: 'Amit Verma',
      teamId: 'team_backend',
      managerId: 'EMP-1002',
      date: '2026-08-30',
      selfieUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=300',
      distanceMeters: 22.0,
      status: 'pending',
      reviewedAt: null,
      rejectionReason: null,
      createdAt: admin.firestore.Timestamp.fromDate(new Date('2026-08-30T09:35:00Z'))
    }
  ];
  for (const appr of approvals) {
    await db.collection('attendanceApprovals').doc(appr.approvalId).set(appr);
  }
  console.log('   ✅ Seeded ' + approvals.length + ' attendance approvals');

  // 12. ATTENDANCE CORRECTIONS
  console.log('📦 12/17 Seeding: attendanceCorrections ...');
  const corrections = [
    {
      correctionId: 'corr_20260828_01',
      attendanceId: 'EMP-1024_2026-08-28',
      employeeId: 'EMP-1024',
      employeeName: 'Rahul Sharma',
      teamId: 'team_mobile',
      managerId: 'EMP-1002',
      date: '2026-08-28',
      requestedClockIn: admin.firestore.Timestamp.fromDate(new Date('2026-08-28T09:30:00Z')),
      requestedClockOut: admin.firestore.Timestamp.fromDate(new Date('2026-08-28T18:30:00Z')),
      reason: 'Mobile network failure at office lobby delayed app clock-in.',
      status: 'approved',
      reviewedBy: 'EMP-1002',
      reviewedAt: admin.firestore.Timestamp.fromDate(new Date('2026-08-29T10:00:00Z')),
      reviewComments: 'Regularized after verification with floor supervisor.',
      createdAt: admin.firestore.Timestamp.fromDate(new Date('2026-08-28T19:00:00Z'))
    },
    {
      correctionId: 'corr_20260829_02',
      attendanceId: 'EMP-1025_2026-08-29',
      employeeId: 'EMP-1025',
      employeeName: 'Priya Patel',
      teamId: 'team_mobile',
      managerId: 'EMP-1002',
      date: '2026-08-29',
      requestedClockIn: admin.firestore.Timestamp.fromDate(new Date('2026-08-29T09:30:00Z')),
      requestedClockOut: admin.firestore.Timestamp.fromDate(new Date('2026-08-29T18:45:00Z')),
      reason: 'Forgot to clock out before leaving building for on-site client demo.',
      status: 'pending',
      reviewedBy: null,
      reviewedAt: null,
      reviewComments: null,
      createdAt: admin.firestore.Timestamp.fromDate(new Date('2026-08-29T20:30:00Z'))
    }
  ];
  for (const c of corrections) {
    await db.collection('attendanceCorrections').doc(c.correctionId).set(c);
  }
  console.log('   ✅ Seeded ' + corrections.length + ' attendance regularization requests');

  // 13. LEAVES
  console.log('📦 13/17 Seeding: leaves ...');
  const leaves = [
    {
      leaveId: 'leave_20260905_01',
      employeeId: 'EMP-1024',
      employeeName: 'Rahul Sharma',
      departmentId: 'dept_eng',
      teamId: 'team_mobile',
      managerId: 'EMP-1002',
      leaveTypeId: 'lt_casual',
      leaveTypeName: 'Casual Leave',
      startDate: '2026-09-05',
      endDate: '2026-09-07',
      totalDays: 3,
      reason: 'Attending family wedding ceremony out of station.',
      status: 'approved',
      approvedBy: 'EMP-1002',
      approvedByName: 'Vikram Mehta (TL)',
      approvedAt: admin.firestore.Timestamp.fromDate(new Date('2026-08-30T10:00:00Z')),
      rejectionReason: null,
      createdAt: admin.firestore.Timestamp.fromDate(new Date('2026-08-30T09:00:00Z')),
      updatedAt: admin.firestore.Timestamp.fromDate(new Date('2026-08-30T10:00:00Z'))
    },
    {
      leaveId: 'leave_20260912_02',
      employeeId: 'EMP-1026',
      employeeName: 'Amit Verma',
      departmentId: 'dept_eng',
      teamId: 'team_backend',
      managerId: 'EMP-1002',
      leaveTypeId: 'lt_sick',
      leaveTypeName: 'Sick / Medical Leave',
      startDate: '2026-09-12',
      endDate: '2026-09-13',
      totalDays: 2,
      reason: 'Scheduled medical health checkup and rest.',
      status: 'pending',
      approvedBy: null,
      approvedByName: null,
      approvedAt: null,
      rejectionReason: null,
      createdAt: admin.firestore.Timestamp.fromDate(new Date('2026-08-30T11:00:00Z')),
      updatedAt: admin.firestore.Timestamp.fromDate(new Date('2026-08-30T11:00:00Z'))
    }
  ];
  for (const lv of leaves) {
    await db.collection('leaves').doc(lv.leaveId).set(lv);
  }
  console.log('   ✅ Seeded ' + leaves.length + ' leave requests');

  // 14. NOTIFICATIONS
  console.log('📦 14/17 Seeding: notifications ...');
  const notifications = [
    {
      notificationId: 'notif_01',
      userId: 'emp_01',
      title: 'Clock-In Approved 🟢',
      message: 'Your clock-in for 30 Aug was approved by Vikram Mehta.',
      type: 'approval',
      entityId: 'EMP-1024_2026-08-30',
      isRead: false,
      createdAt: admin.firestore.Timestamp.fromDate(new Date('2026-08-30T09:40:00Z'))
    },
    {
      notificationId: 'notif_02',
      userId: 'mgr_01',
      title: 'New Leave Request 📝',
      message: 'Amit Verma applied for 2 days Sick Leave (12-13 Sep).',
      type: 'leave',
      entityId: 'leave_20260912_02',
      isRead: false,
      createdAt: admin.firestore.Timestamp.fromDate(new Date('2026-08-30T11:00:00Z'))
    },
    {
      notificationId: 'notif_03',
      userId: 'emp_01',
      title: 'Upcoming Holiday 🏖️',
      message: 'Independence Day holiday on 15th August 2026.',
      type: 'alert',
      entityId: 'hol_2026_independence_day',
      isRead: true,
      createdAt: admin.firestore.Timestamp.fromDate(new Date('2026-08-10T09:00:00Z'))
    }
  ];
  for (const n of notifications) {
    await db.collection('notifications').doc(n.notificationId).set(n);
  }
  console.log('   ✅ Seeded ' + notifications.length + ' notification alerts');

  // 15. REPORTS
  console.log('📦 15/17 Seeding: reports ...');
  const reports = [
    {
      reportId: 'rep_EMP-1024_202608',
      reportType: 'monthly_employee',
      targetScope: 'employee',
      targetId: 'EMP-1024',
      targetName: 'Rahul Sharma',
      periodStart: admin.firestore.Timestamp.fromDate(new Date('2026-08-01T00:00:00Z')),
      periodEnd: admin.firestore.Timestamp.fromDate(new Date('2026-08-30T23:59:59Z')),
      totalWorkingDays: 22,
      presentDays: 21,
      absentDays: 0,
      leaveDays: 1,
      lateDays: 1,
      pendingDays: 0,
      totalHoursWorked: 172.5,
      averageHoursPerDay: 8.21,
      attendancePercentage: 95.5,
      pdfStorageUrl: 'reports/2026-08/rep_EMP-1024_202608.pdf',
      csvStorageUrl: 'reports/2026-08/rep_EMP-1024_202608.csv',
      generatedBy: 'system_cron',
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      reportId: 'rep_dept_eng_202608',
      reportType: 'department_summary',
      targetScope: 'department',
      targetId: 'dept_eng',
      targetName: 'Engineering & Technology',
      periodStart: admin.firestore.Timestamp.fromDate(new Date('2026-08-01T00:00:00Z')),
      periodEnd: admin.firestore.Timestamp.fromDate(new Date('2026-08-30T23:59:59Z')),
      totalWorkingDays: 22,
      presentDays: 280,
      absentDays: 6,
      leaveDays: 12,
      lateDays: 15,
      pendingDays: 2,
      totalHoursWorked: 2310.0,
      averageHoursPerDay: 8.25,
      attendancePercentage: 94.0,
      pdfStorageUrl: 'reports/2026-08/rep_dept_eng_202608.pdf',
      csvStorageUrl: 'reports/2026-08/rep_dept_eng_202608.csv',
      generatedBy: 'system_cron',
      createdAt: admin.firestore.Timestamp.now()
    }
  ];
  for (const r of reports) {
    await db.collection('reports').doc(r.reportId).set(r);
  }
  console.log('   ✅ Seeded ' + reports.length + ' monthly rollup reports');

  // 16. AUDIT LOGS
  console.log('📦 16/17 Seeding: auditLogs ...');
  const auditLogs = [
    {
      logId: 'log_01',
      actorId: 'EMP-1002',
      actorName: 'Vikram Mehta (TL)',
      actorRole: 'manager',
      actionType: 'APPROVE_ATTENDANCE',
      targetCollection: 'attendance',
      targetEntityId: 'EMP-1024_2026-08-30',
      description: 'Vikram Mehta approved clock-in selfie and GPS for Rahul Sharma.',
      oldValue: { status: 'pending', approvalStatus: 'pending' },
      newValue: { status: 'approved', approvalStatus: 'approved' },
      ipAddress: '192.168.1.25',
      userAgent: 'Flutter Android / Google Pixel 8',
      timestamp: admin.firestore.Timestamp.fromDate(new Date('2026-08-30T09:40:00Z'))
    },
    {
      logId: 'log_02',
      actorId: 'EMP-1004',
      actorName: 'Rajesh Sharma (Admin)',
      actorRole: 'admin',
      actionType: 'UPDATE_POLICY',
      targetCollection: 'attendancePolicies',
      targetEntityId: 'policy_standard',
      description: 'Updated Standard Corporate Policy grace period to 15 mins.',
      oldValue: { gracePeriodMinutes: 10 },
      newValue: { gracePeriodMinutes: 15 },
      ipAddress: '192.168.1.1',
      userAgent: 'Flutter Windows Desktop',
      timestamp: admin.firestore.Timestamp.fromDate(new Date('2026-08-25T14:30:00Z'))
    }
  ];
  for (const al of auditLogs) {
    await db.collection('auditLogs').doc(al.logId).set(al);
  }
  console.log('   ✅ Seeded ' + auditLogs.length + ' immutable audit logs');

  // 17. APP SETTINGS
  console.log('📦 17/17 Seeding: appSettings ...');
  const settings = [
    {
      settingKey: 'general',
      companyName: 'AttendX Enterprise Global',
      supportEmail: 'hr-support@attendx.com',
      autoEmailReportsTo: ['pooja.verma@attendx.com', 'rajesh.sharma@attendx.com'],
      allowMockLocation: false,
      enforceBiometrics: true,
      timeZone: 'Asia/Kolkata',
      updatedAt: admin.firestore.Timestamp.now()
    },
    {
      settingKey: 'branding',
      appName: 'AttendX',
      primaryColorHex: '#1E88E5',
      secondaryColorHex: '#26A69A',
      logoUrl: 'https://storage.googleapis.com/attendx-8b4c5.appspot.com/branding/logo.png',
      updatedAt: admin.firestore.Timestamp.now()
    },
    {
      settingKey: 'cron',
      autoClockOutEnabled: true,
      autoClockOutSchedule: '59 23 * * *',
      monthlyReportSchedule: '0 0 1 * *',
      updatedAt: admin.firestore.Timestamp.now()
    }
  ];
  for (const s of settings) {
    await db.collection('appSettings').doc(s.settingKey).set(s);
  }
  console.log('   ✅ Seeded ' + settings.length + ' application configurations');

  console.log('\n====================================================');
  console.log('🎉 ALL 17 FIRESTORE COLLECTIONS SEEDED SUCCESSFULLY!');
  console.log('====================================================');
}

seedAll17Collections().catch((err) => {
  console.error('❌ Seeding failed with error:', err);
  process.exit(1);
});
