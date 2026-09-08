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
import '../shared/custom_widgets.dart';

class TlTeamAttendanceScreen extends StatefulWidget {
  const TlTeamAttendanceScreen({super.key});

  @override
  State<TlTeamAttendanceScreen> createState() => _TlTeamAttendanceScreenState();
}

class _TlTeamAttendanceScreenState extends State<TlTeamAttendanceScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  String _statusFilter = 'all';
  String _searchQuery = '';
  late TabController _tabController;

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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  List<UserModel> _getMyTeam(UserModel tl, HrProvider hrProv) {
    return hrProv.allEmployees.where((e) {
      if (e.userId == tl.userId ||
          (tl.employeeId.isNotEmpty && e.employeeId == tl.employeeId)) {
        return false;
      }
      final byId = e.managerId == tl.userId ||
          (tl.employeeId.isNotEmpty && e.managerId == tl.employeeId) ||
          (tl.name.isNotEmpty && e.managerId == tl.name) ||
          (tl.email.isNotEmpty && e.managerId == tl.email);
      final byName = e.managerName != null &&
          e.managerName!.isNotEmpty &&
          e.managerName!.trim().toLowerCase() == tl.name.trim().toLowerCase();
      final byTeam = tl.teamId.isNotEmpty && tl.teamId != 'unassigned' && e.teamId == tl.teamId;
      return byId || byName || byTeam;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final hrProv = context.watch<HrProvider>();
    final attendanceProv = context.watch<AttendanceProvider>();
    final tl = auth.currentUser;

    if (tl == null) return const Center(child: CircularProgressIndicator());

    final myTeam = _getMyTeam(tl, hrProv);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateStr;

    // Use dedicated TL method — only returns attendance for explicitly assigned members
    final allTeamAttendance = attendanceProv.getTeamAttendanceForTL(tl.userId)
        .where((a) => a.date == dateStr)
        .toList();

    final List<_Pair> pairs = myTeam.map((member) {
      final att = allTeamAttendance
          .where((a) => a.employeeId == member.userId || a.employeeId == member.employeeId)
          .toList();
      return _Pair(member: member, att: att.isNotEmpty ? att.first : null);
    }).toList();

    var filtered = pairs.where((p) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!p.member.name.toLowerCase().contains(q) &&
            !p.member.employeeId.toLowerCase().contains(q)) { return false; }
      }
      switch (_statusFilter) {
        case 'present':
          return p.att != null &&
              (p.att?.status == AttendanceStatus.approved ||
               p.att?.status == AttendanceStatus.completed);
        case 'absent':
          return p.att == null;
        case 'late':
          return p.att != null && p.att!.timingStatus == TimingStatus.lateArrival;
        case 'pending':
          return p.att != null && p.att?.status == AttendanceStatus.pending;
        default:
          return true;
      }
    }).toList();

    final total = pairs.length;
    final presentCnt = pairs.where((p) => p.att != null && (p.att?.status == AttendanceStatus.approved || p.att?.status == AttendanceStatus.completed)).length;
    final absentCnt = pairs.where((p) => p.att == null).length;
    final lateCnt = pairs.where((p) => p.att != null && p.att!.timingStatus == TimingStatus.lateArrival).length;
    final pendingCnt = pairs.where((p) => p.att != null && p.att?.status == AttendanceStatus.pending).length;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : const Color(0xFFF6F8FC),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 0,
            backgroundColor: isDark ? AppTheme.cardDark : Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.maybePop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Team Attendance', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17)),
                Text('$total assigned members', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w500)),
              ],
            ),
            actions: [
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 15, color: AppTheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        isToday ? 'Today' : DateFormat('d MMM').format(_selectedDate),
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(44),
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 2.5,
                tabs: const [Tab(text: 'Attendance'), Tab(text: 'Summary')],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // ─── TAB 1: LIST ─────────────────────
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                // Date banner
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppTheme.primary.withValues(alpha: 0.12), AppTheme.primary.withValues(alpha: 0.03)]),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_rounded, color: AppTheme.primary, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.primary),
                        ),
                        const Spacer(),
                        const Icon(Icons.edit_calendar_rounded, size: 15, color: AppTheme.primary),
                      ],
                    ),
                  ),
                ),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _Chip('All', total, Colors.blueGrey, _statusFilter == 'all', () => setState(() => _statusFilter = 'all')),
                      const SizedBox(width: 8),
                      _Chip('Present', presentCnt, AppTheme.success, _statusFilter == 'present', () => setState(() => _statusFilter = 'present')),
                      const SizedBox(width: 8),
                      _Chip('Absent', absentCnt, AppTheme.danger, _statusFilter == 'absent', () => setState(() => _statusFilter = 'absent')),
                      const SizedBox(width: 8),
                      _Chip('Late', lateCnt, AppTheme.warning, _statusFilter == 'late', () => setState(() => _statusFilter = 'late')),
                      const SizedBox(width: 8),
                      _Chip('Pending', pendingCnt, Colors.orange, _statusFilter == 'pending', () => setState(() => _statusFilter = 'pending')),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Search
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: GoogleFonts.inter(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search name or employee ID...',
                    hintStyle: GoogleFonts.inter(fontSize: 12.5, color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    filled: true,
                    fillColor: isDark ? AppTheme.cardDark : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 12),

                if (myTeam.isEmpty)
                  _Empty(Icons.groups_outlined, 'No Team Members', 'Ask Admin/HR to assign employees to your team.')
                else if (filtered.isEmpty)
                  _Empty(Icons.search_off_rounded, 'No Results', 'Try a different filter or search.')
                else
                  ...filtered.map((p) => _MemberCard(p: p, isDark: isDark)),
              ],
            ),

            // ─── TAB 2: SUMMARY ──────────────────
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              children: [
                Text(
                  DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primary),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2, shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.45,
                  children: [
                    _SCard('Total Team', '$total', Icons.groups_rounded, AppTheme.primary, isDark),
                    _SCard('Present', '$presentCnt', Icons.check_circle_rounded, AppTheme.success, isDark),
                    _SCard('Absent', '$absentCnt', Icons.cancel_rounded, AppTheme.danger, isDark),
                    _SCard('Late', '$lateCnt', Icons.timer_outlined, AppTheme.warning, isDark),
                    _SCard('Pending', '$pendingCnt', Icons.pending_actions_rounded, Colors.orange, isDark),
                    _SCard('Rate', total == 0 ? '0%' : '${((presentCnt / total) * 100).round()}%', Icons.pie_chart_rounded, const Color(0xFF6366F1), isDark),
                  ],
                ),
                const SizedBox(height: 18),
                if (total > 0) ...[
                  Text('Attendance Rate', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                    ),
                    child: Column(children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$presentCnt / $total Present', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(
                            '${((presentCnt / total) * 100).round()}%',
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold,
                              color: presentCnt / total >= 0.8 ? AppTheme.success : AppTheme.warning),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: presentCnt / total,
                          minHeight: 10,
                          backgroundColor: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            presentCnt / total >= 0.8 ? AppTheme.success : AppTheme.warning),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 18),
                ],
                if (absentCnt > 0) ...[
                  Text('❌  Absent Today ($absentCnt)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.danger)),
                  const SizedBox(height: 8),
                  ...pairs.where((p) => p.att == null).map((p) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.danger.withValues(alpha: 0.2)),
                    ),
                    child: Row(children: [
                      CircleAvatar(radius: 18, backgroundColor: AppTheme.danger.withValues(alpha: 0.12),
                        child: ClipOval(child: PhotoDisplayWidget(photoUrl: p.member.avatarUrl, size: 36, borderRadius: 18))),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.member.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('${p.member.employeeId} • ${p.member.department}', style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight)),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text('Absent', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.danger)),
                      ),
                    ]),
                  )),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pair { final UserModel member; final AttendanceModel? att; const _Pair({required this.member, required this.att}); }

