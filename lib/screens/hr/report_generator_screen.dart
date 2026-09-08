import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/report_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hr_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/department_model.dart';
import '../../models/team_model.dart';

class ReportGeneratorScreen extends StatefulWidget {
  final bool isEmbedded;
  final String initialReportType; // 'monthly', 'employee', 'export'

  const ReportGeneratorScreen({
    super.key,
    this.isEmbedded = true,
    this.initialReportType = 'monthly',
  });

  @override
  State<ReportGeneratorScreen> createState() => _ReportGeneratorScreenState();
}

class _ReportGeneratorScreenState extends State<ReportGeneratorScreen> {
  late String _currentType;
  late final TextEditingController _emailController;
  final _searchController = TextEditingController();
  String _selectedDept = 'All';
  String _selectedTeam = 'All';

  @override
  void initState() {
    super.initState();
    _currentType = widget.initialReportType;
    final user = context.read<AuthProvider>().currentUser;
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void didUpdateWidget(covariant ReportGeneratorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialReportType != widget.initialReportType) {
      setState(() {
        _currentType = widget.initialReportType;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showEmailDialog() {
    final hr = context.read<HrProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.mark_email_read, color: AppTheme.primary),
            const SizedBox(width: 10),
            Text(
              'Dispatch Email Report',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trigger automated email delivery of the attendance audit to executive management & finance.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Recipient Emails',
                prefixIcon: Icon(Icons.email, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await hr.sendReportEmail(
                emailAddress: _emailController.text.trim(),
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Report dispatched successfully!'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Send Email'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
          ),
        ],
      ),
    );
  }

  void _showAutomated30DayEmailModal(BuildContext context, HrProvider hr) {
    final reports = hr.generateAll30DayReports();
    int totalPresent = 0;
    int totalAbsent = 0;
    for (final r in reports) {
      totalPresent += r.presentDays;
      totalAbsent += r.absentDays;
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.mark_email_read_rounded,
                    color: Color(0xFF10B981),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Automated 30-Day HR Email Engine',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Calculates employee Present/Absent counts & sends Excel + PDF to HR',
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
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(bottomSheetContext),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
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
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 16,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Cycle: Every 30 Days',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'STATUS: ACTIVE',
                          style: TextStyle(
                            color: AppTheme.success,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'HR & Admin Profile Emails: ${hr.allEmployees.where((u) => u.role == UserRole.hr || u.role == UserRole.admin).map((u) => u.email.trim()).where((e) => e.isNotEmpty).toSet().join(', ')}',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: isDark
                          ? AppTheme.textMutedDark
                          : AppTheme.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.successSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$totalPresent Days',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.success,
                          ),
                        ),
                        const Text(
                          'Total Present Days',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$totalAbsent Days',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.danger,
                          ),
                        ),
                        const Text(
                          'Total Absent Days',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${hr.companyAttendanceRate.toStringAsFixed(1)}%',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.primary,
                          ),
                        ),
                        const Text(
                          'Workforce Rate',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Employee 30-Day Attendance Breakdown',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                  ),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: reports.length,
                  separatorBuilder: (_, _) => const Divider(height: 12),
                  itemBuilder: (ctx, idx) {
                    final r = reports[idx];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.employeeName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '${r.employeeCode} • ${r.department}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.successSoft,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Present: ${r.presentDays}',
                                style: const TextStyle(
                                  color: AppTheme.success,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.dangerSoft,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Absent: ${r.absentDays}',
                                style: const TextStyle(
                                  color: AppTheme.danger,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(bottomSheetContext);
                final res = await hr.sendAutomated30DayHrEmail();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.mark_email_read_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dispatch Automated Email to HR Now',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Includes Excel & PDF attachments',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCodePreview(String title, String content, String label) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      content,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.lightGreenAccent,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final hr = context.read<HrProvider>();
                  if (label.toLowerCase().contains('excel')) {
                    await hr.exportAndShareExcel(context);
                  } else {
                    await hr.exportAndShareCsv(context);
                  }
                },
                icon: const Icon(Icons.download, size: 18),
                label: Text('Export & Save $label File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hr = context.watch<HrProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allReports = hr.generateAll30DayReports();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : const Color(0xFFF8FAFC),
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: Text(
                _currentType == 'monthly'
                    ? 'Monthly Attendance Report'
                    : (_currentType == 'employee'
                          ? 'Employee Performance Audit'
                          : 'Export & Data Center'),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Segmented Chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: isDark ? AppTheme.cardDark : Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSegmentChip(
                      type: 'monthly',
                      label: 'Monthly Report',
                      icon: Icons.calendar_month_rounded,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildSegmentChip(
                      type: 'employee',
                      label: 'Employee Report',
                      icon: Icons.badge_rounded,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildSegmentChip(
                      type: 'export',
                      label: 'Export Excel/PDF',
                      icon: Icons.ios_share_rounded,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),

            // Dynamic Body Content based on _currentType
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildBodyForCurrentType(
                  context,
                  isDark,
                  hr,
                  allReports,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentChip({
    required String type,
    required String label,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _currentType == type;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _currentType = type;
        });
      },
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected
            ? Colors.white
            : (isDark ? Colors.white70 : AppTheme.primary),
      ),
      label: Text(label),
      labelStyle: GoogleFonts.outfit(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 13,
        color: isSelected
            ? Colors.white
            : (isDark ? Colors.white70 : Colors.black87),
      ),
      selectedColor: AppTheme.primary,
      backgroundColor: isDark
          ? const Color(0xFF334155)
          : const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppTheme.primary : Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildBodyForCurrentType(
    BuildContext context,
    bool isDark,
    HrProvider hr,
    List<MonthlyAttendanceReport> allReports,
  ) {
    switch (_currentType) {
      case 'employee':
        return _buildEmployeeReportView(context, isDark, hr, allReports);
      case 'export':
        return _buildExportCenterView(context, isDark, hr, allReports);
      case 'monthly':
      default:
        return _buildMonthlyReportView(context, isDark, hr, allReports);
    }
  }

  // ==========================================
  // VIEW 1: MONTHLY REPORT VIEW
  // ==========================================
  Widget _buildMonthlyReportView(
    BuildContext context,
    bool isDark,
    HrProvider hr,
    List<MonthlyAttendanceReport> reports,
  ) {
    final avgRate = hr.companyAttendanceRate;
    final totalEmp = hr.totalEmployeesCount;

    return Column(
      key: const ValueKey('monthly_report_view'),
      children: [
        // Monthly Audit Engine Banner
        Container(
          padding: const EdgeInsets.all(18),
          margin: const EdgeInsets.all(16),
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
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Company Monthly Audit Engine',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Period: ${DateFormat('dd MMM').format(DateTime.now().subtract(const Duration(days: 30)))} - ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBannerStat(
                    'Workforce Rate',
                    '${avgRate.toStringAsFixed(1)}%',
                  ),
                  _buildBannerStat('Total Audited', '$totalEmp Employees'),
                  _buildBannerStat('Cycle Days', '30 Days'),
                ],
              ),
            ],
          ),
        ),

        // List Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Employee Attendance Breakdown',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${reports.length} Records',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // Reports List
        Expanded(
          child: reports.isEmpty
              ? _buildEmptyState('No monthly attendance data available.')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final rep = reports[index];
                    return _buildMonthlyCard(context, rep, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBannerStat(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          val,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildMonthlyCard(
    BuildContext context,
    MonthlyAttendanceReport rep,
    bool isDark,
  ) {
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rep.employeeName,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${rep.employeeCode} • ${rep.department}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.textMutedDark
                            : AppTheme.textMutedLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: rep.attendancePercentage >= 90
                      ? AppTheme.successSoft
                      : AppTheme.warningSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: rep.attendancePercentage >= 90
                        ? AppTheme.success.withValues(alpha: 0.3)
                        : AppTheme.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${rep.attendancePercentage}% Rate',
                  style: TextStyle(
                    color: rep.attendancePercentage >= 90
                        ? AppTheme.success
                        : AppTheme.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildStatCell(
                  'Present Days',
                  '${rep.presentDays} / ${rep.totalWorkingDays}',
                  AppTheme.success,
                ),
              ),
              Expanded(
                child: _buildStatCell(
                  'Absent Days',
                  '${rep.absentDays}',
                  AppTheme.danger,
                ),
              ),
              Expanded(
                child: _buildStatCell(
                  'Logged Hours',
                  '${rep.totalHoursWorked} hrs',
                  AppTheme.primary,
                ),
              ),
              Expanded(
                child: _buildStatCell(
                  'Avg Shift',
                  '${rep.averageDailyHours} hrs',
                  AppTheme.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // VIEW 2: EMPLOYEE REPORT VIEW
  // ==========================================
  Widget _buildEmployeeReportView(
    BuildContext context,
    bool isDark,
    HrProvider hr,
    List<MonthlyAttendanceReport> reports,
  ) {
    // Filter by Search & Dept & Team
    final filtered = reports.where((r) {
      final matchesSearch =
          _searchController.text.isEmpty ||
          r.employeeName.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          ) ||
          r.employeeCode.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          );
          
      final user = FirestoreService().getAllUsers().cast<UserModel?>().firstWhere((u) => u?.userId == r.employeeId, orElse: () => null);
      final deptName = user?.department ?? r.department;
      final teamName = user?.teamName ?? '';

      final matchesDept =
          _selectedDept == 'All' ||
          deptName.toLowerCase() == _selectedDept.toLowerCase();
          
      final matchesTeam = 
          _selectedTeam == 'All' || 
          teamName.toLowerCase() == _selectedTeam.toLowerCase();

      return matchesSearch && matchesDept && matchesTeam;
    }).toList();

    return Column(
      key: const ValueKey('employee_report_view'),
      children: [
        // Search & Filter Box
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
            ),
          ),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search employee name or code...',
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
                  fillColor: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              StreamBuilder<List<DepartmentModel>>(
                stream: FirestoreService().departmentsStream,
                builder: (context, snapshot) {
                  final depts = snapshot.data ?? FirestoreService().getAllDepartments();
                  final deptNames = ['All', ...depts.map((d) => d.name)];
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: deptNames.map((dept) {
                        final isSel = _selectedDept == dept;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            selected: isSel,
                            label: Text(dept),
                            labelStyle: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            ),
                            selectedColor: AppTheme.primary,
                            backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                            onSelected: (_) {
                              setState(() {
                                _selectedDept = dept;
                                _selectedTeam = 'All'; // reset team filter
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }
              ),
              if (_selectedDept != 'All') ...[
                const SizedBox(height: 10),
                StreamBuilder<List<TeamModel>>(
                  stream: FirestoreService().teamsStream,
                  builder: (context, snapshot) {
                    final depts = FirestoreService().getAllDepartments();
                    final selectedDeptId = depts.firstWhere((d) => d.name == _selectedDept, orElse: () => depts.first).departmentId;
                    final allTeams = snapshot.data ?? FirestoreService().getAllTeams();
                    final teams = allTeams.where((t) => t.departmentId == selectedDeptId).toList();
                    final teamNames = ['All', ...teams.map((t) => t.name)];

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: teamNames.map((teamName) {
                          final isSel = _selectedTeam == teamName;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              selected: isSel,
                              label: Text(teamName),
                              labelStyle: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                              ),
                              selectedColor: AppTheme.primary,
                              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                              onSelected: (_) {
                                setState(() {
                                  _selectedTeam = teamName;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }
                ),
              ],
            ],
          ),
        ),

        // List Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Individual Employee Performance',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${filtered.length} Found',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // List
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState('No employee records found matching filter.')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final rep = filtered[index];
                    return _buildEmployeeCard(context, rep, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmployeeCard(
    BuildContext context,
    MonthlyAttendanceReport rep,
    bool isDark,
  ) {
    final hr = context.read<HrProvider>();
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
                  rep.employeeName.isNotEmpty
                      ? rep.employeeName[0].toUpperCase()
                      : 'E',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rep.employeeName,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'ID: ${rep.employeeCode} • Dept: ${rep.department}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.textMutedDark
                            : AppTheme.textMutedLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => hr.exportSingleEmployeeCsv(context, rep),
                icon: const Icon(Icons.download, size: 14),
                label: const Text('Export'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCell(
                  'Rate',
                  '${rep.attendancePercentage}%',
                  AppTheme.primary,
                ),
              ),
              Expanded(
                child: _buildStatCell(
                  'Present',
                  '${rep.presentDays} days',
                  AppTheme.success,
                ),
              ),
              Expanded(
                child: _buildStatCell(
                  'Late',
                  '${rep.lateArrivals} times',
                  AppTheme.warning,
                ),
              ),
              Expanded(
                child: _buildStatCell(
                  'Total Hours',
                  '${rep.totalHoursWorked} hrs',
                  AppTheme.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // VIEW 3: EXPORT EXCEL/PDF CENTER VIEW
  // ==========================================
  Widget _buildExportCenterView(
    BuildContext context,
    bool isDark,
    HrProvider hr,
    List<MonthlyAttendanceReport> reports,
  ) {
    return SingleChildScrollView(
      key: const ValueKey('export_center_view'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero Export Center Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.import_export_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Export & Data Integration Center',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Generate formal audit PDF documents, Excel sheets & raw CSV files',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildFormatBadge('📄 PDF Document'),
                    _buildFormatBadge('📊 Excel .xlsx'),
                    _buildFormatBadge('📑 Raw CSV'),
                    _buildFormatBadge('✉️ Email Dispatch'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Select Export Format',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 12),

          // 1. PDF Export Action Card
          _buildExportOptionCard(
            context: context,
            isDark: isDark,
            title: 'Formal PDF Audit Report',
            description: 'Print-ready PDF document with corporate headers, employee percentages, and signature line.',
            icon: Icons.picture_as_pdf_rounded,
            color: const Color(0xFFEF4444),
            buttonLabel: 'Generate & Print PDF',
            onTap: () => hr.exportAndPrintPdfReport(context),
            isLoading: hr.isGeneratingReport,
          ),

          const SizedBox(height: 12),

          // 2. Excel Export Action Card
          _buildExportOptionCard(
            context: context,
            isDark: isDark,
            title: 'MS Excel Sheet (.tsv / .xlsx)',
            description: 'Structured tabular data ready for Microsoft Excel, Google Sheets, and Payroll integration.',
            icon: Icons.table_chart_rounded,
            color: const Color(0xFF10B981),
            buttonLabel: 'Export Excel Sheet',
            onTap: () => hr.exportAndShareExcel(context),
            onPreviewTap: () {
              final excelData = hr.getExcelExportContent();
              _showCodePreview('MS Excel Tabular Data', excelData, 'Excel');
            },
            isLoading: hr.isGeneratingReport,
          ),

          const SizedBox(height: 12),

          // 3. CSV Export Action Card
          _buildExportOptionCard(
            context: context,
            isDark: isDark,
            title: 'Raw CSV Data Sheet',
            description: 'Standard comma-separated file format for database imports and custom analytics.',
            icon: Icons.grid_on_rounded,
            color: const Color(0xFF3B82F6),
            buttonLabel: 'Export CSV Sheet',
            onTap: () => hr.exportAndShareCsv(context),
            onPreviewTap: () {
              final csvData = hr.getCsvExportContent();
              _showCodePreview('Raw CSV Data Sheet', csvData, 'CSV');
            },
            isLoading: hr.isGeneratingReport,
          ),

          const SizedBox(height: 12),

          // 4. Automated 30-Day HR Email Engine Card
          _buildExportOptionCard(
            context: context,
            isDark: isDark,
            title: 'Automated 30-Day HR Email Engine',
            description: 'Auto-calculates employee Present & Absent counts every 30 days and emails Excel sheet + PDF audit report directly to HR.',
            icon: Icons.mark_email_read_rounded,
            color: const Color(0xFF10B981),
            buttonLabel: 'Dispatch 30-Day HR Email',
            onTap: () => _showAutomated30DayEmailModal(context, hr),
            isLoading: hr.isGeneratingReport,
          ),
        ],
      ),
    );
  }

  Widget _buildFormatBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildExportOptionCard({
    required BuildContext context,
    required bool isDark,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String buttonLabel,
    required VoidCallback onTap,
    VoidCallback? onPreviewTap,
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: isDark
                        ? AppTheme.textMutedDark
                        : AppTheme.textMutedLight,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : onTap,
                      icon: isLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(icon, size: 15),
                      label: Text(
                        buttonLabel,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    if (onPreviewTap != null)
                      OutlinedButton.icon(
                        onPressed: onPreviewTap,
                        icon: const Icon(Icons.visibility_outlined, size: 14),
                        label: Text(
                          'Preview',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.find_in_page_outlined,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCell(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
