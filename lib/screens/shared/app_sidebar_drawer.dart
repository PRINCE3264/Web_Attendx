import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/leave_provider.dart';
import '../employee/break_tracking_sheet.dart';
import '../employee/leave_management_screen.dart';
import '../employee/attendance_history_screen.dart';
import '../employee/employee_dashboard.dart';
import '../employee/submit_project_report_sheet.dart';
import 'project_reports_screen.dart';
import '../manager/manager_dashboard.dart';
import '../manager/leave_approval_screen.dart';
import '../manager/tl_team_attendance_screen.dart';
import '../hr/hr_dashboard.dart';
import '../hr/report_generator_screen.dart';
import '../hr/all_employees_screen.dart';
import '../hr/all_attendance_screen.dart';
import '../hr/add_employee_sheet.dart';
import '../hr/create_announcement_sheet.dart';
import '../admin/policy_settings_screen.dart';
import '../admin/audit_logs_screen.dart';
import '../admin/admin_panel_screen.dart';
import '../admin/projects_management_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'system_settings_screen.dart';
import 'ai_voice_assistant_sheet.dart';
import '../auth/login_screen.dart';

class AppSidebarDrawer extends StatefulWidget {
  final int currentIndex;
  final Function(int) onSelectTab;
  final Function(Widget screen, String title)? onSelectScreen;

  const AppSidebarDrawer({
    super.key,
    required this.currentIndex,
    required this.onSelectTab,
    this.onSelectScreen,
  });

  @override
  State<AppSidebarDrawer> createState() => _AppSidebarDrawerState();
}

