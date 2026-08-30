import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class UserNotificationProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<NotificationModel> _notifications = [];
  StreamSubscription? _notifSub;

  UserNotificationProvider() {
    _initStream();
  }

  void _initStream() {
    _notifSub = _firestoreService.notificationsStream.listen((records) {
      final user = AuthService().currentUser;
      if (user != null) {
        _notifications = records.where((n) => n.userId == user.userId).toList();
      } else {
        _notifications = [];
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  List<NotificationModel> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> markAsRead(String notificationId) async {
    await _firestoreService.markNotificationAsRead(notificationId);
  }

  Future<void> markAllAsRead() async {
    final unread = _notifications.where((n) => !n.isRead);
    for (final notif in unread) {
      await _firestoreService.markNotificationAsRead(notif.id);
    }
  }
}
