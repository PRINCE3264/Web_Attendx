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
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.3),
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
                          MaterialPageRoute(builder: (_) => const AllEmployeesScreen()),
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
                      subtitle: 'Waiting TL',
                      icon: Icons.hourglass_top,
                      color: const Color(0xFFF59E0B),
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

              const SizedBox(height: 24),

              // Department Attendance Breakdown Bar Chart
              Container(
                padding: const EdgeInsets.all(20),
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
                        Text(
                          'Department Attendance Breakdown',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(Icons.bar_chart, color: AppTheme.primary, size: 20),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 100,
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (val, meta) {
                                  switch (val.toInt()) {
                                    case 0:
                                      return const Text('Mobile', style: TextStyle(fontSize: 11));
                                    case 1:
                                      return const Text('Backend', style: TextStyle(fontSize: 11));
                                    case 2:
                                      return const Text('UI/Design', style: TextStyle(fontSize: 11));
                                    default:
                                      return const Text('');
                                  }
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                                getTitlesWidget: (val, meta) => Text(
                                  '${val.toInt()}%',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: const FlGridData(show: true, drawVerticalLine: false),
                          borderData: FlBorderData(show: false),
                          barGroups: [
                            BarChartGroupData(x: 0, barRods: [
                              BarChartRodData(toY: 92, color: AppTheme.primary, width: 22, borderRadius: BorderRadius.circular(6)),
                            ]),
                            BarChartGroupData(x: 1, barRods: [
                              BarChartRodData(toY: 86, color: AppTheme.secondary, width: 22, borderRadius: BorderRadius.circular(6)),
                            ]),
                            BarChartGroupData(x: 2, barRods: [
                              BarChartRodData(toY: 96, color: AppTheme.accent, width: 22, borderRadius: BorderRadius.circular(6)),
                            ]),
                          ],
                        ),
                      ),
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

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
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
                          MaterialPageRoute(builder: (_) => const ReportGeneratorScreen()),
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
                          MaterialPageRoute(builder: (_) => const AllEmployeesScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
