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

          // Email Content Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: AspectRatio(
                    aspectRatio: 1024 / 1536,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final height = constraints.maxHeight;

                          final topPadding = height * 0.145;
                          final bottomPadding = height * 0.145;
                          final horizontalPadding = width * 0.085;

                          return Stack(
                            children: [
                              // 1. Letterhead Template Background Image
                              Positioned.fill(
                                child: Image.asset(
                                  'assets/mailtemplata.png',
                                  fit: BoxFit.fill,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // 2. Overlay Email Content inside Letterhead Body Window
                              Positioned.fill(
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    horizontalPadding,
                                    topPadding,
                                    horizontalPadding,
                                    bottomPadding,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                                      fontSize: 19,
                                                      fontWeight: FontWeight.w800,
                                                      color: const Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    headlineText,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      color: const Color(0xFF475569),
                                                      height: 1.3,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'We\'re glad to have you with us!',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      color: const Color(0xFF64748B),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: statusBg,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(statusIcon, color: statusColor, size: 22),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 8),

                                        // Primary Action Button
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () {},
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF2563EB),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              elevation: 0,
                                            ),
                                            child: Text(
                                              'View Application Details',
                                              style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 8),

                                        // Application Details Card inside Letterhead
                                        Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          clipBehavior: Clip.hardEdge,
                                          child: Column(
                                            children: [
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                color: const Color(0xFFF1F5F9),
                                                child: Text(
                                                  'APPLICATION DETAILS',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 11,
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
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: statusBg,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(statusIcon, size: 12, color: statusColor),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        statusLabel,
                                                        style: GoogleFonts.outfit(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                          color: statusColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              _buildDetailRow('Reviewed By', reviewerInfo),
                                              _buildDetailRow('Reason / Message', leave.reason.isNotEmpty ? leave.reason : 'Your leave request has been processed.'),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(height: 8),

                                        // Feature Pills (Manage, Track, Support)
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildFeatureBox(
                                                icon: Icons.calendar_month_rounded,
                                                title: 'Manage',
                                                subtitle: 'Applications',
                                                color: const Color(0xFF2563EB),
                                                bg: const Color(0xFFEFF6FF),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: _buildFeatureBox(
                                                icon: Icons.description_rounded,
                                                title: 'Track',
                                                subtitle: 'Status',
                                                color: const Color(0xFF16A34A),
                                                bg: const Color(0xFFF0FDF4),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: _buildFeatureBox(
                                                icon: Icons.headset_mic_rounded,
                                                title: 'Support',
                                                subtitle: 'HR Team',
                                                color: const Color(0xFF9333EA),
                                                bg: const Color(0xFFFAF5FF),
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 8),

                                        Text(
                                          'If you have any questions, feel free to reach out to the HR team.',
                                          style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B)),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Regards,\nEnvision Beyond HR & Management Team',
                                          style: GoogleFonts.outfit(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF1E293B),
                                            height: 1.25,
                                          ),
                                        ),
                                       ],
                                     ),
                                   ),
                                 ),
                               ),
                             ),
                           ],
                         );
                        },
                      ),
                    ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowWidget(String label, Widget widget) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
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
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 8.5, color: color.withValues(alpha: 0.8)),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
