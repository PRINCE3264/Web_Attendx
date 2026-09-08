import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../config/app_theme.dart';
import '../../models/project_report_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hr_provider.dart';

import '../../services/storage_service.dart';

class SubmitProjectReportSheet extends StatefulWidget {
  const SubmitProjectReportSheet({super.key});

  @override
  State<SubmitProjectReportSheet> createState() => _SubmitProjectReportSheetState();
}

class _SubmitProjectReportSheetState extends State<SubmitProjectReportSheet> {
  final _formKey = GlobalKey<FormState>();
  final _workSummaryController = TextEditingController();
  final _blockersController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _selectedProject;
  double _hoursSpent = 8.0;
  final List<String> _screenshotPaths = [];
  final List<String> _videoPaths = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    final projects = context.read<HrProvider>().projectsList;

    if (user?.assignedProjectName != null &&
        user!.assignedProjectName!.isNotEmpty) {
      _selectedProject = user.assignedProjectName;
    } else if (projects.isNotEmpty) {
      _selectedProject = projects.first;
    } else {
      _selectedProject = 'Mobile App Revamp';
    }
  }

  @override
  void dispose() {
    _workSummaryController.dispose();
    _blockersController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> images = await _picker.pickMultiImage();
        if (images.isNotEmpty) {
          setState(() {
            _screenshotPaths.addAll(images.map((img) => img.path));
          });
        }
      } else {
        final XFile? image = await _picker.pickImage(source: source);
        if (image != null) {
          setState(() {
            _screenshotPaths.add(image.path);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 3),
      );
      if (video != null) {
        setState(() {
          _videoPaths.add(video.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick video: $e')),
        );
      }
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProject == null || _selectedProject!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a project')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) {
      setState(() => _isSubmitting = false);
      return;
    }

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final projectId = 'proj_${_selectedProject!.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
    final reportId = 'rep_${const Uuid().v4()}';

    final storageService = StorageService();
    final uploadedScreenshotUrls = <String>[];
    final uploadedVideoUrls = <String>[];

    for (int i = 0; i < _screenshotPaths.length; i++) {
      final path = _screenshotPaths[i];
      if (!path.startsWith('http') && !path.startsWith('data:')) {
        try {
          final url = await storageService.uploadProjectReportMedia(
            reportId: reportId,
            userId: user.userId,
            fileName: 'screenshot_$i.jpg',
            file: XFile(path),
          );
          uploadedScreenshotUrls.add(url);
        } catch (e) {
          debugPrint('Screenshot upload notice: $e');
          uploadedScreenshotUrls.add(path);
        }
      } else {
        uploadedScreenshotUrls.add(path);
      }
    }

    for (int i = 0; i < _videoPaths.length; i++) {
      final path = _videoPaths[i];
      if (!path.startsWith('http') && !path.startsWith('data:')) {
        try {
          final url = await storageService.uploadProjectReportMedia(
            reportId: reportId,
            userId: user.userId,
            fileName: 'video_$i.mp4',
            file: XFile(path),
          );
          uploadedVideoUrls.add(url);
        } catch (e) {
          debugPrint('Video upload notice: $e');
          uploadedVideoUrls.add(path);
        }
      } else {
        uploadedVideoUrls.add(path);
      }
    }

    final report = ProjectReportModel(
      reportId: reportId,
      employeeId: user.userId,
      employeeName: user.name,
      employeeAvatar: user.avatarUrl,
      projectId: projectId,
      projectName: _selectedProject!,
      date: todayStr,
      submittedAt: DateTime.now(),
      workSummary: _workSummaryController.text.trim(),
      hoursSpent: _hoursSpent,
      blockers: _blockersController.text.trim().isEmpty ? null : _blockersController.text.trim(),
      screenshotUrls: uploadedScreenshotUrls,
      videoUrls: uploadedVideoUrls,
      status: 'submitted',
    );

    final hrProv = context.read<HrProvider>();
    await hrProv.submitDailyReport(report);

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Daily Project Report for "$_selectedProject" submitted successfully!'),
              ),
            ],
          ),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final hrProv = context.watch<HrProvider>();
    final allProjects = hrProv.projects;
    final Set<String> projectSet = {};
    for (final proj in allProjects) {
      if (user?.role == UserRole.admin) {
        projectSet.add(proj.projectName);
      } else {
        if (proj.projectId == user?.assignedProjectId ||
            (user?.assignedProjectName != null &&
                proj.projectName.toLowerCase() == user?.assignedProjectName?.toLowerCase()) ||
            proj.assignedEmployeeIds.contains(user?.userId) ||
            (user?.employeeId != null && proj.assignedEmployeeIds.contains(user?.employeeId)) ||
            proj.assignedLeadId == user?.userId ||
            proj.assignedLeadId == user?.employeeId) {
          projectSet.add(proj.projectName);
        }
      }
    }
    if (user?.assignedProjectName != null && user!.assignedProjectName!.isNotEmpty) {
      projectSet.add(user.assignedProjectName!);
    }
    if (_selectedProject != null && _selectedProject!.isNotEmpty) {
      projectSet.add(_selectedProject!);
    }
    final projects = projectSet.isEmpty ? ['Unassigned Project'] : projectSet.toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sheet Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.assignment_add, color: AppTheme.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Submit Daily Project Report',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Project Selection Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedProject,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Select Project',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.folder_special_outlined),
                ),
                items: projects.map((proj) {
                  return DropdownMenuItem(
                    value: proj,
                    child: Text(proj, maxLines: 1, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedProject = val);
                },
                validator: (val) => (val == null || val.isEmpty) ? 'Please select a project' : null,
              ),

              const SizedBox(height: 16),

              // Hours Spent Slider / Selection
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
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
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 18, color: AppTheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Hours Spent Today',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_hoursSpent.toStringAsFixed(1)} hrs',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _hoursSpent,
                      min: 0.5,
                      max: 12.0,
                      divisions: 23,
                      activeColor: AppTheme.primary,
                      label: '${_hoursSpent.toStringAsFixed(1)} h',
                      onChanged: (val) => setState(() => _hoursSpent = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Accomplishments & Work Summary
              TextFormField(
                controller: _workSummaryController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Tasks Completed & Accomplishments *',
                  hintText: 'List key work items completed today, features implemented, bugs resolved...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please detail your daily tasks' : null,
              ),

              const SizedBox(height: 16),

              // Blockers & Challenges (Optional)
              TextFormField(
                controller: _blockersController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Blockers / Pending Dependencies (Optional)',
                  hintText: 'Any issues blocking your progress or needing manager support...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 20),

              // Media Proof Section Header
              Text(
                'Work Verification & Proof (Screenshots & Video)',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Attach visual verification for TL and HR review.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                ),
              ),

              const SizedBox(height: 12),

              // Upload Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                      label: const Text(
                        'Screenshot',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                        side: const BorderSide(color: AppTheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined, size: 16),
                      label: const Text(
                        'Camera',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                        side: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickVideo(ImageSource.gallery),
                      icon: const Icon(Icons.video_call_outlined, size: 16, color: AppTheme.accent),
                      label: const Text(
                        'Add Video',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, color: AppTheme.accent),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                        side: const BorderSide(color: AppTheme.accent),
                      ),
                    ),
                  ),
                ],
              ),

              // Screenshot Thumbnails Grid
              if (_screenshotPaths.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'Screenshots (${_screenshotPaths.length}):',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _screenshotPaths.length,
                    itemBuilder: (context, index) {
                      final path = _screenshotPaths[index];

                      return Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                          color: isDark ? AppTheme.cardDark : Colors.grey.shade200,
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: _buildSmartImage(path, fit: BoxFit.cover, width: 90, height: 90),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _screenshotPaths.removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],

              // Video Previews List
              if (_videoPaths.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'Video Proof Clips (${_videoPaths.length}):',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Column(
                  children: _videoPaths.asMap().entries.map((entry) {
                    final index = entry.key;
                    final path = entry.value;
                    final fileName = path.split(RegExp(r'[/\\]')).last;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppTheme.accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Video Proof Clip attached',
                                  style: GoogleFonts.inter(fontSize: 10, color: AppTheme.accent),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () {
                              setState(() {
                                _videoPaths.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitReport,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 20),
                label: Text(
                  _isSubmitting ? 'SUBMITTING REPORT...' : 'SUBMIT DAILY WORK REPORT',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
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

    final lower = path.toLowerCase();
    final isNetwork = lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('blob:') ||
        lower.startsWith('data:');

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
