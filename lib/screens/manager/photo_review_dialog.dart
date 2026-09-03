import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/attendance_model.dart';
import '../../models/user_model.dart';
import '../shared/custom_widgets.dart';

class PhotoReviewDialog extends StatefulWidget {
  final AttendanceModel attendance;
  final UserModel manager;
  final Function(AttendanceModel) onApproved;
  final Function(AttendanceModel, String) onRejected;

  const PhotoReviewDialog({
    super.key,
    required this.attendance,
    required this.manager,
    required this.onApproved,
    required this.onRejected,
  });

  @override
  State<PhotoReviewDialog> createState() => _PhotoReviewDialogState();
}

class _PhotoReviewDialogState extends State<PhotoReviewDialog> {
  final _reasonController = TextEditingController();
  bool _showRejectInput = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final att = widget.attendance;
    final timeFormatted = att.clockInTime != null
        ? DateFormat('hh:mm:ss a').format(att.clockInTime!)
        : 'Time not recorded';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? AppTheme.cardDark : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                    child: const Icon(Icons.verified_user, color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attendance Verification',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Review selfie and authorize clock-in',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Timing Status Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: att.isLate
                      ? const Color(0xFFFEF2F2)
                      : (att.isGracePeriod ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: att.isLate
                        ? const Color(0xFFFCA5A5)
                        : (att.isGracePeriod ? const Color(0xFFFDE68A) : const Color(0xFFA7F3D0)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      att.isLate
                          ? Icons.warning_amber_rounded
                          : (att.isGracePeriod ? Icons.schedule : Icons.check_circle),
                      color: att.isLate
                          ? const Color(0xFFDC2626)
                          : (att.isGracePeriod ? const Color(0xFFD97706) : const Color(0xFF059669)),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            att.isLate
                                ? 'LATE - PENDING APPROVAL'
                                : (att.isGracePeriod ? 'GRACE PERIOD CLOCK-IN' : 'ON-TIME CLOCK-IN'),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: att.isLate
                                  ? const Color(0xFF991B1B)
                                  : (att.isGracePeriod ? const Color(0xFF92400E) : const Color(0xFF065F46)),
                            ),
                          ),
                          Text(
                            att.isLate
                                ? 'Late by ${att.lateMinutes} mins (Office start: 09:30 AM | Grace ends: 09:45 AM)'
                                : (att.isGracePeriod
                                    ? 'Clocked in during 15-min grace window ($timeFormatted)'
                                    : 'Clocked in on time at $timeFormatted'),
                            style: TextStyle(
                              fontSize: 11,
                              color: att.isLate
                                  ? const Color(0xFFB91C1C)
                                  : (att.isGracePeriod ? const Color(0xFFB45309) : const Color(0xFF047857)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Employee Info Row
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDarkAlt : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      child: ClipOval(
                        child: PhotoDisplayWidget(
                          photoUrl: att.employeeAvatar,
                          size: 40,
                          borderRadius: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            att.employeeName,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            '${att.employeeCode} • ${att.teamName}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(status: att.status, isCompact: true),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Photo Container
              Center(
                child: Container(
                  height: 260,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        PhotoDisplayWidget(
                          photoUrl: att.clockInPhotoUrl,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          bottom: 8,
                          left: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, color: Colors.white70, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      timeFormatted,
                                      style: const TextStyle(color: Colors.white, fontSize: 11),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, color: AppTheme.primaryLight, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      att.location ?? 'Office',
                                      style: const TextStyle(color: Colors.white, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Rejection reason input (if toggled)
              if (_showRejectInput) ...[
                TextField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Rejection Reason',
                    hintText: 'e.g., Selfie unclear, wrong location, etc.',
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Action Buttons
              if (!_showRejectInput) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() => _showRejectInput = true);
                        },
                        icon: const Icon(Icons.close, color: AppTheme.danger, size: 18),
                        label: const Text(
                          'Reject',
                          style: TextStyle(color: AppTheme.danger),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.danger),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          widget.onApproved(att);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => setState(() => _showRejectInput = false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final reason = _reasonController.text.trim().isEmpty
                              ? 'Verification photo was rejected by TL'
                              : _reasonController.text.trim();
                          widget.onRejected(att, reason);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.send, size: 16),
                        label: const Text('Confirm Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.danger,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
