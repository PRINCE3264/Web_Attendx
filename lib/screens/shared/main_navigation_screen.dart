import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/leave_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../employee/employee_dashboard.dart';
import '../employee/attendance_history_screen.dart';
import '../employee/leave_management_screen.dart';
import '../manager/manager_dashboard.dart';
import '../manager/leave_approval_screen.dart';
import '../hr/hr_dashboard.dart';
import '../hr/report_generator_screen.dart';
import '../hr/all_employees_screen.dart';
import '../admin/admin_panel_screen.dart';
import '../admin/policy_settings_screen.dart';
import '../admin/audit_logs_screen.dart';
import '../auth/login_screen.dart';
import 'app_sidebar_drawer.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  UserRole? _previousRole;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _updateTabController(int length) {
    if (_tabController.length != length) {
      _tabController.dispose();
      _tabController = TabController(length: length, vsync: this);
      _tabController.addListener(() {
        if (!_tabController.indexIsChanging) {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showRoleSwitcherDialog() {
    final auth = context.read<AuthProvider>();
    final users = FirestoreService().getAllUsers();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Switch Active Role / User',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            ...users.map((u) {
              final isCurrent = auth.currentUser?.userId == u.userId;
              Color roleColor;
              switch (u.role) {
                case UserRole.admin:
                  roleColor = const Color(0xFFEF4444);
                  break;
                case UserRole.manager:
                  roleColor = AppTheme.secondary;
                  break;
                case UserRole.hr:
                  roleColor = AppTheme.accent;
                  break;
                case UserRole.employee:
                  roleColor = AppTheme.primary;
                  break;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                child: Material(
                  color: isCurrent ? roleColor.withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: CircleAvatar(
                      backgroundColor: roleColor.withValues(alpha: 0.2),
                      child: Icon(
                        u.role == UserRole.admin
                            ? Icons.admin_panel_settings
                            : (u.role == UserRole.manager
                                ? Icons.supervisor_account
                                : (u.role == UserRole.hr ? Icons.badge : Icons.person)),
                        color: roleColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      u.name,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text('${u.role.name} • ${u.department}', style: const TextStyle(fontSize: 12)),
                    trailing: isCurrent
                        ? const Icon(Icons.check_circle, color: AppTheme.success)
                        : OutlinedButton(
                            onPressed: () {
                              auth.selectUser(u);
                              Navigator.pop(ctx);
                              _tabController.animateTo(0);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    );
  }

  void _showNotificationHistory() {
    final notifications = NotificationService().history;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'FCM Notifications & Alerts',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: notifications.isEmpty
                  ? const Center(child: Text('No notifications received yet.'))
                  : ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notif = notifications[index];
                        return ListTile(
                          leading: const Icon(Icons.notifications_active, color: AppTheme.primary),
                          title: Text(notif.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(notif.message, style: const TextStyle(fontSize: 12)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final attendance = context.watch<AttendanceProvider>();
    final leaveProv = context.watch<LeaveProvider>();
    final user = auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const LoginScreen();
    }

    final role = user.role;

    List<Widget> screens = [];
    List<Tab> tabItems = [];
    List<BottomNavigationBarItem> navItems = [];

    final pendingApprovalsCount = attendance.getPendingApprovals().length;
    final pendingLeavesCount = leaveProv.getPendingLeaves().length;

    if (role == UserRole.employee) {
      screens = [
        const EmployeeDashboard(),
        const AttendanceHistoryScreen(),
        const LeaveManagementScreen(),
      ];
      tabItems = [
        const Tab(text: 'Today Clock', icon: Icon(Icons.timer_outlined, size: 18)),
        const Tab(text: 'My History', icon: Icon(Icons.calendar_month_outlined, size: 18)),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.beach_access_outlined, size: 18),
              const SizedBox(width: 6),
              const Text('Leaves'),
              if (pendingLeavesCount > 0) ...[
                const SizedBox(width: 4),
                _buildBadgeCircle('$pendingLeavesCount', const Color(0xFF8B5CF6)),
              ],
            ],
          ),
        ),
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Clock & Today'),
        BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'My History'),
        BottomNavigationBarItem(icon: Icon(Icons.beach_access_outlined), activeIcon: Icon(Icons.beach_access), label: 'Leaves'),
      ];
    } else if (role == UserRole.manager) {
      screens = [
        const ManagerDashboard(),
        const LeaveApprovalScreen(),
        const AllEmployeesScreen(),
      ];
      tabItems = [
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.approval_outlined, size: 18),
              const SizedBox(width: 6),
              const Text('Approvals'),
              if (pendingApprovalsCount > 0) ...[
                const SizedBox(width: 4),
                _buildBadgeCircle('$pendingApprovalsCount', AppTheme.warning),
              ],
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.beach_access_outlined, size: 18),
              const SizedBox(width: 6),
              const Text('Leave Req'),
              if (pendingLeavesCount > 0) ...[
                const SizedBox(width: 4),
                _buildBadgeCircle('$pendingLeavesCount', const Color(0xFF8B5CF6)),
              ],
            ],
          ),
        ),
        const Tab(text: 'Team Roster', icon: Icon(Icons.groups_outlined, size: 18)),
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.approval_outlined), activeIcon: Icon(Icons.approval), label: 'Approvals & Team'),
        BottomNavigationBarItem(icon: Icon(Icons.beach_access_outlined), activeIcon: Icon(Icons.beach_access), label: 'Leave Requests'),
        BottomNavigationBarItem(icon: Icon(Icons.groups_outlined), activeIcon: Icon(Icons.groups), label: 'Team Roster'),
      ];
    } else if (role == UserRole.admin) {
      screens = [
        const AdminPanelScreen(),
        const PolicySettingsScreen(),
        const AuditLogsScreen(),
        const ReportGeneratorScreen(),
      ];
      tabItems = const [
        Tab(text: 'Workforce', icon: Icon(Icons.manage_accounts_outlined, size: 18)),
        Tab(text: 'Policy', icon: Icon(Icons.tune_outlined, size: 18)),
        Tab(text: 'Audit Trail', icon: Icon(Icons.security_outlined, size: 18)),
        Tab(text: 'Reports', icon: Icon(Icons.assessment_outlined, size: 18)),
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.manage_accounts_outlined), activeIcon: Icon(Icons.manage_accounts), label: 'Workforce'),
        BottomNavigationBarItem(icon: Icon(Icons.tune_outlined), activeIcon: Icon(Icons.tune), label: 'Policy Engine'),
        BottomNavigationBarItem(icon: Icon(Icons.security_outlined), activeIcon: Icon(Icons.security), label: 'Audit Trail'),
        BottomNavigationBarItem(icon: Icon(Icons.assessment_outlined), activeIcon: Icon(Icons.assessment), label: 'Reports'),
      ];
    } else {
      // HR
      screens = [
        const HrDashboard(),
        const AllEmployeesScreen(),
        const ReportGeneratorScreen(),
      ];
      tabItems = const [
        Tab(text: 'HR Overview', icon: Icon(Icons.analytics_outlined, size: 18)),
        Tab(text: 'Directory', icon: Icon(Icons.people_outline, size: 18)),
        Tab(text: 'Audit Reports', icon: Icon(Icons.assessment_outlined, size: 18)),
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: 'HR Overview'),
        BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Directory'),
        BottomNavigationBarItem(icon: Icon(Icons.assessment_outlined), activeIcon: Icon(Icons.assessment), label: 'Audit Reports'),
      ];
    }

    if (_previousRole != role) {
      _previousRole = role;
      _updateTabController(screens.length);
    }

    Color roleColor;
    switch (role) {
      case UserRole.admin:
        roleColor = const Color(0xFFEF4444);
        break;
      case UserRole.manager:
        roleColor = AppTheme.secondary;
        break;
      case UserRole.hr:
        roleColor = AppTheme.accent;
        break;
      case UserRole.employee:
        roleColor = AppTheme.primary;
        break;
    }

    return Scaffold(
      drawer: AppSidebarDrawer(
        currentIndex: _tabController.index,
        onSelectTab: (index) {
          _tabController.animateTo(index.clamp(0, screens.length - 1));
          setState(() {});
        },
      ),
      appBar: AppBar(
        titleSpacing: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, size: 26),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            tooltip: 'Open Navigation Drawer',
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: roleColor.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    role == UserRole.admin
                        ? Icons.admin_panel_settings
                        : (role == UserRole.manager
                            ? Icons.supervisor_account
                            : (role == UserRole.hr ? Icons.badge : Icons.person)),
                    size: 14,
                    color: roleColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    role.name,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: roleColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _showRoleSwitcherDialog,
            icon: const Icon(Icons.swap_horiz, size: 16),
            label: const Text('Switch Role', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 22),
            onPressed: _showNotificationHistory,
            tooltip: 'FCM Alerts',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () {
              FirestoreService().resetToDefaultSeed();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Demo attendance, leaves, and audit records refreshed.')),
              );
            },
            tooltip: 'Reset Demo Data',
          ),
        ],
        // Top Segmented Pill TabBar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            height: 52,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: screens.length > 3,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: isDark ? roleColor.withValues(alpha: 0.25) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: roleColor.withValues(alpha: 0.6),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: roleColor,
              unselectedLabelColor: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
              labelStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500),
              tabs: tabItems,
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabController.index.clamp(0, navItems.length - 1),
        onTap: (index) {
          _tabController.animateTo(index);
          setState(() {});
        },
        selectedItemColor: roleColor,
        unselectedItemColor: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
        type: BottomNavigationBarType.fixed,
        items: navItems,
      ),
    );
  }

  static Widget _buildBadgeCircle(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
