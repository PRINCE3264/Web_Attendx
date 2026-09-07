import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/attendance_model.dart';
import '../../models/user_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_provider.dart';
import '../shared/custom_widgets.dart';
import '../shared/project_reports_screen.dart';
import '../../providers/hr_provider.dart';
import '../hr/all_employees_screen.dart';
import 'photo_review_dialog.dart';
import 'leave_approval_screen.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _filterOnlyLate = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openReviewModal(AttendanceModel rec) {
    final auth = context.read<AuthProvider>();
    final attendance = context.read<AttendanceProvider>();
    final manager = auth.currentUser;
    if (manager == null) return;

    showDialog(
      context: context,
      builder: (_) => PhotoReviewDialog(
        attendance: rec,
        manager: manager,
        onApproved: (a) => attendance.approveAttendance(a.attendanceId, manager),
        onRejected: (a, reason) => attendance.rejectAttendance(a.attendanceId, manager, reason),
      ),
    );
  }

  void _handleBulkApprove() async {
    final auth = context.read<AuthProvider>();
    final attendance = context.read<AttendanceProvider>();
    final manager = auth.currentUser;
    if (manager == null) return;

    final count = await attendance.bulkApproveAll(manager);
    if (mounted && count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully bulk approved $count pending attendance submissions!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final attendance = context.watch<AttendanceProvider>();
    final leaveProv = context.watch<LeaveProvider>();
    final user = auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Center(child: Text('Please log in'));
    }

    final pendingList = user.role == UserRole.manager
        ? attendance.getPendingApprovalsForTL(user.userId)
        : attendance.getPendingApprovals();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    var allToday = user.role == UserRole.manager
        ? attendance.getTeamAttendanceForTL(user.userId).where((a) => a.date == todayStr).toList()
        : attendance.getAttendanceByDate(todayStr);

    if (_filterOnlyLate) {
      allToday = allToday.where((a) => a.timingStatus == TimingStatus.lateArrival).toList();
    }

    final approvedToday = allToday.where((a) => a.status == AttendanceStatus.approved || a.status == AttendanceStatus.completed).toList();
    final pendingLeaves = user.role == UserRole.manager
        ? leaveProv.getPendingLeavesForTL(user.userId)
        : leaveProv.getPendingLeaves();

    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppTheme.secondary.withValues(alpha: 0.15),
                            child: ClipOval(
                              child: PhotoDisplayWidget(
                                photoUrl: user.avatarUrl,
                                size: 48,
                                borderRadius: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Team Lead Portal',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                  ),
                                ),
                                Text(
                                  user.name,
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Manager • ${user.teamName}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppTheme.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // KPI Cards
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Pending Approvals',
                              value: '${pendingList.length}',
                              subtitle: pendingList.isNotEmpty ? 'Action required' : 'All clear',
                              icon: Icons.pending_actions,
                              color: pendingList.isNotEmpty ? AppTheme.warning : AppTheme.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              title: 'Present Today',
                              value: '${approvedToday.length}',
                              subtitle: 'Active on duty',
                              icon: Icons.how_to_reg,
                              color: AppTheme.success,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Leave Approvals Quick Banner
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LeaveApprovalScreen(isEmbedded: false)),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.cardDarkAlt : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.beach_access, color: Colors.blue, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Employee Leave Requests (${pendingLeaves.length} Pending)',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.blue),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Daily Project Work Reports Quick Banner
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProjectReportsScreen(isEmbedded: false)),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.cardDarkAlt : AppTheme.primarySoft,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.assignment_turned_in_outlined, color: AppTheme.primary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Daily Project Work Reports Feed (Screenshots & Video Proof)',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.primary),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Bulk Action & Filter Bar
                      Row(
                        children: [
                          if (pendingList.isNotEmpty)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _handleBulkApprove,
                                icon: const Icon(Icons.bolt, size: 18),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('BULK APPROVE (${pendingList.length})'),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.success,
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                ),
                              ),
                            ),
                          if (pendingList.isNotEmpty) const SizedBox(width: 10),
                          FilterChip(
                            label: const Text('Late Only 🔴', style: TextStyle(fontSize: 12)),
                            selected: _filterOnlyLate,
                            onSelected: (val) => setState(() => _filterOnlyLate = val),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Tab Bar
                      TabBar(
                        controller: _tabController,
                        labelColor: AppTheme.primary,
                        unselectedLabelColor: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                        indicatorColor: AppTheme.primary,
                        indicatorWeight: 3,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                        tabs: [
                          Tab(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Pending Approvals', style: TextStyle(fontWeight: FontWeight.bold)),
                                  if (pendingList.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.warning,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${pendingList.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const Tab(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text("Today's Team Roster", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            key: const ValueKey('manager_tab_bar_view'),
            controller: _tabController,
            children: [
              // Pending Approvals List
              pendingList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: AppTheme.successSoft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle_outline, size: 48, color: AppTheme.success),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Pending Approvals',
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'All team clock-in submissions have been processed.',
                            style: GoogleFonts.inter(
                              color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      itemCount: pendingList.length,
                      itemBuilder: (context, index) {
                        final rec = pendingList[index];
                        return _buildPendingCard(context, rec);
                      },
                    ),

              // Team Roster List
              Builder(
                builder: (context) {
                  final hrProv = context.watch<HrProvider>();
                  final myTeamMembers = hrProv.allEmployees.where((e) {
                    // Exclude the TL themselves
                    if (e.userId == user.userId ||
                        (user.employeeId.isNotEmpty && e.employeeId == user.employeeId)) {
                      return false;
                    }
                    // Only include employees explicitly assigned to this TL
                    // Match by managerId (stored as userId, employeeId, name, or email)
                    final assignedByManagerId =
                        e.managerId == user.userId ||
                        (user.employeeId.isNotEmpty && e.managerId == user.employeeId) ||
                        (user.name.isNotEmpty && e.managerId == user.name) ||
                        (user.email.isNotEmpty && e.managerId == user.email);
                    // Match by managerName stored on the employee record
                    final assignedByManagerName =
                        e.managerName != null &&
                        e.managerName!.isNotEmpty &&
                        e.managerName!.trim().toLowerCase() == user.name.trim().toLowerCase();
                    return assignedByManagerId || assignedByManagerName;
                  }).toList();

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Assigned Team Members (${myTeamMembers.length})',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const Scaffold(
                                    body: SafeArea(
                                      child: AllEmployeesScreen(isEmbedded: false),
                                    ),
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.person_add_alt_1_rounded, size: 14),
                            label: const Text('Assign Team', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (myTeamMembers.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.cardDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.groups_outlined, size: 48, color: AppTheme.primary),
                              const SizedBox(height: 12),
                              Text(
                                'No Employees Assigned Yet',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Assign employees to your team roster to track their attendance and manage requests.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const Scaffold(
                                        body: SafeArea(
                                          child: AllEmployeesScreen(isEmbedded: false),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.person_add, size: 16),
                                label: const Text('Assign Employees Now'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        for (final member in myTeamMembers) ...[
                          Builder(
                            builder: (context) {
                              final attendanceMatch = allToday.where((a) => a.employeeId == member.userId || a.employeeId == member.employeeId).toList();
                              if (attendanceMatch.isNotEmpty) {
                                return _buildRosterCard(context, attendanceMatch.first);
                              } else {
                                return _buildUncheckedMemberCard(context, member);
                              }
                            },
                          ),
                        ],
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUncheckedMemberCard(BuildContext context, UserModel member) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            child: ClipOval(
              child: PhotoDisplayWidget(
                photoUrl: member.avatarUrl,
                size: 40,
                borderRadius: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                const SizedBox(height: 2),
                Text(
                  '${member.employeeId} • ${member.department}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.schedule, size: 12, color: Colors.orange),
                SizedBox(width: 4),
                Text('Not Checked In', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.orange)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCard(BuildContext context, AttendanceModel rec) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = rec.clockInTime != null ? DateFormat('hh:mm a').format(rec.clockInTime!) : '--';
    final isLate = rec.isLate;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.cardDark
            : (isLate ? const Color(0xFFFEF2F2) : Colors.white),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLate
              ? AppTheme.danger.withValues(alpha: 0.6)
              : AppTheme.warning.withValues(alpha: 0.4),
          width: isLate ? 1.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                child: ClipOval(
                  child: PhotoDisplayWidget(
                    photoUrl: rec.employeeAvatar,
                    size: 44,
                    borderRadius: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rec.employeeName,
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${rec.employeeCode} • ${rec.teamName}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isLate
                      ? AppTheme.danger
                      : (rec.isGracePeriod ? const Color(0xFFF59E0B) : AppTheme.success),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isLate
                      ? 'LATE - PENDING APPROVAL'
                      : (rec.isGracePeriod ? 'GRACE - PENDING' : 'ON-TIME - PENDING'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (isLate) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.danger.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.danger),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Late by ${rec.lateMinutes.toHoursAndMinutes} (Office Start: 09:30 AM | Grace ends: 09:45 AM)',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              // Photo Thumbnail Preview
              InkWell(
                onTap: () => _openReviewModal(rec),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PhotoDisplayWidget(
                        photoUrl: rec.clockInPhotoUrl,
                        borderRadius: 12,
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.zoom_in, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 14, color: AppTheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Clock In: $timeStr',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.radar, size: 14, color: AppTheme.secondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Geofence: ${rec.distanceFromOfficeMeters}m from HQ',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () => _openReviewModal(rec),
                      icon: const Icon(Icons.remove_red_eye, size: 15),
                      label: Text(isLate ? 'Review Late Clock-In' : 'Review & Verify'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLate ? const Color(0xFFDC2626) : AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRosterCard(BuildContext context, AttendanceModel rec) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            child: ClipOval(
              child: PhotoDisplayWidget(
                photoUrl: rec.employeeAvatar,
                size: 40,
                borderRadius: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        rec.employeeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      rec.timingStatus.label,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'In: ${rec.clockInTime != null ? DateFormat('hh:mm a').format(rec.clockInTime!) : "--"} • Break: ${rec.totalBreakMinutes}m • Net: ${rec.formattedNetDuration}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(status: rec.status, isCompact: true),
        ],
      ),
    );
  }
}
