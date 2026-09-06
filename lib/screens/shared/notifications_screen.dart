import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<UserNotificationProvider>();
    final notifications = notifProvider.notifications;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.cardDark : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Text(
              'Notifications',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: isDark ? Colors.white : AppTheme.textMainLight,
              ),
            ),
            if (notifProvider.unreadCount > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${notifProvider.unreadCount} NEW',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (notifProvider.unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: () => notifProvider.markAllAsRead(),
                icon: const Icon(Icons.done_all_rounded, size: 16, color: AppTheme.primary),
                label: Text(
                  'Mark all read',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppTheme.primary,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        size: 52,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'All Caught Up! 🎉',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.textMainLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Holiday notices, employee updates, and approval alerts will appear here.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return _buildNotificationCard(context, notif, notifProvider, isDark);
              },
            ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationModel notif,
    UserNotificationProvider notifProvider,
    bool isDark,
  ) {
    IconData icon;
    Color color;
    String tag;

    final lowerType = notif.type.toLowerCase();
    final lowerTitle = notif.title.toLowerCase();

    if (lowerType.contains('holiday')) {
      icon = Icons.beach_access_rounded;
      color = const Color(0xFFD97706); // Amber
      tag = 'HOLIDAY';
    } else if (lowerType.contains('notice') || lowerType.contains('announcement')) {
      icon = Icons.campaign_rounded;
      color = const Color(0xFF0EA5E9); // Sky
      tag = 'NOTICE';
    } else if (lowerType.contains('approval') || lowerTitle.contains('approved')) {
      icon = Icons.check_circle_rounded;
      color = AppTheme.success; // Emerald
      tag = 'APPROVED';
    } else if (lowerType.contains('rejection') || lowerTitle.contains('rejected')) {
      icon = Icons.cancel_rounded;
      color = AppTheme.danger; // Red
      tag = 'REJECTED';
    } else if (lowerTitle.contains('enrolled') || lowerTitle.contains('joined') || lowerTitle.contains('employee')) {
      icon = Icons.person_add_alt_1_rounded;
      color = const Color(0xFF2563EB); // Royal Blue
      tag = 'EMPLOYEE JOINED';
    } else {
      icon = Icons.notifications_active_rounded;
      color = AppTheme.primary;
      tag = 'UPDATE';
    }

    final isUnread = !notif.isRead;
    final displayTitle = notif.title.replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]', unicode: true), '').trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isUnread
            ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF4F6FF))
            : (isDark ? AppTheme.cardDark : Colors.white),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUnread
              ? AppTheme.primary.withValues(alpha: 0.25)
              : (isDark ? AppTheme.borderDark : const Color(0xFFF1F5F9)),
          width: isUnread ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : (isUnread ? 0.05 : 0.03)),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            if (isUnread) {
              notifProvider.markAsRead(notif.id);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unread Indicator Bar
                if (isUnread) ...[
                  Container(
                    width: 4,
                    height: 48,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],

                // Icon Badge
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Tag Badge & Time
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag,
                              style: GoogleFonts.inter(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('dd MMM, hh:mm a').format(notif.createdAt),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Title
                      Text(
                        displayTitle.isNotEmpty ? displayTitle : notif.title,
                        style: GoogleFonts.outfit(
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                          fontSize: 15,
                          color: isDark ? Colors.white : AppTheme.textMainLight,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Message Body
                      Text(
                        notif.message,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          height: 1.4,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        ),
                      ),
                    ],
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
