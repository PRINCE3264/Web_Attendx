import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/hr_provider.dart';
import 'providers/leave_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/shared/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/firestore_service.dart';
import 'services/auth_service.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    FirestoreService().ensureFirestoreConnected();
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }
  runApp(const SmartAttendanceApp());
}

class SmartAttendanceApp extends StatefulWidget {
  const SmartAttendanceApp({super.key});

  @override
  State<SmartAttendanceApp> createState() => _SmartAttendanceAppState();
}

class _SmartAttendanceAppState extends State<SmartAttendanceApp> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldMessengerState> _messengerKey = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription? _notifSubscription;
  Timer? _usageTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startUsageTimer();
    // Listen for FCM & In-app notifications
    _notifSubscription = NotificationService().notificationStream.listen((notif) {
      _showInAppNotification(notif);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _usageTimer?.cancel();
    _notifSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    
    if (state == AppLifecycleState.resumed) {
      if (userId != null) FirestoreService().logSessionStart(userId);
      _startUsageTimer();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      if (userId != null) FirestoreService().logSessionEnd(userId);
      _usageTimer?.cancel();
    }
  }

  void _startUsageTimer() {
    _usageTimer?.cancel();
    
    // Only run usage timer if user is logged in
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return;
    
    FirestoreService().logSessionStart(currentUser.userId);
    
    // Set for 1 hour of continuous usage
    _usageTimer = Timer(const Duration(hours: 1), _triggerOneHourAlert);
  }

  void _triggerOneHourAlert() {
    if (AuthService().currentUser == null) return;
    // Show local notification
    NotificationService().sendNotification(
      title: '1 Hour Alert ⏰',
      message: "You've been using the app for 1 hour continuously. Take a short break!",
      type: 'info',
    );
    
    // Add extra vibration for the alarm feel
    for (int i = 0; i < 5; i++) {
      Future.delayed(Duration(milliseconds: i * 600), () {
        HapticFeedback.vibrate();
        HapticFeedback.heavyImpact();
      });
    }
  }

  void _showInAppNotification(AppNotification notif) {
    if (AuthService().currentUser == null) return;
    try {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('Notification chime error: $e');
    }

    Color iconColor;
    IconData iconData;

    switch (notif.type) {
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

    _messengerKey.currentState?.showSnackBar(
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
                    notif.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      fontSize: 14,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notif.message,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 12.5,
                      height: 1.3,
                    ),
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

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => HrProvider()),
        ChangeNotifierProvider(create: (_) => LeaveProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => UserNotificationProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Smart Attendance System',
            scaffoldMessengerKey: _messengerKey,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
