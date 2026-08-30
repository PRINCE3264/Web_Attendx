import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/policy_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';

class PolicySettingsScreen extends StatefulWidget {
  final bool isEmbedded;
  const PolicySettingsScreen({super.key, this.isEmbedded = true});

  @override
  State<PolicySettingsScreen> createState() => _PolicySettingsScreenState();
}

class _PolicySettingsScreenState extends State<PolicySettingsScreen> {
  late TextEditingController _startTimeController;
  late TextEditingController _graceController;
  late TextEditingController _minHoursController;
  late TextEditingController _maxBreakController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late TextEditingController _radiusController;
  late TextEditingController _officeNameController;

  @override
  void initState() {
    super.initState();
    final policy = context.read<AdminProvider>().policy;
    _startTimeController = TextEditingController(text: policy.officeStartTime);
    _graceController = TextEditingController(text: '${policy.gracePeriodMinutes}');
    _minHoursController = TextEditingController(text: '${policy.minimumWorkingHours}');
    _maxBreakController = TextEditingController(text: '${policy.maxBreakMinutes}');
    _latController = TextEditingController(text: '${policy.officeLatitude}');
    _lngController = TextEditingController(text: '${policy.officeLongitude}');
    _radiusController = TextEditingController(text: '${policy.geofenceRadiusMeters}');
    _officeNameController = TextEditingController(text: policy.officeName);
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _graceController.dispose();
    _minHoursController.dispose();
    _maxBreakController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    _officeNameController.dispose();
    super.dispose();
  }

  void _savePolicy() async {
    final auth = context.read<AuthProvider>();
    final adminProv = context.read<AdminProvider>();
    final admin = auth.currentUser;
    if (admin == null) return;

    final updated = AttendancePolicyModel(
      officeStartTime: _startTimeController.text.trim(),
      gracePeriodMinutes: int.tryParse(_graceController.text.trim()) ?? 15,
      minimumWorkingHours: double.tryParse(_minHoursController.text.trim()) ?? 8.0,
      maxBreakMinutes: int.tryParse(_maxBreakController.text.trim()) ?? 60,
      officeLatitude: double.tryParse(_latController.text.trim()) ?? 28.6139,
      officeLongitude: double.tryParse(_lngController.text.trim()) ?? 77.2090,
      geofenceRadiusMeters: double.tryParse(_radiusController.text.trim()) ?? 300.0,
      officeName: _officeNameController.text.trim().isEmpty ? 'HQ Office' : _officeNameController.text.trim(),
    );

    final success = await adminProv.updatePolicy(updated, admin);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance Policy & Geofence rules updated successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: Text(
                'Attendance Policy Engine',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : AppTheme.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.primaryLight.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.rule, color: AppTheme.primary, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Configurable Company Rules',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            'Control shift timing thresholds, grace periods, and office GPS perimeter.',
                            style: GoogleFonts.inter(fontSize: 12, color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Shift Timing Section
              Text('Shift & Timing Rules', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _startTimeController,
                      decoration: const InputDecoration(labelText: 'Office Start (HH:mm)', prefixIcon: Icon(Icons.schedule)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _graceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Grace Period (Mins)', prefixIcon: Icon(Icons.timer)),
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Min Working Shift (Hours)', prefixIcon: Icon(Icons.hourglass_empty)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _maxBreakController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Max Break Allowed (Mins)', prefixIcon: Icon(Icons.coffee)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Geofencing & GPS Perimeter Section
              Text('Office Geofencing & GPS Coordinates', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              TextField(
                controller: _officeNameController,
                decoration: const InputDecoration(labelText: 'Office Premises Name', prefixIcon: Icon(Icons.business)),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _latController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Latitude', prefixIcon: Icon(Icons.location_searching)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _lngController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Longitude', prefixIcon: Icon(Icons.location_searching)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _radiusController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Geofence Allowed Radius (Meters)', prefixIcon: Icon(Icons.radar)),
              ),

              const SizedBox(height: 28),

              ElevatedButton.icon(
                onPressed: _savePolicy,
                icon: const Icon(Icons.save, size: 18),
                label: const Text('SAVE & APPLY POLICY RULES'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
