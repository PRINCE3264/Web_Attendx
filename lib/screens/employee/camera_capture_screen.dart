import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../shared/custom_widgets.dart';

class CameraCaptureScreen extends StatefulWidget {
  final String actionType; // 'clockIn' or 'clockOut'

  const CameraCaptureScreen({
    super.key,
    this.actionType = 'clockIn',
  });

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  String _selectedLocation = 'HQ Office - Floor 3';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCapture();
    });
  }

  void _startCapture() async {
    final provider = context.read<AttendanceProvider>();
    await provider.captureSelfie();
  }

  void _submit() async {
    final auth = context.read<AuthProvider>();
    final attendance = context.read<AttendanceProvider>();
    final user = auth.currentUser;

    if (user == null) return;

    if (widget.actionType == 'clockIn') {
      final success = await attendance.submitClockIn(
        user,
        location: _selectedLocation,
      );

      if (success && mounted) {
        Navigator.pop(context, true);
      }
    } else {
      final todayRec = attendance.getTodayAttendance(user.userId);
      if (todayRec != null) {
        final success = await attendance.submitClockOut(todayRec.attendanceId);
        if (success && mounted) {
          Navigator.pop(context, true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendance = context.watch<AttendanceProvider>();
    final isClockIn = widget.actionType == 'clockIn';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          isClockIn ? 'Selfie Verification (Clock In)' : 'Selfie Verification (Clock Out)',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Instructions Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF), // Soft blue
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.camera_alt, color: AppTheme.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Face Verification Required',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: const Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Snap your live front-camera selfie inside the office perimeter to clock in.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF1E40AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Interactive Camera Capture Box
                Center(
                  child: InkWell(
                    onTap: attendance.isProcessing ? null : _startCapture,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 280,
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: attendance.tempPhotoDataUrl != null
                              ? AppTheme.success
                              : const Color(0xFFCBD5E1),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: attendance.isProcessing
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(strokeWidth: 3),
                                    SizedBox(height: 12),
                                    Text('Opening Camera...', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              )
                            : attendance.tempPhotoDataUrl != null
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      PhotoDisplayWidget(
                                        photoUrl: attendance.tempPhotoDataUrl,
                                        fit: BoxFit.cover,
                                      ),
                                      Positioned(
                                        bottom: 12,
                                        left: 12,
                                        right: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.75),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.check_circle, color: AppTheme.success, size: 16),
                                              SizedBox(width: 6),
                                              Text(
                                                'Selfie Captured • Tap to Retake',
                                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(18),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.photo_camera_rounded,
                                          size: 48,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        'Tap to Open Camera',
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Take front selfie photo',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Office Location Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedLocation,
                      isExpanded: true,
                      icon: const Icon(Icons.location_on, color: AppTheme.primary, size: 20),
                      items: const [
                        DropdownMenuItem(
                          value: 'HQ Office - Floor 3',
                          child: Text('🏢 HQ Office - Floor 3 (Mobile Engineering)'),
                        ),
                        DropdownMenuItem(
                          value: 'HQ Office - Floor 4',
                          child: Text('🏢 HQ Office - Floor 4 (Backend Wing)'),
                        ),
                        DropdownMenuItem(
                          value: 'Branch Office - West Hub',
                          child: Text('🏢 Branch Office - West Hub'),
                        ),
                        DropdownMenuItem(
                          value: 'Remote / Work From Home',
                          child: Text('🏠 Authorized Work From Home (WFH)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedLocation = val);
                      },
                    ),
                  ),
                ),

                if (attendance.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    attendance.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.danger, fontSize: 13),
                  ),
                ],

                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: attendance.isProcessing ? null : _startCapture,
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                        label: const Text('Open Camera'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: attendance.tempPhotoDataUrl == null || attendance.isProcessing
                            ? null
                            : _submit,
                        icon: attendance.isProcessing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(isClockIn ? Icons.login : Icons.logout, size: 18),
                        label: Text(isClockIn ? 'Submit Clock-In' : 'Submit Clock-Out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isClockIn ? AppTheme.primary : AppTheme.success,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