class _MemberCard extends StatelessWidget {
  final _Pair p; final bool isDark;
  const _MemberCard({required this.p, required this.isDark});
  String _formatBreak(int totalMins) {
    if (totalMins <= 0) return '0m';
    final h = totalMins ~/ 60;
    final m = totalMins % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final att = p.att;
    final isAbsent = att == null;
    Color dotColor = isAbsent ? AppTheme.danger : AppTheme.success;
    if (att?.status == AttendanceStatus.pending) dotColor = Colors.orange;
    if (att?.timingStatus == TimingStatus.lateArrival) dotColor = AppTheme.warning;

    final clockInStr = att?.clockInTime != null ? DateFormat('hh:mm a').format(att!.clockInTime!) : '--:--';
    final clockOutStr = att?.clockOutTime != null ? DateFormat('hh:mm a').format(att!.clockOutTime!) : (att?.clockInTime != null ? 'Working' : '--:--');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAbsent
              ? AppTheme.danger.withValues(alpha: 0.2)
              : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
        ),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar + Name & Dept + Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: dotColor.withValues(alpha: 0.12),
                      child: ClipOval(
                        child: PhotoDisplayWidget(
                          photoUrl: p.member.avatarUrl,
                          size: 40,
                          borderRadius: 20,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppTheme.cardDark : Colors.white,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.member.name,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${p.member.employeeId} • ${p.member.department}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                isAbsent
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Absent',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.danger,
                          ),
                        ),
                      )
                    : StatusBadge(status: att.status, isCompact: true),
              ],
            ),

            // Bottom Timing Details Container (If present)
            if (!isAbsent) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    // In Time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('In Time', style: GoogleFonts.inter(fontSize: 10, color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight)),
                          const SizedBox(height: 2),
                          Text(clockInStr, style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    // Out Time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Out Time', style: GoogleFonts.inter(fontSize: 10, color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight)),
                          const SizedBox(height: 2),
                          Text(clockOutStr, style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    // Break
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Break', style: GoogleFonts.inter(fontSize: 10, color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight)),
                          const SizedBox(height: 2),
                          Text(_formatBreak(att.totalBreakMinutes), style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.orange)),
                        ],
                      ),
                    ),
                    // Net Hours
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Net Hours', style: GoogleFonts.inter(fontSize: 10, color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight)),
                          const SizedBox(height: 2),
                          Text(att.formattedNetDuration, style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label; final int count; final Color color; final bool active; final VoidCallback onTap;
  const _Chip(this.label, this.count, this.color, this.active, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: active ? color : color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: active ? color : color.withValues(alpha: 0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: active ? Colors.white : color)),
      const SizedBox(width: 5),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(color: active ? Colors.white.withValues(alpha: 0.25) : color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
        child: Text('$count', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: active ? Colors.white : color)),
      ),
    ]),
  ));
}

class _SCard extends StatelessWidget {
  final String label, value; final IconData icon; final Color color; final bool isDark;
  const _SCard(this.label, this.value, this.icon, this.color, this.isDark);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    decoration: BoxDecoration(
      color: isDark ? AppTheme.cardDark : Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: 0.2)),
      boxShadow: isDark ? [] : [BoxShadow(color: color.withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 15),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 19, color: color),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 1),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w500, color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );
}

class _Empty extends StatelessWidget {
  final IconData icon; final String title, subtitle;
  const _Empty(this.icon, this.title, this.subtitle);
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppTheme.primarySoft.withValues(alpha: 0.3), shape: BoxShape.circle), child: Icon(icon, size: 44, color: AppTheme.primary)),
        const SizedBox(height: 14),
        Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 6),
        Text(subtitle, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12.5, color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight)),
      ]),
    );
  }
}
