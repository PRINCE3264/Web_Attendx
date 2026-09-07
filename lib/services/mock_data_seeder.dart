import '../models/user_model.dart';
import '../models/team_model.dart';
import '../models/leave_model.dart';
import '../models/policy_model.dart';
import '../models/attendance_model.dart';
import '../models/correction_model.dart';
import '../models/audit_log_model.dart';
import '../models/project_model.dart';
import '../models/notification_model.dart';

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
        casualUsed: 0,
        sickTotal: 8,
        sickUsed: 0,
        earnedTotal: 15,
        earnedUsed: 0,
      ),
      LeaveBalanceModel(
        employeeId: 'emp_02',
        casualTotal: 12,
        casualUsed: 0,
        sickTotal: 8,
        sickUsed: 0,
        earnedTotal: 15,
        earnedUsed: 0,
      ),
      LeaveBalanceModel(
        employeeId: 'emp_03',
        casualTotal: 12,
        casualUsed: 0,
        sickTotal: 8,
        sickUsed: 0,
        earnedTotal: 15,
        earnedUsed: 0,
      ),
      LeaveBalanceModel(
        employeeId: 'emp_04',
        casualTotal: 12,
        casualUsed: 0,
        sickTotal: 8,
        sickUsed: 0,
        earnedTotal: 15,
        earnedUsed: 0,
      ),
      LeaveBalanceModel(
        employeeId: 'mgr_01',
        casualTotal: 12,
        casualUsed: 0,
        sickTotal: 8,
        sickUsed: 0,
        earnedTotal: 15,
        earnedUsed: 0,
      ),
      LeaveBalanceModel(
        employeeId: 'hr_01',
        casualTotal: 12,
        casualUsed: 0,
        sickTotal: 8,
        sickUsed: 0,
        earnedTotal: 15,
        earnedUsed: 0,
      ),
      LeaveBalanceModel(
        employeeId: 'admin_01',
        casualTotal: 12,
        casualUsed: 0,
        sickTotal: 8,
        sickUsed: 0,
        earnedTotal: 15,
        earnedUsed: 0,
      ),
    ];
  }

  static List<LeaveRequestModel> getSeedLeaveRequests() {
    return [];
  }

  static List<AttendanceCorrectionModel> getSeedCorrections() {
    return [];
  }

  static List<AuditLogModel> getSeedAuditLogs() {
    return [];
  }

  static List<AttendanceModel> getSeedAttendanceHistory() {
    return [];
  }

  static List<ProjectModel> getSeedProjects() {
    return [];
  }

  static List<NotificationModel> getSeedNotifications() {
    final now = DateTime.now();
    return [
      NotificationModel(
        id: 'notif_seed_1',
        userId: 'ALL',
        title: '🏖️ Upcoming Holiday: Ganesh Chaturthi Notice',
        message: 'The office will remain closed on September 15 for Ganesh Chaturthi celebrations. Enjoy your holiday!',
        type: 'holiday',
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      NotificationModel(
        id: 'notif_seed_2',
        userId: 'ALL',
        title: '🆕 New Employee Joined: Vikram Mehta',
        message: 'Vikram Mehta (MGR-201) joined Engineering Management as Team Lead (TL). Welcome aboard!',
        type: 'info',
        createdAt: now.subtract(const Duration(hours: 12)),
      ),
      NotificationModel(
        id: 'notif_seed_3',
        userId: 'ALL',
        title: '📢 System Update: AttendX 2.5 Features',
        message: 'New geolocation tracking, leave balances, and instant notification system are now live.',
        type: 'notice',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      NotificationModel(
        id: 'notif_seed_4',
        userId: 'emp_01',
        title: '✅ Attendance Marked Successfully',
        message: 'Your shift check-in for today at 09:30 AM has been recorded.',
        type: 'approval',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      NotificationModel(
        id: 'notif_seed_5',
        userId: 'mgr_01',
        title: '📝 Pending Leave Approvals',
        message: 'You have 2 pending leave requests waiting for your review.',
        type: 'info',
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      NotificationModel(
        id: 'notif_seed_6',
        userId: 'hr_01',
        title: '📊 Monthly Attendance Audit Ready',
        message: 'The August attendance and leave summary reports are ready for review.',
        type: 'report',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }
}
