import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<UserNotificationProvider>();
    final notifications = notifProvider.notifications;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (notifProvider.unreadCount > 0)
            TextButton.icon(
              onPressed: () => notifProvider.markAllAsRead(),
              icon: const Icon(Icons.done_all, size: 16),
              label: const Text('Mark all read'),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardDark : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      size: 48,
                      color: isDark ? AppTheme.textMutedDark : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Notifications Yet',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Holiday notices, company updates, and approval alerts will appear here.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: isDark ? AppTheme.borderDark : const Color(0xFFF1F5F9),
              ),
              itemBuilder: (context, index) {
                final notif = notifications[index];

                IconData icon;
                Color color;
                String tag;

                switch (notif.type) {
                  case 'holiday':
                    icon = Icons.beach_access_rounded;
                    color = const Color(0xFFD97706);
                    tag = 'Holiday';
                    break;
                  case 'notice':
                    icon = Icons.campaign_rounded;
                    color = const Color(0xFF7C3AED);
                    tag = 'Notice';
                    break;
                  case 'approval':
                    icon = Icons.check_circle_rounded;
                    color = AppTheme.success;
                    tag = 'Approved';
                    break;
                  case 'rejection':
                    icon = Icons.cancel_rounded;
                    color = AppTheme.danger;
                    tag = 'Rejected';
                    break;
                  default:
                    icon = Icons.notifications_rounded;
                    color = AppTheme.primary;
                    tag = 'Update';
                }

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  tileColor: notif.isRead
                      ? (isDark ? AppTheme.bgDark : Colors.white)
                      : (isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFEFF6FF)),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: color.withValues(alpha: 0.15),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      if (!notif.isRead)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(right: 8, top: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          notif.title,
                          style: GoogleFonts.outfit(
                            fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        notif.message,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(notif.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    if (!notif.isRead) {
                      notifProvider.markAsRead(notif.id);
                    }
                  },
                );
              },
            ),
    );
  }
}
