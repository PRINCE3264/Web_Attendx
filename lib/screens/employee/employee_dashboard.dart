import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/attendance_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/report_service.dart';
import '../shared/custom_widgets.dart';
import 'camera_capture_screen.dart';
import 'attendance_history_screen.dart';
import 'break_tracking_sheet.dart';
import 'leave_management_screen.dart';
import 'correction_request_dialog.dart';

class EmployeeDashboard extends StatelessWidget {
  const EmployeeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final attendance = context.watch<AttendanceProvider>();
    final user = auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Center(child: Text('Please log in'));
    }

    final todayRec = attendance.getTodayAttendance(user.userId);
    final history = attendance.getEmployeeHistory(user.userId);
    final report30Day = ReportService.calculate30DayReport(
      employee: user,
      attendanceList: history,
    );

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {},
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Greeting & Live Clock
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
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
                            'Welcome back,',
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
                            '${user.employeeId} • ${user.teamName}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Digital Live Clock
                const DigitalLiveClock(),

                const SizedBox(height: 20),

                // Today's Attendance Status Card
                _buildTodayStatusCard(context, todayRec, user),

                const SizedBox(height: 16),

                // Quick Action Buttons (Leave Portal & Attendance Regularization)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LeaveManagementScreen()),
                          );
                        },
                        icon: const Icon(Icons.beach_access, size: 18, color: AppTheme.secondary),
                        label: const Text('Apply Leave', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (todayRec != null) {
                            showDialog(
                              context: context,
                              builder: (_) => CorrectionRequestDialog(attendance: todayRec),
                            );
                          } else if (history.isNotEmpty) {
                            showDialog(
                              context: context,
                              builder: (_) => CorrectionRequestDialog(attendance: history.first),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No past attendance record available to regularize.')),
                            );
                          }
                        },
                        icon: const Icon(Icons.edit_calendar, size: 18, color: AppTheme.accent),
                        label: const Text('Regularize', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 30-Day Snapshot Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '30-Day Attendance Overview',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AttendanceHistoryScreen(),
                          ),
                        );
                      },
                      child: const Text('View Full History'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // KPI Stat Cards Grid
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Present Days',
                        value: '${report30Day.presentDays}',
                        subtitle: 'of ${report30Day.totalWorkingDays} days',
                        icon: Icons.check_circle_outline,
                        color: AppTheme.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: 'Attendance Rate',
                        value: '${report30Day.attendancePercentage}%',
                        subtitle: '${report30Day.totalHoursWorked}h logged',
                        icon: Icons.pie_chart_outline,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Absent / Leaves',
                        value: '${report30Day.absentDays}',
                        subtitle: 'days off',
                        icon: Icons.event_busy,
                        color: AppTheme.danger,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: 'Late Clock-Ins',
                        value: '${report30Day.lateArrivals}',
                        subtitle: 'after grace period',
                        icon: Icons.alarm,
                        color: AppTheme.warning,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Recent Attendance History List
                Text(
                  'Recent Activity Log',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                if (history.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                      ),
                    ),
                    child: const Center(
                      child: Text('No attendance history recorded yet.'),
                    ),
                  )
                else
                  ...history.take(4).map((rec) => _buildHistoryItem(context, rec)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayStatusCard(BuildContext context, AttendanceModel? todayRec, dynamic user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (todayRec == null) {
      // Not Clocked In
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.touch_app, color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shift Not Started',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Ready to start your workday? Capture selfie inside office perimeter.',
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
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.successSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.radar, size: 14, color: AppTheme.success),
                  SizedBox(width: 6),
                  Text(
                    'GPS Verified • Inside Office Geofence Perimeter (<300m)',
                    style: TextStyle(fontSize: 11, color: AppTheme.success, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CameraCaptureScreen(actionType: 'clockIn'),
                  ),
                );
              },
              icon: const Icon(Icons.camera_alt, size: 20),
              label: const Text('CLOCK IN (CAMERA SELFIE)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      );
    }

    if (todayRec.status == AttendanceStatus.pending) {
      // Pending Approval State
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : AppTheme.warningSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.warning.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.warning),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clock-In Awaiting Review',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF92400E),
                        ),
                      ),
                      Text(
                        'Clocked in at ${DateFormat('hh:mm a').format(todayRec.clockInTime!)} (${todayRec.timingStatus.label}). Sent to TL for verification.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? AppTheme.textMutedDark : const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
                if (todayRec.clockInPhotoUrl != null)
                  PhotoDisplayWidget(
                    photoUrl: todayRec.clockInPhotoUrl,
                    size: 46,
                    borderRadius: 10,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppTheme.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Distance from Office: ${todayRec.distanceFromOfficeMeters}m (Geofence Verified)',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (todayRec.status == AttendanceStatus.approved) {
      // Approved and Active Shift
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : AppTheme.successSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.success.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.verified, color: AppTheme.success, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shift Active • On Duty',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF065F46),
                        ),
                      ),
                      Text(
                        'Gross: ${todayRec.formattedGrossDuration} • Break: ${todayRec.totalBreakMinutes}m • Net: ${todayRec.formattedNetDuration}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? AppTheme.textMutedDark : const Color(0xFF047857),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const StatusBadge(status: AttendanceStatus.approved, isCompact: true),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Break tracking button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => BreakTrackingSheet(attendance: todayRec),
                      );
                    },
                    icon: Icon(
                      todayRec.isOnBreak ? Icons.play_arrow : Icons.coffee,
                      size: 18,
                      color: const Color(0xFFF59E0B),
                    ),
                    label: Text(
                      todayRec.isOnBreak ? 'ON BREAK ☕' : 'BREAK ☕',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Clock Out button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CameraCaptureScreen(actionType: 'clockOut'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('CLOCK OUT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (todayRec.status == AttendanceStatus.rejected) {
      // Rejected State
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : AppTheme.dangerSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.danger.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.cancel, color: AppTheme.danger, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attendance Rejected',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF991B1B),
                        ),
                      ),
                      Text(
                        'Reason: ${todayRec.rejectionReason ?? "Photo verification failed"}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? AppTheme.textMutedDark : const Color(0xFFB91C1C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CameraCaptureScreen(actionType: 'clockIn'),
                  ),
                );
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('RE-TAKE PHOTO & RE-SUBMIT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      );
    }

    // Completed
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.infoSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.info.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.info.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.task_alt, color: AppTheme.info, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Attendance Completed',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E40AF),
                  ),
                ),
                Text(
                  'In: ${todayRec.clockInTime != null ? DateFormat('hh:mm a').format(todayRec.clockInTime!) : "--"} • Out: ${todayRec.clockOutTime != null ? DateFormat('hh:mm a').format(todayRec.clockOutTime!) : "--"} • Net: ${todayRec.formattedNetDuration}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? AppTheme.textMutedDark : const Color(0xFF1D4ED8),
                  ),
                ),
              ],
            ),
          ),
          const StatusBadge(status: AttendanceStatus.completed, isCompact: true),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, AttendanceModel rec) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final date = DateTime.tryParse(rec.date);
    final dateFormatted = date != null ? DateFormat('EEE, dd MMM yyyy').format(date) : rec.date;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
      ),
      child: Row(
        children: [
          if (rec.clockInPhotoUrl != null)
            PhotoDisplayWidget(
              photoUrl: rec.clockInPhotoUrl,
              size: 42,
              borderRadius: 10,
            )
          else
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.event_note, color: AppTheme.primary, size: 20),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      dateFormatted,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      rec.timingStatus.label,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'In: ${rec.clockInTime != null ? DateFormat('hh:mm a').format(rec.clockInTime!) : "--"} • Out: ${rec.clockOutTime != null ? DateFormat('hh:mm a').format(rec.clockOutTime!) : "--"} • Net: ${rec.formattedNetDuration}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(status: rec.status, isCompact: true),
        ],
      ),
    );
  }
}
