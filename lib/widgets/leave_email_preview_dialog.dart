import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/leave_model.dart';
import '../models/user_model.dart';
import '../config/app_theme.dart';
import '../services/leave_email_template_service.dart';

class LeaveEmailPreviewDialog extends StatelessWidget {
  final LeaveRequestModel leave;
  final UserModel employee;
  final String actionType; // 'applied', 'approved', 'rejected'
  final String? reviewerName;
  final String? rejectionReason;

  const LeaveEmailPreviewDialog({
    super.key,
    required this.leave,
    required this.employee,
    this.actionType = 'approved',
    this.reviewerName,
    this.rejectionReason,
  });

  static void show(
    BuildContext context, {
    required LeaveRequestModel leave,
    required UserModel employee,
    String actionType = 'approved',
    String? reviewerName,
    String? rejectionReason,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LeaveEmailPreviewDialog(
        leave: leave,
        employee: employee,
        actionType: actionType,
        reviewerName: reviewerName,
        rejectionReason: rejectionReason,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final df = DateFormat('dd MMM yyyy');
    final startDateStr = df.format(leave.startDate);
    final endDateStr = df.format(leave.endDate);

    Color statusColor;
    Color statusBg;
    IconData statusIcon;
    String statusLabel;
    String headlineText;

    if (actionType == 'approved' || leave.status == LeaveStatus.approved) {
      statusLabel = 'Approved';
      statusColor = const Color(0xFF16A34A);
      statusBg = const Color(0xFFDCFCE7);
      statusIcon = Icons.check_circle_rounded;
      headlineText = 'Your leave application has been successfully approved.';
    } else if (actionType == 'rejected' || leave.status == LeaveStatus.rejected) {
      statusLabel = 'Rejected';
      statusColor = const Color(0xFFDC2626);
      statusBg = const Color(0xFFFEE2E2);
      statusIcon = Icons.cancel_rounded;
      headlineText = 'Your leave application has been reviewed and rejected.';
    } else {
      statusLabel = 'Pending Approval';
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFFEF3C7);
      statusIcon = Icons.hourglass_top_rounded;
      headlineText = 'Your leave application has been submitted successfully.';
    }

    final String reviewerInfo = reviewerName ?? (leave.reviewerName ?? 'HR Team');

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgDark : const Color(0xFFF1F5F9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mark_email_read_rounded, color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Official Branded Email Preview',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.textMainLight,
                        ),
                      ),
                      Text(
                        'Envision Beyond India Private Limited Mail Template',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Email Content Scroll Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 580),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Top Brand Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'envision',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      'beyond',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFFEF4444),
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'PEOPLE | TECHNOLOGY | A BETTER TOMORROW',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF93C5FD),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'www.envisionbeyond.com',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 2. Email Body Content
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hello ${employee.name.split(' ')[0]},',
                                        style: GoogleFonts.outfit(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        headlineText,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: const Color(0xFF475569),
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'We\'re glad to have you with us!',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: statusBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(statusIcon, color: statusColor, size: 32),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Primary Action Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'View Application Details',
                                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // 3. Application Details Card
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    color: const Color(0xFFF1F5F9),
                                    child: Text(
                                      'APPLICATION DETAILS',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1E293B),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  _buildDetailRow('Application ID', leave.leaveId.toUpperCase()),
                                  _buildDetailRow('Employee Name', employee.name),
                                  _buildDetailRow('Department', employee.department),
                                  _buildDetailRow('Leave Type', leave.leaveType.label),
                                  _buildDetailRow('From Date', startDateStr),
                                  _buildDetailRow('To Date', endDateStr),
                                  _buildDetailRow('Total Days', '${leave.totalDays} Days'),
                                  _buildDetailRowWidget(
                                    'Status',
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusBg,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(statusIcon, size: 14, color: statusColor),
                                          const SizedBox(width: 6),
                                          Text(
                                            statusLabel,
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: statusColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  _buildDetailRow('Approved / Reviewed By', reviewerInfo),
                                  _buildDetailRow('Message / Reason', leave.reason.isNotEmpty ? leave.reason : 'Your leave request has been processed.'),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // 4. Feature Pills (Manage, Track, Support)
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFeatureBox(
                                    icon: Icons.calendar_month_rounded,
                                    title: 'Manage',
                                    subtitle: 'Your Applications',
                                    color: const Color(0xFF2563EB),
                                    bg: const Color(0xFFEFF6FF),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildFeatureBox(
                                    icon: Icons.description_rounded,
                                    title: 'Track',
                                    subtitle: 'Request Status',
                                    color: const Color(0xFF16A34A),
                                    bg: const Color(0xFFF0FDF4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildFeatureBox(
                                    icon: Icons.headset_mic_rounded,
                                    title: 'Get Support',
                                    subtitle: 'We\'re here to help',
                                    color: const Color(0xFF9333EA),
                                    bg: const Color(0xFFFAF5FF),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            Text(
                              'If you have any questions, feel free to reach out to the HR team.',
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Regards,\nEnvision Beyond India Private Limited',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              'People | Technology | A Better Tomorrow',
                              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),

                      // 5. Dark Footer
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        color: const Color(0xFF0F172A),
                        child: Column(
                          children: [
                            Text(
                              'Envision Beyond India Private Limited • Bangalore, India',
                              style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Email: hr@envisionbeyond.com • Web: www.envisionbeyond.com',
                              style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              border: Border(top: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Close Preview'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await LeaveEmailTemplateService.sendLeaveStatusEmail(
                        leave: leave,
                        employee: employee,
                        actionType: actionType,
                        reviewerName: reviewerName,
                        rejectionReason: rejectionReason,
                      );
                    },
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Dispatch Mail Now'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowWidget(String label, Widget widget) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
            ),
          ),
          widget,
        ],
      ),
    );
  }

  Widget _buildFeatureBox({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 9.5, color: color.withValues(alpha: 0.8)),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
