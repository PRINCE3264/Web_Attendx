import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/policy_model.dart';
import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hr_provider.dart';
import '../../services/firestore_service.dart';

class SystemSettingsScreen extends StatefulWidget {
  final bool isEmbedded;
  const SystemSettingsScreen({super.key, this.isEmbedded = false});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  late TextEditingController _officeNameController;
  late TextEditingController _startTimeController;
  late TextEditingController _graceController;
  late TextEditingController _minHoursController;
  late TextEditingController _maxBreakController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late TextEditingController _radiusController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final policy = FirestoreService().currentPolicy;
    _officeNameController = TextEditingController(text: policy.officeName);
    _startTimeController = TextEditingController(text: policy.officeStartTime);
    _graceController = TextEditingController(text: '${policy.gracePeriodMinutes}');
    _minHoursController = TextEditingController(text: '${policy.minimumWorkingHours}');
    _maxBreakController = TextEditingController(text: '${policy.maxBreakMinutes}');
    _latController = TextEditingController(text: '${policy.officeLatitude}');
    _lngController = TextEditingController(text: '${policy.officeLongitude}');
    _radiusController = TextEditingController(text: '${policy.geofenceRadiusMeters}');
  }

  @override
  void dispose() {
    _officeNameController.dispose();
    _startTimeController.dispose();
    _graceController.dispose();
    _minHoursController.dispose();
    _maxBreakController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _saveSystemSettings() async {
    final auth = context.read<AuthProvider>();
    final adminProv = context.read<AdminProvider>();
    final currentUser = auth.currentUser;

    if (currentUser?.role != UserRole.admin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permission Denied: Only Admins can modify system settings.'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final updatedPolicy = AttendancePolicyModel(
      officeName: _officeNameController.text.trim().isEmpty ? 'HQ Office' : _officeNameController.text.trim(),
      officeStartTime: _startTimeController.text.trim().isEmpty ? '09:00 AM' : _startTimeController.text.trim(),
      gracePeriodMinutes: int.tryParse(_graceController.text.trim()) ?? 15,
      minimumWorkingHours: double.tryParse(_minHoursController.text.trim()) ?? 8.0,
      maxBreakMinutes: int.tryParse(_maxBreakController.text.trim()) ?? 60,
      officeLatitude: double.tryParse(_latController.text.trim()) ?? 21.1986872,
      officeLongitude: double.tryParse(_lngController.text.trim()) ?? 72.7965515,
      geofenceRadiusMeters: double.tryParse(_radiusController.text.trim()) ?? 500.0,
    );

    final success = await adminProv.updatePolicy(updatedPolicy, currentUser!);
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'System Settings & Company Policy updated successfully!' : 'Failed to update system settings.'),
          backgroundColor: success ? AppTheme.success : AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.currentUser;
    final isAdmin = currentUser?.role == UserRole.admin;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final canPop = Navigator.canPop(context);
    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : const Color(0xFFF8FAFC),
      appBar: (widget.isEmbedded && !canPop)
          ? null
          : AppBar(
              leading: canPop
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.pop(context),
                    )
                  : null,
              title: Text(
                'System Settings',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Access Control Role Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isAdmin
                      ? (isDark ? AppTheme.cardDark : AppTheme.primarySoft)
                      : (isDark ? const Color(0xFF1E1E2E) : const Color(0xFFFEF3C7)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isAdmin
                        ? AppTheme.primary.withValues(alpha: 0.3)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isAdmin ? Icons.admin_panel_settings : Icons.lock_outline,
                      color: isAdmin ? AppTheme.primary : const Color(0xFFD97706),
                      size: 28,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAdmin ? 'Admin Mode (Edit & Update Access)' : 'System Overview (Read-Only Mode)',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isAdmin
                                  ? (isDark ? Colors.white : AppTheme.primary)
                                  : (isDark ? Colors.white : const Color(0xFF92400E)),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isAdmin
                                ? 'You have full administrative privileges to edit company rules, geofence, and shift timings.'
                                : 'You are logged in as ${currentUser?.role.name.toUpperCase() ?? "User"}. System configuration can only be edited by System Admins.',
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
              ),

              const SizedBox(height: 24),

              // Section 1: Company & Office Premises
              _buildSectionHeader('Office Premises & Location', Icons.business_rounded, isDark),
              const SizedBox(height: 12),

              TextField(
                controller: _officeNameController,
                enabled: isAdmin,
                decoration: InputDecoration(
                  labelText: 'Office Premises Name',
                  prefixIcon: const Icon(Icons.business),
                  filled: !isAdmin,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _latController,
                      enabled: isAdmin,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Latitude',
                        prefixIcon: const Icon(Icons.location_searching),
                        filled: !isAdmin,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _lngController,
                      enabled: isAdmin,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Longitude',
                        prefixIcon: const Icon(Icons.location_searching),
                        filled: !isAdmin,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _radiusController,
                enabled: isAdmin,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Geofence Perimeter (Meters)',
                  prefixIcon: const Icon(Icons.radar),
                  filled: !isAdmin,
                ),
              ),

              const SizedBox(height: 24),

              // Section 2: Shift Timing & Grace Rules
              _buildSectionHeader('Shift Timing & Attendance Rules', Icons.schedule_rounded, isDark),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _startTimeController,
                      enabled: isAdmin,
                      decoration: InputDecoration(
                        labelText: 'Office Start Time',
                        prefixIcon: const Icon(Icons.access_time),
                        filled: !isAdmin,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _graceController,
                      enabled: isAdmin,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Grace Period (Mins)',
                        prefixIcon: const Icon(Icons.timer),
                        filled: !isAdmin,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minHoursController,
                      enabled: isAdmin,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Min Working Shift (Hrs)',
                        prefixIcon: const Icon(Icons.hourglass_bottom),
                        filled: !isAdmin,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _maxBreakController,
                      enabled: isAdmin,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Max Break (Mins)',
                        prefixIcon: const Icon(Icons.coffee),
                        filled: !isAdmin,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Section 3: App & Firebase Sync Status
              _buildSectionHeader('System Info & Cloud Services', Icons.cloud_done_rounded, isDark),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('App Version', 'AttendX v1.0.0+1 (Production Build)', Icons.info_outline),
                    const Divider(height: 20),
                    _buildInfoRow('Database Engine', 'Google Cloud Firestore (Real-Time)', Icons.storage_rounded),
                    const Divider(height: 20),
                    _buildInfoRow('Storage Service', 'Firebase Cloud Storage (Media Proof)', Icons.cloud_upload_outlined),
                    const Divider(height: 20),
                    _buildInfoRow('Project Master List', '${context.watch<HrProvider>().projectsList.length} Active Projects Registered', Icons.folder_special_outlined),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Save Action Button (Admin ONLY)
              if (isAdmin) ...[
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveSystemSettings,
                  icon: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded, size: 20),
                  label: Text(
                    _isSaving ? 'SAVING SYSTEM SETTINGS...' : 'SAVE & APPLY SYSTEM SETTINGS',
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
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Editing restricted to Admin accounts only',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.textMainLight,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.secondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
