import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/attendance_model.dart';
import '../models/break_model.dart';
import '../models/correction_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  List<AttendanceModel> _allAttendance = [];
  List<AttendanceCorrectionModel> _corrections = [];
  bool _isProcessing = false;
  String? _errorMessage;

  XFile? _tempPhotoFile;
  String? _tempPhotoDataUrl;

  StreamSubscription? _attendanceSub;
  StreamSubscription? _correctionsSub;

  AttendanceProvider() {
    _initStream();
  }

  void _initStream() {
    _allAttendance = _firestoreService.getAllAttendance();
    _corrections = _firestoreService.getAllCorrections();

    _attendanceSub = _firestoreService.attendanceStream.listen((records) {
      _allAttendance = records;
      notifyListeners();
    });

    _correctionsSub = _firestoreService.correctionsStream.listen((corrs) {
      _corrections = corrs;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _attendanceSub?.cancel();
    _correctionsSub?.cancel();
    super.dispose();
  }

  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  XFile? get tempPhotoFile => _tempPhotoFile;
  String? get tempPhotoDataUrl => _tempPhotoDataUrl;
  List<AttendanceCorrectionModel> get corrections => _corrections;

  AttendanceModel? getTodayAttendance(String? employeeId) {
    if (employeeId == null) return null;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      return _allAttendance.firstWhere(
        (a) => a.employeeId == employeeId && a.date == todayStr,
      );
    } catch (_) {
      return null;
    }
  }

  List<AttendanceModel> getEmployeeHistory(String? employeeId) {
    if (employeeId == null) return [];
    return _allAttendance
        .where((a) => a.employeeId == employeeId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<AttendanceModel> getPendingApprovals() {
    return _allAttendance
        .where((a) => a.status == AttendanceStatus.pending)
        .toList()
      ..sort((a, b) => (b.clockInTime ?? DateTime.now()).compareTo(a.clockInTime ?? DateTime.now()));
  }

  List<AttendanceModel> getLateEmployeesToday() {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _allAttendance
        .where((a) => a.date == todayStr && a.timingStatus == TimingStatus.lateArrival)
        .toList();
  }

  List<AttendanceModel> getAttendanceByDate(String dateStr) {
    return _allAttendance.where((a) => a.date == dateStr).toList();
  }

  Future<bool> captureSelfie() async {
    try {
      _isProcessing = true;
      _errorMessage = null;
      notifyListeners();

      final photo = await _storageService.captureSelfiePhoto();
      if (photo == null) {
        _isProcessing = false;
        notifyListeners();
        return false;
      }

      _tempPhotoFile = photo;
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(now);

      _tempPhotoDataUrl = await _storageService.uploadAttendancePhoto(
        userId: 'temp_user',
        date: dateStr,
        type: 'clockIn',
        file: photo,
      );

      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to capture photo: $e';
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  void clearTempPhoto() {
    _tempPhotoFile = null;
    _tempPhotoDataUrl = null;
    notifyListeners();
  }

  // Submit Clock-In with Geofence coordinates
  Future<bool> submitClockIn(
    UserModel user, {
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    if (_tempPhotoDataUrl == null) {
      _errorMessage = 'Selfie photo is required to Clock-In.';
      notifyListeners();
      return false;
    }

    try {
      _isProcessing = true;
      _errorMessage = null;
      notifyListeners();

      await _firestoreService.submitClockIn(
        user: user,
        photoUrl: _tempPhotoDataUrl!,
        location: location,
        latitude: latitude,
        longitude: longitude,
      );

      _tempPhotoFile = null;
      _tempPhotoDataUrl = null;
      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  // Break tracking actions
  Future<bool> startBreak(String attendanceId, BreakType type, UserModel user) async {
    try {
      _isProcessing = true;
      notifyListeners();

      await _firestoreService.startBreak(
        attendanceId: attendanceId,
        type: type,
        user: user,
      );

      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> endBreak(String attendanceId, UserModel user) async {
    try {
      _isProcessing = true;
      notifyListeners();

      await _firestoreService.endBreak(
        attendanceId: attendanceId,
        user: user,
      );

      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  // Approvals & Bulk Approvals
  Future<bool> approveAttendance(String attendanceId, UserModel manager, {String? comment}) async {
    try {
      _isProcessing = true;
      notifyListeners();

      await _firestoreService.approveAttendance(
        attendanceId: attendanceId,
        manager: manager,
        comment: comment,
      );

      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  Future<int> bulkApproveAll(UserModel manager) async {
    try {
      _isProcessing = true;
      notifyListeners();

      final count = await _firestoreService.bulkApprovePending(manager);

      _isProcessing = false;
      notifyListeners();
      return count;
    } catch (e) {
      _errorMessage = e.toString();
      _isProcessing = false;
      notifyListeners();
      return 0;
    }
  }

  Future<bool> rejectAttendance(String attendanceId, UserModel manager, String reason) async {
    try {
      _isProcessing = true;
      notifyListeners();

      await _firestoreService.rejectAttendance(
        attendanceId: attendanceId,
        manager: manager,
        reason: reason,
      );

      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitClockOut(String attendanceId) async {
    try {
      _isProcessing = true;
      notifyListeners();

      await _firestoreService.submitClockOut(
        attendanceId: attendanceId,
        clockOutPhotoUrl: _tempPhotoDataUrl,
      );

      _tempPhotoFile = null;
      _tempPhotoDataUrl = null;
      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  // Regularization / Correction requests
  Future<bool> submitCorrection({
    required UserModel employee,
    required String attendanceId,
    required String date,
    required DateTime requestedClockIn,
    required DateTime requestedClockOut,
    required String reason,
  }) async {
    try {
      _isProcessing = true;
      notifyListeners();

      await _firestoreService.submitCorrectionRequest(
        employee: employee,
        attendanceId: attendanceId,
        date: date,
        requestedClockIn: requestedClockIn,
        requestedClockOut: requestedClockOut,
        reason: reason,
      );

      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> reviewCorrection({
    required String correctionId,
    required bool isApproved,
    required UserModel manager,
    String? note,
  }) async {
    try {
      _isProcessing = true;
      notifyListeners();

      await _firestoreService.reviewCorrection(
        correctionId: correctionId,
        isApproved: isApproved,
        manager: manager,
        note: note,
      );

      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }
}
