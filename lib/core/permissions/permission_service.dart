import 'role_model.dart';
import '../../models/user_model.dart';

class PermissionService {
  static final Map<AppRole, Set<AppPermission>> _rolePermissions = {
    AppRole.employee: {
      AppPermission.clockIn,
      AppPermission.clockOut,
      AppPermission.viewOwnAttendance,
      AppPermission.viewOwnCalendar,
      AppPermission.applyLeave,
      AppPermission.viewOwnLeaves,
      AppPermission.requestCorrection,
    },
    AppRole.tl: {
      AppPermission.clockIn,
      AppPermission.clockOut,
      AppPermission.viewOwnAttendance,
      AppPermission.viewOwnCalendar,
      AppPermission.applyLeave,
      AppPermission.viewOwnLeaves,
      AppPermission.requestCorrection,
      // TL Capabilities
      AppPermission.viewTeamMembers,
      AppPermission.viewTeamAttendance,
      AppPermission.reviewClockInPhotos,
      AppPermission.approveAttendance,
      AppPermission.rejectAttendance,
      AppPermission.approveTeamLeaves,
      AppPermission.viewTeamStats,
      AppPermission.viewLateEmployees,
      AppPermission.viewMissingClockOuts,
    },
    AppRole.hr: {
      AppPermission.clockIn,
      AppPermission.clockOut,
      AppPermission.viewOwnAttendance,
      AppPermission.viewOwnCalendar,
      AppPermission.applyLeave,
      AppPermission.viewOwnLeaves,
      AppPermission.requestCorrection,
      // HR Capabilities
      AppPermission.viewAllEmployees,
      AppPermission.viewCompanyAttendance,
      AppPermission.generateAttendanceReports,
      AppPermission.exportPdfReports,
      AppPermission.exportExcelReports,
      AppPermission.exportCsvReports,
      AppPermission.manageHolidays,
      AppPermission.manageShifts,
      AppPermission.viewAllDepartments,
      AppPermission.viewAllTeams,
    },
    AppRole.admin: AppPermission.values.toSet(), // Admin has all permissions
  };

  static bool hasPermission(AppRole role, AppPermission permission) {
    if (role == AppRole.admin) return true;
    return _rolePermissions[role]?.contains(permission) ?? false;
  }

  static bool userHasPermission(UserModel? user, AppPermission permission) {
    if (user == null) return false;
    final role = AppRole.fromString(user.role.name);
    return hasPermission(role, permission);
  }

  static bool canAccessRoute(AppRole role, String route) {
    if (role == AppRole.admin) return true;

    if (route.startsWith('/admin')) {
      return role == AppRole.admin;
    }
    if (route.startsWith('/hr')) {
      return role == AppRole.hr || role == AppRole.admin;
    }
    if (route.startsWith('/tl')) {
      return role == AppRole.tl || role == AppRole.admin;
    }
    if (route.startsWith('/employee')) {
      return true; // All authenticated roles have employee base access
    }
    return true;
  }
}
