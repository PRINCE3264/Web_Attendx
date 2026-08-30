import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/hr_provider.dart';
import '../../services/report_service.dart';
import '../shared/custom_widgets.dart';
import 'add_employee_sheet.dart';

class AllEmployeesScreen extends StatelessWidget {
  final bool isEmbedded;
  const AllEmployeesScreen({super.key, this.isEmbedded = true});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final hr = context.watch<HrProvider>();
    final attendance = context.watch<AttendanceProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = auth.currentUser;

    // Filter employees: if logged in as TL (manager), only show employees assigned to that TL
    final employees = (currentUser?.role == UserRole.manager && currentUser != null)
        ? hr.filteredEmployees.where((e) => e.managerId == currentUser.userId).toList()
        : hr.filteredEmployees;

    return Scaffold(
      appBar: isEmbedded
          ? null
          : AppBar(
              title: Text(
                currentUser?.role == UserRole.manager ? 'Team Roster' : 'All Employees Directory',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
      floatingActionButton: (currentUser?.role == UserRole.admin || currentUser?.role == UserRole.hr) 
          ? FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => const AddEmployeeSheet(),
                );
              },
              backgroundColor: AppTheme.primary,
              child: const Icon(Icons.person_add, color: Colors.white),
            )
          : null,
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

            // Department Filters (only for HR/Admin)
            if (currentUser?.role != UserRole.manager)
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
                          onSelected: (selected) {
                            if (selected) hr.setDepartmentFilter(dept);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // Employee List View
            Expanded(
              child: employees.isEmpty
                  ? Center(
                      child: Text(
                        'No employees found matching query.',
                        style: GoogleFonts.inter(color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: employees.length,
                      itemBuilder: (context, index) {
                        final emp = employees[index];
                        final todayRec = attendance.getTodayAttendance(emp.userId);
                        final report = ReportService.calculate30DayReport(
                          employee: emp,
                          attendanceList: attendance.getEmployeeHistory(emp.userId),
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
                                        if (emp.managerName != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'TL: ${emp.managerName}',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.secondary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (todayRec != null)
                                    StatusBadge(status: todayRec.status, isCompact: true)
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.dangerSoft,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                                      ),
                                      child: const Text(
                                        'Not Clocked',
                                        style: TextStyle(
                                          color: AppTheme.danger,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStatItem('30-Day Rate', '${report.attendancePercentage.toStringAsFixed(1)}%'),
                                  _buildStatItem('Days Present', '${report.presentDays} days'),
                                  _buildStatItem('Late In', '${report.lateArrivals} times'),
                                  _buildStatItem('Absent', '${report.absentDays} days'),
                                ],
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

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
