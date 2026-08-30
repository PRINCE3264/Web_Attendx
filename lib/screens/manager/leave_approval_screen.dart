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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final leaveProv = context.watch<LeaveProvider>();
    final manager = auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pendingLeaves = (manager?.role == UserRole.manager && manager != null)
        ? leaveProv.getPendingLeavesForTL(manager.userId)
        : leaveProv.getPendingLeaves();
    final allLeaves = (manager?.role == UserRole.manager && manager != null)
        ? leaveProv.getLeavesForTL(manager.userId)
        : leaveProv.allLeaves;

    return Scaffold(
      appBar: isEmbedded
          ? null
          : AppBar(
              title: Text(
                'Leave Requests & Approvals',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pending Section
              Text(
                'Pending Review (${pendingLeaves.length})',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (pendingLeaves.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                  ),
                  child: const Center(child: Text('No pending leave applications.')),
                )
              else
                ...pendingLeaves.map((l) => _buildPendingLeaveCard(context, l, manager, isDark)),

              const SizedBox(height: 24),

              // All Leave Applications
              Text(
                'Team Leave Log',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              ...allLeaves.where((l) => l.status != LeaveStatus.pending).map((l) {
                final df = DateFormat('dd MMM yyyy');
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.employeeName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('${l.leaveType.label} • ${df.format(l.startDate)} - ${df.format(l.endDate)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: l.status == LeaveStatus.approved ? AppTheme.successSoft : AppTheme.dangerSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          l.status.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: l.status == LeaveStatus.approved ? AppTheme.success : AppTheme.danger,
                          ),
                        ),
                      ),
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

  Widget _buildPendingLeaveCard(BuildContext context, LeaveRequestModel l, dynamic manager, bool isDark) {
    final leaveProv = context.read<LeaveProvider>();
    final df = DateFormat('dd MMM yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l.employeeName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
              Text('${l.totalDays} Days', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${l.leaveType.label} • ${df.format(l.startDate)} to ${df.format(l.endDate)}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDarkAlt : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Reason: ${l.reason}',
              style: TextStyle(fontSize: 12, color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: manager == null
                      ? null
                      : () => leaveProv.reviewLeave(
                            leaveId: l.leaveId,
                            isApproved: false,
                            manager: manager,
                            rejectionReason: 'Leave denied due to sprint release dependencies',
                          ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    side: const BorderSide(color: AppTheme.danger),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: manager == null
                      ? null
                      : () => leaveProv.reviewLeave(
                            leaveId: l.leaveId,
                            isApproved: true,
                            manager: manager,
                          ),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
