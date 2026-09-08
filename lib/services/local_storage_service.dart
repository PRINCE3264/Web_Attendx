import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
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

  Directory? _appDocDir;

  Future<File?> _getFile(String filename) async {
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

  // --- Session Persistence (Saved Logged In User) ---
  Future<void> saveSession(UserModel? user) async {
    try {
      final file = await _getFile('attendx_session.json');
      if (file == null) return;
      if (user == null) {
        if (await file.exists()) await file.delete();
      } else {
        await file.writeAsString(jsonEncode(user.toMap()));
      }
    } catch (e) {
      debugPrint('Error saving user session: $e');
    }
  }

  Future<UserModel?> loadSession() async {
    try {
      final file = await _getFile('attendx_session.json');
      if (file == null || !await file.exists()) return null;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return null;
      final Map<String, dynamic> map = jsonDecode(content);
      return UserModel.fromMap(map, (map['userId'] ?? '').toString());
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
        await file.writeAsString(newId);
      }
      _cachedDeviceId = newId;
      return newId;
    } catch (_) {
      final fallback = 'DEV_${DateTime.now().millisecondsSinceEpoch}';
      _cachedDeviceId = fallback;
      return fallback;
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
