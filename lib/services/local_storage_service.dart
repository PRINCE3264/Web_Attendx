import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user_model.dart';
import '../models/attendance_model.dart';
import '../models/leave_model.dart';
import '../models/correction_model.dart';
import '../models/policy_model.dart';

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
}
