import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class UserNotificationProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<NotificationModel> _notifications = [];
  StreamSubscription? _notifSub;
  StreamSubscription? _authSub;

  UserNotificationProvider() {
    _initStream();
  }

  void _initStream() {
    _refresh();

    _notifSub = _firestoreService.notificationsStream.listen((_) {
      _refresh();
    });

    _authSub = AuthService().authStateChanges.listen((_) {
      _refresh();
    });
  }

  void _refresh() {
    final user = AuthService().currentUser;
    if (user != null) {
      _notifications = _firestoreService.getNotificationsForUser(user.userId);
    } else {
      _notifications = [];
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _authSub?.cancel();
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
