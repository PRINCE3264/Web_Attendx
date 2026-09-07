import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'local_storage_service.dart';

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

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'message': message,
        'type': type,
        'timestamp': timestamp.toIso8601String(),
      };

  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(
        id: map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: map['title'] as String? ?? '',
        message: map['message'] as String? ?? '',
        type: map['type'] as String? ?? 'info',
        timestamp: map['timestamp'] != null
            ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  NotificationService._internal() {
    _initLocalNotifications();
    _loadPersistedHistory();
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

  /// Load previously persisted notifications from disk on startup
  Future<void> _loadPersistedHistory() async {
    try {
      final saved = await LocalStorageService().loadNotifications();
      if (saved != null && saved.isNotEmpty) {
        final loaded = saved.map((m) => AppNotification.fromMap(m)).toList();
        _history.addAll(loaded);
      }
    } catch (e) {
      debugPrint('Error loading persisted notifications: $e');
    }
  }

  /// Persist current history to disk
  Future<void> _persistHistory() async {
    try {
      final maps = _history.map((n) => n.toMap()).toList();
      await LocalStorageService().saveNotifications(maps);
    } catch (e) {
      debugPrint('Error persisting notifications: $e');
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

    // Persist immediately so notifications survive app close
    _persistHistory();

    _showSystemNotification(notification);
  }

  /// Clear all in-app notifications and remove from disk
  Future<void> clearAll() async {
    _history.clear();
    await LocalStorageService().clearNotifications();
    try {
      await _localNotifications.cancelAll();
    } catch (e) {
      debugPrint('Error canceling system notifications: $e');
    }
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
        color: Color(0xFF2563EB),
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
        iconColor = const Color(0xFF0EA5E9);
        iconData = Icons.assessment;
        break;
      default:
        iconColor = const Color(0xFF2563EB);
        iconData = Icons.notifications;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      fontSize: 14,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 12.5,
                      height: 1.3,
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
