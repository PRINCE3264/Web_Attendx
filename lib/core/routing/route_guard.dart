import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_theme.dart';
import '../permissions/role_model.dart';
import '../permissions/permission_service.dart';
import '../../models/user_model.dart';

class RouteGuard {
  static Widget protect({
    required BuildContext context,
    required UserModel? user,
    required AppPermission requiredPermission,
    required Widget child,
  }) {
    if (user == null) {
      return const AccessDeniedScreen(
        reason: 'You must be authenticated to access this resource.',
      );
    }

    final hasPerm = PermissionService.userHasPermission(user, requiredPermission);
    if (!hasPerm) {
      return AccessDeniedScreen(
        userRole: AppRole.fromString(user.role.name),
        requiredPermission: requiredPermission,
      );
    }

    return child;
  }
}

class AccessDeniedScreen extends StatelessWidget {
  final AppRole? userRole;
  final AppPermission? requiredPermission;
  final String? reason;
  final VoidCallback? onRedirectHome;

  const AccessDeniedScreen({
    super.key,
    this.userRole,
    this.requiredPermission,
    this.reason,
    this.onRedirectHome,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Access Restricted'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.gpp_bad_rounded,
                    size: 64,
                    color: AppTheme.danger,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Access Denied',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMainLight,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  reason ?? 'You do not have permission to access this page.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textMutedLight,
                    height: 1.5,
                  ),
                ),
                if (userRole != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: userRole!.badgeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: userRole!.badgeColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(userRole!.icon, size: 16, color: userRole!.badgeColor),
                        const SizedBox(width: 6),
                        Text(
                          'Your Role: ${userRole!.displayName}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: userRole!.badgeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: () {
                    if (onRedirectHome != null) {
                      onRedirectHome!();
                    } else {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Back to My Dashboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
