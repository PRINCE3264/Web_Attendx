import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/attendance_model.dart';
import '../models/leave_model.dart';
import '../models/correction_model.dart';
import '../models/policy_model.dart';
import '../models/project_report_model.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  static const String _kSessionUserKey = 'attendx_session_user_v3';
  static const String _kSessionTimestampKey = 'attendx_session_timestamp_v3';
  static const int kSessionMaxDays = 30;

  static final Map<String, dynamic> _memoryStore = {};

  Directory? _appDocDir;

  Future<File?> _getFile(String filename) async {
    if (kIsWeb) return null;
    try {
      _appDocDir ??= await getApplicationDocumentsDirectory();
      return File('${_appDocDir!.path}/$filename');
    } catch (e) {
      return null;
    }
  }

  // --- Users Persistence ---
  Future<void> saveUsers(List<UserModel> users) async {
    try {
      final file = await _getFile('attendx_users.json');
      if (file == null) return;
      final jsonList = users.map((u) => u.toMap()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving users to local storage: $e');
    }
  }

  Future<List<UserModel>?> loadUsers() async {
    try {
      final file = await _getFile('attendx_users.json');
      if (file == null || !await file.exists()) return null;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return null;
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((m) => UserModel.fromMap(m as Map<String, dynamic>, (m['userId'] ?? '').toString())).toList();
    } catch (e) {
      debugPrint('Error loading users from local storage: $e');
      return null;
    }
  }

  // --- Session Persistence (Saved Logged In User with 30-Day Expiry via SharedPreferences) ---
  Future<void> saveSession(UserModel? user) async {
    try {
      if (user == null) {
        _memoryStore.remove(_kSessionUserKey);
        _memoryStore.remove(_kSessionTimestampKey);
      } else {
        final Map<String, dynamic> map = user.toMap();
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        map['saved_login_time'] = DateTime.now().toIso8601String();
        map['session_created_ms'] = nowMs;

        _memoryStore[_kSessionUserKey] = jsonEncode(map);
        _memoryStore[_kSessionTimestampKey] = nowMs;
      }

      try {
        final prefs = await SharedPreferences.getInstance();
        if (user == null) {
          await prefs.remove(_kSessionUserKey);
          await prefs.remove(_kSessionTimestampKey);
          if (!kIsWeb) {
            try {
              final file = await _getFile('attendx_session.json');
              if (file != null && await file.exists()) {
                await file.delete();
              }
            } catch (_) {}
          }
        } else {
          final jsonStr = _memoryStore[_kSessionUserKey] as String;
          final nowMs = _memoryStore[_kSessionTimestampKey] as int;
          await prefs.setString(_kSessionUserKey, jsonStr);
          await prefs.setInt(_kSessionTimestampKey, nowMs);

          if (!kIsWeb) {
            try {
              final file = await _getFile('attendx_session.json');
              if (file != null) {
                await file.writeAsString(jsonStr);
              }
            } catch (_) {}
          }
        }
      } catch (e) {
        debugPrint('SharedPreferences session save notice (memory fallback active): $e');
      }
    } catch (e) {
      debugPrint('Error saving user session: $e');
    }
  }

  Future<UserModel?> loadSession() async {
    try {
      String? userJson;
      int? timestampMs;

      try {
        final prefs = await SharedPreferences.getInstance();
        userJson = prefs.getString(_kSessionUserKey);
        timestampMs = prefs.getInt(_kSessionTimestampKey);
      } catch (e) {
        debugPrint('SharedPreferences session load notice (memory fallback active): $e');
        userJson = _memoryStore[_kSessionUserKey] as String?;
        timestampMs = _memoryStore[_kSessionTimestampKey] as int?;
      }

      // Fallback check to legacy mobile file if SharedPreferences key is empty
      if ((userJson == null || userJson.trim().isEmpty) && !kIsWeb) {
        try {
          final file = await _getFile('attendx_session.json');
          if (file != null && await file.exists()) {
            final content = await file.readAsString();
            if (content.trim().isNotEmpty) {
              userJson = content;
            }
          }
        } catch (_) {}
      }

      if (userJson == null || userJson.trim().isEmpty) {
        return null;
      }

      final Map<String, dynamic> map = jsonDecode(userJson);

      // Check 30-day expiration constraint
      if (timestampMs == null && map.containsKey('session_created_ms')) {
        timestampMs = int.tryParse(map['session_created_ms']?.toString() ?? '');
      }
      if (timestampMs == null && map.containsKey('saved_login_time')) {
        final savedTime = DateTime.tryParse(map['saved_login_time']?.toString() ?? '');
        if (savedTime != null) {
          timestampMs = savedTime.millisecondsSinceEpoch;
        }
      }

      if (timestampMs != null) {
        final savedDateTime = DateTime.fromMillisecondsSinceEpoch(timestampMs);
        final int daysPassed = DateTime.now().difference(savedDateTime).inDays;
        if (daysPassed >= kSessionMaxDays) {
          debugPrint('⚠️ Session expired after 30 days ($daysPassed days elapsed). User must log in again.');
          await saveSession(null);
          return null;
        }
      }

      final user = UserModel.fromMap(map, (map['userId'] ?? '').toString());
      return user;
    } catch (e) {
      debugPrint('Error loading session: $e');
      return null;
    }
  }

  // --- Attendance Persistence ---
  Future<void> saveAttendance(List<AttendanceModel> records) async {
    try {
      final file = await _getFile('attendx_attendance.json');
      if (file == null) return;
      final jsonList = records.map((r) => r.toMap()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving attendance to local storage: $e');
    }
  }

  Future<List<AttendanceModel>?> loadAttendance() async {
    try {
      final file = await _getFile('attendx_attendance.json');
      if (file == null || !await file.exists()) return null;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return null;
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((m) => AttendanceModel.fromMap(m as Map<String, dynamic>, (m['attendanceId'] ?? '').toString())).toList();
    } catch (e) {
      debugPrint('Error loading attendance from local storage: $e');
      return null;
    }
  }

  // --- Leaves Persistence ---
  Future<void> saveLeaves(List<LeaveRequestModel> leaves) async {
    try {
      final file = await _getFile('attendx_leaves.json');
      if (file == null) return;
      final jsonList = leaves.map((l) => l.toMap()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving leaves to local storage: $e');
    }
  }

  Future<List<LeaveRequestModel>?> loadLeaves() async {
    try {
      final file = await _getFile('attendx_leaves.json');
      if (file == null || !await file.exists()) return null;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return null;
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((m) => LeaveRequestModel.fromMap(m as Map<String, dynamic>, (m['leaveId'] ?? '').toString())).toList();
    } catch (e) {
      debugPrint('Error loading leaves from local storage: $e');
      return null;
    }
  }

  // --- Corrections Persistence ---
  Future<void> saveCorrections(List<AttendanceCorrectionModel> corrections) async {
    try {
      final file = await _getFile('attendx_corrections.json');
      if (file == null) return;
      final jsonList = corrections.map((c) => c.toMap()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving corrections to local storage: $e');
    }
  }

  Future<List<AttendanceCorrectionModel>?> loadCorrections() async {
    try {
      final file = await _getFile('attendx_corrections.json');
      if (file == null || !await file.exists()) return null;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return null;
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((m) => AttendanceCorrectionModel.fromMap(m as Map<String, dynamic>, (m['correctionId'] ?? '').toString())).toList();
    } catch (e) {
      debugPrint('Error loading corrections from local storage: $e');
      return null;
    }
  }

  // --- Policy Persistence ---
  Future<void> savePolicy(AttendancePolicyModel policy) async {
    try {
      final file = await _getFile('attendx_policy.json');
      if (file == null) return;
      await file.writeAsString(jsonEncode(policy.toMap()));
    } catch (e) {
      debugPrint('Error saving policy to local storage: $e');
    }
  }

  Future<AttendancePolicyModel?> loadPolicy() async {
    try {
      final file = await _getFile('attendx_policy.json');
      if (file == null || !await file.exists()) return null;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return null;
      final Map<String, dynamic> map = jsonDecode(content);
      return AttendancePolicyModel.fromMap(map, (map['policyId'] ?? 'policy_standard').toString());
    } catch (e) {
      debugPrint('Error loading policy from local storage: $e');
      return null;
    }
  }

  // --- Notifications Persistence ---
  // Keeps notifications so they survive app restarts.
  static const int _maxSavedNotifications = 1000;

  Future<void> saveNotifications(List<Map<String, dynamic>> notifications) async {
    try {
      final file = await _getFile('attendx_notifications.json');
      if (file == null) return;
      
      // Keep up to 1000 notifications so old data doesn't get cleaned up soon
      final capped = notifications.length > _maxSavedNotifications
          ? notifications.sublist(0, _maxSavedNotifications)
          : notifications;
      await file.writeAsString(jsonEncode(capped));
    } catch (e) {
      debugPrint('Error saving notifications to local storage: $e');
    }
  }

  Future<List<Map<String, dynamic>>?> loadNotifications() async {
    try {
      final file = await _getFile('attendx_notifications.json');
      if (file == null || !await file.exists()) return null;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return null;
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error loading notifications from local storage: $e');
      return null;
    }
  }

  // --- Firestore Notifications Persistence ---
  Future<void> saveFirestoreNotifications(List<Map<String, dynamic>> notifications) async {
    try {
      final file = await _getFile('attendx_fs_notifications.json');
      if (file == null) return;
      
      final capped = notifications.length > 1000
          ? notifications.sublist(0, 1000)
          : notifications;
      await file.writeAsString(jsonEncode(capped));
    } catch (e) {
      debugPrint('Error saving fs notifications: $e');
    }
  }

  Future<List<Map<String, dynamic>>?> loadFirestoreNotifications() async {
    try {
      final file = await _getFile('attendx_fs_notifications.json');
      if (file == null || !await file.exists()) return null;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return null;
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error loading fs notifications: $e');
      return null;
    }
  }

  Future<void> clearNotifications() async {
    try {
      final file = await _getFile('attendx_notifications.json');
      if (file != null && await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('Error clearing notifications from local storage: $e');
    }
  }

  String? _cachedDeviceId;

  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null && _cachedDeviceId!.isNotEmpty) {
      return _cachedDeviceId!;
    }
    if (kIsWeb) {
      _cachedDeviceId = 'WEB_DEVICE_STATIONARY';
      return _cachedDeviceId!;
    }
    try {
      final file = await _getFile('attendx_device_id.txt');
      if (file != null && await file.exists()) {
        final id = (await file.readAsString()).trim();
        if (id.isNotEmpty) {
          _cachedDeviceId = id;
          return id;
        }
      }
      final newId = 'DEV_${DateTime.now().millisecondsSinceEpoch}_${(1000 + DateTime.now().microsecondsSinceEpoch % 9000)}';
      if (file != null) {
        await file.writeAsString(newId, flush: true);
      }
      _cachedDeviceId = newId;
      return newId;
    } catch (_) {
      _cachedDeviceId ??= 'DEV_${Platform.operatingSystem.toUpperCase()}_STATIONARY_ID';
      return _cachedDeviceId!;
    }
  }

  Future<void> clearAllData() async {
    try {
      final filenames = [
        'attendx_attendance.json',
        'attendx_leaves.json',
        'attendx_corrections.json',
        'attendx_projects.json',
        'attendx_project_reports.json',
      ];
      for (final name in filenames) {
        final file = await _getFile(name);
        if (file != null && await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('Error clearing local storage data: $e');
    }
  }

  // --- Project Reports Persistence ---
  Future<void> saveProjectReports(List<ProjectReportModel> reports) async {
    try {
      final file = await _getFile('attendx_project_reports.json');
      if (file == null) return;
      final jsonList = reports.map((r) => r.toMap()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving project reports to local storage: $e');
    }
  }

  Future<List<ProjectReportModel>?> loadProjectReports() async {
    try {
      final file = await _getFile('attendx_project_reports.json');
      if (file == null || !await file.exists()) return null;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return null;
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList
          .map((m) => ProjectReportModel.fromMap(m as Map<String, dynamic>, (m['reportId'] ?? '').toString()))
          .toList();
    } catch (e) {
      debugPrint('Error loading project reports from local storage: $e');
      return null;
    }
  }
}
