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
import '../services/auth_service.dart';
import '../services/notification_service.dart';

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
    _allAttendance = _filterAttendance(_firestoreService.getAllAttendance());
    _corrections = _firestoreService.getAllCorrections();

    _attendanceSub = _firestoreService.attendanceStream.listen((records) {
      _allAttendance = _filterAttendance(records);
      notifyListeners();
    });

    _correctionsSub = _firestoreService.correctionsStream.listen((corrs) {
      _corrections = corrs; // Could also filter corrections if needed
      notifyListeners();
    });
  }

  List<AttendanceModel> _filterAttendance(List<AttendanceModel> records) {
    try {
      final user = AuthService().currentUser;
      if (user != null) {
        if (user.role == UserRole.employee || user.role == UserRole.manager) {
          final validIds = <String>{
            user.userId.toLowerCase(),
            if (user.employeeId.isNotEmpty) user.employeeId.toLowerCase(),
            if (user.email.isNotEmpty) user.email.toLowerCase(),
          };
          return records.where((r) =>
            validIds.contains(r.employeeId.toLowerCase()) ||
            validIds.contains(r.employeeCode.toLowerCase()) ||
            validIds.contains(r.uid.toLowerCase())).toList();
        }
      }
    } catch (_) {}
    return records; // HR and Admin get all records
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
  List<AttendanceModel> get allAttendance => _allAttendance;
  List<AttendanceCorrectionModel> get corrections => _corrections;

  AttendanceModel? getTodayAttendance(String? identifier) {
    if (identifier == null) return null;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final targetUser = _firestoreService.getUserById(identifier) ?? AuthService().currentUser;
    final validIds = <String>{
      identifier.toLowerCase(),
      if (targetUser != null) targetUser.userId.toLowerCase(),
      if (targetUser != null && targetUser.employeeId.isNotEmpty) targetUser.employeeId.toLowerCase(),
      if (targetUser != null && targetUser.email.isNotEmpty) targetUser.email.toLowerCase(),
    };

    try {
      return _allAttendance.firstWhere(
        (a) => (validIds.contains(a.employeeId.toLowerCase()) ||
                validIds.contains(a.employeeCode.toLowerCase()) ||
                validIds.contains(a.uid.toLowerCase())) &&
            a.date == todayStr,
      );
    } catch (_) {
      return _firestoreService.getTodayAttendance(identifier);
    }
  }

  List<AttendanceModel> getEmployeeHistory(String? identifier) {
    if (identifier == null) return [];
    final targetUser = _firestoreService.getUserById(identifier) ?? AuthService().currentUser;
    final validIds = <String>{
      identifier.toLowerCase(),
      if (targetUser != null) targetUser.userId.toLowerCase(),
      if (targetUser != null && targetUser.employeeId.isNotEmpty) targetUser.employeeId.toLowerCase(),
      if (targetUser != null && targetUser.email.isNotEmpty) targetUser.email.toLowerCase(),
    };

    final list = _allAttendance.where((a) {
      return validIds.contains(a.employeeId.toLowerCase()) ||
          validIds.contains(a.employeeCode.toLowerCase()) ||
          validIds.contains(a.uid.toLowerCase());
    }).toList();

    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<AttendanceModel> getPendingApprovals() {
    return _allAttendance
        .where((a) => a.status == AttendanceStatus.pending)
        .toList()
      ..sort((a, b) => (b.clockInTime ?? DateTime.now()).compareTo(a.clockInTime ?? DateTime.now()));
  }

  List<AttendanceModel> getPendingApprovalsForTL(String? tlId) {
    if (tlId == null) return [];
    return _firestoreService.getPendingApprovalsForTL(tlId);
  }

  List<AttendanceModel> getTeamAttendanceForTL(String? tlId) {
    if (tlId == null) return [];
    return _firestoreService.getAttendanceForTL(tlId);
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

  Future<bool> captureSelfie({ImageSource source = ImageSource.camera}) async {
    try {
      _isProcessing = true;
      _errorMessage = null;
      notifyListeners();

      final photo = await _storageService.captureSelfiePhoto(source: source);
      if (photo == null) {
        _isProcessing = false;
        notifyListeners();
        return false;
      }

      _tempPhotoFile = photo;
      _tempPhotoDataUrl = photo.path;
      _isProcessing = false;
      notifyListeners();

      // Upload photo in background without blocking UI
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(now);
      _storageService.uploadAttendancePhoto(
        userId: 'temp_user',
        date: dateStr,
        type: 'clockIn',
        file: photo,
      ).then((uploadedUrl) {
        if (uploadedUrl.isNotEmpty && _tempPhotoFile == photo) {
          _tempPhotoDataUrl = uploadedUrl;
          notifyListeners();
        }
      }).catchError((err) {
        debugPrint('Background attendance photo upload notice: $err');
      });

      return true;
    } catch (e) {
      _errorMessage = 'Failed to capture photo: $e';
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  void resetProcessing() {
    _isProcessing = false;
    _errorMessage = null;
    notifyListeners();
  }

  void clearTempPhoto() {
    _tempPhotoFile = null;
    _tempPhotoDataUrl = null;
    _isProcessing = false;
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

      checkShiftCompletedAlert(user);

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

  final Set<String> _notified8HourAttendanceIds = {};
  final Set<String> _notifiedBreakLimitIds = {};

  void checkShiftCompletedAlert(UserModel user) {
    final todayRec = getTodayAttendance(user.userId);
    if (todayRec == null || todayRec.clockOutTime != null) return;

    final netMins = todayRec.netWorkingDuration?.inMinutes ?? 0;
    final breakMins = todayRec.totalBreakMinutes;

    // 1. Max 1-Hour Break limit alert (60 mins)
    if (breakMins >= 60 && !_notifiedBreakLimitIds.contains(todayRec.attendanceId)) {
      _notifiedBreakLimitIds.add(todayRec.attendanceId);
      NotificationService().sendNotification(
        title: '☕ Maximum 1-Hour Break Reached',
        message: '${user.name}, you have reached the daily maximum break allowance of 1 hour (${breakMins}m logged). Please resume work.',
        type: 'warning',
      );
    }

    // 2. 8-Hour Net Work target alert (480 mins)
    if (netMins >= 480 && !_notified8HourAttendanceIds.contains(todayRec.attendanceId)) {
      _notified8HourAttendanceIds.add(todayRec.attendanceId);
      
      NotificationService().sendNotification(
        title: '🎉 8-Hour Workday Completed!',
        message: 'Congratulations ${user.name}! You completed your 8-hour net work target (Total shift span: ${todayRec.formattedGrossDuration}). You can clock out now.',
        type: 'approval',
      );
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

  Future<bool> submitClockOut(String attendanceId, {double? latitude, double? longitude}) async {
    try {
      _isProcessing = true;
      notifyListeners();

      await _firestoreService.submitClockOut(
        attendanceId: attendanceId,
        clockOutPhotoUrl: _tempPhotoDataUrl,
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
