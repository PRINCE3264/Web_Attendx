// File generated for Firebase configuration: attendx-8b4c5
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static const String projectId = 'attendx-8b4c5';
  static const String storageBucket = 'attendx-8b4c5.appspot.com';

  static dynamic get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.windows:
        return windows;
      default:
        return android;
    }
  }

  static const dynamic web = {
    'apiKey': 'AIzaSyDemoDummyKeyForAttendX-8b4c5Web',
    'appId': '1:104928374619:web:a1b2c3d4e5f6g7h8',
    'messagingSenderId': '104928374619',
    'projectId': 'attendx-8b4c5',
    'authDomain': 'attendx-8b4c5.firebaseapp.com',
    'storageBucket': 'attendx-8b4c5.appspot.com',
  };

  static const dynamic android = {
    'apiKey': 'AIzaSyDemoDummyKeyForAttendX-8b4c5Android',
    'appId': '1:104928374619:android:a1b2c3d4e5f6g7h8',
    'messagingSenderId': '104928374619',
    'projectId': 'attendx-8b4c5',
    'storageBucket': 'attendx-8b4c5.appspot.com',
  };

  static const dynamic ios = {
    'apiKey': 'AIzaSyDemoDummyKeyForAttendX-8b4c5iOS',
    'appId': '1:104928374619:ios:a1b2c3d4e5f6g7h8',
    'messagingSenderId': '104928374619',
    'projectId': 'attendx-8b4c5',
    'storageBucket': 'attendx-8b4c5.appspot.com',
    'iosBundleId': 'com.attendance.attendx',
  };

  static const dynamic windows = {
    'apiKey': 'AIzaSyDemoDummyKeyForAttendX-8b4c5Windows',
    'appId': '1:104928374619:windows:a1b2c3d4e5f6g7h8',
    'messagingSenderId': '104928374619',
    'projectId': 'attendx-8b4c5',
    'authDomain': 'attendx-8b4c5.firebaseapp.com',
    'storageBucket': 'attendx-8b4c5.appspot.com',
  };
}
