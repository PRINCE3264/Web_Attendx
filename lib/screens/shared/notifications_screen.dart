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
        title: const Text('Notifications'),
        actions: [
          if (notifProvider.unreadCount > 0)
            TextButton(
              onPressed: () {
                notifProvider.markAllAsRead();
              },
              child: const Text('Mark all as read'),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? const Center(child: Text('No notifications'))
          : ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notif = notifications[index];

                IconData icon;
                Color color;

                switch (notif.type) {
                  case 'holiday':
                    icon = Icons.celebration;
                    color = AppTheme.secondary;
                    break;
                  case 'notice':
                    icon = Icons.campaign;
                    color = AppTheme.accent;
                    break;
                  default:
                    icon = Icons.notifications;
                    color = AppTheme.primary;
                }

                return ListTile(
                  tileColor: notif.isRead
                      ? (isDark ? AppTheme.bgDark : Colors.white)
                      : (isDark
                            ? AppTheme.cardDark.withValues(alpha: 0.8)
                            : AppTheme.primarySoft.withValues(alpha: 0.3)),
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.2),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  title: Text(
                    notif.title,
                    style: GoogleFonts.outfit(
                      fontWeight: notif.isRead
                          ? FontWeight.w500
                          : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(notif.message),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a')
                            .format(notif.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: isDark
                              ? AppTheme.textMutedDark
                              : AppTheme.textMutedLight,
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