class _AppSidebarDrawerState extends State<AppSidebarDrawer> {
  void _navigateToScreen(Widget screen, String title, {int? defaultTabIndex}) {
    Navigator.pop(context);
    if (defaultTabIndex != null) {
      widget.onSelectTab(defaultTabIndex);
    } else if (widget.onSelectScreen != null) {
      widget.onSelectScreen!(screen, title);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final attendance = context.watch<AttendanceProvider>();
    final leaveProv = context.watch<LeaveProvider>();
    final user = auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pendingApprovals = attendance.getPendingApprovals().length;
    final pendingLeaves = leaveProv.getPendingLeaves().length;
    final todayAttendance = attendance.getTodayAttendance(user?.userId);

    final String initial = user != null && user.name.isNotEmpty
        ? user.name.trim()[0].toUpperCase()
        : 'U';

    final String roleName = user != null ? user.role.name.toUpperCase() : 'USER';
    final String displayName = user != null ? user.name.toUpperCase() : 'ATTENDX USER';
    final String department = user != null ? user.department : 'Enterprise';

    return Drawer(
      backgroundColor: isDark ? AppTheme.cardDark : Colors.white,
      elevation: 16,
      child: Column(
        children: [
          // 1. Curved Blue Ripple Header
          _buildCustomHeader(context, user, initial, displayName, roleName, department),

          // 2. Navigation Menu Items List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // 1. Employee Navigation Items
                if (user?.role == UserRole.employee) ...[
                  _buildNavItem(
                    icon: Icons.grid_view_rounded,
                    title: 'Clock & Today',
                    isSelected: widget.currentIndex == 0,
                    onTap: () => _navigateToScreen(const SizedBox(), 'Clock & Today', defaultTabIndex: 0),
                  ),
                  _buildNavItem(
                    icon: Icons.calendar_month_rounded,
                    title: 'My Attendance',
                    isSelected: widget.currentIndex == 1,
                    onTap: () => _navigateToScreen(const AttendanceHistoryScreen(), 'My Attendance', defaultTabIndex: 1),
                  ),
                  _buildNavItem(
                    icon: Icons.coffee_rounded,
                    title: 'Break Tracker',
                    onTap: () {
                      Navigator.pop(context);
                      if (todayAttendance != null) {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                          ),
                          builder: (_) => BreakTrackingSheet(attendance: todayAttendance),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please clock in before starting a break.')),
                        );
                      }
                    },
                  ),
                  _buildNavItem(
                    icon: Icons.beach_access_rounded,
                    title: 'Leave Management',
                    isSelected: widget.currentIndex == 2,
                    badgeText: pendingLeaves > 0 ? '$pendingLeaves' : null,
                    badgeColor: const Color(0xFF2563EB),
                    onTap: () => _navigateToScreen(const LeaveManagementScreen(), 'Leave Management', defaultTabIndex: 2),
                  ),
                  _buildNavItem(
                    icon: Icons.assignment_add,
                    title: 'Daily Project Update',
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const SubmitProjectReportSheet(),
                      );
                    },
                  ),
                  _buildNavItem(
                    icon: Icons.folder_special_outlined,
                    title: 'Project Work Reports',
                    onTap: () => _navigateToScreen(const ProjectReportsScreen(isEmbedded: true), 'Project Work Reports'),
                  ),
                  _buildNavItem(
                    icon: Icons.folder_special_rounded,
                    title: 'My Projects',
                    onTap: () => _navigateToScreen(const ProjectsManagementScreen(isEmbedded: true), 'My Projects'),
                  ),
                  _buildNavItem(
                    icon: Icons.settings_outlined,
                    title: 'System Settings',
                    onTap: () => _navigateToScreen(const SystemSettingsScreen(isEmbedded: true), 'System Settings'),
                  ),
                ],

                // 2. TL (Team Lead) Navigation Items
                if (user?.role == UserRole.manager) ...[
                  _buildNavItem(
                    icon: Icons.touch_app_rounded,
                    title: 'My Clock-In & Self',
                    isSelected: widget.currentIndex == 0,
                    onTap: () => _navigateToScreen(const EmployeeDashboard(), 'My Clock-In & Self', defaultTabIndex: 0),
                  ),
                  _buildNavItem(
                    icon: Icons.grid_view_rounded,
                    title: 'Approvals & Team',
                    isSelected: widget.currentIndex == 1,
                    badgeText: pendingApprovals > 0 ? '$pendingApprovals' : null,
                    badgeColor: AppTheme.warning,
                    onTap: () => _navigateToScreen(const ManagerDashboard(), 'Approvals & Team', defaultTabIndex: 1),
                  ),
                  _buildNavItem(
                    icon: Icons.beach_access_rounded,
                    title: 'Leave Requests',
                    isSelected: widget.currentIndex == 2,
                    badgeText: pendingLeaves > 0 ? '$pendingLeaves' : null,
                    badgeColor: const Color(0xFF2563EB),
                    onTap: () => _navigateToScreen(const LeaveApprovalScreen(), 'Leave Requests', defaultTabIndex: 2),
                  ),
                  _buildNavItem(
                    icon: Icons.how_to_reg_rounded,
                    title: 'Team Attendance',
                    onTap: () => _navigateToScreen(const TlTeamAttendanceScreen(), 'Team Attendance'),
                  ),
                  _buildNavItem(
                    icon: Icons.groups_rounded,
                    title: 'Team Roster',
                    isSelected: widget.currentIndex == 3,
                    onTap: () => _navigateToScreen(const AllEmployeesScreen(), 'Team Roster', defaultTabIndex: 3),
                  ),
                  _buildNavItem(
                    icon: Icons.assignment_turned_in_outlined,
                    title: 'Team Work Report',
                    onTap: () => _navigateToScreen(const ProjectReportsScreen(isEmbedded: true), 'Team Work Report'),
                  ),
                  _buildNavItem(
                    icon: Icons.folder_special_rounded,
                    title: 'My Projects',
                    onTap: () => _navigateToScreen(const ProjectsManagementScreen(isEmbedded: true), 'My Projects'),
                  ),
                  _buildNavItem(
                    icon: Icons.settings_outlined,
                    title: 'System Settings',
                    onTap: () => _navigateToScreen(const SystemSettingsScreen(isEmbedded: true), 'System Settings'),
                  ),
                ],

                // 3. Admin Navigation Items
                if (user?.role == UserRole.admin) ...[
                  _buildNavItem(
                    icon: Icons.home_rounded,
                    title: 'Dashboard',
                    isSelected: widget.currentIndex == 0,
                    onTap: () => _navigateToScreen(const AdminPanelScreen(), 'Admin Dashboard', defaultTabIndex: 0),
                  ),
                  _buildNavItem(
                    icon: Icons.folder_special_rounded,
                    title: 'Project Management',
                    onTap: () => _navigateToScreen(const ProjectsManagementScreen(isEmbedded: true), 'Project Master Directory'),
                  ),
                  _buildExpandableSection(
                    title: 'Employee Management',
                    icon: Icons.badge_outlined,
                    children: [
                      _buildSubItem('All Employees', onTap: () => _navigateToScreen(const AllEmployeesScreen(initialRoleFilter: 'employee'), 'Employee Directory')),
                      _buildSubItem('Add Employee', onTap: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                          builder: (_) => const AddEmployeeSheet(initialRole: UserRole.employee),
                        );
                      }),
                    ],
                  ),
                  _buildExpandableSection(
                    title: 'TL Management',
                    icon: Icons.supervisor_account_outlined,
                    children: [
                      _buildSubItem('All Team Leads (TL)', onTap: () => _navigateToScreen(const AllEmployeesScreen(initialRoleFilter: 'manager'), 'Team Lead Directory')),
                      _buildSubItem('Add TL', onTap: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                          builder: (_) => const AddEmployeeSheet(initialRole: UserRole.manager),
                        );
                      }),
                    ],
                  ),
                  _buildExpandableSection(
                    title: 'HR Management',
                    icon: Icons.admin_panel_settings_outlined,
                    children: [
                      _buildSubItem('All HR Personnel', onTap: () => _navigateToScreen(const AllEmployeesScreen(initialRoleFilter: 'hr'), 'HR Directory')),
                      _buildSubItem('Add HR', onTap: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                          builder: (_) => const AddEmployeeSheet(initialRole: UserRole.hr),
                        );
                      }),
                    ],
                  ),
                  _buildExpandableSection(
                    title: 'Account Status',
                    icon: Icons.manage_accounts_outlined,
                    children: [
                      _buildSubItem('All Users Directory', onTap: () => _navigateToScreen(const AllEmployeesScreen(), 'All Users Directory')),
                      _buildSubItem('Suspended / Deactivated', onTap: () => _navigateToScreen(const AllEmployeesScreen(initialStatusFilter: 'inactive'), 'Suspended Accounts')),
                    ],
                  ),
                  _buildExpandableSection(
                    title: 'Attendance',
                    icon: Icons.calendar_month_outlined,
                    children: [
                      _buildSubItem('All Attendance', onTap: () => _navigateToScreen(const AllAttendanceScreen(), 'Company Attendance Feed')),
                      _buildSubItem('Daily Attendance', onTap: () => _navigateToScreen(const HrDashboard(), 'Daily Overview')),
                      _buildSubItem('Monthly Attendance', onTap: () => _navigateToScreen(const AttendanceHistoryScreen(isEmbedded: true), 'Monthly Attendance Calendar')),
                      _buildSubItem('Employee Attendance', onTap: () => _navigateToScreen(const AllEmployeesScreen(), 'User Directory')),
                      _buildSubItem('Attendance Reports', onTap: () => _navigateToScreen(const ReportGeneratorScreen(), 'Audit Reports', defaultTabIndex: 3)),
                    ],
                  ),
                  _buildExpandableSection(
                    title: 'Leave Management',
                    icon: Icons.beach_access_outlined,
                    children: [
                      _buildSubItem('All Requests', onTap: () => _navigateToScreen(const LeaveApprovalScreen(initialFilter: 'all'), 'Leave Requests')),
                      _buildSubItem('Pending', onTap: () => _navigateToScreen(const LeaveApprovalScreen(initialFilter: 'pending'), 'Leave Requests')),
                      _buildSubItem('Approved', onTap: () => _navigateToScreen(const LeaveApprovalScreen(initialFilter: 'approved'), 'Leave Requests')),
                      _buildSubItem('Rejected', onTap: () => _navigateToScreen(const LeaveApprovalScreen(initialFilter: 'rejected'), 'Leave Requests')),
                    ],
                  ),
                  _buildExpandableSection(
                    title: 'Announcements',
                    icon: Icons.campaign_outlined,
                    children: [
                      _buildSubItem('Create', onTap: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                          builder: (_) => const CreateAnnouncementSheet(),
                        );
                      }),
                      _buildSubItem('Holiday', onTap: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                          builder: (_) => const CreateAnnouncementSheet(),
                        );
                      }),
                      _buildSubItem('Send to All', onTap: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                          builder: (_) => const CreateAnnouncementSheet(),
                        );
                      }),
                      _buildSubItem('History', onTap: () => _navigateToScreen(const NotificationsScreen(), 'Notifications')),
                    ],
                  ),
                  _buildNavItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    onTap: () => _navigateToScreen(const NotificationsScreen(), 'Notifications'),
                  ),
                  _buildExpandableSection(
                    title: 'Reports',
                    icon: Icons.bar_chart_outlined,
                    children: [
                      _buildSubItem('Daily Project Work Reports', onTap: () => _navigateToScreen(const ProjectReportsScreen(isEmbedded: true), 'Daily Project Work Reports')),
                      _buildSubItem('Monthly Report', onTap: () => _navigateToScreen(const ReportGeneratorScreen(initialReportType: 'monthly'), 'Monthly Reports', defaultTabIndex: 3)),
                      _buildSubItem('Employee Report', onTap: () => _navigateToScreen(const ReportGeneratorScreen(initialReportType: 'employee'), 'Employee Reports', defaultTabIndex: 3)),
                      _buildSubItem('Export Excel/PDF', onTap: () => _navigateToScreen(const ReportGeneratorScreen(initialReportType: 'export'), 'Data Export Center', defaultTabIndex: 3)),
                    ],
                  ),
                  _buildExpandableSection(
                    title: 'System Settings',
                    icon: Icons.settings_outlined,
                    children: [
                      _buildSubItem('Roles & Permissions', onTap: () => _navigateToScreen(const PolicySettingsScreen(isEmbedded: true), 'Roles & Permissions', defaultTabIndex: 1)),
                      _buildSubItem('Departments', onTap: () => _navigateToScreen(const AllEmployeesScreen(isEmbedded: true), 'Department Directory')),
                      _buildSubItem('Attendance Rules', onTap: () => _navigateToScreen(const PolicySettingsScreen(isEmbedded: true), 'Attendance Rules', defaultTabIndex: 1)),
                      _buildSubItem('App Settings', onTap: () => _navigateToScreen(const SystemSettingsScreen(isEmbedded: true), 'App & System Settings')),
                      _buildSubItem('Audit Logs', onTap: () => _navigateToScreen(const AuditLogsScreen(isEmbedded: true), 'Audit Logs', defaultTabIndex: 2)),
                    ],
                  ),
                ],

                // 4. HR Navigation Items
                if (user?.role == UserRole.hr) ...[
                  _buildNavItem(
                    icon: Icons.home_rounded,
                    title: 'Dashboard',
                    isSelected: widget.currentIndex == 0,
                    onTap: () => _navigateToScreen(const HrDashboard(), 'HR Overview', defaultTabIndex: 0),
                  ),
                  _buildNavItem(
                    icon: Icons.folder_special_rounded,
                    title: 'Company Projects',
                    onTap: () => _navigateToScreen(const ProjectsManagementScreen(isEmbedded: true), 'Company Projects'),
                  ),
                  _buildExpandableSection(
                    title: 'Employees',
                    icon: Icons.people_alt_outlined,
                    children: [
                      _buildSubItem('All Employees', onTap: () => _navigateToScreen(const AllEmployeesScreen(), 'Directory', defaultTabIndex: 1)),
                      _buildSubItem('Add Employee', onTap: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                          builder: (_) => const AddEmployeeSheet(),
                        );
                      }),
                      _buildSubItem('Active / Inactive', onTap: () => _navigateToScreen(const AllEmployeesScreen(initialStatusFilter: 'active'), 'Directory')),
                    ],
                  ),
                  _buildExpandableSection(
                    title: 'Attendance',
                    icon: Icons.calendar_month_outlined,
                    children: [
                      _buildSubItem('All Attendance', onTap: () => _navigateToScreen(const AllAttendanceScreen(), 'Company Attendance Feed')),
                      _buildSubItem('Daily Attendance', onTap: () => _navigateToScreen(const HrDashboard(), 'Daily Overview', defaultTabIndex: 0)),
                      _buildSubItem('Monthly Attendance', onTap: () => _navigateToScreen(const AttendanceHistoryScreen(isEmbedded: true), 'Monthly Attendance Calendar')),
                      _buildSubItem('Attendance Report', onTap: () => _navigateToScreen(const ReportGeneratorScreen(), 'Audit Reports', defaultTabIndex: 2)),
                    ],
                  ),
                  _buildExpandableSection(
                    title: 'Leave',
                    icon: Icons.beach_access_outlined,
                    children: [
                      _buildSubItem('Leave Requests', onTap: () => _navigateToScreen(const LeaveApprovalScreen(initialFilter: 'all'), 'Leave Requests')),
                      _buildSubItem('Approved', onTap: () => _navigateToScreen(const LeaveApprovalScreen(initialFilter: 'approved'), 'Leave Requests')),
                      _buildSubItem('Rejected', onTap: () => _navigateToScreen(const LeaveApprovalScreen(initialFilter: 'rejected'), 'Leave Requests')),
                    ],
                  ),
                  _buildExpandableSection(
                    title: 'Announcements',
                    icon: Icons.campaign_outlined,
                    children: [
                      _buildSubItem('Create Announcement', onTap: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                          builder: (_) => const CreateAnnouncementSheet(),
                        );
                      }),
                      _buildSubItem('Holiday', onTap: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                          builder: (_) => const CreateAnnouncementSheet(),
                        );
                      }),
                      _buildSubItem('History', onTap: () => _navigateToScreen(const NotificationsScreen(), 'Notifications')),
                    ],
                  ),
                  _buildNavItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    onTap: () => _navigateToScreen(const NotificationsScreen(), 'Notifications'),
                  ),
                  _buildExpandableSection(
                    title: 'Reports',
                    icon: Icons.bar_chart_outlined,
                    children: [
                      _buildSubItem('Daily Project Work Reports', onTap: () => _navigateToScreen(const ProjectReportsScreen(isEmbedded: true), 'Daily Project Work Reports')),
                      _buildSubItem('Monthly Report', onTap: () => _navigateToScreen(const ReportGeneratorScreen(initialReportType: 'monthly'), 'Monthly Reports', defaultTabIndex: 2)),
                      _buildSubItem('Employee Report', onTap: () => _navigateToScreen(const ReportGeneratorScreen(initialReportType: 'employee'), 'Employee Reports', defaultTabIndex: 2)),
                      _buildSubItem('Export Excel/PDF', onTap: () => _navigateToScreen(const ReportGeneratorScreen(initialReportType: 'export'), 'Data Export Center', defaultTabIndex: 2)),
                    ],
                  ),
                  _buildNavItem(
                    icon: Icons.settings_outlined,
                    title: 'System Settings',
                    onTap: () => _navigateToScreen(const SystemSettingsScreen(isEmbedded: true), 'System Settings'),
                  ),
                ],

                // Common AI Chatbot & Profile Navigation Items
                _buildNavItem(
                  icon: Icons.smart_toy_rounded,
                  title: 'AI Chatbot',
                  badgeText: 'AI',
                  badgeColor: const Color(0xFF2563EB),
                  onTap: () {
                    Navigator.pop(context);
                    AIVoiceAssistantSheet.show(context);
                  },
                ),
                _buildNavItem(
                  icon: Icons.person_outline_rounded,
                  title: 'My Profile',
                  isSelected: (widget.currentIndex == 3 && user?.role == UserRole.employee) ||
                      (widget.currentIndex == 4 && (user?.role == UserRole.admin || user?.role == UserRole.manager)),
                  onTap: () {
                    final role = user?.role;
                    int profileIndex = 3;
                    if (role == UserRole.admin || role == UserRole.manager) profileIndex = 4;
                    _navigateToScreen(const ProfileScreen(), 'Profile', defaultTabIndex: profileIndex);
                  },
                ),
              ],
            ),
          ),

          // 3. Logout Item at Bottom
          const Divider(height: 1, thickness: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final nav = Navigator.of(context);
                await auth.logout();
                nav.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 22),
                    const SizedBox(width: 14),
                    Text(
                      'Logout',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFEF4444),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomHeader(
    BuildContext context,
    UserModel? user,
    String initial,
    String displayName,
    String roleName,
    String department,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2563EB),
            Color(0xFF3B82F6),
            Color(0xFF60A5FA),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.elliptical(280, 48),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x332563EB),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Ripple Circles
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: 20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),

          // Main Header Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar with Avatar and Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // White Circle Avatar
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: GoogleFonts.outfit(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ),

                  // Close Button
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // User Info & Enterprise Pill Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$roleName • $department',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Translucent Badge Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Envision Beyond',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    bool isSelected = false,
    String? badgeText,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedBg = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFEFF6FF); // Light blue tint like reference

    final selectedColor = const Color(0xFF2563EB); // Primary Blue
    final unselectedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF4B5563);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isSelected ? selectedBg : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Icon(
          icon,
          size: 22,
          color: isSelected ? selectedColor : unselectedColor,
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? selectedColor : (isDark ? Colors.white : const Color(0xFF1F2937)),
          ),
        ),
        trailing: badgeText != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor ?? const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        onTap: onTap,
      ),
    ),
  );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF4B5563);
    
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        leading: Icon(icon, size: 22, color: unselectedColor),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        childrenPadding: const EdgeInsets.only(left: 36, bottom: 8),
        children: children,
      ),
    );
  }

  Widget _buildSubItem(String title, {required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isDark ? Colors.white54 : Colors.black38,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
