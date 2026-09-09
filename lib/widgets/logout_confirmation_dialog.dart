import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/attendance_model.dart';
import '../providers/attendance_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';

/// Interactive dialog for confirming session logout and optionally submitting
/// a punch-out timestamp if an active shift is detected for the user.
class LogoutConfirmationDialog extends StatefulWidget {
  const LogoutConfirmationDialog({super.key});

  /// Static helper to trigger the logout confirmation & punch dialog directly.
  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const LogoutConfirmationDialog(),
    );
  }

  @override
  State<LogoutConfirmationDialog> createState() => _LogoutConfirmationDialogState();
}

class _LogoutConfirmationDialogState extends State<LogoutConfirmationDialog> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final attendance = context.watch<AttendanceProvider>();
    final user = auth.currentUser;

    final AttendanceModel? todayRec =
        user != null ? attendance.getTodayAttendance(user.userId) : null;
    final bool isClockedIn =
        todayRec != null && todayRec.clockInTime != null && todayRec.clockOutTime == null;

    final DateTime now = DateTime.now();
    final String formattedLogoutTime = DateFormat('hh:mm:ss a').format(now);
    final String formattedDate = DateFormat('EEEE, MMM d, yyyy').format(now);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      elevation: 8,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Icon and Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isClockedIn ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isClockedIn ? Icons.access_alarm_rounded : Icons.logout_rounded,
                    color: isClockedIn ? AppTheme.danger : AppTheme.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isClockedIn ? 'Punch Out & Logout' : 'Confirm Logout',
                        style: GoogleFonts.outfit(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMainLight,
                        ),
                      ),
                      Text(
                        'Session & Attendance Confirmation',
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Logout Timestamp Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 20, color: Color(0xFF475569)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LOGOUT / CONFIRMATION PUNCH TIME',
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              formattedLogoutTime,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                formattedDate,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 11.5,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Active Shift Warning (if clocked in)
            if (isClockedIn) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Active Shift Currently Running!',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Clock In Time:',
                          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF78350F)),
                        ),
                        Text(
                          DateFormat('hh:mm a').format(todayRec.clockInTime!),
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF78350F)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Shift Elapsed:',
                          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF78350F)),
                        ),
                        Text(
                          todayRec.formattedGrossDuration,
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF78350F)),
                        ),
                      ],
                    ),
                    const Divider(height: 16, color: Color(0xFFFCD34D)),
                    Text(
                      'Would you like to punch out your shift before logging out of AttendX?',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF92400E),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              Text(
                'Are you sure you want to end your session and log out?',
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  color: const Color(0xFF475569),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Action Buttons
            if (_isProcessing)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (isClockedIn) ...[
              // Option 1: Punch Out & Logout
              ElevatedButton.icon(
                onPressed: () => _performPunchOutAndLogout(context, auth, attendance, todayRec),
                icon: const Icon(Icons.timer_off_rounded, size: 18),
                label: const Text('PUNCH OUT & LOGOUT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 8),

              // Option 2: Logout Without Punching Out
              OutlinedButton.icon(
                onPressed: () => _performLogoutOnly(context, auth),
                icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFF64748B)),
                label: Text(
                  'Logout Only (Stay Clocked In)',
                  style: GoogleFonts.outfit(color: const Color(0xFF475569), fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),

              // Option 3: Cancel
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
                ),
              ),
            ] else ...[
              // Standard Logout when not clocked in
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _performLogoutOnly(context, auth),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _performPunchOutAndLogout(
    BuildContext context,
    AuthProvider auth,
    AttendanceProvider attendance,
    AttendanceModel todayRec,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _isProcessing = true;
    });

    final success = await attendance.submitClockOut(todayRec.attendanceId);

    if (!mounted) return;

    if (success) {
      final punchTime = DateFormat('hh:mm a').format(DateTime.now());
      messenger.showSnackBar(
        SnackBar(
          content: Text('Punch Out successful at $punchTime. Logging out...'),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 2),
        ),
      );
      await auth.logout();
      if (!mounted) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      setState(() {
        _isProcessing = false;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(attendance.errorMessage ?? 'Failed to punch out before logout.'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  Future<void> _performLogoutOnly(BuildContext context, AuthProvider auth) async {
    final navigator = Navigator.of(context);

    setState(() {
      _isProcessing = true;
    });
    await auth.logout();
    if (!mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
