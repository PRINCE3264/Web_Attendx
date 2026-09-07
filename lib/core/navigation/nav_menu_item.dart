import 'package:flutter/material.dart';
import '../permissions/role_model.dart';

enum NavDestinationKey {
  // Common
  dashboard,
  projectReports,
  aiAssistant,
  myProfile,
  settings,
  notifications,
  logout,

  // Employee
  myAttendance,
  clockIn,
  clockOut,
  attendanceHistory,
  attendanceCalendar,
  leave,
  leaveHistory,

  // TL / Manager
  teamAttendance,
  pendingApprovals,
  leaveApprovals,
  teamMembers,
  teamWorkReport,

  // HR
  employees,
  companyAttendance,
  attendanceReports,
  dailyReport,
  monthlyReport,
  report30Day,
  leaveManagement,
  teams,
  departments,
  holidays,
  shifts,

  // Admin
  users,
  managersTLs,
  hrManagement,
  officeLocations,
  geofencing,
  attendancePolicies,
  auditLogs,
  systemSettings,
  projectsManagement,
}

class NavMenuItem {
  final String title;
  final IconData icon;
  final NavDestinationKey destination;
  final String route;
  final AppPermission? requiredPermission;
  final int? badgeCount;
  final bool isDivider;
  final bool isDestructive;

  const NavMenuItem({
    required this.title,
    required this.icon,
    required this.destination,
    required this.route,
    this.requiredPermission,
    this.badgeCount,
    this.isDivider = false,
    this.isDestructive = false,
  });
}
