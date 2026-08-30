import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/hr_provider.dart';
import '../../services/report_service.dart';
import '../shared/custom_widgets.dart';

class AllEmployeesScreen extends StatelessWidget {
  const AllEmployeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hr = context.watch<HrProvider>();
    final attendance = context.watch<AttendanceProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final employees = hr.filteredEmployees;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Employees Directory',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar & Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                onChanged: (val) => hr.setSearchQuery(val),
                decoration: InputDecoration(
                  hintText: 'Search employee name or ID (e.g. EMP-1042)...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: hr.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => hr.setSearchQuery(''),
                        )
                      : null,
                ),
              ),
            ),

            // Department Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Engineering', 'Design & UI'].map((dept) {
                    final isSelected = hr.selectedDepartmentFilter == dept;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(dept),
                        selected: isSelected,
                        onSelected: (_) => hr.setDepartmentFilter(dept),
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

            const SizedBox(height: 8),

            // Employee List
            Expanded(
              child: employees.isEmpty
                  ? Center(
                      child: Text(
                        'No employees found',
                        style: GoogleFonts.inter(
                          color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: employees.length,
                      itemBuilder: (context, index) {
                        final emp = employees[index];
                        final history = attendance.getEmployeeHistory(emp.userId);
                        final rep = ReportService.calculate30DayReport(
                          employee: emp,
                          attendanceList: history,
                        );

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
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    child: ClipOval(
                                      child: PhotoDisplayWidget(
                                        photoUrl: emp.avatarUrl,
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
                                          emp.name,
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${emp.employeeId} • ${emp.department}',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                          ),
                                        ),
                                        Text(
                                          'TL: ${emp.managerName ?? "Vikram Mehta"}',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: rep.attendancePercentage >= 90
                                          ? AppTheme.successSoft
                                          : AppTheme.warningSoft,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${rep.attendancePercentage}% Rate',
                                      style: TextStyle(
                                        color: rep.attendancePercentage >= 90
                                            ? AppTheme.success
                                            : AppTheme.warning,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.cardDarkAlt : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildMetric('Present', '${rep.presentDays} d', AppTheme.success),
                                    _buildMetric('Absent', '${rep.absentDays} d', AppTheme.danger),
                                    _buildMetric('Total Hours', '${rep.totalHoursWorked} h', AppTheme.primary),
                                    _buildMetric('Avg/Day', '${rep.averageDailyHours} h', AppTheme.secondary),
                                  ],
                                ),
                              ),
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

  Widget _buildMetric(String label, String val, Color color) {
    return Column(
      children: [
        Text(
          val,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}
