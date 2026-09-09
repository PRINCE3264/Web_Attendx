import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../config/app_theme.dart';
import '../../models/policy_model.dart';
import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

class SystemSettingsScreen extends StatefulWidget {
  final bool isEmbedded;
  const SystemSettingsScreen({super.key, this.isEmbedded = true});

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
  late MapController _mapController;
  double _currentZoom = 16.0;

  bool _isSaving = false;

  void _onSettingChanged() {
    if (mounted) {
      final lat = double.tryParse(_latController.text.trim()) ?? 21.1986872;
      final lng = double.tryParse(_lngController.text.trim()) ?? 72.7965515;
      try {
        _mapController.move(LatLng(lat, lng), _currentZoom);
      } catch (_) {}
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    final policy = FirestoreService().currentPolicy;
    _officeNameController = TextEditingController(text: policy.officeName);
    _startTimeController = TextEditingController(text: policy.officeStartTime);
    _graceController = TextEditingController(
      text: '${policy.gracePeriodMinutes}',
    );
    _minHoursController = TextEditingController(
      text: '${policy.minimumWorkingHours}',
    );
    _maxBreakController = TextEditingController(
      text: '${policy.maxBreakMinutes}',
    );
    _latController = TextEditingController(text: '${policy.officeLatitude}');
    _lngController = TextEditingController(text: '${policy.officeLongitude}');
    _radiusController = TextEditingController(
      text: '${policy.geofenceRadiusMeters}',
    );

    _officeNameController.addListener(_onSettingChanged);
    _latController.addListener(_onSettingChanged);
    _lngController.addListener(_onSettingChanged);
    _radiusController.addListener(_onSettingChanged);
  }

  @override
  void dispose() {
    _officeNameController.removeListener(_onSettingChanged);
    _latController.removeListener(_onSettingChanged);
    _lngController.removeListener(_onSettingChanged);
    _radiusController.removeListener(_onSettingChanged);

    _mapController.dispose();
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

  void _zoomInMap() {
    try {
      final center = _mapController.camera.center;
      final zoom = (_mapController.camera.zoom + 1.0).clamp(3.0, 19.0);
      _mapController.move(center, zoom);
      setState(() {
        _currentZoom = zoom;
      });
    } catch (_) {}
  }

  void _zoomOutMap() {
    try {
      final center = _mapController.camera.center;
      final zoom = (_mapController.camera.zoom - 1.0).clamp(3.0, 19.0);
      _mapController.move(center, zoom);
      setState(() {
        _currentZoom = zoom;
      });
    } catch (_) {}
  }

  void _resetMapZoom() {
    try {
      final lat = double.tryParse(_latController.text.trim()) ?? 21.1986872;
      final lng = double.tryParse(_lngController.text.trim()) ?? 72.7965515;
      _mapController.move(LatLng(lat, lng), 16.0);
      setState(() {
        _currentZoom = 16.0;
      });
    } catch (_) {}
  }

  Future<void> _saveSystemSettings() async {
    final auth = context.read<AuthProvider>();
    final adminProv = context.read<AdminProvider>();
    final currentUser = auth.currentUser;

    if (currentUser?.role != UserRole.admin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Permission Denied: Only Admins can modify system settings.',
          ),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final updatedPolicy = AttendancePolicyModel(
      officeName: _officeNameController.text.trim().isEmpty
          ? 'HQ Office'
          : _officeNameController.text.trim(),
      officeStartTime: _startTimeController.text.trim().isEmpty
          ? '09:00 AM'
          : _startTimeController.text.trim(),
      gracePeriodMinutes: int.tryParse(_graceController.text.trim()) ?? 15,
      minimumWorkingHours:
          double.tryParse(_minHoursController.text.trim()) ?? 8.0,
      maxBreakMinutes: int.tryParse(_maxBreakController.text.trim()) ?? 60,
      officeLatitude: double.tryParse(_latController.text.trim()) ?? 21.1986872,
      officeLongitude:
          double.tryParse(_lngController.text.trim()) ?? 72.7965515,
      geofenceRadiusMeters:
          double.tryParse(_radiusController.text.trim()) ?? 500.0,
    );

    final success = await adminProv.updatePolicy(updatedPolicy, currentUser!);
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'System Settings & Company Policy updated successfully!'
                : 'Failed to update system settings.',
          ),
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
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
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
                      : (isDark
                            ? const Color(0xFF1E1E2E)
                            : const Color(0xFFFEF3C7)),
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
                      color: isAdmin
                          ? AppTheme.primary
                          : const Color(0xFFD97706),
                      size: 28,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAdmin
                                ? 'Admin Mode (Edit & Update Access)'
                                : 'System Overview (Read-Only Mode)',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isAdmin
                                  ? (isDark ? Colors.white : AppTheme.primary)
                                  : (isDark
                                        ? Colors.white
                                        : const Color(0xFF92400E)),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isAdmin
                                ? 'You have full administrative privileges to edit company rules, geofence, and shift timings.'
                                : 'You are logged in as ${currentUser?.role.name.toUpperCase() ?? "User"}. System configuration can only be edited by System Admins.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark
                                  ? AppTheme.textMutedDark
                                  : AppTheme.textMutedLight,
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
              _buildSectionHeader(
                'Office Premises & Location',
                Icons.business_rounded,
                isDark,
              ),
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Geofence Perimeter (Meters)',
                  prefixIcon: const Icon(Icons.radar),
                  filled: !isAdmin,
                ),
              ),

