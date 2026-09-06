import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../config/app_theme.dart';
import 'app_sidebar_drawer.dart';
import 'notifications_screen.dart';
import 'ai_voice_assistant_sheet.dart';
import 'profile_screen.dart';
import '../employee/employee_dashboard.dart';
import '../employee/attendance_history_screen.dart';
import '../employee/leave_management_screen.dart';
import '../manager/manager_dashboard.dart';

import '../manager/leave_approval_screen.dart';
import '../hr/hr_dashboard.dart';
import '../hr/all_employees_screen.dart';
import '../hr/report_generator_screen.dart';
import '../admin/admin_panel_screen.dart';
import '../admin/policy_settings_screen.dart';
import '../admin/audit_logs_screen.dart';
import '../auth/login_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  UserRole? _previousRole;
  Widget? _customScreen;
  String? _customScreenTitle;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final notifProvider = context.watch<UserNotificationProvider>();
    final user = auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const LoginScreen();
    }

    final role = user.role;

    List<Widget> screens = [];
    List<BottomNavigationBarItem> navItems = [];

    if (role == UserRole.employee) {
      screens = [
        const EmployeeDashboard(),
        const AttendanceHistoryScreen(),
        const LeaveManagementScreen(),
        const ProfileScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Clock & Today'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), activeIcon: Icon(Icons.calendar_month), label: 'My Attendance'),
        BottomNavigationBarItem(icon: Icon(Icons.beach_access_outlined), activeIcon: Icon(Icons.beach_access), label: 'Leaves'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
      ];
    } else if (role == UserRole.manager) {
      screens = [
        const ManagerDashboard(),
        const LeaveApprovalScreen(),
        const AllEmployeesScreen(),
        const ProfileScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.approval_outlined), activeIcon: Icon(Icons.approval), label: 'Approvals & Team'),
        BottomNavigationBarItem(icon: Icon(Icons.beach_access_outlined), activeIcon: Icon(Icons.beach_access), label: 'Leave Requests'),
        BottomNavigationBarItem(icon: Icon(Icons.groups_outlined), activeIcon: Icon(Icons.groups), label: 'Team Roster'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
      ];
    } else if (role == UserRole.admin) {
      screens = [
        const AdminPanelScreen(),
        const PolicySettingsScreen(),
        const AuditLogsScreen(),
        const ReportGeneratorScreen(),
        const ProfileScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.manage_accounts_outlined), activeIcon: Icon(Icons.manage_accounts), label: 'Workforce'),
        BottomNavigationBarItem(icon: Icon(Icons.tune_outlined), activeIcon: Icon(Icons.tune), label: 'Policy Engine'),
        BottomNavigationBarItem(icon: Icon(Icons.security_outlined), activeIcon: Icon(Icons.security), label: 'Audit Trail'),
        BottomNavigationBarItem(icon: Icon(Icons.assessment_outlined), activeIcon: Icon(Icons.assessment), label: 'Reports'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
      ];
    } else {
      // HR / Management
      screens = [
        const HrDashboard(),
        const AllEmployeesScreen(),
        const ReportGeneratorScreen(),
        const ProfileScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: 'HR Overview'),
        BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Directory'),
        BottomNavigationBarItem(icon: Icon(Icons.assessment_outlined), activeIcon: Icon(Icons.assessment), label: 'Audit Reports'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
      ];
    }

    if (_previousRole != role) {
      _previousRole = role;
      _updateTabController(screens.length);
      // Always reset to tab 0 on role change so HR lands on HR Overview, etc.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _tabController.index != 0) {
          _tabController.animateTo(0);
        }
      });
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
        currentIndex: _customScreen != null ? -1 : _tabController.index,
        onSelectTab: (index) {
          setState(() {
            _customScreen = null;
            _customScreenTitle = null;
            _tabController.animateTo(index.clamp(0, screens.length - 1));
          });
        },
        onSelectScreen: (screen, title) {
          setState(() {
            _customScreen = screen;
            _customScreenTitle = title;
          });
        },
      ),
      appBar: AppBar(
        titleSpacing: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(
              _customScreen != null ? Icons.arrow_back_rounded : Icons.menu_rounded,
              size: 26,
            ),
            onPressed: () {
              if (_customScreen != null) {
                setState(() {
                  _customScreen = null;
                  _customScreenTitle = null;
                });
              } else {
                Scaffold.of(ctx).openDrawer();
              }
            },
            tooltip: _customScreen != null ? 'Back to Main Dashboard' : 'Open Navigation Drawer',
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
            if (_customScreenTitle != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '• $_customScreenTitle',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 24),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                },
                tooltip: 'Notifications',
              ),
              if (notifProvider.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      notifProvider.unreadCount > 9 ? '9+' : '${notifProvider.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 22),
            onPressed: () {
              // TODO: Implement more options
            },
            tooltip: 'More Options',
          ),
        ],
      ),
      body: _customScreen ??
          TabBarView(
            controller: _tabController,
            children: screens,
          ),
      floatingActionButton: const AIVoiceButton(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _customScreen != null ? 0 : _tabController.index.clamp(0, navItems.length - 1),
        onTap: (index) {
          setState(() {
            _customScreen = null;
            _customScreenTitle = null;
            _tabController.animateTo(index);
          });
        },
        selectedItemColor: _customScreen != null
            ? (isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight)
            : roleColor,
        unselectedItemColor: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
        type: BottomNavigationBarType.fixed,
        items: navItems,
      ),
    );
  }
}
