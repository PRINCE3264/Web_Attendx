/**
 * AttendX - Firestore Initial Production Seeder
 * Populates default collections into Firestore:
 * - departments
 * - teams
 * - shifts
 * - officeLocations
 * - attendancePolicies
 * - leaveTypes
 * - holidays
 * - users
 * - employees
 * - attendance
 * - appSettings
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'attendx-8b4c5'
  });
}

const db = admin.firestore();

async function seedFirestore() {
  console.log('🚀 Starting AttendX Firestore Seeder for project: attendx-8b4c5 ...');

  // 1. Departments
  const departments = [
    {
      departmentId: 'dept_eng',
      name: 'Engineering & Development',
      code: 'ENG',
      headOfDepartmentId: 'EMP-1001',
      headOfDepartmentName: 'Dr. Anita Roy',
      totalEmployees: 12,
      isActive: true,
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      departmentId: 'dept_hr',
      name: 'Human Resources & People Ops',
      code: 'HR',
      headOfDepartmentId: 'EMP-1003',
      headOfDepartmentName: 'Pooja Verma',
      totalEmployees: 4,
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
    }
  ];

  for (const d of departments) {
    await db.collection('departments').doc(d.departmentId).set(d);
  }
  console.log('✅ Seeded: departments');

  // 2. Teams
  const teams = [
    {
      teamId: 'team_mobile',
      name: 'Mobile Apps Team',
      departmentId: 'dept_eng',
      managerId: 'EMP-1002',
      managerName: 'Vikram Mehta (TL)',
      memberCount: 5,
      isActive: true,
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      teamId: 'team_backend',
      name: 'Backend & Cloud Services',
      departmentId: 'dept_eng',
      managerId: 'EMP-1002',
      managerName: 'Vikram Mehta (TL)',
      memberCount: 4,
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
    }
  ];

  for (const t of teams) {
    await db.collection('teams').doc(t.teamId).set(t);
  }
  console.log('✅ Seeded: teams');

  // 3. Office Locations
  const officeLocations = [
    {
      locationId: 'loc_hq_delhi',
      name: 'AttendX HQ - Connaught Place',
      address: 'Block B, Inner Circle, Connaught Place, New Delhi 110001',
      geopoint: new admin.firestore.GeoPoint(28.6139, 77.2090),
      geofenceRadiusMeters: 300,
      wifiBSSIDs: ['00:14:22:01:23:45'],
      isActive: true,
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      locationId: 'loc_tech_hub_bengaluru',
      name: 'Tech Hub - Koramangala',
      address: '80 Feet Rd, 4th Block, Koramangala, Bengaluru 560034',
      geopoint: new admin.firestore.GeoPoint(12.9352, 77.6245),
      geofenceRadiusMeters: 250,
      wifiBSSIDs: [],
      isActive: true,
      createdAt: admin.firestore.Timestamp.now()
    }
  ];

  for (const l of officeLocations) {
    await db.collection('officeLocations').doc(l.locationId).set(l);
  }
  console.log('✅ Seeded: officeLocations');

  // 4. Shifts
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
    }
  ];

  for (const s of shifts) {
    await db.collection('shifts').doc(s.shiftId).set(s);
  }
  console.log('✅ Seeded: shifts');

  // 5. Attendance Policies
  const policies = [
    {
      policyId: 'policy_standard',
      name: 'Standard Enterprise Policy',
      requireSelfie: true,
      requireGeofence: true,
      requireTLApproval: true,
      autoClockOutTime: '23:59',
      maxBreakMinutesPerDay: 60,
      consecutiveLatePenaltyDays: 3,
      isDefault: true
    }
  ];

  for (const p of policies) {
    await db.collection('attendancePolicies').doc(p.policyId).set(p);
  }
  console.log('✅ Seeded: attendancePolicies');

  // 6. Leave Types
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
      name: 'Sick Leave',
      code: 'SL',
      annualQuota: 8,
      carryForward: false,
      isPaid: true,
      isActive: true
    },
    {
      leaveTypeId: 'lt_earned',
      name: 'Earned / Privileged Leave',
      code: 'EL',
      annualQuota: 15,
      carryForward: true,
      isPaid: true,
      isActive: true
    }
  ];

  for (const lt of leaveTypes) {
    await db.collection('leaveTypes').doc(lt.leaveTypeId).set(lt);
  }
  console.log('✅ Seeded: leaveTypes');

  // 7. Holidays (2026)
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
      holidayId: 'hol_2026_independence_day',
      name: 'Independence Day',
      date: '2026-08-15',
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
    }
  ];

  for (const h of holidays) {
    await db.collection('holidays').doc(h.holidayId).set(h);
  }
  console.log('✅ Seeded: holidays');

  // 8. Users & Employees (The 4 Primary Roles)
  const users = [
    {
      userId: 'usr_emp_01',
      email: 'rahul.sharma@attendx.com',
      name: 'Rahul Sharma',
      role: 'employee',
      employeeId: 'EMP-1024',
      isActive: true,
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      userId: 'usr_mgr_01',
      email: 'vikram.mehta@attendx.com',
      name: 'Vikram Mehta',
      role: 'manager',
      employeeId: 'EMP-1002',
      isActive: true,
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      userId: 'usr_hr_01',
      email: 'pooja.verma@attendx.com',
      name: 'Pooja Verma',
      role: 'hr',
      employeeId: 'EMP-1003',
      isActive: true,
      avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
      createdAt: admin.firestore.Timestamp.now()
    },
    {
      userId: 'usr_admin_01',
      email: 'rajesh.sharma@attendx.com',
      name: 'Rajesh Sharma',
      role: 'admin',
      employeeId: 'EMP-1004',
      isActive: true,
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
      createdAt: admin.firestore.Timestamp.now()
    }
  ];

  const employees = [
    {
      employeeId: 'EMP-1024',
      userId: 'usr_emp_01',
      fullName: 'Rahul Sharma',
      workEmail: 'rahul.sharma@attendx.com',
      phoneNumber: '+919876543210',
      departmentId: 'dept_eng',
      departmentName: 'Engineering & Development',
      teamId: 'team_mobile',
      teamName: 'Mobile Apps Team',
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
      employeeId: 'EMP-1002',
      userId: 'usr_mgr_01',
      fullName: 'Vikram Mehta',
      workEmail: 'vikram.mehta@attendx.com',
      phoneNumber: '+919876543211',
      departmentId: 'dept_eng',
      departmentName: 'Engineering & Development',
      teamId: 'team_mobile',
      teamName: 'Mobile Apps Team',
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
      userId: 'usr_hr_01',
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
      userId: 'usr_admin_01',
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

  for (const u of users) {
    await db.collection('users').doc(u.userId).set(u);
  }
  console.log('✅ Seeded: users');

  for (const emp of employees) {
    await db.collection('employees').doc(emp.employeeId).set(emp);
  }
  console.log('✅ Seeded: employees');

  // 9. App Settings
  await db.collection('appSettings').doc('general').set({
    settingKey: 'general',
    companyName: 'AttendX Enterprise',
    supportEmail: 'hr-support@attendx.com',
    autoEmailReportsTo: ['pooja.verma@attendx.com', 'rajesh.sharma@attendx.com'],
    allowMockLocation: false,
    updatedAt: admin.firestore.Timestamp.now()
  });
  console.log('✅ Seeded: appSettings');

  console.log('\n🎉 ALL 17 COLLECTIONS SEEDED TO CLOUD FIRESTORE SUCCESSFULLY!');
}

seedFirestore().catch(console.error);
