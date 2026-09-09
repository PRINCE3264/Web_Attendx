import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/attendance_model.dart';
import '../../models/user_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hr_provider.dart';
import '../manager/photo_review_dialog.dart';

class AllAttendanceScreen extends StatefulWidget {
  final bool isEmbedded;
  final String initialStatusFilter; // 'all', 'approved', 'pending', 'late', 'rejected'

  const AllAttendanceScreen({
    super.key,
    this.isEmbedded = true,
    this.initialStatusFilter = 'all',
  });

  @override
  State<AllAttendanceScreen> createState() => _AllAttendanceScreenState();
}

class _AllAttendanceScreenState extends State<AllAttendanceScreen> {
  late String _statusFilter;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.initialStatusFilter;
  }

  @override
  void didUpdateWidget(covariant AllAttendanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialStatusFilter != widget.initialStatusFilter) {
      setState(() {
        _statusFilter = widget.initialStatusFilter;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final attendanceProv = context.watch<AttendanceProvider>();
    final hrProv = context.watch<HrProvider>();
    final currentUser = auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allRecords = attendanceProv.allAttendance;
    final allUsersMap = {for (var u in hrProv.filteredEmployees) u.userId: u};

    // Filter by Status & Search
    final filteredRecords = allRecords.where((rec) {
      final empName = rec.employeeName.isNotEmpty ? rec.employeeName : (allUsersMap[rec.employeeId]?.name ?? '');
      final empCode = rec.employeeCode.isNotEmpty ? rec.employeeCode : (allUsersMap[rec.employeeId]?.employeeId ?? '');
      final date = rec.date;

      final query = _searchController.text.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          empName.toLowerCase().contains(query) ||
          empCode.toLowerCase().contains(query) ||
          date.contains(query);

      if (!matchesSearch) return false;

      if (_statusFilter == 'approved') {
        return rec.status == AttendanceStatus.approved || rec.status == AttendanceStatus.completed;
      }
      if (_statusFilter == 'pending') {
        return rec.status == AttendanceStatus.pending;
      }
      if (_statusFilter == 'late') {
        return rec.timingStatus == TimingStatus.lateArrival;
      }
      if (_statusFilter == 'rejected') {
        return rec.status == AttendanceStatus.rejected;
      }
      return true;
    }).toList();

    // Stats Counters for today
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayRecords = allRecords.where((r) => r.date == todayStr).toList();
    final presentToday = todayRecords.where((r) => r.status == AttendanceStatus.approved || r.status == AttendanceStatus.completed).length;
    final lateToday = todayRecords.where((r) => r.timingStatus == TimingStatus.lateArrival).length;
    final pendingToday = todayRecords.where((r) => r.status == AttendanceStatus.pending).length;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : const Color(0xFFF8FAFC),
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: Text(
                'All Employee Attendance Feed',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Master KPI Summary Row
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.history_toggle_off_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Company Master Attendance Feed',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Real-time stream of all clock-ins & attendance logs',
                              style: GoogleFonts.inter(fontSize: 11.5, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHeaderStat('Present Today', '$presentToday', const Color(0xFF4ADE80)),
                      _buildHeaderStat('Late In', '$lateToday', const Color(0xFFFBBF24)),
                      _buildHeaderStat('Pending', '$pendingToday', const Color(0xFFF472B6)),
                      _buildHeaderStat('Total Logs', '${allRecords.length}', Colors.white),
                    ],
                  ),
                ],
              ),
            ),

            // Search Bar & Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search employee name, ID, or date (yyyy-MM-dd)...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark ? AppTheme.cardDark : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'All Logs (${allRecords.length})', isDark),
                        const SizedBox(width: 6),
                        _buildFilterChip('approved', 'Approved', isDark),
                        const SizedBox(width: 6),
                        _buildFilterChip('pending', 'Pending Approval', isDark),
                        const SizedBox(width: 6),
                        _buildFilterChip('late', 'Late Arrival', isDark),
                        const SizedBox(width: 6),
                        _buildFilterChip('rejected', 'Rejected', isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Main Attendance Stream List
            Expanded(
              child: filteredRecords.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      itemCount: filteredRecords.length,
                      itemBuilder: (context, index) {
                        final rec = filteredRecords[index];
                        final emp = allUsersMap[rec.employeeId];
                        return _buildAttendanceCard(context, rec, emp, currentUser, isDark);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String label, String val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          val,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: color),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10.5, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String filterKey, String label, bool isDark) {
    final isSelected = _statusFilter == filterKey;
    return ChoiceChip(
      selected: isSelected,
      checkmarkColor: Colors.white,
      onSelected: (_) {
        setState(() {
          _statusFilter = filterKey;
        });
      },
      label: Text(label),
      labelStyle: GoogleFonts.outfit(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12,
        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
      ),
      selectedColor: AppTheme.primary,
      backgroundColor: isDark ? AppTheme.cardDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppTheme.primary : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(
    BuildContext context,
    AttendanceModel rec,
    UserModel? emp,
    UserModel? currentUser,
    bool isDark,
  ) {
    final empName = rec.employeeName.isNotEmpty ? rec.employeeName : (emp?.name ?? 'Employee');
    final empCode = rec.employeeCode.isNotEmpty ? rec.employeeCode : (emp?.employeeId ?? rec.employeeId);
    final dept = emp?.department ?? 'General';
    final clockInStr = rec.clockInTime != null ? DateFormat('hh:mm a').format(rec.clockInTime!) : '--:--';
    final clockOutStr = rec.clockOutTime != null ? DateFormat('hh:mm a').format(rec.clockOutTime!) : 'Active Shift';

    Color statusBg = AppTheme.successSoft;
    Color statusFg = AppTheme.success;
    String statusText = 'APPROVED';

    if (rec.status == AttendanceStatus.pending) {
      statusBg = AppTheme.warningSoft;
      statusFg = AppTheme.warning;
      statusText = 'PENDING';
    } else if (rec.status == AttendanceStatus.rejected) {
      statusBg = AppTheme.dangerSoft;
      statusFg = AppTheme.danger;
      statusText = 'REJECTED';
    }

    final isLate = rec.timingStatus == TimingStatus.lateArrival;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                child: Text(
                  empName.isNotEmpty ? empName[0].toUpperCase() : 'E',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      empName,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$empCode • $dept',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusFg.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusFg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildInfoColumn('Date', rec.date, isDark),
              ),
              Expanded(
                child: _buildInfoColumn('Clock In', clockInStr, isDark, isAccent: true),
              ),
              Expanded(
                child: _buildInfoColumn('Clock Out', clockOutStr, isDark),
              ),
              Expanded(
                child: _buildInfoColumn(
                  'Timing',
                  isLate ? 'Late' : 'On Time',
                  isDark,
                  colorOverride: isLate ? AppTheme.warning : AppTheme.success,
                ),
              ),
            ],
          ),
          if (rec.clockInPhotoUrl != null && rec.clockInPhotoUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                if (currentUser == null) return;
                final prov = context.read<AttendanceProvider>();
                showDialog(
                  context: context,
                  builder: (_) => PhotoReviewDialog(
                    attendance: rec,
                    manager: currentUser,
                    onApproved: (a) => prov.approveAttendance(a.attendanceId, currentUser),
                    onRejected: (a, reason) => prov.rejectAttendance(a.attendanceId, currentUser, reason),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.camera_alt_outlined, size: 14, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'View Verification Photo',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, bool isDark, {bool isAccent = false, Color? colorOverride}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: colorOverride ?? (isAccent ? AppTheme.primary : (isDark ? Colors.white : Colors.black87)),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            'No attendance records found matching current filter.',
            style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
