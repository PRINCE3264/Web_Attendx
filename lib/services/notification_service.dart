import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type; // 'approval', 'rejection', 'report', 'info'
  final DateTime timestamp;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  NotificationService._internal() {
    _initLocalNotifications();
  }

  Future<void> _initLocalNotifications() async {
    if (_isInitialized) return;
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

      await _localNotifications.initialize(initSettings);

      const androidChannel = AndroidNotificationChannel(
        'attendx_announcements',
        'AttendX Official Announcements & Notifications',
        description: 'System channel for AttendX announcements, notices, and approvals.',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(androidChannel);
        await androidPlugin.requestNotificationsPermission();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Local notifications init error: $e');
    }
  }

  final _notificationController = StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get notificationStream => _notificationController.stream;

  final List<AppNotification> _history = [];
  List<AppNotification> get history => List.unmodifiable(_history);

  void playNotificationSound() {
    try {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.vibrate();
      HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('Notification sound feedback error: $e');
    }
  }

  void sendNotification({
    required String title,
    required String message,
    String type = 'info',
  }) {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
    );

    playNotificationSound();
    _history.insert(0, notification);
    _notificationController.add(notification);

    _showSystemNotification(notification);
  }

  Future<void> _showSystemNotification(AppNotification notification) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'attendx_announcements',
        'AttendX Official Announcements & Notifications',
        channelDescription: 'System channel for AttendX announcements, notices, and approvals.',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF4F46E5),
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final notificationId = notification.id.hashCode & 0x7FFFFFFF;
      await _localNotifications.show(
        notificationId,
        notification.title,
        notification.message,
        notificationDetails,
      );
    } catch (e) {
      debugPrint('System mobile notification error: $e');
    }
  }

  void showNotificationBanner(BuildContext context, AppNotification notification) {
    Color iconColor;
    IconData iconData;

    switch (notification.type) {
      case 'approval':
        iconColor = const Color(0xFF10B981);
        iconData = Icons.check_circle;
        break;
      case 'rejection':
        iconColor = const Color(0xFFEF4444);
        iconData = Icons.cancel;
        break;
      case 'report':
        iconColor = const Color(0xFF8B5CF6);
        iconData = Icons.assessment;
        break;
      default:
        iconColor = const Color(0xFF4F46E5);
        iconData = Icons.notifications;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(iconData, color: iconColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void dispose() {
    _notificationController.close();
  }
}
