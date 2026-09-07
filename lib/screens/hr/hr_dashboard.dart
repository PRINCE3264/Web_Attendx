
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hr_provider.dart';
import '../shared/custom_widgets.dart';
import 'all_employees_screen.dart';
import 'report_generator_screen.dart';
import 'create_announcement_sheet.dart';
import '../manager/leave_approval_screen.dart';
import '../shared/project_reports_screen.dart';

class HrDashboard extends StatelessWidget {
  const HrDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final hr = context.watch<HrProvider>();
    final user = auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Center(child: Text('Please log in'));
    }

    final totalCount = hr.totalEmployeesCount;
    final presentCount = hr.presentTodayCount;
    final pendingCount = hr.pendingApprovalsCount;
    final lateCount = hr.lateTodayCount;
    final onLeaveCount = hr.onLeaveTodayCount;
    final absentCount = hr.absentTodayCount;
    final rate = hr.companyAttendanceRate;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Profile Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.accent.withValues(alpha: 0.15),
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
                          'HR & People Operations',
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
                          'Executive Administrator • ${user.department}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Overview Banner
              Container(
                padding: const EdgeInsets.all(20),
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
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Company Attendance Rate',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${rate.toStringAsFixed(1)}%',
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$presentCount of $totalCount employees clocked in today (${DateFormat('dd MMM yyyy').format(DateTime.now())})',
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.analytics, color: Colors.white, size: 32),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // AI Insights Card
              _buildAiInsightsCard(isDark, hr),

              const SizedBox(height: 20),

              // KPI Grid (Row 1)
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Total Workforce',
                      value: '$totalCount',
                      subtitle: 'Active employees',
                      icon: Icons.groups,
                      color: AppTheme.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AllEmployeesScreen(isEmbedded: false)),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Present Today',
                      value: '$presentCount',
                      subtitle: '${(presentCount / (totalCount > 0 ? totalCount : 1) * 100).toStringAsFixed(0)}% on duty',
                      icon: Icons.check_circle,
                      color: AppTheme.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // KPI Grid (Row 2 - Late & Leaves)
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Late Clock-Ins',
                      value: '$lateCount',
                      subtitle: 'After 09:45 AM',
                      icon: Icons.alarm,
                      color: AppTheme.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'On Approved Leave',
                      value: '$onLeaveCount',
                      subtitle: 'Approved off',
                      icon: Icons.beach_access,
                      color: AppTheme.secondary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LeaveApprovalScreen(isEmbedded: false)),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // KPI Grid (Row 3 - Pending & Absent)
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Pending Reviews',
                      value: '$pendingCount',
                      subtitle: 'Leave / Clock-in',
                      icon: Icons.hourglass_top,
                      color: const Color(0xFFF59E0B),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LeaveApprovalScreen(isEmbedded: false)),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Absent / Off',
                      value: '$absentCount',
                      subtitle: 'Unplanned',
                      icon: Icons.person_off,
                      color: AppTheme.danger,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

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
                    color: isDark ? AppTheme.cardDark : AppTheme.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.assignment_turned_in_outlined, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Company Daily Project Work Reports (${hr.dailyProjectReports.length} Submitted)',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.primary),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Automated 30-Day HR Email Quick Banner
              InkWell(
                onTap: () async {
                  final res = await hr.sendAutomated30DayHrEmail();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Automated 30-Day Attendance Report emailed to HR (${res['totalPresentDays']} Present / ${res['totalAbsentDays']} Absent)!',
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: AppTheme.success,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.cardDark : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mark_email_read_rounded, color: Color(0xFF10B981), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Automated 30-Day HR Email Engine (Send Excel + PDF)',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF065F46)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'AUTO-EMAIL',
                          style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Department Attendance Breakdown Bar Chart
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Department Attendance',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.bar_chart_rounded, color: AppTheme.primary, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final deptRates = hr.departmentAttendanceRates;
                        final deptList = deptRates.entries.toList();
                        final double itemWidth = 76.0;
                        final double requiredWidth = deptList.length * itemWidth;
                        final double chartWidth = requiredWidth > constraints.maxWidth ? requiredWidth : constraints.maxWidth;

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: requiredWidth > constraints.maxWidth ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
                          child: SizedBox(
                            width: chartWidth,
                            height: 220,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: 115,
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      final deptName = deptList[groupIndex].key;
                                      return BarTooltipItem(
                                        '$deptName\n',
                                        GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                        children: [
                                          TextSpan(
                                            text: '${rod.toY.toStringAsFixed(1)}%',
                                            style: GoogleFonts.inter(color: Colors.lightBlueAccent, fontWeight: FontWeight.w600, fontSize: 11),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 42,
                                      getTitlesWidget: (val, meta) {
                                        final idx = val.toInt();
                                        if (idx < 0 || idx >= deptList.length) return const SizedBox.shrink();
                                        String rawName = deptList[idx].key;
                                        String name = rawName;
                                        if (rawName == 'Engineering & Technology' || rawName == 'Engineering') name = 'Engineering';
                                        if (rawName == 'Human Resources' || rawName == 'HR & Admin') name = 'HR & Admin';
                                        if (rawName == 'Design & UI' || rawName == 'Design') name = 'Design & UI';
                                        if (rawName == 'Operations' || rawName == 'Corporate Administration') name = 'Operations';

                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: SizedBox(
                                            width: 70,
                                            child: Text(
                                              name,
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                height: 1.15,
                                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 36,
                                      interval: 50,
                                      getTitlesWidget: (val, meta) {
                                        if (val < 0 || val > 100) return const SizedBox.shrink();
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 4),
                                          child: Text(
                                            '${val.toInt()}%',
                                            textAlign: TextAlign.right,
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: const Color(0xFF94A3B8),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 22,
                                      getTitlesWidget: (val, meta) {
                                        final idx = val.toInt();
                                        if (idx < 0 || idx >= deptList.length) return const SizedBox.shrink();
                                        return Text(
                                          '${deptList[idx].value.toStringAsFixed(0)}%',
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primary,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: 50,
                                  getDrawingHorizontalLine: (val) => FlLine(
                                    color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                                    strokeWidth: 1,
                                    dashArray: [4, 4],
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: List.generate(deptList.length, (idx) {
                                  final val = deptList[idx].value;
                                  return BarChartGroupData(
                                    x: idx,
                                    barRods: [
                                      BarChartRodData(
                                        toY: val.clamp(0.0, 100.0),
                                        width: 22,
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                        gradient: LinearGradient(
                                          colors: idx % 3 == 0
                                              ? const [Color(0xFF3B82F6), Color(0xFF1D4ED8)]
                                              : (idx % 3 == 1
                                                  ? const [Color(0xFF06B6D4), Color(0xFF0284C7)]
                                                  : const [Color(0xFF2563EB), Color(0xFF1E40AF)]),
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Quick Actions (30-Day Report Generator & Email)
              Text(
                'HR Audit & Report Management',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Material(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.hardEdge,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                    ),
                  ),
                  child: Column(
                    children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primarySoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.picture_as_pdf, color: AppTheme.primary),
                      ),
                      title: Text(
                        'Audit Reports (Daily, Monthly, 30-Day)',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        'Export PDF, CSV, Excel, and dispatch automated emails to leadership.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ReportGeneratorScreen(isEmbedded: false)),
                        );
                      },
                    ),
                    const Divider(height: 20),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.successSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.badge, color: AppTheme.success),
                      ),
                      title: Text(
                        'All Employees Directory',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        'Inspect individual attendance histories, breaks, and team mappings.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AllEmployeesScreen(isEmbedded: false)),
                        );
                      },
                    ),
                    const Divider(height: 20),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.beach_access, color: Color(0xFFD97706)),
                      ),
                      title: Text(
                        'Leave Requests & Authorizations',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        'Review, approve, or reject employee leave applications company-wide.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LeaveApprovalScreen(isEmbedded: false)),
                        );
                      },
                    ),
                    const Divider(height: 20),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.campaign, color: AppTheme.accent),
                      ),
                      title: Text(
                        'Broadcast Announcements',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        'Publish holidays or general notices to all employees or managers.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (_) => const CreateAnnouncementSheet(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildAiInsightsCard(bool isDark, HrProvider hr) {
    final lowestDeptStr = hr.lowestDepartmentInsight;
    final mostLateStr = hr.mostLateEmployeeInsight;
    final highestAttendanceStr = hr.highestAttendanceEmployeeInsight;
    final below75Count = hr.employeesBelow75Count;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF374151) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF4B5563) : const Color(0xFFF59E0B).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : const Color(0xFFF59E0B).withValues(alpha: 0.1),
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
              const Icon(Icons.psychology, color: Color(0xFFD97706), size: 22),
              const SizedBox(width: 8),
              Text(
                'AI Attendance Insights',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF92400E),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Auto-Detected',
                  style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightRow(Icons.trending_down, lowestDeptStr, isDark),
          const SizedBox(height: 10),
          _buildInsightRow(Icons.watch_later, mostLateStr, isDark),
          const SizedBox(height: 10),
          _buildInsightRow(Icons.verified, highestAttendanceStr, isDark),
          const SizedBox(height: 10),
          _buildInsightRow(
            Icons.warning_amber,
            '$below75Count employee${below75Count == 1 ? '' : 's'} below 75%',
            isDark,
            isWarning: below75Count > 0,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(IconData icon, String text, bool isDark, {bool isWarning = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isWarning ? AppTheme.danger : (isDark ? Colors.white70 : Colors.black87)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isWarning ? FontWeight.w600 : FontWeight.w500,
              color: isWarning ? AppTheme.danger : (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ),
      ],
    );
  }
}
