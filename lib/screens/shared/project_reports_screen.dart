import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/project_report_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hr_provider.dart';
import '../shared/custom_widgets.dart';

class ProjectReportsScreen extends StatefulWidget {
  final bool isEmbedded;
  const ProjectReportsScreen({super.key, this.isEmbedded = true});

  @override
  State<ProjectReportsScreen> createState() => _ProjectReportsScreenState();
}

class _ProjectReportsScreenState extends State<ProjectReportsScreen> {
  String _selectedProject = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final hrProv = context.watch<HrProvider>();
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final projects = ['All', ...hrProv.projectsList];
    List<ProjectReportModel> reports = hrProv.dailyProjectReports;

    // Filter by TL if logged in as TL
    if (currentUser?.role == UserRole.manager && currentUser != null) {
      final teamEmpKeys = <String>{};
      for (final e in hrProv.allEmployees) {
        final assignedByManagerId =
            e.managerId == currentUser.userId ||
            (currentUser.employeeId.isNotEmpty && e.managerId == currentUser.employeeId) ||
            (currentUser.name.isNotEmpty && e.managerId == currentUser.name) ||
            (currentUser.email.isNotEmpty && e.managerId == currentUser.email);
        final assignedByManagerName =
            e.managerName != null &&
            e.managerName!.isNotEmpty &&
            e.managerName!.trim().toLowerCase() == currentUser.name.trim().toLowerCase();
        final sameTeam = e.teamId.isNotEmpty && e.teamId == currentUser.teamId;
        final sameProject = currentUser.assignedProjectName != null &&
            currentUser.assignedProjectName!.isNotEmpty &&
            e.assignedProjectName != null &&
            e.assignedProjectName!.toLowerCase() == currentUser.assignedProjectName!.toLowerCase();

        if (assignedByManagerId || assignedByManagerName || sameTeam || sameProject) {
          teamEmpKeys.add(e.userId);
          if (e.employeeId.isNotEmpty) teamEmpKeys.add(e.employeeId);
          if (e.name.isNotEmpty) teamEmpKeys.add(e.name.toLowerCase());
        }
      }
      teamEmpKeys.add(currentUser.userId);
      if (currentUser.employeeId.isNotEmpty) teamEmpKeys.add(currentUser.employeeId);
      if (currentUser.name.isNotEmpty) teamEmpKeys.add(currentUser.name.toLowerCase());

      reports = reports.where((r) =>
        teamEmpKeys.contains(r.employeeId) ||
        teamEmpKeys.contains(r.employeeName.toLowerCase())
      ).toList();
    } else if (currentUser?.role == UserRole.employee && currentUser != null) {
      // Filter for Employee to only see their own reports
      reports = reports.where((r) =>
        r.employeeId == currentUser.userId ||
        (currentUser.employeeId.isNotEmpty && r.employeeId == currentUser.employeeId) ||
        r.employeeName.toLowerCase() == currentUser.name.toLowerCase()
      ).toList();
    }

    // Filter by Project
    if (_selectedProject != 'All') {
      reports = reports.where((r) => r.projectName.toLowerCase() == _selectedProject.toLowerCase()).toList();
    }

