import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/attendance_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';

class CorrectionRequestDialog extends StatefulWidget {
  final AttendanceModel attendance;

  const CorrectionRequestDialog({
    super.key,
    required this.attendance,
  });

  @override
  State<CorrectionRequestDialog> createState() => _CorrectionRequestDialogState();
}

class _CorrectionRequestDialogState extends State<CorrectionRequestDialog> {
  late TimeOfDay _inTime;
  late TimeOfDay _outTime;
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _inTime = const TimeOfDay(hour: 9, minute: 30);
    _outTime = const TimeOfDay(hour: 18, minute: 30);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final att = widget.attendance;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? AppTheme.cardDark : Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primarySoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.history_toggle_off, color: AppTheme.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Regularize Attendance',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'For date: ${att.date}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: _inTime);
                        if (picked != null) setState(() => _inTime = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Correct In Time'),
                        child: Text(_inTime.format(context)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: _outTime);
                        if (picked != null) setState(() => _outTime = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Correct Out Time'),
                        child: Text(_outTime.format(context)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Reason for Regularization',
                  hintText: 'e.g. On-field client visit, biometric failure...',
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: () async {
                  final auth = context.read<AuthProvider>();
                  final attendance = context.read<AttendanceProvider>();
                  final user = auth.currentUser;
                  if (user == null) return;

                  final dateParts = att.date.split('-');
                  final year = int.tryParse(dateParts[0]) ?? DateTime.now().year;
                  final month = int.tryParse(dateParts[1]) ?? DateTime.now().month;
                  final day = int.tryParse(dateParts[2]) ?? DateTime.now().day;

                  final reqIn = DateTime(year, month, day, _inTime.hour, _inTime.minute);
                  final reqOut = DateTime(year, month, day, _outTime.hour, _outTime.minute);

                  final reason = _reasonController.text.trim().isEmpty
                      ? 'Attendance correction request'
                      : _reasonController.text.trim();

                  final nav = Navigator.of(context);
                  await attendance.submitCorrection(
                    employee: user,
                    attendanceId: att.attendanceId,
                    date: att.date,
                    requestedClockIn: reqIn,
                    requestedClockOut: reqOut,
                    reason: reason,
                  );

                  if (mounted) nav.pop();
                },
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Submit for TL Review'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