              const SizedBox(height: 14),

              // Visual Live Map Preview Widget
              _buildMapPreviewWidget(isDark),

              const SizedBox(height: 12),

              // Interactive Google Maps HQ Location Card
              InkWell(
                onTap: _openGoogleMapsLocation,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.map_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Open HQ Location on Google Maps',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tap to view navigation & directions',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.open_in_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Section 2: Shift Timing & Grace Rules
              _buildSectionHeader(
                'Shift Timing & Attendance Rules',
                Icons.schedule_rounded,
                isDark,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _startTimeController,
                      enabled: isAdmin,
                      decoration: InputDecoration(
                        labelText: 'Start Time',
                        hintText: '09:00 AM',
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
                        labelText: 'Grace (Mins)',
                        hintText: '15',
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Min Hours',
                        hintText: '8.0',
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
                        hintText: '60',
                        prefixIcon: const Icon(Icons.coffee),
                        filled: !isAdmin,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Save Action Button (Admin ONLY)
              if (isAdmin) ...[
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveSystemSettings,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded, size: 20),
                  label: Text(
                    _isSaving
                        ? 'SAVING SYSTEM SETTINGS...'
                        : 'SAVE & APPLY SYSTEM SETTINGS',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Editing restricted to Admin accounts only',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
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



  Future<void> _openGoogleMapsLocation() async {
    final lat = double.tryParse(_latController.text.trim()) ?? 21.1986872;
    final lng = double.tryParse(_lngController.text.trim()) ?? 72.7965515;
    final mapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final Uri url = Uri.parse(mapsUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Error launching map URL: $e');
    }
  }

  Widget _buildMapPreviewWidget(bool isDark) {
    final officeName = _officeNameController.text.trim().isEmpty
        ? 'United Green Hospital'
        : _officeNameController.text.trim();
    final lat = double.tryParse(_latController.text.trim()) ?? 21.1986872;
    final lng = double.tryParse(_lngController.text.trim()) ?? 72.7965515;
    final radiusValue = double.tryParse(_radiusController.text.trim()) ?? 300.0;
    final targetLatLng = LatLng(lat, lng);
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.currentUser?.role == UserRole.admin;

    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // Dynamic Live OpenStreetMap Canvas
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: targetLatLng,
                  initialZoom: _currentZoom,
                  minZoom: 3.0,
                  maxZoom: 19.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                  onPositionChanged: (pos, hasGesture) {
                    if ((pos.zoom - _currentZoom).abs() > 0.05) {
                      setState(() {
                        _currentZoom = pos.zoom;
                      });
                    }
                  },
                  onTap: isAdmin
                      ? (tapPosition, point) {
                          _latController.text = point.latitude.toStringAsFixed(7);
                          _lngController.text = point.longitude.toStringAsFixed(7);
                          _mapController.move(point, _currentZoom);
                          setState(() {});
                        }
                      : null,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.attendx.smartattendance',
                    maxZoom: 19,
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: targetLatLng,
                        width: 260,
                        height: 120,
                        alignment: Alignment.topCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              constraints: const BoxConstraints(maxWidth: 240),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0F172A)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF2563EB),
                                  width: 1.2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    officeName,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFDC2626),
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'GPS: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)} • ${radiusValue.toStringAsFixed(0)}m Geofence',
                                    style: GoogleFonts.inter(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppTheme.textMutedDark
                                          : const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFFEA4335),
                              size: 38,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Top Left Live Map Badge Indicator
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black87 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.map_rounded,
                      size: 14,
                      color: Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Live OpenStreetMap • Zoom: ${_currentZoom.toStringAsFixed(1)}x',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Top Right Map Controls Stack
            Positioned(
              top: 12,
              right: 12,
              child: Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _zoomInMap,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                          border: Border.all(
                            color: isDark ? Colors.white24 : Colors.black12,
                          ),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _zoomOutMap,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                          border: Border.all(
                            color: isDark ? Colors.white24 : Colors.black12,
                          ),
                        ),
                        child: const Icon(
                          Icons.remove_rounded,
                          size: 18,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _resetMapZoom,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                          border: Border.all(
                            color: isDark ? Colors.white24 : Colors.black12,
                          ),
                        ),
                        child: const Icon(
                          Icons.my_location_rounded,
                          size: 16,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Map Status Banner Overlay with Dynamic Office Info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.92),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.place_rounded,
                      color: Color(0xFFEA4335),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$officeName • ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)} (${radiusValue.toStringAsFixed(0)}m radius)',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: _openGoogleMapsLocation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Open Map',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.open_in_new_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
