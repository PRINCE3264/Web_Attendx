import 'package:flutter/material.dart';
import 'nav_menu_item.dart';
import '../permissions/role_model.dart';

class TLMenu {
  static List<NavMenuItem> getMenuItems({int pendingApprovalsCount = 0, int pendingNotifs = 0}) => [
    const NavMenuItem(
      title: 'My Clock-In & Self',
      icon: Icons.touch_app_rounded,
      destination: NavDestinationKey.myAttendance,
      route: '/employee/dashboard',
    ),
    const NavMenuItem(
      title: 'Dashboard',
      icon: Icons.dashboard_rounded,
      destination: NavDestinationKey.dashboard,
      route: '/tl/dashboard',
    ),
    const NavMenuItem(
      title: 'Team Attendance',
      icon: Icons.groups_rounded,
      destination: NavDestinationKey.teamAttendance,
      route: '/tl/team-attendance',
      requiredPermission: AppPermission.viewTeamAttendance,
    ),
    NavMenuItem(
      title: 'Pending Approvals',
      icon: Icons.fact_check_outlined,
      destination: NavDestinationKey.pendingApprovals,
      route: '/tl/approvals',
      requiredPermission: AppPermission.approveAttendance,
      badgeCount: pendingApprovalsCount > 0 ? pendingApprovalsCount : null,
    ),
    const NavMenuItem(
      title: 'Attendance History',
      icon: Icons.history_edu_rounded,
      destination: NavDestinationKey.attendanceHistory,
      route: '/tl/history',
      requiredPermission: AppPermission.viewTeamAttendance,
    ),
    const NavMenuItem(
      title: 'Leave Approvals',
      icon: Icons.approval_rounded,
      destination: NavDestinationKey.leaveApprovals,
      route: '/tl/leave-approvals',
      requiredPermission: AppPermission.approveTeamLeaves,
    ),
    const NavMenuItem(
      title: 'Team Members',
      icon: Icons.badge_outlined,
      destination: NavDestinationKey.teamMembers,
      route: '/tl/team-members',
      requiredPermission: AppPermission.viewTeamMembers,
    ),
    const NavMenuItem(
      title: 'Project Work Reports',
      icon: Icons.assignment_turned_in_outlined,
      destination: NavDestinationKey.projectReports,
      route: '/tl/project-reports',
    ),
    const NavMenuItem(
      title: 'Company Projects',
      icon: Icons.folder_special_rounded,
      destination: NavDestinationKey.projectsManagement,
      route: '/tl/projects',
    ),
    NavMenuItem(
      title: 'Notifications',
      icon: Icons.notifications_none_rounded,
      destination: NavDestinationKey.notifications,
      route: '/tl/notifications',
      badgeCount: pendingNotifs > 0 ? pendingNotifs : null,
    ),
    const NavMenuItem(
      title: 'AI Assistant',
      icon: Icons.smart_toy_rounded,
      destination: NavDestinationKey.aiAssistant,
      route: '/tl/ai-assistant',
    ),
    const NavMenuItem(
      title: 'My Profile',
      icon: Icons.person_outline_rounded,
      destination: NavDestinationKey.myProfile,
      route: '/tl/profile',
    ),
    const NavMenuItem(
      title: 'System Settings',
      icon: Icons.settings_applications_rounded,
      destination: NavDestinationKey.systemSettings,
      route: '/tl/settings',
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
