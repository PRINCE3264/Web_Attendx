import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../config/app_theme.dart';
import '../../models/attendance_model.dart';
import '../../models/leave_model.dart';
import '../../models/user_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hr_provider.dart';
import '../../providers/leave_provider.dart';
import '../shared/custom_widgets.dart';
import 'correction_request_dialog.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final bool isEmbedded;
  final String? targetUserId;

  const AttendanceHistoryScreen({
    super.key,
    this.isEmbedded = true,
    this.targetUserId,
  });

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  late DateTime _selectedMonth;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDate;
  String _selectedStatusFilter = 'All';
  String? _selectedEmployeeId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
    _focusedDay = now;
  }

  /// Calculates total working days (Monday-Friday) in the selected month
  int _getWorkingDaysInMonth(DateTime monthDate) {
    final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;
    int workingDays = 0;
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(monthDate.year, monthDate.month, day);
      if (date.weekday != DateTime.saturday && date.weekday != DateTime.sunday) {
        workingDays++;
      }
    }
    return workingDays;
  }

  void _changeMonth(int increment) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + increment, 1);
      _focusedDay = _selectedMonth;
      _selectedDate = null;
    });
  }

  Future<void> _pickMonthYear() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2025, 1),
      lastDate: DateTime(2030, 12),
      helpText: 'SELECT MONTH & YEAR',
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month, 1);
        _focusedDay = _selectedMonth;
        _selectedDate = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final attendance = context.watch<AttendanceProvider>();
    final leaveProv = context.watch<LeaveProvider>();
    final hr = context.watch<HrProvider>();
    final user = auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    if (user == null) {
      return const Scaffold(body: Center(child: Text('User session not found')));
    }

    final activeUserId = _selectedEmployeeId ?? widget.targetUserId ?? user.userId;
    final allUserHistory = attendance.getEmployeeHistory(activeUserId);
    final allUserLeaves = leaveProv.getLeavesForEmployee(activeUserId);
    final todayAttendance = attendance.getTodayAttendance(activeUserId);

    // Map history by date string 'yyyy-MM-dd'
    final historyMap = <String, AttendanceModel>{};
    for (final item in allUserHistory) {
      historyMap[item.date] = item;
    }

    // Filter records for selected month
    final monthStr = DateFormat('yyyy-MM').format(_selectedMonth);
    final isCurrentMonth = monthStr == DateFormat('yyyy-MM').format(now);

    // Calculate Month Metrics accurately
    final totalWorkingDays = _getWorkingDaysInMonth(_selectedMonth);
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;

    int presentCount = 0;
    int lateCount = 0;
    int pendingCount = 0;
    int rejectedCount = 0;
    int leaveCount = 0;
    int absentCount = 0;

    // Check each day of the month for exact status classification
    for (int day = 1; day <= daysInMonth; day++) {
      final dayDate = DateTime(_selectedMonth.year, _selectedMonth.month, day);
      final dateKey = DateFormat('yyyy-MM-dd').format(dayDate);
      final isWeekend = dayDate.weekday == DateTime.saturday || dayDate.weekday == DateTime.sunday;
      final isPastOrToday = !dayDate.isAfter(now);

      final rec = historyMap[dateKey];
      final hasApprovedLeave = allUserLeaves.any((l) =>
          l.status == LeaveStatus.approved &&
          !dayDate.isBefore(DateTime(l.startDate.year, l.startDate.month, l.startDate.day)) &&
          !dayDate.isAfter(DateTime(l.endDate.year, l.endDate.month, l.endDate.day)));

      if (hasApprovedLeave && !isWeekend) {
        leaveCount++;
      } else if (rec != null) {
        if (rec.status == AttendanceStatus.pending) {
          pendingCount++;
        } else if (rec.status == AttendanceStatus.rejected) {
          rejectedCount++;
        } else if (rec.timingStatus == TimingStatus.lateArrival) {
          lateCount++;
        } else if (rec.status == AttendanceStatus.approved || rec.status == AttendanceStatus.completed) {
          presentCount++;
        }
      } else if (isPastOrToday && !isWeekend) {
        absentCount++;
      }
    }

    // Total attended days = Present + Late
    final totalAttended = presentCount + lateCount;
    final calculatedRate = totalWorkingDays > 0 ? ((totalAttended / totalWorkingDays) * 100) : 0.0;
    final attendancePct = calculatedRate.clamp(0.0, 100.0).toStringAsFixed(1);

    // Filter date-wise history based on filter chip & selected date
    final filteredHistory = allUserHistory.where((rec) {
      if (!rec.date.startsWith(monthStr)) return false;

      if (_selectedDate != null) {
        final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate!);
        if (rec.date != dateKey) return false;
      }

      if (_selectedStatusFilter == 'All') return true;
      if (_selectedStatusFilter == 'Present') {
        return (rec.status == AttendanceStatus.approved || rec.status == AttendanceStatus.completed) &&
            rec.timingStatus != TimingStatus.lateArrival;
      }
      if (_selectedStatusFilter == 'Late') return rec.timingStatus == TimingStatus.lateArrival;
      if (_selectedStatusFilter == 'Pending') return rec.status == AttendanceStatus.pending;
      if (_selectedStatusFilter == 'Rejected') return rec.status == AttendanceStatus.rejected;
      return true;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Screen Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (Navigator.canPop(context)) ...[
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 22),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Back',
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.role == UserRole.employee ? 'My Attendance' : 'Monthly Attendance',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          user.role == UserRole.employee
                              ? 'Personal Monthly Attendance & Calendar'
                              : 'Monthly Attendance Calendar & Logs',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person, size: 14, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            user.role == UserRole.employee ? user.name : 'Monthly View',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Employee Selector Dropdown for Admin/HR/Manager
              if (user.role != UserRole.employee && hr.filteredEmployees.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: hr.filteredEmployees.any((e) => e.userId == activeUserId)
                          ? activeUserId
                          : hr.filteredEmployees.first.userId,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.primary),
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      items: hr.filteredEmployees.map((emp) {
                        return DropdownMenuItem<String>(
                          value: emp.userId,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                                child: Text(
                                  emp.name.isNotEmpty ? emp.name[0].toUpperCase() : 'E',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${emp.name} — ${emp.department} (${emp.employeeId})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedEmployeeId = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // 2. Month Selector Navigation Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 24),
                      onPressed: () => _changeMonth(-1),
                      tooltip: 'Previous Month',
                    ),
                    InkWell(
                      onTap: _pickMonthYear,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, size: 18, color: AppTheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('MMMM yyyy').format(_selectedMonth),
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, size: 20, color: AppTheme.primary),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 24),
                      onPressed: () => _changeMonth(1),
                      tooltip: 'Next Month',
                    ),
                  ],
                ),
              ),

              // 3. Today's Live Attendance Status Banner (When viewing current month)
              if (isCurrentMonth) ...[
                const SizedBox(height: 14),
                _buildTodayLiveStatusBanner(context, todayAttendance, isDark),
              ],

              const SizedBox(height: 16),

              // 4. MONTHLY SUMMARY CARD
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
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
                        Expanded(
                          child: Text(
                            '${DateFormat('MMMM yyyy').format(_selectedMonth)} Summary',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: calculatedRate >= 90
                                ? AppTheme.successSoft
                                : (calculatedRate >= 75 ? AppTheme.warningSoft : AppTheme.dangerSoft),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$attendancePct% Attendance',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: calculatedRate >= 90
                                  ? AppTheme.success
                                  : (calculatedRate >= 75 ? AppTheme.warning : AppTheme.danger),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Metrics Grid (Present, Absent, Late, Leave, Pending, Rejected)
                    Row(
                      children: [
                        Expanded(child: _buildMetricTile('Present', '$presentCount', AppTheme.success, isDark)),
                        Expanded(child: _buildMetricTile('Absent', '$absentCount', AppTheme.danger, isDark)),
                        Expanded(child: _buildMetricTile('Late', '$lateCount', const Color(0xFFF59E0B), isDark)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildMetricTile('Leave', '$leaveCount', const Color(0xFF0EA5E9), isDark)),
                        Expanded(child: _buildMetricTile('Pending', '$pendingCount', const Color(0xFFEAB308), isDark)),
                        Expanded(child: _buildMetricTile('Rejected', '$rejectedCount', const Color(0xFFDC2626), isDark)),
                      ],
                    ),

                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Bottom info: Total Working Days & Attendance %
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.business_center_outlined, size: 16, color: AppTheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Total Working Days (Mon-Fri):',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$totalWorkingDays Days',
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 5. MONTHLY CALENDAR GRID (Mon Tue Wed Thu Fri Sat Sun)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Attendance Calendar',
                    style: GoogleFonts.outfit(fontSize: 16.5, fontWeight: FontWeight.bold),
                  ),
                  if (_selectedDate != null)
                    TextButton(
                      onPressed: () => setState(() => _selectedDate = null),
                      child: const Text('Show Full Month'),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                ),
                child: Column(
                  children: [
                    TableCalendar(
                      firstDay: DateTime(2025, 1, 1),
                      lastDay: DateTime(2030, 12, 31),
                      focusedDay: _focusedDay,
                      headerVisible: false,
                      calendarFormat: CalendarFormat.month,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          if (_selectedDate != null && isSameDay(_selectedDate, selectedDay)) {
                            _selectedDate = null; // Unselect if tapped again
                          } else {
                            _selectedDate = selectedDay;
                          }
                          _focusedDay = focusedDay;
                        });
                      },
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          border: Border.all(color: AppTheme.primary, width: 2),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        outsideDaysVisible: false,
                      ),
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, events) {
                          final dateKey = DateFormat('yyyy-MM-dd').format(date);
                          final rec = historyMap[dateKey];
                          final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
                          final isPastOrToday = !date.isAfter(now);

                          // Check approved leave for this date
                          final hasApprovedLeave = allUserLeaves.any((l) =>
                              l.status == LeaveStatus.approved &&
                              !date.isBefore(DateTime(l.startDate.year, l.startDate.month, l.startDate.day)) &&
                              !date.isAfter(DateTime(l.endDate.year, l.endDate.month, l.endDate.day)));

                          String badgeText = '';
                          Color badgeBg = Colors.grey.shade200;
                          Color badgeFg = Colors.black87;

                          if (hasApprovedLeave && !isWeekend) {
                            badgeText = 'LV';
                            badgeBg = const Color(0xFFDBEAFE);
                            badgeFg = const Color(0xFF1D4ED8);
                          } else if (rec != null) {
                            if (rec.status == AttendanceStatus.pending) {
                              badgeText = 'Pnd';
                              badgeBg = const Color(0xFFFEF3C7);
                              badgeFg = const Color(0xFFD97706);
                            } else if (rec.status == AttendanceStatus.rejected) {
                              badgeText = 'Rjk';
                              badgeBg = const Color(0xFFFEE2E2);
                              badgeFg = const Color(0xFFDC2626);
                            } else if (rec.timingStatus == TimingStatus.lateArrival) {
                              badgeText = 'L';
                              badgeBg = const Color(0xFFFEF3C7);
                              badgeFg = const Color(0xFFD97706);
                            } else {
                              badgeText = 'P';
                              badgeBg = const Color(0xFFDCFCE7);
                              badgeFg = const Color(0xFF15803D);
                            }
                          } else if (isWeekend) {
                            badgeText = 'WO';
                            badgeBg = Colors.grey.shade100;
                            badgeFg = Colors.grey.shade600;
                          } else if (isPastOrToday) {
                            badgeText = 'A';
                            badgeBg = const Color(0xFFFEE2E2);
                            badgeFg = const Color(0xFFDC2626);
                          }

                          if (badgeText.isEmpty) return null;

                          return Positioned(
                            bottom: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                badgeText,
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: badgeFg,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Calendar Legend Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.cardDarkAlt : const Color(0xFFF8FAFC),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                      ),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildLegendChip('P = Present', const Color(0xFF15803D), const Color(0xFFDCFCE7)),
                          _buildLegendChip('A = Absent', const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
                          _buildLegendChip('L = Late', const Color(0xFFD97706), const Color(0xFFFEF3C7)),
                          _buildLegendChip('LV = Leave', const Color(0xFF1D4ED8), const Color(0xFFDBEAFE)),
                          _buildLegendChip('Pnd = Pending', const Color(0xFFB45309), const Color(0xFFFEF3C7)),
                          _buildLegendChip('Rjk = Rejected', const Color(0xFF991B1B), const Color(0xFFFEE2E2)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 6. DATE-WISE ATTENDANCE HISTORY & FILTER CHIPS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedDate != null
                        ? 'Details for ${DateFormat('dd MMMM yyyy').format(_selectedDate!)}'
                        : 'Date-wise Attendance History',
                    style: GoogleFonts.outfit(fontSize: 16.5, fontWeight: FontWeight.bold),
                  ),
                  if (_selectedDate != null)
                    TextButton(
                      onPressed: () => setState(() => _selectedDate = null),
                      child: const Text('Show All'),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Present', 'Late', 'Pending', 'Rejected'].map((filter) {
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

              const SizedBox(height: 12),

              // LOGS LIST
              if (filteredHistory.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.event_busy, size: 42, color: Colors.grey.shade400),
                      const SizedBox(height: 10),
                      Text(
                        'No attendance records found for the selected filter.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredHistory.length,
                  itemBuilder: (context, index) {
                    final rec = filteredHistory[index];
                    final date = DateTime.tryParse(rec.date);
                    final dateFormatted = date != null ? DateFormat('EEEE, dd MMM yyyy').format(date) : rec.date;
                    final isLate = rec.isLate;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.cardDark : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isLate
                              ? AppTheme.warning.withValues(alpha: 0.5)
                              : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
                          width: isLate ? 1.4 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
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
                          if (isLate) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFD97706)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Late Clock-In (${rec.lateMinutes.toHoursAndMinutes} late)',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (rec.clockInPhotoUrl != null)
                                PhotoDisplayWidget(
                                  photoUrl: rec.clockInPhotoUrl,
                                  size: 48,
                                  borderRadius: 12,
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.login, size: 14, color: AppTheme.success),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Clock In: ${rec.clockInTime != null ? DateFormat('hh:mm a').format(rec.clockInTime!) : "--"}',
                                          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.logout, size: 14, color: Color(0xFFEF4444)),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Clock Out: ${rec.clockOutTime != null ? DateFormat('hh:mm a').format(rec.clockOutTime!) : "--"}',
                                          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                    if (rec.totalWorkMinutes != null || rec.grossDuration != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.timer_outlined, size: 14, color: AppTheme.primary),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Worked: ${rec.formattedNetDuration} (Gross: ${rec.formattedGrossDuration})',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: AppTheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (rec.rejectionReason != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.dangerSoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.cancel, size: 16, color: AppTheme.danger),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Rejection Reason: ${rec.rejectionReason}',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppTheme.danger,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (rec.status == AttendanceStatus.rejected || rec.isMissingClockOut) ...[
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => CorrectionRequestDialog(attendance: rec),
                                  );
                                },
                                icon: const Icon(Icons.edit_note, size: 16),
                                label: const Text('Request Regularization', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayLiveStatusBanner(BuildContext context, AttendanceModel? todayRec, bool isDark) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, dd MMMM yyyy').format(now);

    String title = 'Not Clocked In Today';
    String subtitle = 'Office starts at 09:30 AM (15m grace period). Tap Clock-In to start shift.';
    Color color = Colors.grey.shade600;
    Color bgColor = Colors.grey.shade100;
    IconData icon = Icons.timer_off_outlined;

    if (todayRec != null) {
      if (todayRec.status == AttendanceStatus.pending) {
        if (todayRec.isLate) {
          title = 'Late Clock-In (Pending TL Approval)';
          subtitle = 'Clocked in at ${DateFormat('hh:mm a').format(todayRec.clockInTime!)} (${todayRec.lateMinutes.toHoursAndMinutes} late). Awaiting TL review.';
          color = const Color(0xFFDC2626);
          bgColor = const Color(0xFFFEF2F2);
          icon = Icons.warning_amber_rounded;
        } else {
          title = 'Clock-In Awaiting Review';
          subtitle = 'Clocked in at ${DateFormat('hh:mm a').format(todayRec.clockInTime!)} (${todayRec.timingStatus.label}). Awaiting TL review.';
          color = const Color(0xFFD97706);
          bgColor = const Color(0xFFFEF3C7);
          icon = Icons.hourglass_top_rounded;
        }
      } else if (todayRec.status == AttendanceStatus.approved) {
        title = 'Shift Active (Approved by TL)';
        subtitle = 'Clocked in at ${DateFormat('hh:mm a').format(todayRec.clockInTime!)} • Worked: ${todayRec.formattedNetDuration}';
        color = const Color(0xFF059669);
        bgColor = const Color(0xFFECFDF5);
        icon = Icons.verified_rounded;
      } else if (todayRec.status == AttendanceStatus.completed) {
        title = 'Shift Completed';
        subtitle = 'Net duration worked: ${todayRec.formattedNetDuration} • Clock Out: ${DateFormat('hh:mm a').format(todayRec.clockOutTime!)}';
        color = AppTheme.primary;
        bgColor = AppTheme.primarySoft;
        icon = Icons.check_circle_rounded;
      } else if (todayRec.status == AttendanceStatus.rejected) {
        title = 'Attendance Rejected';
        subtitle = 'Reason: ${todayRec.rejectionReason ?? "Rejected by TL"}';
        color = AppTheme.danger;
        bgColor = AppTheme.dangerSoft;
        icon = Icons.cancel_rounded;
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today\'s Status',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : color,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: isDark ? AppTheme.textMutedDark : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendChip(String text, Color fgColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fgColor,
        ),
      ),
    );
  }
}
