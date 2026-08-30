import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/attendance_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_provider.dart';
import '../shared/custom_widgets.dart';
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

    final pendingList = attendance.getPendingApprovals();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    var allToday = attendance.getAttendanceByDate(todayStr);

    if (_filterOnlyLate) {
      allToday = allToday.where((a) => a.timingStatus == TimingStatus.lateArrival).toList();
    }

    final approvedToday = allToday.where((a) => a.status == AttendanceStatus.approved || a.status == AttendanceStatus.completed).toList();
    final pendingLeaves = leaveProv.getPendingLeaves();

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
                            MaterialPageRoute(builder: (_) => const LeaveApprovalScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.cardDarkAlt : Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.purple.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.beach_access, color: Colors.purple, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Employee Leave Requests (${pendingLeaves.length} Pending)',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.purple),
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
                                label: Text('BULK APPROVE (${pendingList.length})'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.success,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          if (pendingList.isNotEmpty) const SizedBox(width: 10),
                          FilterChip(
                            label: const Text('Late Only 🔴'),
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
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Pending Approvals'),
                                if (pendingList.isNotEmpty) ...[
                                  const SizedBox(width: 8),
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
                          const Tab(text: "Today's Team Roster"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
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
              allToday.isEmpty
                  ? Center(
                      child: Text(
                        'No attendance logged for today matching filters.',
                        style: GoogleFonts.inter(
                          color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      itemCount: allToday.length,
                      itemBuilder: (context, index) {
                        final rec = allToday[index];
                        return _buildRosterCard(context, rec);
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingCard(BuildContext context, AttendanceModel rec) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = rec.clockInTime != null ? DateFormat('hh:mm a').format(rec.clockInTime!) : '--';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.warning.withValues(alpha: 0.35),
          width: 1.2,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const StatusBadge(status: AttendanceStatus.pending, isCompact: true),
                  const SizedBox(height: 2),
                  Text(rec.timingStatus.label, style: const TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
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
                      label: const Text('Review & Verify'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12),
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
      padding: const EdgeInsets.all(14),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      rec.employeeName,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      rec.timingStatus.label,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
                Text(
                  'In: ${rec.clockInTime != null ? DateFormat('hh:mm a').format(rec.clockInTime!) : "--"} • Break: ${rec.totalBreakMinutes}m • Net: ${rec.formattedNetDuration}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(status: rec.status, isCompact: true),
        ],
      ),
    );
  }
}
