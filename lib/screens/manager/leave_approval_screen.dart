import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/leave_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_provider.dart';

class LeaveApprovalScreen extends StatelessWidget {
  final bool isEmbedded;
  const LeaveApprovalScreen({super.key, this.isEmbedded = true});

  void _showRejectionDialog(
    BuildContext context,
    LeaveRequestModel leave,
    UserModel reviewer,
  ) {
    final reasonController = TextEditingController();
    final leaveProv = context.read<LeaveProvider>();

    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: AppTheme.danger, size: 24),
            const SizedBox(width: 10),
            Text(
              'Reject Leave Request',
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
              'Reject leave for ${leave.employeeName} (${leave.leaveType.label}, ${leave.totalDays} Days)?',
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Reason for Rejection *',
                hintText: 'e.g. Critical release deadline, overlap with team members...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim().isEmpty
                  ? 'Leave not approved by ${reviewer.role.name}. Please connect with your supervisor.'
                  : reasonController.text.trim();
              Navigator.pop(dlgCtx);
              await leaveProv.reviewLeave(
                leaveId: leave.leaveId,
                isApproved: false,
                manager: reviewer,
                rejectionReason: reason,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Leave rejected for ${leave.employeeName}.'),
                    backgroundColor: AppTheme.danger,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirm Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final leaveProv = context.watch<LeaveProvider>();
    final reviewer = auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isTL = reviewer?.role == UserRole.manager;
    final pendingLeaves = (isTL && reviewer != null)
        ? leaveProv.getPendingLeavesForTL(reviewer.userId)
        : leaveProv.getPendingLeaves();
    final allLeaves = (isTL && reviewer != null)
        ? leaveProv.getLeavesForTL(reviewer.userId)
        : leaveProv.allLeaves;

    String portalTitle = 'Leave Requests & Approvals';
    String portalSubtitle = 'Review, approve, or reject employee leave applications';
    if (reviewer?.role == UserRole.admin) {
      portalTitle = 'Admin Leave Approval Portal';
      portalSubtitle = 'Company-wide leave applications and absence authorizations';
    } else if (reviewer?.role == UserRole.hr) {
      portalTitle = 'HR Leave & Absence Portal';
      portalSubtitle = 'People & culture company leave oversight and approvals';
    } else if (isTL) {
      portalTitle = 'Team Lead Leave Portal';
      portalSubtitle = 'Department & reportee leave requests';
    }

    return Scaffold(
      appBar: isEmbedded
          ? null
          : AppBar(
              title: Text(
                portalTitle,
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: reviewer?.role == UserRole.admin
                        ? [const Color(0xFFEF4444), const Color(0xFFB91C1C)]
                        : (reviewer?.role == UserRole.hr
                            ? [const Color(0xFF7C3AED), const Color(0xFF5B21B6)]
                            : [AppTheme.primary, const Color(0xFF1E40AF)]),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.beach_access_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            portalTitle,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            portalSubtitle,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Pending Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pending Review (${pendingLeaves.length})',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (pendingLeaves.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${pendingLeaves.length} Action Needed',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (pendingLeaves.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline, color: AppTheme.success, size: 36),
                        SizedBox(height: 8),
                        Text(
                          'All caught up! No pending leave applications.',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...pendingLeaves.map((l) => _buildPendingLeaveCard(context, l, reviewer, isDark)),

              const SizedBox(height: 24),

              // Past Reviewed Leave Applications
              Text(
                'Leave Log & History (${allLeaves.where((l) => l.status != LeaveStatus.pending).length})',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              ...allLeaves.where((l) => l.status != LeaveStatus.pending).map((l) {
                final df = DateFormat('dd MMM yyyy');
                final isApproved = l.status == LeaveStatus.approved;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
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
                                  l.employeeName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  '${l.leaveType.label} • ${df.format(l.startDate)} - ${df.format(l.endDate)} (${l.totalDays} Days)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isApproved ? AppTheme.successSoft : AppTheme.dangerSoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              l.status.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isApproved ? AppTheme.success : AppTheme.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (l.reviewerName != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          '${isApproved ? "✓ Approved" : "✕ Rejected"} by ${l.reviewerName}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isApproved ? AppTheme.success : AppTheme.danger,
                          ),
                        ),
                      ],
                      if (l.rejectionReason != null && l.rejectionReason!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Rejection Reason: ${l.rejectionReason}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF991B1B)),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingLeaveCard(
    BuildContext context,
    LeaveRequestModel l,
    UserModel? reviewer,
    bool isDark,
  ) {
    final leaveProv = context.read<LeaveProvider>();
    final df = DateFormat('dd MMM yyyy');
    final balance = leaveProv.getLeaveBalance(l.employeeId);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
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
                    l.employeeName,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '${l.employeeCode} • ${l.department}',
                    style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${l.totalDays} ${l.totalDays > 1 ? "Days" : "Day"}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDarkAlt : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppTheme.borderDark : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.date_range, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${l.leaveType.label} • ${df.format(l.startDate)} to ${df.format(l.endDate)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDarkAlt : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Reason: ${l.reason}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppTheme.textMutedDark : const Color(0xFF334155),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Employee Leave Quota Status
          Row(
            children: [
              const Text(
                'Available Quota: ',
                style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              Text(
                'CL: ${balance.casualRemaining}  |  SL: ${balance.sickRemaining}  |  EL: ${balance.earnedRemaining}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: reviewer == null
                      ? null
                      : () => _showRejectionDialog(context, l, reviewer),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    side: const BorderSide(color: AppTheme.danger),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: reviewer == null
                      ? null
                      : () async {
                          await leaveProv.reviewLeave(
                            leaveId: l.leaveId,
                            isApproved: true,
                            manager: reviewer,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✓ Approved leave for ${l.employeeName}'),
                                backgroundColor: AppTheme.success,
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
