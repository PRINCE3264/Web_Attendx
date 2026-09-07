import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/hr_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../shared/custom_widgets.dart';
import 'add_employee_sheet.dart';

class AllEmployeesScreen extends StatefulWidget {
  final bool isEmbedded;
  final String initialStatusFilter; // 'all', 'active', 'inactive'
  final String initialRoleFilter; // 'all', 'employee', 'manager', 'hr', 'admin'

  const AllEmployeesScreen({
    super.key,
    this.isEmbedded = true,
    this.initialStatusFilter = 'all',
    this.initialRoleFilter = 'all',
  });

  @override
  State<AllEmployeesScreen> createState() => _AllEmployeesScreenState();
}

class _AllEmployeesScreenState extends State<AllEmployeesScreen> {
  late String _statusFilter;
  late String _roleFilter;
  String _tlTeamScope = 'my_team'; // 'my_team' or 'all'

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.initialStatusFilter;
    _roleFilter = widget.initialRoleFilter;
  }

  @override
  void didUpdateWidget(covariant AllEmployeesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialStatusFilter != widget.initialStatusFilter ||
        oldWidget.initialRoleFilter != widget.initialRoleFilter) {
      setState(() {
        _statusFilter = widget.initialStatusFilter;
        _roleFilter = widget.initialRoleFilter;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final hr = context.watch<HrProvider>();
    final attendance = context.watch<AttendanceProvider>();
    final adminProv = context.watch<AdminProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = auth.currentUser;

    final isTL = currentUser?.role == UserRole.manager && currentUser != null;
    final myTeamEmployees = isTL
        ? hr.filteredEmployees
              .where(
                (e) =>
                    e.userId != currentUser.userId &&
                    e.employeeId != currentUser.employeeId &&
                    (e.managerId == currentUser.userId ||
                        (e.managerId != null &&
                            e.managerId == currentUser.employeeId) ||
                        (e.managerId != null &&
                            e.managerId == currentUser.name) ||
                        (e.managerName != null &&
                            e.managerName!.isNotEmpty &&
                            (e.managerName == currentUser.name ||
                                e.managerName == currentUser.userId ||
                                e.managerName == currentUser.employeeId)) ||
                        (currentUser.teamId.isNotEmpty &&
                            currentUser.teamId != 'unassigned' &&
                            e.teamId == currentUser.teamId)),
              )
              .toList()
        : <UserModel>[];

    // Filter employees by TL scope if logged in as TL
    final baseEmployees = isTL
        ? (_tlTeamScope == 'my_team' ? myTeamEmployees : hr.filteredEmployees)
        : hr.filteredEmployees;

    // Apply Role filter first to establish role-based directory list
    final roleFilteredBase = baseEmployees.where((e) {
      if (_roleFilter == 'employee' && e.role != UserRole.employee) {
        return false;
      }
      if (_roleFilter == 'manager' && e.role != UserRole.manager) return false;
      if (_roleFilter == 'hr' && e.role != UserRole.hr) return false;
      if (_roleFilter == 'admin' && e.role != UserRole.admin) return false;
      return true;
    }).toList();

    // Apply Active / Inactive status filter on the role-filtered base
    final activeCount = roleFilteredBase.where((e) => e.isActive).length;
    final inactiveCount = roleFilteredBase.where((e) => !e.isActive).length;

    final employees = roleFilteredBase.where((e) {
      if (_statusFilter == 'active' && !e.isActive) return false;
      if (_statusFilter == 'inactive' && e.isActive) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : const Color(0xFFF8FAFC),
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: Text(
                _roleFilter == 'manager'
                    ? 'Team Lead Directory'
                    : (_roleFilter == 'hr'
                          ? 'HR Personnel Directory'
                          : (_roleFilter == 'employee'
                                ? 'Employee Directory'
                                : (currentUser?.role == UserRole.manager
                                      ? 'Team Roster'
                                      : 'User Directory'))),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
      floatingActionButton:
          (currentUser?.role == UserRole.admin ||
              currentUser?.role == UserRole.hr)
          ? FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (_) => const AddEmployeeSheet(),
                );
              },
              backgroundColor: AppTheme.primary,
              child: const Icon(Icons.person_add, color: Colors.white),
            )
          : (isTL
                ? FloatingActionButton.extended(
                    onPressed: () =>
                        _showTLManageTeamSheet(context, currentUser),
                    backgroundColor: AppTheme.primary,
                    icon: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Assign Team Members',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null),
      body: SafeArea(
        child: Column(
          children: [
            // TL Scope Switch Chips (My Team vs All Company)
            if (isTL)
              _buildTLScopeChips(
                isDark,
                myTeamEmployees.length,
                hr.filteredEmployees.length,
              ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                onChanged: (val) => hr.setSearchQuery(val),
                decoration: InputDecoration(
                  hintText: 'Search employee name or ID (e.g. EMP-1042)...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: hr.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => hr.setSearchQuery(''),
                        )
                      : null,
                ),
              ),
            ),

            // Status Filter Chips (All, Active, Inactive)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStatusChip(
                      'all',
                      'All (${roleFilteredBase.length})',
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildStatusChip(
                      'active',
                      'Active ($activeCount)',
                      isDark,
                      badgeColor: AppTheme.success,
                    ),
                    const SizedBox(width: 8),
                    _buildStatusChip(
                      'inactive',
                      'Inactive ($inactiveCount)',
                      isDark,
                      badgeColor: AppTheme.danger,
                    ),
                  ],
                ),
              ),
            ),

            // Department Filters (only for HR/Admin)
            if (currentUser?.role != UserRole.manager)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Engineering', 'Design & UI'].map((dept) {
                      final isSelected = hr.selectedDepartmentFilter == dept;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            dept,
                            style: const TextStyle(fontSize: 12),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) hr.setDepartmentFilter(dept);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            const SizedBox(height: 4),

            // Employee Cards List View
            Expanded(
              child: employees.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _statusFilter == 'inactive'
                                  ? Icons.no_accounts_outlined
                                  : Icons.people_outline,
                              size: 48,
                              color: isDark
                                  ? AppTheme.textMutedDark
                                  : AppTheme.textMutedLight,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No Employees Found',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _statusFilter == 'inactive'
                                  ? 'There are currently no inactive or deactivated employees.'
                                  : 'No employee profiles match the current filter criteria.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: employees.length,
                      itemBuilder: (context, index) {
                        final emp = employees[index];
                        final todayRec = attendance.getTodayAttendance(
                          emp.userId,
                        );
                        final report = ReportService.calculate30DayReport(
                          employee: emp,
                          attendanceList: attendance.getEmployeeHistory(
                            emp.userId,
                          ),
                        );

                        return _buildEmployeeCard(
                          context,
                          emp,
                          todayRec,
                          report,
                          currentUser,
                          adminProv,
                          isDark,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(
    String key,
    String label,
    bool isDark, {
    Color? badgeColor,
  }) {
    final isSelected = _statusFilter == key;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _statusFilter = key);
      },
      label: Text(
        label,
        style: GoogleFonts.outfit(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          fontSize: 12.5,
          color: isSelected
              ? Colors.white
              : (isDark ? AppTheme.textMutedDark : AppTheme.textMainLight),
        ),
      ),
      selectedColor: badgeColor ?? AppTheme.primary,
      backgroundColor: isDark ? AppTheme.cardDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? (badgeColor ?? AppTheme.primary)
              : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildEmployeeCard(
    BuildContext context,
    UserModel emp,
    dynamic todayRec,
    dynamic report,
    UserModel? currentUser,
    AdminProvider adminProv,
    bool isDark,
  ) {
    final isActive = emp.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? (isDark ? AppTheme.cardDark : Colors.white)
            : (isDark
                  ? const Color(0xFF1E1E2E)
                  : AppTheme.dangerSoft.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? (isDark
                    ? AppTheme.borderDark
                    : AppTheme.primary.withValues(alpha: 0.15))
              : AppTheme.danger.withValues(alpha: 0.35),
          width: isActive ? 1.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Avatar, Name, Role/Status Badge & Active Switch
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  PhotoDisplayWidget(
                    photoUrl: emp.avatarUrl,
                    size: 48,
                    borderRadius: 24,
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.success : AppTheme.danger,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppTheme.cardDark : Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            emp.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : AppTheme.textMainLight,
                            ),
                          ),
                        ),
                        // Status Badge Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppTheme.successSoft
                                : AppTheme.dangerSoft,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActive
                                  ? AppTheme.success.withValues(alpha: 0.3)
                                  : AppTheme.danger.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isActive
                                    ? Icons.check_circle_rounded
                                    : Icons.block_rounded,
                                size: 12,
                                color: isActive
                                    ? AppTheme.success
                                    : AppTheme.danger,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isActive ? 'ACTIVE' : 'INACTIVE',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? AppTheme.success
                                      : AppTheme.danger,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${emp.employeeId} • ${emp.department} • ${emp.role.name.toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.textMutedDark
                            : AppTheme.textMutedLight,
                      ),
                    ),
                    if (emp.role == UserRole.employee) ...[
                      const SizedBox(height: 3),
                      Text(
                        'TL: ${emp.managerName ?? 'Unassigned'} • Proj: ${emp.assignedProjectName ?? 'Unassigned'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ] else if (emp.role == UserRole.manager) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Proj: ${emp.assignedProjectName ?? 'Unassigned'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // Admin/HR/TL Action Bar Row
          if (currentUser?.role == UserRole.admin ||
              currentUser?.role == UserRole.hr ||
              currentUser?.role == UserRole.manager) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (currentUser?.role == UserRole.admin ||
                    currentUser?.role == UserRole.hr) ...[
                  _buildCardActionButton(
                    icon: Icons.edit_note_rounded,
                    label: 'Edit',
                    color: AppTheme.primary,
                    onTap: () => _showEditUserModal(context, emp),
                  ),
                  _buildCardActionButton(
                    icon: Icons.phonelink_erase_rounded,
                    label: emp.deviceId != null ? 'Reset Device Lock' : 'Device Unlocked',
                    color: emp.deviceId != null ? Colors.orange : const Color(0xFF64748B),
                    onTap: () => _resetEmployeeDeviceLock(context, emp, currentUser!),
                  ),
                ],
                if (currentUser?.role == UserRole.manager &&
                    emp.role == UserRole.employee) ...[
                  if (emp.managerId == currentUser!.userId ||
                      (emp.managerId != null &&
                          emp.managerId == currentUser.employeeId)) ...[
                    _buildCardActionButton(
                      icon: Icons.check_circle_rounded,
                      label: 'In Your Team',
                      color: AppTheme.success,
                      onTap: () =>
                          _showTLRemoveDialog(context, emp, currentUser),
                    ),
                    _buildCardActionButton(
                      icon: Icons.folder_special_rounded,
                      label: 'Assign Proj',
                      color: AppTheme.accent,
                      onTap: () => _showAssignProjectSheet(context, emp),
                    ),
                  ] else
                    _buildCardActionButton(
                      icon: Icons.person_add_alt_1_rounded,
                      label: 'Assign to My Team',
                      color: const Color(0xFF2563EB),
                      onTap: () =>
                          _assignEmployeeToMe(context, emp, currentUser),
                    ),
                ],
                if (currentUser?.role == UserRole.admin ||
                    currentUser?.role == UserRole.hr) ...[
                  if (emp.role == UserRole.employee) ...[
                    _buildCardActionButton(
                      icon: Icons.supervisor_account_rounded,
                      label: 'Assign TL',
                      color: const Color(0xFF2563EB),
                      onTap: () => _showAssignTLSheet(context, emp),
                    ),
                  ],
                  if (emp.role == UserRole.employee ||
                      emp.role == UserRole.manager) ...[
                    _buildCardActionButton(
                      icon: Icons.folder_special_rounded,
                      label: 'Assign Proj',
                      color: AppTheme.accent,
                      onTap: () => _showAssignProjectSheet(context, emp),
                    ),
                  ],
                  _buildCardActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    color: AppTheme.danger,
                    onTap: () => _confirmDeleteEmployee(context, emp),
                  ),
                ],
              ],
            ),
          ],

          // Inactive Warning Banner (if deactivated)
          if (!isActive) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.dangerSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.danger.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_person_outlined,
                    size: 16,
                    color: AppTheme.danger,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Account suspended - Workspace & login access revoked.',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 24),

          // Lower Section: Attendance Metrics & Admin Active Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                '30-Day Rate',
                '${report.attendancePercentage.toStringAsFixed(1)}%',
              ),
              _buildStatItem('Days Present', '${report.presentDays}d'),
              _buildStatItem('Late In', '${report.lateArrivals}x'),
              _buildStatItem('Absent', '${report.absentDays}d'),
              // Admin/HR Activation Toggle Switch
              if (currentUser?.role == UserRole.admin ||
                  currentUser?.role == UserRole.hr) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isActive ? 'Deactivate' : 'Reactivate',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 24,
                      child: Switch(
                        value: isActive,
                        activeThumbColor: AppTheme.success,
                        onChanged: (val) {
                          if (currentUser != null) {
                            adminProv.toggleUserStatus(
                              emp.userId,
                              val,
                              currentUser,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCardActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignTLSheet(BuildContext context, UserModel employee) {
    final auth = context.read<AuthProvider>();
    final currentUser = auth.currentUser;
    if (currentUser == null) return;

    final managers = context
        .read<HrProvider>()
        .filteredEmployees
        .where((u) => u.role == UserRole.manager)
        .toList();
    final allManagers = FirestoreService()
        .getAllUsers()
        .where((u) => u.role == UserRole.manager)
        .toList();
    final Map<String, UserModel> managerMap = {};
    for (final m in [...managers, ...allManagers]) {
      managerMap[m.userId] = m;
    }
    final combinedManagers = managerMap.values.toList();

    UserModel? selectedTL;
    if (employee.managerId != null && employee.managerId != 'unassigned') {
      try {
        selectedTL = combinedManagers.firstWhere(
          (m) => m.userId == employee.managerId,
        );
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.assignment_ind_rounded,
                          color: AppTheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assign Team Lead (TL)',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              'Assign ${employee.name} (${employee.employeeId}) to a manager.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark
                                    ? AppTheme.textMutedDark
                                    : AppTheme.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (combinedManagers.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'No Team Leads / Managers available.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark
                              ? AppTheme.textMutedDark
                              : AppTheme.textMutedLight,
                        ),
                      ),
                    ),
                  ] else ...[
                    Text(
                      'SELECT MANAGER / TL:',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: combinedManagers.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final m = combinedManagers[index];
                          final isSelected = selectedTL?.userId == m.userId;
                          return InkWell(
                            onTap: () {
                              setModalState(() {
                                selectedTL = m;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primary.withValues(alpha: 0.12)
                                    : (isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.grey.withValues(
                                              alpha: 0.08,
                                            )),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: isSelected
                                        ? AppTheme.primary
                                        : Colors.grey.shade400,
                                    child: Text(
                                      m.name.isNotEmpty
                                          ? m.name[0].toUpperCase()
                                          : 'M',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m.name,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: isSelected
                                                ? AppTheme.primary
                                                : (isDark
                                                      ? Colors.white
                                                      : Colors.black87),
                                          ),
                                        ),
                                        Text(
                                          '${m.department} • ${m.employeeId}',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: isDark
                                                ? AppTheme.textMutedDark
                                                : AppTheme.textMutedLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    color: isSelected
                                        ? AppTheme.primary
                                        : Colors.grey.shade400,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: selectedTL == null
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            final adminProv = context.read<AdminProvider>();
                            final messenger = ScaffoldMessenger.of(context);
                            final success = await adminProv.assignEmployeeToTL(
                              employeeId: employee.userId,
                              tlUser: selectedTL!,
                              admin: currentUser,
                            );

                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? '✅ ${employee.name} assigned to TL ${selectedTL!.name}!'
                                        : '❌ Failed to assign TL.',
                                  ),
                                  backgroundColor: success
                                      ? AppTheme.success
                                      : AppTheme.danger,
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text(
                      'Confirm TL Assignment',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAssignProjectSheet(BuildContext context, UserModel employee) {
    final hrProv = context.read<HrProvider>();
    final currentUser = context.read<AuthProvider>().currentUser;

    // Admin and HR see all projects, TLs only see projects they manage or are assigned to
    final projects = hrProv.projects
        .where((p) {
          if (currentUser?.role == UserRole.admin ||
              currentUser?.role == UserRole.hr) {
            return true;
          }
          return p.assignedLeadId == currentUser?.userId ||
              p.assignedLeadId == currentUser?.employeeId ||
              p.projectId == currentUser?.assignedProjectId ||
              (currentUser?.assignedProjectName != null &&
                  p.projectName.toLowerCase() ==
                      currentUser?.assignedProjectName?.toLowerCase()) ||
              p.assignedEmployeeIds.contains(currentUser?.userId) ||
              (currentUser?.employeeId != null &&
                  p.assignedEmployeeIds.contains(currentUser?.employeeId));
        })
        .map((p) => p.projectName)
        .toList();

    String? selectedProject = employee.assignedProjectName;
    if (selectedProject == null || !projects.contains(selectedProject)) {
      selectedProject = projects.isNotEmpty ? projects.first : null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.folder_special_rounded,
                          color: AppTheme.accent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assign Active Project',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              'Assign ${employee.name} (${employee.employeeId}) to a project.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark
                                    ? AppTheme.textMutedDark
                                    : AppTheme.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (projects.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'No projects available in workspace.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark
                              ? AppTheme.textMutedDark
                              : AppTheme.textMutedLight,
                        ),
                      ),
                    ),
                  ] else ...[
                    Text(
                      'SELECT PROJECT:',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accent,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: projects.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final proj = projects[index];
                          final isSelected = selectedProject == proj;
                          return InkWell(
                            onTap: () {
                              setModalState(() {
                                selectedProject = proj;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.accent.withValues(alpha: 0.12)
                                    : (isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.grey.withValues(
                                              alpha: 0.08,
                                            )),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.accent
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.accent
                                          : Colors.grey.shade400,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.folder_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      proj,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: isSelected
                                            ? AppTheme.accent
                                            : (isDark
                                                  ? Colors.white
                                                  : Colors.black87),
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    color: isSelected
                                        ? AppTheme.accent
                                        : Colors.grey.shade400,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: selectedProject == null
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            final hrProv = context.read<HrProvider>();
                            final messenger = ScaffoldMessenger.of(context);
                            await hrProv.assignProjectToEmployee(
                              employee.userId,
                              selectedProject!,
                            );

                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '✅ ${employee.name} assigned to "$selectedProject"!',
                                  ),
                                  backgroundColor: AppTheme.success,
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text(
                      'Confirm Project Assignment',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditUserModal(BuildContext context, UserModel targetUser) {
    final nameController = TextEditingController(text: targetUser.name);
    final emailController = TextEditingController(text: targetUser.email);
    final empIdController = TextEditingController(text: targetUser.employeeId);
    final deptController = TextEditingController(text: targetUser.department);
    UserRole selectedRole = targetUser.role;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.edit_note_rounded,
                              color: AppTheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Edit Employee Profile',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  'Update details for ${targetUser.name} (${targetUser.employeeId})',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Name is required'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Work Email *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Email is required'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: empIdController,
                        decoration: const InputDecoration(
                          labelText: 'Employee ID *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Employee ID is required'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: deptController,
                        decoration: const InputDecoration(
                          labelText: 'Department *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Department is required'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      DropdownButtonFormField<UserRole>(
                        isExpanded: true,
                        initialValue: selectedRole,
                        menuMaxHeight: 220,
                        dropdownColor: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        decoration: const InputDecoration(
                          labelText: 'User Role *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.security),
                        ),
                        items: UserRole.values.map((role) {
                          return DropdownMenuItem<UserRole>(
                            value: role,
                            child: Text(
                              role.name.toUpperCase(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedRole = val);
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      ElevatedButton.icon(
                        icon: const Icon(Icons.save_rounded, size: 18),
                        label: const Text(
                          'Save Profile Updates',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final admin = context
                              .read<AuthProvider>()
                              .currentUser;
                          if (admin == null) return;

                          final updatedUser = targetUser.copyWith(
                            name: nameController.text.trim(),
                            email: emailController.text.trim(),
                            employeeId: empIdController.text.trim(),
                            department: deptController.text.trim(),
                            role: selectedRole,
                          );

                          final nav = Navigator.of(ctx);
                          final messenger = ScaffoldMessenger.of(context);
                          final adminProv = context.read<AdminProvider>();
                          final success = await adminProv.updateEmployee(
                            updatedUser,
                            admin,
                          );
                          nav.pop();

                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? '✅ Profile for ${updatedUser.name} updated successfully!'
                                      : '❌ Failed to update employee.',
                                ),
                                backgroundColor: success
                                    ? AppTheme.success
                                    : AppTheme.danger,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteEmployee(BuildContext context, UserModel targetUser) {
    final admin = context.read<AuthProvider>().currentUser;
    if (admin == null) return;

    if (admin.userId == targetUser.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ You cannot delete your own active account.'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.danger,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                'Delete Account?',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to permanently delete employee "${targetUser.name}" (${targetUser.employeeId})?\n\nThis action cannot be undone.',
            style: GoogleFonts.inter(fontSize: 13.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final nav = Navigator.of(ctx);
                final messenger = ScaffoldMessenger.of(context);
                final adminProv = context.read<AdminProvider>();
                final success = await adminProv.deleteEmployee(
                  targetUser.userId,
                  admin,
                );
                nav.pop();

                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? '🗑️ Employee "${targetUser.name}" has been deleted.'
                            : '❌ Failed to delete employee.',
                      ),
                      backgroundColor: success ? AppTheme.danger : Colors.grey,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.delete_forever, size: 18),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTLScopeChips(bool isDark, int myTeamCount, int totalCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tlTeamScope = 'my_team'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _tlTeamScope == 'my_team'
                        ? AppTheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: Text(
                      'My Assigned Team ($myTeamCount)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        color: _tlTeamScope == 'my_team'
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tlTeamScope = 'all'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _tlTeamScope == 'all'
                        ? AppTheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: Text(
                      'All Employees ($totalCount)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        color: _tlTeamScope == 'all'
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _assignEmployeeToMe(
    BuildContext context,
    UserModel employee,
    UserModel currentUser,
  ) async {
    final hr = context.read<HrProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final success = await hr.assignEmployeeToTL(
      employeeId: employee.userId,
      tlUser: currentUser,
      actor: currentUser,
    );

    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '✅ ${employee.name} added to your Team Roster!'
                : '❌ Failed to assign employee.',
          ),
          backgroundColor: success ? AppTheme.success : AppTheme.danger,
        ),
      );
    }
  }

  void _showTLRemoveDialog(
    BuildContext context,
    UserModel employee,
    UserModel currentUser,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Remove from Team?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to remove "${employee.name}" from your team roster?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final hr = context.read<HrProvider>();
              await hr.unassignEmployeeFromTL(
                employeeId: employee.userId,
                actor: currentUser,
              );
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Removed ${employee.name} from your team.'),
                  ),
                );
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showTLManageTeamSheet(BuildContext context, UserModel currentUser) {
    String search = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final hr = context.watch<HrProvider>();
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final allEmps = hr.allEmployees
                .where((u) => u.role == UserRole.employee)
                .toList();
            final filtered = allEmps.where((u) {
              if (search.isEmpty) return true;
              return u.name.toLowerCase().contains(search.toLowerCase()) ||
                  u.employeeId.toLowerCase().contains(search.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.groups_rounded,
                          color: AppTheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assign Employees to My Team',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              'Select employees to add to your Team Roster',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark
                                    ? AppTheme.textMutedDark
                                    : AppTheme.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (val) => setModalState(() => search = val),
                    decoration: const InputDecoration(
                      hintText: 'Search employee by name or ID...',
                      prefixIcon: Icon(Icons.search, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('No employees found.'))
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final emp = filtered[index];
                              final isMyTeam =
                                  emp.managerId == currentUser.userId ||
                                  (emp.managerId != null &&
                                      emp.managerId == currentUser.employeeId);

                              final subtitleText =
                                  '${emp.employeeId} • ${emp.department}'
                                  '${isMyTeam ? " • In Your Team" : (emp.managerName != null ? " • TL: ${emp.managerName}" : "")}';

                              return ListTile(
                                leading: PhotoDisplayWidget(
                                  photoUrl: emp.avatarUrl,
                                  size: 40,
                                  borderRadius: 20,
                                ),
                                title: Text(
                                  emp.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  subtitleText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isMyTeam
                                        ? AppTheme.success
                                        : (isDark
                                              ? Colors.white60
                                              : Colors.black54),
                                    fontWeight: isMyTeam
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                trailing: isMyTeam
                                    ? OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.danger,
                                          side: const BorderSide(
                                            color: AppTheme.danger,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                        ),
                                        onPressed: () async {
                                          await hr.unassignEmployeeFromTL(
                                            employeeId: emp.userId,
                                            actor: currentUser,
                                          );

                                          setModalState(() {});
                                        },
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          size: 14,
                                        ),
                                        label: const Text(
                                          'Remove',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    : ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                        ),
                                        onPressed: () async {
                                          await hr.assignEmployeeToTL(
                                            employeeId: emp.userId,
                                            tlUser: currentUser,
                                            actor: currentUser,
                                          );
                                          setModalState(() {});
                                        },
                                        icon: const Icon(
                                          Icons.person_add,
                                          size: 14,
                                        ),
                                        label: const Text(
                                          'Add',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _resetEmployeeDeviceLock(BuildContext context, UserModel emp, UserModel actor) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? AppTheme.cardDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Header Badge
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phonelink_erase_rounded,
                  color: Color(0xFFD97706),
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),

              // Title
              Text(
                'Reset Phone Device Lock?',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.45,
                    color: isDark ? AppTheme.textMutedDark : const Color(0xFF64748B),
                  ),
                  children: [
                    const TextSpan(text: 'Are you sure you want to reset the registered phone device lock for '),
                    TextSpan(
                      text: emp.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const TextSpan(text: '? They will be able to register a new phone device on their next login.'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Buttons Action Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(
                          color: isDark ? AppTheme.borderDark : const Color(0xFFCBD5E1),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(ctx, true),
                      icon: const Icon(Icons.restart_alt_rounded, size: 18),
                      label: Text(
                        'Reset Device',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true && context.mounted) {
      await AuthService().resetUserDeviceBinding(emp.userId, actor);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Phone Device Lock successfully reset for ${emp.name}.'),
            backgroundColor: AppTheme.success,
          ),
        );
        setState(() {});
      }
    }
  }
}
