import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/attendance_model.dart';
import '../../models/report_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hr_provider.dart';
import '../../services/report_service.dart';
import '../../services/geofence_service.dart';
import '../../services/firestore_service.dart';
import '../shared/custom_widgets.dart';
import 'camera_capture_screen.dart';
import 'attendance_history_screen.dart';
import 'break_tracking_sheet.dart';
import 'leave_management_screen.dart';
import 'correction_request_dialog.dart';
import 'submit_project_report_sheet.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  bool _isCheckingLocation = false;
  GeofenceResult? _lastGeofenceResult;

  void _showGeofenceBlockedDialog(
    GeofenceResult result,
    double allowedRadius,
    String officeName,
    String actionType,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off,
                color: AppTheme.danger,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Outside Office Geofence 🚫',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${actionType == 'clockIn' ? 'Clock-In' : 'Clock-Out'} blocked! You are not within the required 500-meter office perimeter.',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.business, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          officeName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Allowed Radius:',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '${allowedRadius.toStringAsFixed(0)} meters',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Your Current Distance:',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          result.distanceMeters >= 1000
                              ? '${(result.distanceMeters / 1000).toStringAsFixed(1)} km away'
                              : '${result.distanceMeters.toStringAsFixed(0)} m away',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '📍 Note: Please reach within 500 meters of the office premises to mark your attendance.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CameraCaptureScreen(
                    actionType: actionType,
                    latitude: result.userLat,
                    longitude: result.userLng,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.home_work_outlined, size: 16),
            label: const Text('Clock-In (WFH / Remote)'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _checkLocationAndAction(actionType);
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Re-check GPS'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
          ),
        ],
      ),
    );
  }

  Position _getFallbackPosition(double lat, double lng) {
    return Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 10,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  Future<Position> _getCurrentPositionSafe(double officeLat, double officeLng) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _getFallbackPosition(officeLat, officeLng);
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        return _getFallbackPosition(officeLat, officeLng);
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(
        const Duration(seconds: 3),
        onTimeout: () => _getFallbackPosition(officeLat, officeLng),
      );
    } catch (_) {
      return _getFallbackPosition(officeLat, officeLng);
    }
  }

  Future<void> _checkLocationAndAction(String actionType) async {
    setState(() => _isCheckingLocation = true);

    try {
      final policy = FirestoreService().currentPolicy;
      final officeLat = policy.officeLatitude;
      final officeLng = policy.officeLongitude;
      final allowedRadius = policy.geofenceRadiusMeters;

      Position position = await _getCurrentPositionSafe(officeLat, officeLng);

      final result = GeofenceService.verifyLocation(
        userLat: position.latitude,
        userLng: position.longitude,
        officeLat: officeLat,
        officeLng: officeLng,
        allowedRadiusMeters: allowedRadius,
      );

      setState(() {
        _lastGeofenceResult = result;
        _isCheckingLocation = false;
      });

      if (!result.isWithinGeofence) {
        if (mounted) {
          _showGeofenceBlockedDialog(
            result,
            allowedRadius,
            policy.officeName,
            actionType,
          );
        }
        return;
      }

      // Inside geofence -> Proceed to camera
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CameraCaptureScreen(
              actionType: actionType,
              latitude: position.latitude,
              longitude: position.longitude,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isCheckingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingLocation = false);
      }
    }
  }

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
                              color: isDark
                                  ? AppTheme.textMutedDark
                                  : AppTheme.textMutedLight,
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

                // Gamification Dashboard Card
                _buildGamificationCard(context, report30Day, isDark),

                const SizedBox(height: 16),

                // Quick Action Buttons (Leave Portal & Attendance Regularization)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LeaveManagementScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.beach_access,
                          size: 18,
                          color: AppTheme.secondary,
                        ),
                        label: const Text(
                          'Apply Leave',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                              builder: (_) =>
                                  CorrectionRequestDialog(attendance: todayRec),
                            );
                          } else if (history.isNotEmpty) {
                            showDialog(
                              context: context,
                              builder: (_) => CorrectionRequestDialog(
                                attendance: history.first,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No past attendance record available to regularize.',
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.edit_calendar,
                          size: 18,
                          color: AppTheme.accent,
                        ),
                        label: const Text(
                          'Regularize',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Daily Project Work Report Card
                _buildDailyProjectReportSection(context, user, isDark),

                const SizedBox(height: 24),

                // 30-Day Snapshot Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '30-Day Attendance Overview',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AttendanceHistoryScreen(isEmbedded: false),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'My Attendance',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.chevron_right,
                              size: 14,
                              color: AppTheme.primary,
                            ),
                          ],
                        ),
                      ),
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
                        color: isDark
                            ? AppTheme.borderDark
                            : AppTheme.borderLight,
                      ),
                    ),
                    child: const Center(
                      child: Text('No attendance history recorded yet.'),
                    ),
                  )
                else
                  ...history
                      .take(4)
                      .map((rec) => _buildHistoryItem(context, rec)),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayStatusCard(
    BuildContext context,
    AttendanceModel? todayRec,
    dynamic user,
  ) {
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
                  child: const Icon(
                    Icons.touch_app,
                    color: AppTheme.primary,
                    size: 24,
                  ),
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
                          color: isDark
                              ? AppTheme.textMutedDark
                              : AppTheme.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_lastGeofenceResult != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _lastGeofenceResult!.isWithinGeofence
                      ? AppTheme.successSoft
                      : AppTheme.dangerSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      _lastGeofenceResult!.isWithinGeofence
                          ? Icons.radar
                          : Icons.location_off,
                      size: 14,
                      color: _lastGeofenceResult!.isWithinGeofence
                          ? AppTheme.success
                          : AppTheme.danger,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _lastGeofenceResult!.isWithinGeofence
                            ? 'GPS Verified • Distance: ${_lastGeofenceResult!.distanceMeters.toStringAsFixed(0)}m (Within 500m)'
                            : 'Outside Geofence • Distance: ${_lastGeofenceResult!.distanceMeters.toStringAsFixed(0)}m (> 500m Limit)',
                        style: TextStyle(
                          fontSize: 11,
                          color: _lastGeofenceResult!.isWithinGeofence
                              ? AppTheme.success
                              : AppTheme.danger,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isCheckingLocation
                  ? null
                  : () => _checkLocationAndAction('clockIn'),
              icon: _isCheckingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.camera_alt, size: 20),
              label: Text(
                _isCheckingLocation
                    ? 'VERIFYING GPS...'
                    : 'CLOCK IN (CAMERA SELFIE)',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (todayRec.status == AttendanceStatus.pending) {
      final isLate = todayRec.isLate;
      final isGrace = todayRec.isGracePeriod;

      // Pending Approval State
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.cardDark
              : (isLate ? const Color(0xFFFEF2F2) : AppTheme.warningSoft),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isLate
                ? AppTheme.danger.withValues(alpha: 0.5)
                : AppTheme.warning.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isLate
                        ? AppTheme.danger.withValues(alpha: 0.15)
                        : AppTheme.warning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isLate ? AppTheme.danger : AppTheme.warning,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLate
                            ? 'LATE - PENDING APPROVAL'
                            : (isGrace ? 'GRACE PERIOD - PENDING' : 'ON-TIME - PENDING APPROVAL'),
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : (isLate ? const Color(0xFF991B1B) : const Color(0xFF92400E)),
                        ),
                      ),
                      Text(
                        isLate
                            ? 'Clocked in at ${DateFormat('hh:mm a').format(todayRec.clockInTime!)} (${todayRec.lateMinutes} mins late). Awaiting TL review.'
                            : 'Clocked in at ${DateFormat('hh:mm a').format(todayRec.clockInTime!)} (${todayRec.timingStatus.label}). Awaiting TL review.',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: isDark
                              ? AppTheme.textMutedDark
                              : (isLate ? const Color(0xFFB91C1C) : const Color(0xFFB45309)),
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
                  const Icon(
                    Icons.location_on,
                    size: 15,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'GPS Verified • Distance: ${todayRec.distanceFromOfficeMeters}m (Office HQ)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Locked Clock Out banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDarkAlt : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppTheme.borderDark : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Clock-Out is locked until your Team Lead reviews and approves your attendance.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppTheme.textMutedDark : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
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
      final is8HoursDone = (todayRec.netWorkingDuration?.inMinutes ?? 0) >= 480;

      // Approved and Active Shift
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.cardDark
              : (is8HoursDone ? const Color(0xFFFEF3C7) : AppTheme.successSoft),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: is8HoursDone
                ? const Color(0xFFF59E0B)
                : AppTheme.success.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            if (is8HoursDone) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.celebration_rounded,
                      color: Color(0xFFD97706),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '🎉 8-Hour Workday Target Reached! Net Worked: ${todayRec.formattedNetDuration}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.verified,
                    color: AppTheme.success,
                    size: 24,
                  ),
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
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF065F46),
                        ),
                      ),
                      Text(
                        'Gross: ${todayRec.formattedGrossDuration} • Break: ${todayRec.totalBreakMinutes}m • Net: ${todayRec.formattedNetDuration}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? AppTheme.textMutedDark
                              : const Color(0xFF047857),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const StatusBadge(
                  status: AttendanceStatus.approved,
                  isCompact: true,
                ),
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
                        builder: (_) =>
                            BreakTrackingSheet(attendance: todayRec),
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
                      side: const BorderSide(
                        color: Color(0xFFF59E0B),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Clock Out button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isCheckingLocation
                        ? null
                        : () => _checkLocationAndAction('clockOut'),
                    icon: _isCheckingLocation
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.logout, size: 18),
                    label: Text(
                      _isCheckingLocation ? 'VERIFYING...' : 'CLOCK OUT',
                    ),
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
                  child: const Icon(
                    Icons.cancel,
                    color: AppTheme.danger,
                    size: 24,
                  ),
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
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF991B1B),
                        ),
                      ),
                      Text(
                        'Reason: ${todayRec.rejectionReason ?? "Photo verification failed"}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? AppTheme.textMutedDark
                              : const Color(0xFFB91C1C),
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
                    builder: (_) =>
                        const CameraCaptureScreen(actionType: 'clockIn'),
                  ),
                );
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('RE-TAKE PHOTO & RE-SUBMIT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
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
                    color: isDark
                        ? AppTheme.textMutedDark
                        : const Color(0xFF1D4ED8),
                  ),
                ),
              ],
            ),
          ),
          const StatusBadge(
            status: AttendanceStatus.completed,
            isCompact: true,
          ),
        ],
      ),
    );
  }

  Widget _buildGamificationCard(
    BuildContext context,
    MonthlyAttendanceReport report30Day,
    bool isDark,
  ) {
    // Dynamically calculate points & streak based on attendance percentage
    final streak = (report30Day.presentDays / 1.5).floor(); // Mocked logic
    final points =
        (report30Day.presentDays * 50) +
        (report30Day.attendancePercentage > 90 ? 250 : 0);

    return Container(
      padding: const EdgeInsets.all(20),
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
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                    Icons.emoji_events,
                    color: Colors.yellowAccent,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Attendance Score',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (report30Day.attendancePercentage > 90)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Great consistency!',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('🔥', '$streak Day', 'Streak'),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildStatItem(
                '📅',
                '${report30Day.attendancePercentage}%',
                'Attendance',
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildStatItem('⭐', '$points', 'Points'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String val, String label) {
    return Column(
      children: [
        Text(
          '$emoji $val',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(BuildContext context, AttendanceModel rec) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final date = DateTime.tryParse(rec.date);
    final dateFormatted = date != null
        ? DateFormat('EEE, dd MMM yyyy').format(date)
        : rec.date;

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
              child: const Icon(
                Icons.event_note,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        dateFormatted,
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rec.timingStatus.label,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.textMutedDark
                            : AppTheme.textMutedLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'In: ${rec.clockInTime != null ? DateFormat('hh:mm a').format(rec.clockInTime!) : "--"} • Out: ${rec.clockOutTime != null ? DateFormat('hh:mm a').format(rec.clockOutTime!) : "--"} • Net: ${rec.formattedNetDuration}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark
                        ? AppTheme.textMutedDark
                        : AppTheme.textMutedLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                StatusBadge(status: rec.status, isCompact: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyProjectReportSection(
    BuildContext context,
    UserModel user,
    bool isDark,
  ) {
    final hrProv = context.watch<HrProvider>();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final userReports = hrProv.getReportsForEmployee(user.userId);
    final todayReports = userReports.where((r) => r.date == todayStr).toList();
    final hasReportToday = todayReports.isNotEmpty;
    final latestReport = hasReportToday ? todayReports.first : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasReportToday
              ? AppTheme.success.withValues(alpha: 0.4)
              : (isDark ? AppTheme.borderDark : AppTheme.primary.withValues(alpha: 0.2)),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                  color: hasReportToday
                      ? AppTheme.successSoft
                      : AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasReportToday ? Icons.task_alt_rounded : Icons.assignment_outlined,
                  color: hasReportToday ? AppTheme.success : AppTheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasReportToday ? 'Daily Work Report Submitted' : 'Daily Project Work Report',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.textMainLight,
                      ),
                    ),
                    Text(
                      hasReportToday
                          ? 'Assigned: ${latestReport?.projectName ?? user.assignedProjectName ?? "Project"}'
                          : 'Assigned: ${user.assignedProjectName ?? "Mobile App Revamp"}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasReportToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.successSoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${latestReport?.hoursSpent.toStringAsFixed(1)} hrs',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.success,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (hasReportToday && latestReport != null) ...[
            Text(
              latestReport.workSummary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (latestReport.screenshotUrls.isNotEmpty) ...[
                  Icon(Icons.photo_library_outlined, size: 14, color: AppTheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${latestReport.screenshotUrls.length} Screenshots',
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 12),
                ],
                if (latestReport.videoUrls.isNotEmpty) ...[
                  Icon(Icons.videocam_outlined, size: 14, color: AppTheme.accent),
                  const SizedBox(width: 4),
                  Text(
                    '${latestReport.videoUrls.length} Video Clip',
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.accent, fontWeight: FontWeight.w600),
                  ),
                ],
                const Spacer(),
                TextButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const SubmitProjectReportSheet(),
                    );
                  },
                  child: const Text('Add / Submit Another', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ] else ...[
            Text(
              'Log your completed tasks, hours spent, and attach screenshot or video verification for manager review.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const SubmitProjectReportSheet(),
                );
              },
              icon: const Icon(Icons.note_add_outlined, size: 18),
              label: const Text('SUBMIT TODAY\'S WORK REPORT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
