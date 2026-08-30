import 'package:flutter/material.dart';

enum AppRole {
  employee,
  tl,
  hr,
  admin;

  static AppRole fromString(String? role) {
    if (role == null) return AppRole.employee;
    switch (role.toLowerCase().trim()) {
      case 'tl':
      case 'manager':
      case 'team_lead':
        return AppRole.tl;
      case 'hr':
      case 'hr_manager':
        return AppRole.hr;
      case 'admin':
      case 'super_admin':
        return AppRole.admin;
      case 'employee':
      default:
        return AppRole.employee;
    }
  }

  String get displayName {
    switch (this) {
      case AppRole.employee:
        return 'Employee';
      case AppRole.tl:
        return 'TL / Manager';
      case AppRole.hr:
        return 'HR';
      case AppRole.admin:
        return 'Admin';
    }
  }

  String get roleCode {
    switch (this) {
      case AppRole.employee:
        return 'employee';
      case AppRole.tl:
        return 'tl';
      case AppRole.hr:
        return 'hr';
      case AppRole.admin:
        return 'admin';
    }
  }

  Color get badgeColor {
    switch (this) {
      case AppRole.employee:
        return const Color(0xFF3B82F6); // Blue
      case AppRole.tl:
        return const Color(0xFF0EA5E9); // Sky
      case AppRole.hr:
        return const Color(0xFF8B5CF6); // Purple
      case AppRole.admin:
        return const Color(0xFFEF4444); // Red
    }
  }

  IconData get icon {
    switch (this) {
      case AppRole.employee:
        return Icons.person_outline;
      case AppRole.tl:
        return Icons.supervisor_account_outlined;
      case AppRole.hr:
        return Icons.badge_outlined;
      case AppRole.admin:
        return Icons.admin_panel_settings_outlined;
    }
  }
}

enum AppPermission {
  // Employee permissions
  clockIn,
  clockOut,
  viewOwnAttendance,
  viewOwnCalendar,
  applyLeave,
  viewOwnLeaves,
  requestCorrection,

  // TL Permissions
  viewTeamMembers,
  viewTeamAttendance,
  reviewClockInPhotos,
  approveAttendance,
  rejectAttendance,
  approveTeamLeaves,
  viewTeamStats,
  viewLateEmployees,
  viewMissingClockOuts,

  // HR Permissions
  viewAllEmployees,
  viewCompanyAttendance,
  generateAttendanceReports,
  exportPdfReports,
  exportExcelReports,
  exportCsvReports,
  manageHolidays,
  manageShifts,
  viewAllDepartments,
  viewAllTeams,

  // Admin Permissions
  manageUsers,
  manageRoles,
  manageDepartments,
  manageTeams,
  manageOfficeLocations,
  manageGeofencing,
  manageAttendancePolicies,
  viewAuditLogs,
  manageSystemSettings,
  fullAccess,
}
