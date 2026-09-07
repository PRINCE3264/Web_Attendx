import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/navigation/nav_menu_item.dart';
import '../../core/permissions/role_model.dart';
import '../../core/permissions/permission_service.dart';
import '../../core/routing/route_guard.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/role_based_sidebar.dart';
import '../admin/admin_panel_screen.dart';
import '../admin/audit_logs_screen.dart';
import '../admin/policy_settings_screen.dart';
import '../admin/projects_management_screen.dart';

import '../auth/login_screen.dart';
import '../employee/attendance_history_screen.dart';
import '../employee/camera_capture_screen.dart';
import '../employee/employee_dashboard.dart';
import '../employee/leave_management_screen.dart';
import '../hr/all_employees_screen.dart';
import '../hr/hr_dashboard.dart';
import '../hr/report_generator_screen.dart';
import '../manager/leave_approval_screen.dart';
import '../manager/manager_dashboard.dart';
import 'ai_voice_assistant_sheet.dart';
import 'project_reports_screen.dart';
import 'system_settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  NavDestinationKey _activeDestination = NavDestinationKey.dashboard;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    final role = AppRole.fromString(user.role.name);
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: isDesktop
          ? null
          : RoleBasedSidebar(
              activeDestination: _activeDestination,
              onSelectMenu: _handleMenuSelection,
            ),
      body: Row(
        children: [
          // Permanent Sidebar on Desktop / Large screens
          if (isDesktop)
            RoleBasedSidebar(
              activeDestination: _activeDestination,
              onSelectMenu: _handleMenuSelection,
              isPermanent: true,
            ),

          // Main Workspace Area
          Expanded(
            child: Column(
              children: [
                // Top Global Header Bar
                _buildGlobalHeader(context, user, role, isDesktop),

                const Divider(height: 1, color: Color(0xFFF1F5F9)),

                // Role-Protected Active Screen Content
                Expanded(child: _resolveActiveScreen(role, user)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalHeader(
    BuildContext context,
    UserModel user,
    AppRole role,
    bool isDesktop,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 680;

    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 16),
      color: Colors.white,
      child: Row(
        children: [
          if (!isDesktop)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(
                  Icons.menu_rounded,
                  size: 24,
                  color: AppTheme.textMainLight,
                ),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                tooltip: 'Open Sidebar',
              ),
            ),
          const SizedBox(width: 4),

          // Header Text: Welcome, {User Name}
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${user.name}',
                  style: GoogleFonts.outfit(
                    fontSize: isCompact ? 14.5 : 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMainLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Role: ${role.displayName} • ${user.department}',
                  style: GoogleFonts.inter(
                    fontSize: isCompact ? 10.5 : 11.5,
                    fontWeight: FontWeight.w500,
                    color: role.badgeColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Role Badge Pill (Show full pill on larger screens, compact icon badge on small screens)
          if (!isCompact)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: role.badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: role.badgeColor.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(role.icon, size: 14, color: role.badgeColor),
                  const SizedBox(width: 6),
                  Text(
                    role.displayName,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: role.badgeColor,
                    ),
                  ),
                ],
              ),
            ),

          if (!isCompact) const SizedBox(width: 8),

          // Instant Role Switcher Button
          if (isCompact)
            IconButton(
              onPressed: _showRoleSwitcherDialog,
              icon: const Icon(
                Icons.swap_horiz_rounded,
                size: 20,
                color: AppTheme.primary,
              ),
              tooltip: 'Switch Role',
            )
          else
            TextButton.icon(
              onPressed: _showRoleSwitcherDialog,
              icon: const Icon(Icons.swap_horiz_rounded, size: 16),
              label: const Text('Switch Role', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
            ),

          // Notification Icon
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              size: 20,
              color: Color(0xFF64748B),
            ),
            onPressed: _showNotificationsSheet,
            tooltip: 'FCM Alerts',
          ),
        ],
      ),
    );
  }

  Widget _resolveActiveScreen(AppRole role, UserModel user) {
    switch (_activeDestination) {
      case NavDestinationKey.dashboard:
        switch (role) {
          case AppRole.employee:
            return const EmployeeDashboard();
          case AppRole.tl:
            return const ManagerDashboard();
          case AppRole.hr:
            return const HrDashboard();
          case AppRole.admin:
            return const AdminPanelScreen();
        }

      case NavDestinationKey.myAttendance:
        return const EmployeeDashboard();

      case NavDestinationKey.attendanceHistory:
      case NavDestinationKey.attendanceCalendar:
        return const AttendanceHistoryScreen();

      case NavDestinationKey.clockIn:
        return const CameraCaptureScreen(actionType: 'clockIn');

      case NavDestinationKey.clockOut:
        return const CameraCaptureScreen(actionType: 'clockOut');

      case NavDestinationKey.leave:
      case NavDestinationKey.leaveHistory:
      case NavDestinationKey.leaveManagement:
        return const LeaveManagementScreen();

      // TL & Approvals
      case NavDestinationKey.pendingApprovals:
      case NavDestinationKey.teamAttendance:
      case NavDestinationKey.teamMembers:
        return RouteGuard.protect(
          context: context,
          user: user,
          requiredPermission: AppPermission.viewTeamAttendance,
          child: const ManagerDashboard(),
        );

      case NavDestinationKey.leaveApprovals:
        return RouteGuard.protect(
          context: context,
          user: user,
          requiredPermission: AppPermission.approveTeamLeaves,
          child: const LeaveApprovalScreen(),
        );

      // HR
      case NavDestinationKey.employees:
        return RouteGuard.protect(
          context: context,
          user: user,
          requiredPermission: AppPermission.viewAllEmployees,
          child: const AllEmployeesScreen(),
        );

      case NavDestinationKey.companyAttendance:
      case NavDestinationKey.teams:
      case NavDestinationKey.departments:
      case NavDestinationKey.holidays:
      case NavDestinationKey.shifts:
        return RouteGuard.protect(
          context: context,
          user: user,
          requiredPermission: AppPermission.viewCompanyAttendance,
          child: const HrDashboard(),
        );

      case NavDestinationKey.attendanceReports:
      case NavDestinationKey.dailyReport:
      case NavDestinationKey.monthlyReport:
      case NavDestinationKey.report30Day:
        return RouteGuard.protect(
          context: context,
          user: user,
          requiredPermission: AppPermission.generateAttendanceReports,
          child: const ReportGeneratorScreen(),
        );

      case NavDestinationKey.projectReports:
        return const ProjectReportsScreen(isEmbedded: true);

      case NavDestinationKey.projectsManagement:
        return const ProjectsManagementScreen(isEmbedded: true);

      // Admin
      case NavDestinationKey.users:
      case NavDestinationKey.managersTLs:
      case NavDestinationKey.hrManagement:
      case NavDestinationKey.officeLocations:
      case NavDestinationKey.geofencing:
        return RouteGuard.protect(
          context: context,
          user: user,
          requiredPermission: AppPermission.manageUsers,
          child: const AdminPanelScreen(),
        );

      case NavDestinationKey.systemSettings:
      case NavDestinationKey.settings:
        return const SystemSettingsScreen(isEmbedded: true);

      case NavDestinationKey.attendancePolicies:
        return RouteGuard.protect(
          context: context,
          user: user,
          requiredPermission: AppPermission.manageAttendancePolicies,
          child: const PolicySettingsScreen(),
        );

      case NavDestinationKey.auditLogs:
        return RouteGuard.protect(
          context: context,
          user: user,
          requiredPermission: AppPermission.viewAuditLogs,
          child: const AuditLogsScreen(),
        );

      case NavDestinationKey.notifications:
      case NavDestinationKey.myProfile:
      default:
        // Default to role primary dashboard
        switch (role) {
          case AppRole.employee:
            return const EmployeeDashboard();
          case AppRole.tl:
            return const ManagerDashboard();
          case AppRole.hr:
            return const HrDashboard();
          case AppRole.admin:
            return const AdminPanelScreen();
        }
    }
  }

  void _handleMenuSelection(NavMenuItem item) {
    if (item.destination == NavDestinationKey.logout) {
      return;
    }

    if (item.destination == NavDestinationKey.aiAssistant) {
      AIVoiceAssistantSheet.show(context);
      return;
    }

    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final role = user != null
        ? AppRole.fromString(user.role.name)
        : AppRole.employee;

    // Verify permission before switching destination
    if (item.requiredPermission != null &&
        !PermissionService.hasPermission(role, item.requiredPermission!)) {
      showDialog(
        context: context,
        builder: (_) => AccessDeniedScreen(
          userRole: role,
          requiredPermission: item.requiredPermission,
        ),
      );
      return;
    }

    setState(() {
      _activeDestination = item.destination;
    });
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'FCM Alerts & Updates',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildNotifTile(
              icon: Icons.access_time_rounded,
              title: 'Clock-in Reminder',
              body: 'Don’t forget to clock in before 09:45 AM to avoid late status.',
              time: '10m ago',
              color: AppTheme.primary,
            ),
            _buildNotifTile(
              icon: Icons.verified_user_rounded,
              title: 'Attendance Approval',
              body: 'Your attendance for yesterday has been verified and approved.',
              time: '2h ago',
              color: AppTheme.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifTile({
    required IconData icon,
    required String title,
    required String body,
    required String time,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            radius: 18,
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  void _showRoleSwitcherDialog() {
    final users = FirestoreService().getAllUsers();
    final auth = context.read<AuthProvider>();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Switch Active User & Role',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...users.map((u) {
                final isCurrent = auth.currentUser?.userId == u.userId;
                final role = AppRole.fromString(u.role.name);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: isCurrent
                        ? role.badgeColor.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: role.badgeColor.withValues(alpha: 0.2),
                        child: Icon(
                          role.icon,
                          color: role.badgeColor,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        u.name,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${role.displayName} • ${u.department}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: isCurrent
                          ? const Icon(
                              Icons.check_circle,
                              color: AppTheme.success,
                            )
                          : OutlinedButton(
                              onPressed: () {
                                auth.selectUser(u);
                                Navigator.pop(ctx);
                                setState(() {
                                  _activeDestination =
                                      NavDestinationKey.dashboard;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                              ),
                              child: const Text('Switch'),
                            ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