    // Filter by Search Query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      reports = reports.where((r) =>
        r.employeeName.toLowerCase().contains(q) ||
        r.projectName.toLowerCase().contains(q) ||
        r.workSummary.toLowerCase().contains(q)
      ).toList();
    }

    final totalHours = reports.fold<double>(0, (sum, r) => sum + r.hoursSpent);
    final uniqueProjectsCount = reports.map((r) => r.projectName).toSet().length;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : const Color(0xFFF8FAFC),
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: Text(
                'Daily Project Work Reports',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
      body: SafeArea(
        child: Column(
          children: [
            // Top KPI Overview Banner
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Reports',
                      '${reports.length}',
                      Icons.folder_shared_outlined,
                      AppTheme.primary,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryCard(
                      'Hours Logged',
                      '${totalHours.toStringAsFixed(1)} h',
                      Icons.access_time_rounded,
                      AppTheme.success,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryCard(
                      'Active Projects',
                      '$uniqueProjectsCount',
                      Icons.work_outline_rounded,
                      AppTheme.accent,
                      isDark,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar (Row 1 - Full Width)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                decoration: InputDecoration(
                  hintText: 'Search report, employee, tasks...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                ),
              ),
            ),

            // Project Dropdown Filter (Row 2 - Full Width)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedProject,
                    isExpanded: true,
                    icon: const Icon(Icons.filter_list_rounded, size: 20, color: AppTheme.primary),
                    items: projects.map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(
                        p == 'All' ? 'Filter by Project: All Projects' : 'Project: $p',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedProject = val);
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Reports List Feed
            Expanded(
              child: reports.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size: 48,
                              color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No Work Reports Found',
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'No daily project reports match the current filter or search query.',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: reports.length,
                      itemBuilder: (context, index) {
                        final report = reports[index];
                        return _buildReportCard(context, report, isDark);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, ProjectReportModel report, bool isDark) {
    final auth = context.watch<AuthProvider>();
    final hrProv = context.watch<HrProvider>();
    final currentUser = auth.currentUser;
    final submittedTimeStr = DateFormat('dd MMM yyyy, hh:mm a').format(report.submittedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
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
          // Employee Info & Project Badge Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PhotoDisplayWidget(
                photoUrl: report.employeeAvatar,
                size: 42,
                borderRadius: 21,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.employeeName,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      submittedTimeStr,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              // Hours & Project Pill & Delete Action
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '${report.hoursSpent.toStringAsFixed(1)} hrs',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      if (currentUser?.role == UserRole.admin || currentUser?.role == UserRole.hr) ...[
                        const SizedBox(width: 2),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                          icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 18),
                          tooltip: 'Delete Report from DB',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (dlgCtx) => AlertDialog(
                                title: const Text('Delete Work Report?'),
                                content: Text('Delete daily work report for "${report.projectName}" submitted by ${report.employeeName} permanently from Firebase Firestore DB?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dlgCtx),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      Navigator.pop(dlgCtx);
                                      await hrProv.deleteProjectReport(report.reportId, currentUser!);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('🗑️ Work Report permanently deleted from DB.'),
                                            backgroundColor: AppTheme.danger,
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                                    child: const Text('Delete from DB'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Project Name Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.folder_special_rounded, size: 14, color: AppTheme.secondary),
                const SizedBox(width: 6),
                Text(
                  report.projectName,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Accomplishments / Work Summary Text
          Text(
            'Tasks & Summary:',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 2),
          Text(
            report.workSummary,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.4,
              color: isDark ? Colors.white : AppTheme.textMainLight,
            ),
          ),

          // Blockers Section (if any)
          if (report.blockers != null && report.blockers!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.dangerSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.danger.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Blocker: ${report.blockers}',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Media Proof Section (Screenshots Gallery)
          if (report.screenshotUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Screenshot Proof (${report.screenshotUrls.length}):',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 75,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: report.screenshotUrls.length,
                itemBuilder: (context, imgIdx) {
                  final imgPath = report.screenshotUrls[imgIdx];

                  return GestureDetector(
                    onTap: () => _openImageLightbox(context, imgPath),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _buildSmartImage(imgPath, fit: BoxFit.cover, width: 75, height: 75),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // Video Proof Clips Section
          if (report.videoUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Video Demo Proof (${report.videoUrls.length}):',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Column(
              children: report.videoUrls.map((vPath) {
                final fileName = vPath.split(RegExp(r'[/\\]')).last;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.play_circle_fill_rounded, color: AppTheme.accent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'VIDEO PROOF',
                          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _openImageLightbox(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 500),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildSmartImage(imagePath, fit: BoxFit.contain),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartImage(String path, {BoxFit fit = BoxFit.cover, double? width, double? height}) {
    if (path.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey.shade300,
        child: const Icon(Icons.image, color: Colors.grey),
      );
    }

    if (path.startsWith('data:image')) {
      try {
        final base64Part = path.split(',').last;
        final bytes = base64Decode(base64Part);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => Container(
            width: width,
            height: height,
            color: Colors.grey.shade300,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
        );
      } catch (_) {}
    }

    final lower = path.toLowerCase();
    final isNetwork = lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('blob:');

    if (isNetwork) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade300,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }

    if (!kIsWeb) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          return Image.file(
            file,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => Container(
              width: width,
              height: height,
              color: Colors.grey.shade300,
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          );
        }
      } catch (_) {}
    }

    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade300,
      child: const Icon(Icons.image, color: Colors.grey),
    );
  }
}
