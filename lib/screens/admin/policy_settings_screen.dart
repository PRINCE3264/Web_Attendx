import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
  late MapController _mapController;
  double _currentZoom = 16.0;

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
    final policy = context.read<AdminProvider>().policy;
    _startTimeController = TextEditingController(text: policy.officeStartTime);
    _graceController = TextEditingController(text: '${policy.gracePeriodMinutes}');
    _minHoursController = TextEditingController(text: '${policy.minimumWorkingHours}');
    _maxBreakController = TextEditingController(text: '${policy.maxBreakMinutes}');
    _latController = TextEditingController(text: '${policy.officeLatitude}');
    _lngController = TextEditingController(text: '${policy.officeLongitude}');
    _radiusController = TextEditingController(text: '${policy.geofenceRadiusMeters}');
    _officeNameController = TextEditingController(text: policy.officeName);

    _latController.addListener(_onSettingChanged);
    _lngController.addListener(_onSettingChanged);
    _radiusController.addListener(_onSettingChanged);
    _officeNameController.addListener(_onSettingChanged);
  }

  @override
  void dispose() {
    _latController.removeListener(_onSettingChanged);
    _lngController.removeListener(_onSettingChanged);
    _radiusController.removeListener(_onSettingChanged);
    _officeNameController.removeListener(_onSettingChanged);
    _mapController.dispose();

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
      officeLatitude: double.tryParse(_latController.text.trim()) ?? 21.1986872,
      officeLongitude: double.tryParse(_lngController.text.trim()) ?? 72.7965515,
      geofenceRadiusMeters: double.tryParse(_radiusController.text.trim()) ?? 300.0,
      officeName: _officeNameController.text.trim().isEmpty ? 'HQ Office' : _officeNameController.text.trim(),
    );

    final success = await adminProv.updatePolicy(updated, admin);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Attendance policy updated successfully' : 'Failed to update policy'),
        backgroundColor: success ? AppTheme.success : AppTheme.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lat = double.tryParse(_latController.text.trim()) ?? 21.1986872;
    final lng = double.tryParse(_lngController.text.trim()) ?? 72.7965515;
    final radiusValue = double.tryParse(_radiusController.text.trim()) ?? 300.0;
    final targetLatLng = LatLng(lat, lng);
    final officeName = _officeNameController.text.trim().isEmpty ? 'HQ Office' : _officeNameController.text.trim();

    return Scaffold(
      appBar: widget.isEmbedded ? null : AppBar(title: const Text('Policy & Shift Rules')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Global Shift & Geofence Policy',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Define shift timings, grace periods, and GPS coordinates for attendance check-ins.',
                  style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
                ),
                const SizedBox(height: 24),

                // Shift timings
                Text('Timing Rules', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _startTimeController,
                        decoration: const InputDecoration(labelText: 'Office Start Time', prefixIcon: Icon(Icons.access_time)),
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
                        decoration: const InputDecoration(labelText: 'Min Working Hours', prefixIcon: Icon(Icons.hourglass_bottom)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _maxBreakController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Max Break (Mins)', prefixIcon: Icon(Icons.coffee)),
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

                const SizedBox(height: 14),

                // Interactive Real OpenStreetMap Preview
                Container(
                  height: 260,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: targetLatLng,
                              initialZoom: _currentZoom,
                              minZoom: 3.0,
                              maxZoom: 19.0,
                              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                              onPositionChanged: (pos, _) {
                                if ((pos.zoom - _currentZoom).abs() > 0.05) {
                                  setState(() => _currentZoom = pos.zoom);
                                }
                              },
                              onTap: (tapPosition, point) {
                                _latController.text = point.latitude.toStringAsFixed(7);
                                _lngController.text = point.longitude.toStringAsFixed(7);
                                _mapController.move(point, _currentZoom);
                                setState(() {});
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.attendx.smartattendance',
                                maxZoom: 19,
                              ),
                              CircleLayer(
                                circles: [
                                  CircleMarker(
                                    point: targetLatLng,
                                    radius: radiusValue,
                                    useRadiusInMeter: true,
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.20),
                                    borderColor: const Color(0xFF2563EB),
                                    borderStrokeWidth: 2.5,
                                  ),
                                ],
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: targetLatLng,
                                    width: 240,
                                    height: 100,
                                    alignment: Alignment.topCenter,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFF2563EB)),
                                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                          ),
                                          child: Text(
                                            officeName,
                                            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFDC2626)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(Icons.location_on_rounded, color: Color(0xFFEA4335), size: 34),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black87 : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.touch_app_rounded, size: 13, color: Color(0xFF2563EB)),
                                const SizedBox(width: 4),
                                Text(
                                  'Tap map to set pin location',
                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  final z = (_mapController.camera.zoom + 1).clamp(3.0, 19.0);
                                  _mapController.move(_mapController.camera.center, z);
                                  setState(() => _currentZoom = z);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
                                  ),
                                  child: const Icon(Icons.add, size: 16, color: Color(0xFF2563EB)),
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () {
                                  final z = (_mapController.camera.zoom - 1).clamp(3.0, 19.0);
                                  _mapController.move(_mapController.camera.center, z);
                                  setState(() => _currentZoom = z);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
                                  ),
                                  child: const Icon(Icons.remove, size: 16, color: Color(0xFF2563EB)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
      ),
    );
  }
}
