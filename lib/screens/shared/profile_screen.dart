import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/leave_provider.dart';
import '../../providers/admin_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/report_service.dart';
import 'custom_widgets.dart';
import 'edit_profile_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _pushNotificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final leaveProv = context.watch<LeaveProvider>();
    final attendanceProv = context.watch<AttendanceProvider>();
    final adminProv = context.watch<AdminProvider>();
    final policy = adminProv.policy;
    final firestore = FirestoreService();

    if (user == null) {
      return const Center(child: Text('No active user'));
    }

    final leaveBalance = leaveProv.getLeaveBalance(user.userId);
    final history = attendanceProv.getEmployeeHistory(user.userId);
    final report30Day = ReportService.calculate30DayReport(
      employee: user,
      attendanceList: history,
    );

    // Dynamic Manager Resolution
    String managerDisplay = user.managerName ?? '';
    if (managerDisplay.isEmpty && user.managerId != null && user.managerId!.isNotEmpty) {
      final mgrUser = firestore.getUserById(user.managerId!);
      managerDisplay = mgrUser?.name ?? user.managerId!;
    }
    if (managerDisplay.isEmpty) {
      managerDisplay = user.role == UserRole.admin ? 'Executive Leadership' : 'Direct Executive';
    }

    // Dynamic Shift Name
    final shiftDisplay = user.shiftName.isNotEmpty
        ? user.shiftName
        : 'Standard Shift (${policy.officeStartTime} - 06:30 PM)';

    // Dynamic Org Name
    final orgDisplay = policy.officeName.isNotEmpty
        ? policy.officeName.split(',').first.trim()
        : 'Envision Beyond India Pvt Ltd';

    Color roleColor;
    switch (user.role) {
      case UserRole.admin:
        roleColor = const Color(0xFFEF4444);
        break;
      case UserRole.manager:
        roleColor = AppTheme.secondary;
        break;
      case UserRole.hr:
        roleColor = AppTheme.accent;
        break;
      case UserRole.employee:
        roleColor = AppTheme.primary;
        break;
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      onPressed: () {
                        showAppResponsiveModal(
                          context: context,
                          maxWidth: 600,
                          builder: (_) => const EditProfileSheet(),
                        );
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.edit_square, color: AppTheme.primary, size: 20),
                      ),
                      tooltip: 'Edit Profile & Photo',
                    ),
                  ),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          showAppResponsiveModal(
                            context: context,
                            maxWidth: 600,
                            builder: (_) => const EditProfileSheet(),
                          );
                        },
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: roleColor.withValues(alpha: 0.15),
                              ),
                              child: ClipOval(
                                child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                                    ? Center(
                                        child: Text(
                                          user.name.isNotEmpty
                                              ? user.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
                                              : 'U',
                                          style: GoogleFonts.outfit(
                                            fontSize: 30,
                                            fontWeight: FontWeight.bold,
                                            color: roleColor,
                                          ),
                                        ),
                                      )
                                    : PhotoDisplayWidget(
                                        photoUrl: user.avatarUrl,
                                        size: 92,
                                        borderRadius: 46,
                                      ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? AppTheme.cardDark : Colors.white,
                                  width: 2.5,
                                ),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.name,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.textMainLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              user.role == UserRole.admin
                                  ? Icons.admin_panel_settings
                                  : (user.role == UserRole.manager
                                      ? Icons.supervisor_account
                                      : (user.role == UserRole.hr ? Icons.badge : Icons.person)),
                              size: 16,
                              color: roleColor,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                user.teamName.isNotEmpty && user.teamName != 'Unassigned'
                                    ? '${user.role.name} • ${user.department} • ${user.teamName}'
                                    : '${user.role.name} • ${user.department}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: roleColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time_filled_rounded, size: 14, color: AppTheme.primary),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                shiftDisplay,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Key Overview Stats
            Row(
              children: [
                Expanded(
                  child: _buildQuickStatTile(
                    context,
                    label: 'Present Days',
                    value: '${report30Day.presentDays}',
                    icon: Icons.check_circle_outline,
                    color: AppTheme.success,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickStatTile(
                    context,
                    label: 'Leave Balance',
                    value: '${leaveBalance.totalRemaining}',
                    icon: Icons.beach_access_outlined,
                    color: AppTheme.accent,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickStatTile(
                    context,
                    label: 'Attendance Rate',
                    value: '${report30Day.attendancePercentage}%',
                    icon: Icons.analytics_outlined,
                    color: AppTheme.primary,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Employment Information
            _buildSectionCard(
              context,
              title: 'Employment Details',
              icon: Icons.badge_outlined,
              isDark: isDark,
              children: [
                _buildInfoRow(
                  label: 'Organization',
                  value: orgDisplay,
                  icon: Icons.domain,
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                _buildInfoRow(
                  label: 'Employee ID',
                  value: user.employeeId.isNotEmpty ? user.employeeId : user.userId,
                  icon: Icons.fingerprint,
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                _buildInfoRow(
                  label: 'Department',
                  value: user.department.isNotEmpty ? user.department : 'General',
                  icon: Icons.business_outlined,
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                _buildInfoRow(
                  label: 'Team',
                  value: user.teamName.isNotEmpty ? user.teamName : 'General Team',
                  icon: Icons.groups_outlined,
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                _buildInfoRow(
                  label: 'Work Shift',
                  value: shiftDisplay,
                  icon: Icons.schedule_rounded,
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                _buildInfoRow(
                  label: 'Reporting Manager',
                  value: managerDisplay,
                  icon: Icons.person_outline,
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                _buildInfoRow(
                  label: 'Joined Date',
                  value: user.createdAt != null
                      ? DateFormat('dd MMM yyyy').format(user.createdAt!)
                      : 'Active Member',
                  icon: Icons.calendar_today_outlined,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Account & Preferences
            _buildSectionCard(
              context,
              title: 'Preferences & Security',
              icon: Icons.security_outlined,
              isDark: isDark,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_active_outlined, color: AppTheme.primary, size: 20),
                  ),
                  title: Text(
                    'Push Notifications',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: const Text('FCM alerts for shift & approvals', style: TextStyle(fontSize: 12)),
                  trailing: Switch(
                    value: _pushNotificationsEnabled,
                    onChanged: (val) {
                      setState(() {
                        _pushNotificationsEnabled = val;
                      });
                    },
                    activeThumbColor: AppTheme.primary,
                  ),
                ),
                _buildDivider(isDark),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.successSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on_outlined, color: AppTheme.success, size: 20),
                  ),
                  title: Text(
                    'GPS Geofence Validation',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text('Verified within ${policy.geofenceRadiusMeters.round()}m radius', style: const TextStyle(fontSize: 12)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Active', style: TextStyle(fontSize: 11, color: AppTheme.success, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Logout Button
            OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Confirm Logout'),
                    content: const Text('Are you sure you want to log out from this device?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await auth.logout();
                }
              },
              icon: const Icon(Icons.logout, color: AppTheme.danger, size: 20),
              label: Text(
                'LOG OUT',
                style: GoogleFonts.outfit(
                  color: AppTheme.danger,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.danger, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 16),

            Center(
              child: Text(
                'Smart Attendance System • v1.0.0+1',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.textMainLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTheme.textMainLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 16,
      thickness: 1,
      color: isDark ? AppTheme.borderDark : const Color(0xFFF1F5F9),
    );
  }
}
