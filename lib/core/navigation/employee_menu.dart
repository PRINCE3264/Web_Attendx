import 'package:flutter/material.dart';
import 'nav_menu_item.dart';
import '../permissions/role_model.dart';

class EmployeeMenu {
  static List<NavMenuItem> getMenuItems({int pendingNotifs = 0}) => [
    const NavMenuItem(
      title: 'Dashboard',
      icon: Icons.dashboard_rounded,
      destination: NavDestinationKey.dashboard,
      route: '/employee/dashboard',
    ),
    const NavMenuItem(
      title: 'Community EB',
      icon: Icons.groups_rounded,
      destination: NavDestinationKey.communityEB,
      route: '/community-eb',
    ),
    const NavMenuItem(
      title: 'My Attendance',
      icon: Icons.today_rounded,
      destination: NavDestinationKey.myAttendance,
      route: '/employee/attendance',
      requiredPermission: AppPermission.viewOwnAttendance,
    ),
    const NavMenuItem(
      title: 'Clock In',
      icon: Icons.camera_alt_outlined,
      destination: NavDestinationKey.clockIn,
      route: '/employee/clock-in',
      requiredPermission: AppPermission.clockIn,
    ),
    const NavMenuItem(
      title: 'Clock Out',
      icon: Icons.logout_rounded,
      destination: NavDestinationKey.clockOut,
      route: '/employee/clock-out',
      requiredPermission: AppPermission.clockOut,
    ),
    const NavMenuItem(
      title: 'Attendance History',
      icon: Icons.history_rounded,
      destination: NavDestinationKey.attendanceHistory,
      route: '/employee/history',
      requiredPermission: AppPermission.viewOwnAttendance,
    ),
    const NavMenuItem(
      title: 'Attendance Calendar',
      icon: Icons.calendar_month_rounded,
      destination: NavDestinationKey.attendanceCalendar,
      route: '/employee/calendar',
      requiredPermission: AppPermission.viewOwnCalendar,
    ),
    const NavMenuItem(
      title: 'Project Work Reports',
      icon: Icons.assignment_turned_in_outlined,
      destination: NavDestinationKey.projectReports,
      route: '/employee/project-reports',
    ),
    const NavMenuItem(
      title: 'My Projects',
      icon: Icons.folder_special_rounded,
      destination: NavDestinationKey.projectsManagement,
      route: '/employee/projects',
    ),
    const NavMenuItem(
      title: 'Leave',
      icon: Icons.beach_access_rounded,
      destination: NavDestinationKey.leave,
      route: '/employee/leave',
      requiredPermission: AppPermission.applyLeave,
    ),
    const NavMenuItem(
      title: 'Leave History',
      icon: Icons.assignment_outlined,
      destination: NavDestinationKey.leaveHistory,
      route: '/employee/leave-history',
      requiredPermission: AppPermission.viewOwnLeaves,
    ),
    NavMenuItem(
      title: 'Notifications',
      icon: Icons.notifications_none_rounded,
      destination: NavDestinationKey.notifications,
      route: '/employee/notifications',
      badgeCount: pendingNotifs > 0 ? pendingNotifs : null,
    ),
    const NavMenuItem(
      title: 'AI Assistant',
      icon: Icons.smart_toy_rounded,
      destination: NavDestinationKey.aiAssistant,
      route: '/employee/ai-assistant',
    ),
    const NavMenuItem(
      title: 'My Profile',
      icon: Icons.person_outline_rounded,
      destination: NavDestinationKey.myProfile,
      route: '/employee/profile',
    ),
    const NavMenuItem(
      title: 'System Settings',
      icon: Icons.settings_applications_rounded,
      destination: NavDestinationKey.systemSettings,
      route: '/employee/settings',
    ),
    const NavMenuItem(
      title: 'Logout',
      icon: Icons.power_settings_new_rounded,
      destination: NavDestinationKey.logout,
      route: '/auth/logout',
      isDestructive: true,
    ),
  ];
}
