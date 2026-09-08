import '../models/user_model.dart';
import '../models/team_model.dart';
import '../models/department_model.dart';
import '../models/leave_model.dart';
import '../models/policy_model.dart';
import '../models/attendance_model.dart';
import '../models/correction_model.dart';
import '../models/audit_log_model.dart';
import '../models/project_model.dart';
import '../models/project_report_model.dart';
import '../models/notification_model.dart';

class MockDataSeeder {
  static List<UserModel> getSeedUsers() => [];

  static List<TeamModel> getSeedTeams() => [
    TeamModel(
      teamId: 'team_mobile',
      name: 'Mobile Apps Team (Flutter)',
      departmentId: 'dept_eng',
      managerId: 'EMP-1002',
      managerName: 'Vikram Mehta (TL)',
      memberCount: 5,
      isActive: true,
    ),
    TeamModel(
      teamId: 'team_backend',
      name: 'Backend & Cloud Infrastructure',
      departmentId: 'dept_eng',
      managerId: 'EMP-1002',
      managerName: 'Vikram Mehta (TL)',
      memberCount: 4,
      isActive: true,
    ),
    TeamModel(
      teamId: 'team_hr_ops',
      name: 'HR Operations & Talent Acquisition',
      departmentId: 'dept_hr',
      managerId: 'EMP-1003',
      managerName: 'Pooja Verma',
      memberCount: 3,
      isActive: true,
    ),
    TeamModel(
      teamId: 'team_qa',
      name: 'QA & Software Testing',
      departmentId: 'dept_eng',
      managerId: 'EMP-1002',
      managerName: 'Vikram Mehta (TL)',
      memberCount: 3,
      isActive: true,
    ),
  ];

  static List<DepartmentModel> getSeedDepartments() => [
    DepartmentModel(
      departmentId: 'dept_eng',
      name: 'Engineering & Technology',
      code: 'ENG',
      headOfDepartmentId: 'EMP-1001',
      headOfDepartmentName: 'Dr. Anita Roy',
      totalEmployees: 14,
      isActive: true,
    ),
    DepartmentModel(
      departmentId: 'dept_hr',
      name: 'Human Resources & People Ops',
      code: 'HR',
      headOfDepartmentId: 'EMP-1003',
      headOfDepartmentName: 'Pooja Verma',
      totalEmployees: 5,
      isActive: true,
    ),
    DepartmentModel(
      departmentId: 'dept_ops',
      name: 'Operations & Management',
      code: 'OPS',
      headOfDepartmentId: 'EMP-1004',
      headOfDepartmentName: 'Rajesh Sharma',
      totalEmployees: 6,
      isActive: true,
    ),
    DepartmentModel(
      departmentId: 'dept_design',
      name: 'UI/UX & Product Design',
      code: 'DES',
      headOfDepartmentId: 'EMP-1005',
      headOfDepartmentName: 'Siddharth Rao',
      totalEmployees: 4,
      isActive: true,
    ),
  ];

  static AttendancePolicyModel getSeedPolicy() => AttendancePolicyModel();

  static List<LeaveBalanceModel> getSeedLeaveBalances() => [];

  static List<LeaveRequestModel> getSeedLeaveRequests() => [];

  static List<AttendanceCorrectionModel> getSeedCorrections() => [];

  static List<AuditLogModel> getSeedAuditLogs() => [];

  static List<AttendanceModel> getSeedAttendanceHistory() => [];

  static List<ProjectModel> getSeedProjects() => [];

  static List<ProjectReportModel> getSeedProjectReports() => [];

  static List<NotificationModel> getSeedNotifications() => [];
}
