import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/attendance_model.dart';
import '../../models/break_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';

class BreakTrackingSheet extends StatefulWidget {
  final AttendanceModel attendance;

  const BreakTrackingSheet({
    super.key,
    required this.attendance,
  });

  @override
  State<BreakTrackingSheet> createState() => _BreakTrackingSheetState();
}

class _BreakTrackingSheetState extends State<BreakTrackingSheet> {
  BreakType _selectedType = BreakType.tea;

  void _startBreak() async {
    final auth = context.read<AuthProvider>();
    final attendance = context.read<AttendanceProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final success = await attendance.startBreak(
      widget.attendance.attendanceId,
      _selectedType,
      user,
    );

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  void _endBreak() async {
    final auth = context.read<AuthProvider>();
    final attendance = context.read<AttendanceProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final success = await attendance.endBreak(
      widget.attendance.attendanceId,
      user,
    );

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final att = widget.attendance;
    final activeBreak = att.activeBreak;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.coffee, color: Color(0xFFF59E0B), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Break & Rest Tracking',
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Policy: Max 1h Break • Today: ${att.totalBreakMinutes.toHoursAndMinutesCompact} logged',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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
          const SizedBox(height: 14),

          // Policy Summary Card (8h Net Work + 1h Break = 9h Total Shift)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDarkAlt : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppTheme.borderDark : const Color(0xFFBFDBFE),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Daily Shift Target: 8 Hours Net Work + Max 1 Hour Break = 9 Hours Total Shift',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E40AF),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (att.totalBreakMinutes >= 60) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '⚠️ Maximum 1-Hour Break Allowance Reached (${att.totalBreakMinutes.toHoursAndMinutes} logged). Additional break time will extend your shift.',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF991B1B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          if (activeBreak != null) ...[
            // Active Break Alert
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warningSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer, color: AppTheme.warning, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${activeBreak.type.label} in Progress',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF92400E),
                              ),
                            ),
                            Text(
                              'Running for ${activeBreak.formattedDuration}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _endBreak,
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('END BREAK & RESUME WORK'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      minimumSize: const Size.fromHeight(46),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Start Break selection
            Text(
              'Select Break Type:',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Row(
              children: BreakType.values.map((type) {
                final isSelected = _selectedType == type;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () => setState(() => _selectedType = type),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary.withValues(alpha: 0.12)
                              : (isDark ? AppTheme.cardDarkAlt : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppTheme.primary : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              type == BreakType.tea
                                  ? '☕'
                                  : (type == BreakType.lunch ? '🍱' : '🚶'),
                              style: const TextStyle(fontSize: 22),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              type == BreakType.tea
                                  ? 'Tea'
                                  : (type == BreakType.lunch ? 'Lunch' : 'Personal'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppTheme.primary : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _startBreak,
              icon: const Icon(Icons.pause, size: 18),
              label: Text('START ${_selectedType.name.toUpperCase()} BREAK'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warning,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],

          if (att.breaks.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              "Today's Break Log",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ...att.breaks.map((b) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDarkAlt : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(b.type.label, style: const TextStyle(fontSize: 12)),
                    Text(
                      b.isActive ? 'Active...' : b.formattedDuration,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: b.isActive ? AppTheme.warning : AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
