import 'package:flutter/material.dart';
import 'nav_menu_item.dart';
import '../permissions/role_model.dart';

class HRMenu {
  static List<NavMenuItem> getMenuItems({int pendingNotifs = 0}) => [
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
      route: '/hr/dashboard',
    ),
    const NavMenuItem(
      title: 'Employees',
      icon: Icons.people_alt_outlined,
      destination: NavDestinationKey.employees,
      route: '/hr/employees',
      requiredPermission: AppPermission.viewAllEmployees,
    ),
    const NavMenuItem(
      title: 'Attendance',
      icon: Icons.co_present_outlined,
      destination: NavDestinationKey.companyAttendance,
      route: '/hr/attendance',
      requiredPermission: AppPermission.viewCompanyAttendance,
    ),
    const NavMenuItem(
      title: 'Attendance Reports',
      icon: Icons.analytics_outlined,
      destination: NavDestinationKey.attendanceReports,
      route: '/hr/reports',
      requiredPermission: AppPermission.generateAttendanceReports,
    ),
    const NavMenuItem(
      title: 'Daily Report',
      icon: Icons.calendar_view_day_rounded,
      destination: NavDestinationKey.dailyReport,
      route: '/hr/reports/daily',
      requiredPermission: AppPermission.generateAttendanceReports,
    ),
    const NavMenuItem(
      title: 'Monthly Report',
      icon: Icons.calendar_view_month_rounded,
      destination: NavDestinationKey.monthlyReport,
      route: '/hr/reports/monthly',
      requiredPermission: AppPermission.generateAttendanceReports,
    ),
    const NavMenuItem(
      title: '30-Day Report',
      icon: Icons.insert_chart_outlined_rounded,
      destination: NavDestinationKey.report30Day,
      route: '/hr/reports/30-day',
      requiredPermission: AppPermission.generateAttendanceReports,
    ),
    const NavMenuItem(
      title: 'Leave Management',
      icon: Icons.beach_access_rounded,
      destination: NavDestinationKey.leaveManagement,
      route: '/hr/leaves',
    ),
    const NavMenuItem(
      title: 'Teams',
      icon: Icons.hub_outlined,
      destination: NavDestinationKey.teams,
      route: '/hr/teams',
      requiredPermission: AppPermission.viewAllTeams,
    ),
    const NavMenuItem(
      title: 'Departments',
      icon: Icons.domain_rounded,
      destination: NavDestinationKey.departments,
      route: '/hr/departments',
      requiredPermission: AppPermission.viewAllDepartments,
    ),
    const NavMenuItem(
      title: 'Holidays',
      icon: Icons.event_available_rounded,
      destination: NavDestinationKey.holidays,
      route: '/hr/holidays',
      requiredPermission: AppPermission.manageHolidays,
    ),
    const NavMenuItem(
      title: 'Shifts',
      icon: Icons.access_time_rounded,
      destination: NavDestinationKey.shifts,
      route: '/hr/shifts',
      requiredPermission: AppPermission.manageShifts,
    ),
    NavMenuItem(
      title: 'Notifications',
      icon: Icons.notifications_none_rounded,
      destination: NavDestinationKey.notifications,
      route: '/hr/notifications',
      badgeCount: pendingNotifs > 0 ? pendingNotifs : null,
    ),
    const NavMenuItem(
      title: 'AI Assistant',
      icon: Icons.smart_toy_rounded,
      destination: NavDestinationKey.aiAssistant,
      route: '/hr/ai-assistant',
    ),
    const NavMenuItem(
      title: 'My Profile',
      icon: Icons.person_outline_rounded,
      destination: NavDestinationKey.myProfile,
      route: '/hr/profile',
    ),
    const NavMenuItem(
      title: 'Settings',
      icon: Icons.settings_outlined,
      destination: NavDestinationKey.settings,
      route: '/hr/settings',
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
