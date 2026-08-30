import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/report_model.dart';
import '../../providers/hr_provider.dart';

class ReportGeneratorScreen extends StatefulWidget {
  const ReportGeneratorScreen({super.key});

  @override
  State<ReportGeneratorScreen> createState() => _ReportGeneratorScreenState();
}

class _ReportGeneratorScreenState extends State<ReportGeneratorScreen> {
  final _emailController = TextEditingController(text: 'executives@company.com');

  @override
  void dispose() {
    _emailController.dispose();
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
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trigger automated email delivery of the 30-day attendance audit to leadership & finance.',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Recipient Emails (comma separated)',
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
              await hr.sendReportEmail(emailAddress: _emailController.text.trim());
            },
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Send Email'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _showCsvPreview(String csvContent) {
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
                  'CSV Export Preview',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    csvContent,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.lightGreenAccent,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CSV ready for download / integration.')),
                );
              },
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Confirm & Save CSV'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hr = context.watch<HrProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reports = hr.generateAll30DayReports();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '30-Day Attendance Reports',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Action Bar (PDF, CSV, Email)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primarySoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.cloud_done, color: AppTheme.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Automated 30-Day Engine',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              'Period: ${DateFormat('dd MMM').format(DateTime.now().subtract(const Duration(days: 30)))} - ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // PDF Export Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: hr.isGeneratingReport ? null : () => hr.exportAndPrintPdfReport(context),
                          icon: const Icon(Icons.picture_as_pdf, size: 16),
                          label: const Text('Export PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // CSV Export Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final csv = hr.getCsvExportContent();
                            _showCsvPreview(csv);
                          },
                          icon: const Icon(Icons.table_view, size: 16),
                          label: const Text('CSV Export'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Automatic Email Trigger
                      IconButton.filled(
                        onPressed: _showEmailDialog,
                        icon: const Icon(Icons.email, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: Colors.white,
                        ),
                        tooltip: 'Send Automated Email',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Calculation Results Table
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final rep = reports[index];
                  return _buildReportItem(context, rep);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem(BuildContext context, MonthlyAttendanceReport rep) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rep.employeeName,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '${rep.employeeCode} • ${rep.department}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    color: rep.attendancePercentage >= 90 ? AppTheme.success : AppTheme.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCell('Present Days', '${rep.presentDays} / ${rep.totalWorkingDays}', AppTheme.success),
              _buildStatCell('Absent Days', '${rep.absentDays}', AppTheme.danger),
              _buildStatCell('Logged Hours', '${rep.totalHoursWorked} hrs', AppTheme.primary),
              _buildStatCell('Avg Shift', '${rep.averageDailyHours} hrs', AppTheme.secondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCell(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: color),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}
