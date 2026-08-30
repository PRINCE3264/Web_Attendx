import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../config/app_theme.dart';
import '../../models/attendance_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../shared/custom_widgets.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final bool isEmbedded;
  const AttendanceHistoryScreen({super.key, this.isEmbedded = true});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _selectedStatusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final attendance = context.watch<AttendanceProvider>();
    final user = auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not found')));
    }

    final allHistory = attendance.getEmployeeHistory(user.userId);
    final historyMap = <String, AttendanceModel>{};
    for (final item in allHistory) {
      historyMap[item.date] = item;
    }

    // Filter by status
    final filteredHistory = allHistory.where((rec) {
      if (_selectedStatusFilter == 'All') return true;
      if (_selectedStatusFilter == 'Approved') {
        return rec.status == AttendanceStatus.approved || rec.status == AttendanceStatus.completed;
      }
      if (_selectedStatusFilter == 'Pending') return rec.status == AttendanceStatus.pending;
      if (_selectedStatusFilter == 'Rejected') return rec.status == AttendanceStatus.rejected;
      return true;
    }).toList();

    return Scaffold(
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: Text(
                'Attendance History & Calendar',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
      body: SafeArea(
        child: Column(
          children: [
            // Calendar Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                ),
              ),
              child: TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 90)),
                lastDay: DateTime.now().add(const Duration(days: 30)),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() => _calendarFormat = format);
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: AppTheme.primaryLight.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: AppTheme.success,
                    shape: BoxShape.circle,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    final dateKey = DateFormat('yyyy-MM-dd').format(date);
                    final rec = historyMap[dateKey];
                    if (rec == null) return null;

                    Color dotColor;
                    switch (rec.status) {
                      case AttendanceStatus.completed:
                      case AttendanceStatus.approved:
                        dotColor = AppTheme.success;
                        break;
                      case AttendanceStatus.pending:
                        dotColor = AppTheme.warning;
                        break;
                      case AttendanceStatus.rejected:
                        dotColor = AppTheme.danger;
                        break;
                    }

                    return Positioned(
                      bottom: 4,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Approved', 'Pending', 'Rejected'].map((filter) {
                    final isSelected = _selectedStatusFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedStatusFilter = filter);
                        },
                        selectedColor: AppTheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // List of Logs
            Expanded(
              child: filteredHistory.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'No records found matching "$_selectedStatusFilter"',
                            style: GoogleFonts.inter(
                              color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredHistory.length,
                      itemBuilder: (context, index) {
                        final rec = filteredHistory[index];
                        final date = DateTime.tryParse(rec.date);
                        final dateFormatted =
                            date != null ? DateFormat('EEEE, dd MMM yyyy').format(date) : rec.date;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.cardDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    dateFormatted,
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  StatusBadge(status: rec.status, isCompact: true),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  if (rec.clockInPhotoUrl != null)
                                    PhotoDisplayWidget(
                                      photoUrl: rec.clockInPhotoUrl,
                                      size: 48,
                                      borderRadius: 10,
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Clock In: ${rec.clockInTime != null ? DateFormat('hh:mm a').format(rec.clockInTime!) : "--"}',
                                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          'Clock Out: ${rec.clockOutTime != null ? DateFormat('hh:mm a').format(rec.clockOutTime!) : "--"}',
                                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                        if (rec.totalWorkMinutes != null || rec.grossDuration != null)
                                          Text(
                                            'Net Duration: ${rec.formattedNetDuration}',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: AppTheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (rec.rejectionReason != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.dangerSoft,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info_outline, size: 14, color: AppTheme.danger),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Reason: ${rec.rejectionReason}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.danger,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
