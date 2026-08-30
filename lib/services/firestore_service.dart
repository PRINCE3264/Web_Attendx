import 'dart:async';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/attendance_model.dart';
import '../models/team_model.dart';
import '../models/break_model.dart';
import '../models/leave_model.dart';
import '../models/correction_model.dart';
import '../models/policy_model.dart';
import 'mock_data_seeder.dart';
import 'notification_service.dart';
import 'audit_service.dart';
import 'geofence_service.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal() {
    _initializeData();
  }

  final List<UserModel> _users = [];
  final List<AttendanceModel> _attendance = [];
  final List<TeamModel> _teams = [];
  final List<LeaveRequestModel> _leaves = [];
  final List<LeaveBalanceModel> _leaveBalances = [];
  final List<AttendanceCorrectionModel> _corrections = [];
  AttendancePolicyModel _policy = MockDataSeeder.getSeedPolicy();

  final _attendanceStreamController = StreamController<List<AttendanceModel>>.broadcast();
  final _usersStreamController = StreamController<List<UserModel>>.broadcast();
  final _teamsStreamController = StreamController<List<TeamModel>>.broadcast();
  final _leavesStreamController = StreamController<List<LeaveRequestModel>>.broadcast();
  final _correctionsStreamController = StreamController<List<AttendanceCorrectionModel>>.broadcast();
  final _policyStreamController = StreamController<AttendancePolicyModel>.broadcast();

  Stream<List<AttendanceModel>> get attendanceStream => _attendanceStreamController.stream;
  Stream<List<UserModel>> get usersStream => _usersStreamController.stream;
  Stream<List<TeamModel>> get teamsStream => _teamsStreamController.stream;
  Stream<List<LeaveRequestModel>> get leavesStream => _leavesStreamController.stream;
  Stream<List<AttendanceCorrectionModel>> get correctionsStream => _correctionsStreamController.stream;
  Stream<AttendancePolicyModel> get policyStream => _policyStreamController.stream;

  void _initializeData() {
    _users.addAll(MockDataSeeder.getSeedUsers());
    _teams.addAll(MockDataSeeder.getSeedTeams());
    _attendance.addAll(MockDataSeeder.getSeedAttendanceHistory());
    _leaves.addAll(MockDataSeeder.getSeedLeaveRequests());
    _leaveBalances.addAll(MockDataSeeder.getSeedLeaveBalances());
    _corrections.addAll(MockDataSeeder.getSeedCorrections());
    _policy = MockDataSeeder.getSeedPolicy();
    AuditService().seedInitialLogs(MockDataSeeder.getSeedAuditLogs());
    _notifyAll();
  }

  void _notifyAll() {
    _attendanceStreamController.add(List.unmodifiable(_attendance));
    _usersStreamController.add(List.unmodifiable(_users));
    _teamsStreamController.add(List.unmodifiable(_teams));
    _leavesStreamController.add(List.unmodifiable(_leaves));
    _correctionsStreamController.add(List.unmodifiable(_corrections));
    _policyStreamController.add(_policy);
  }

  void resetToDefaultSeed() {
    _users.clear();
    _teams.clear();
    _attendance.clear();
    _leaves.clear();
    _leaveBalances.clear();
    _corrections.clear();
    _initializeData();
  }

  // Policy methods
  AttendancePolicyModel get currentPolicy => _policy;

  Future<void> updatePolicy(AttendancePolicyModel newPolicy, UserModel actor) async {
    final oldStart = _policy.officeStartTime;
    _policy = newPolicy;
    _policyStreamController.add(_policy);

    AuditService().log(
      actor: actor,
      actionType: 'POLICY_UPDATE',
      description: 'Updated Attendance Policy (Start: ${_policy.officeStartTime}, Grace: ${_policy.gracePeriodMinutes}m, Geofence: ${_policy.geofenceRadiusMeters}m).',
      targetEntityId: newPolicy.policyId,
      oldValue: 'Start: $oldStart',
      newValue: 'Start: ${_policy.officeStartTime}',
    );

    NotificationService().sendNotification(
      title: 'Policy Updated ⚙️',
      message: 'Attendance rules have been updated by ${actor.name}.',
      type: 'info',
    );
  }

  // User management (Admin)
  List<UserModel> getAllUsers() => List.unmodifiable(_users);
  List<UserModel> getEmployees() => _users.where((u) => u.role == UserRole.employee).toList();

  UserModel? getUserById(String id) {
    try {
      return _users.firstWhere((u) => u.userId == id);
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> createEmployee(UserModel newUser, UserModel actor) async {
    _users.add(newUser);
    _leaveBalances.add(LeaveBalanceModel(employeeId: newUser.userId));
    _usersStreamController.add(List.unmodifiable(_users));

    AuditService().log(
      actor: actor,
      actionType: 'ADMIN_USER_ADD',
      description: 'Added new employee: ${newUser.name} (${newUser.employeeId}) in ${newUser.department}.',
      targetEntityId: newUser.userId,
    );

    NotificationService().sendNotification(
      title: 'Employee Added 👤',
      message: '${newUser.name} has been enrolled into the system.',
      type: 'info',
    );

    return newUser;
  }

  Future<UserModel> updateEmployee(UserModel updatedUser, UserModel actor) async {
    final index = _users.indexWhere((u) => u.userId == updatedUser.userId);
    if (index != -1) {
      _users[index] = updatedUser;
      _usersStreamController.add(List.unmodifiable(_users));

      AuditService().log(
        actor: actor,
        actionType: 'ADMIN_USER_EDIT',
        description: 'Updated employee profile for ${updatedUser.name}.',
        targetEntityId: updatedUser.userId,
      );
    }
    return updatedUser;
  }

  Future<void> toggleUserActive(String userId, bool isActive, UserModel actor) async {
    final index = _users.indexWhere((u) => u.userId == userId);
    if (index != -1) {
      final old = _users[index];
      _users[index] = old.copyWith(isActive: isActive);
      _usersStreamController.add(List.unmodifiable(_users));

      AuditService().log(
        actor: actor,
        actionType: 'ADMIN_USER_STATUS',
        description: '${isActive ? "Activated" : "Disabled"} user account for ${old.name}.',
        targetEntityId: userId,
        oldValue: 'isActive: ${old.isActive}',
        newValue: 'isActive: $isActive',
      );
    }
  }

  // Attendance Queries
  List<AttendanceModel> getAllAttendance() => List.unmodifiable(_attendance);

  AttendanceModel? getTodayAttendance(String employeeId) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      return _attendance.firstWhere(
        (a) => a.employeeId == employeeId && a.date == todayStr,
      );
    } catch (_) {
      return null;
    }
  }

  List<AttendanceModel> getAttendanceForEmployee(String employeeId) {
    return _attendance
        .where((a) => a.employeeId == employeeId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<AttendanceModel> getPendingApprovals() {
    return _attendance
        .where((a) => a.status == AttendanceStatus.pending)
        .toList()
      ..sort((a, b) => (b.clockInTime ?? DateTime.now()).compareTo(a.clockInTime ?? DateTime.now()));
  }

  List<AttendanceModel> getAttendanceByDate(String dateStr) {
    return _attendance.where((a) => a.date == dateStr).toList();
  }

  // Clock-In with Geofence & Timing Policy evaluation
  Future<AttendanceModel> submitClockIn({
    required UserModel user,
    required String photoUrl,
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final attendanceId = '${user.userId}_$dateStr';

    _attendance.removeWhere((a) => a.attendanceId == attendanceId);

    // Geofencing verification
    final userLat = latitude ?? _policy.officeLatitude + 0.0002;
    final userLng = longitude ?? _policy.officeLongitude + 0.0001;

    final geofenceRes = GeofenceService.verifyLocation(
      userLat: userLat,
      userLng: userLng,
      officeLat: _policy.officeLatitude,
      officeLng: _policy.officeLongitude,
      allowedRadiusMeters: _policy.geofenceRadiusMeters,
    );

    // Policy Timing evaluation
    TimingStatus timingStatus = TimingStatus.onTime;
    final startParts = _policy.officeStartTime.split(':');
    final startHour = int.tryParse(startParts[0]) ?? 9;
    final startMin = int.tryParse(startParts[1]) ?? 30;

    final shiftStartTime = DateTime(now.year, now.month, now.day, startHour, startMin);
    final graceEndTime = shiftStartTime.add(Duration(minutes: _policy.gracePeriodMinutes));

    if (now.isAfter(graceEndTime)) {
      timingStatus = TimingStatus.lateArrival;
    } else if (now.isAfter(shiftStartTime)) {
      timingStatus = TimingStatus.gracePeriod;
    }

    final record = AttendanceModel(
      attendanceId: attendanceId,
      employeeId: user.userId,
      employeeName: user.name,
      employeeCode: user.employeeId,
      employeeAvatar: user.avatarUrl,
      teamId: user.teamId,
      teamName: user.teamName,
      date: dateStr,
      clockInTime: now,
      clockInPhotoUrl: photoUrl,
      status: AttendanceStatus.pending,
      timingStatus: timingStatus,
      latitude: userLat,
      longitude: userLng,
      isWithinGeofence: geofenceRes.isWithinGeofence,
      distanceFromOfficeMeters: geofenceRes.distanceMeters,
      location: location ?? (_policy.officeName),
      createdAt: now,
    );

    _attendance.insert(0, record);
    _notifyAll();

    AuditService().log(
      actor: user,
      actionType: 'CLOCK_IN',
      description: '${user.name} clocked in (${timingStatus.label}, Distance: ${geofenceRes.distanceMeters}m).',
      targetEntityId: attendanceId,
    );

    NotificationService().sendNotification(
      title: 'Clock-In Submitted 📍',
      message: '${user.name} clocked in at ${DateFormat('hh:mm a').format(now)} (${timingStatus.label}). Awaiting TL Review.',
      type: 'info',
    );

    return record;
  }

  // Break Tracking (Start / End)
  Future<AttendanceModel> startBreak({
    required String attendanceId,
    required BreakType type,
    required UserModel user,
  }) async {
    final index = _attendance.indexWhere((a) => a.attendanceId == attendanceId);
    if (index == -1) throw Exception('Attendance record not found');

    final rec = _attendance[index];
    final now = DateTime.now();
    final newBreak = BreakRecord(
      breakId: 'brk_${now.millisecondsSinceEpoch}',
      type: type,
      startTime: now,
    );

    final updatedBreaks = List<BreakRecord>.from(rec.breaks)..add(newBreak);
    final updated = rec.copyWith(breaks: updatedBreaks);
    _attendance[index] = updated;
    _notifyAll();

    AuditService().log(
      actor: user,
      actionType: 'BREAK_START',
      description: '${user.name} started ${type.label}.',
      targetEntityId: attendanceId,
    );

    NotificationService().sendNotification(
      title: 'Break Started ☕',
      message: 'Enjoy your ${type.label}. Timer is running.',
      type: 'info',
    );

    return updated;
  }

  Future<AttendanceModel> endBreak({
    required String attendanceId,
    required UserModel user,
  }) async {
    final index = _attendance.indexWhere((a) => a.attendanceId == attendanceId);
    if (index == -1) throw Exception('Attendance record not found');

    final rec = _attendance[index];
    final now = DateTime.now();

    final updatedBreaks = rec.breaks.map((b) {
      if (b.isActive) {
        final duration = now.difference(b.startTime).inMinutes;
        return b.copyWith(endTime: now, durationMinutes: duration);
      }
      return b;
    }).toList();

    int totalBreakMins = 0;
    for (final b in updatedBreaks) {
      totalBreakMins += b.currentDurationMinutes;
    }

    final updated = rec.copyWith(
      breaks: updatedBreaks,
      totalBreakMinutes: totalBreakMins,
    );
    _attendance[index] = updated;
    _notifyAll();

    AuditService().log(
      actor: user,
      actionType: 'BREAK_END',
      description: '${user.name} resumed duty after break. Total break: ${totalBreakMins}m.',
      targetEntityId: attendanceId,
    );

    NotificationService().sendNotification(
      title: 'Break Ended 👍',
      message: 'Welcome back! Shift timer resumed.',
      type: 'info',
    );

    return updated;
  }

  // Manager Approve / Reject / Bulk Approve
  Future<AttendanceModel> approveAttendance({
    required String attendanceId,
    required UserModel manager,
    String? comment,
  }) async {
    final index = _attendance.indexWhere((a) => a.attendanceId == attendanceId);
    if (index == -1) throw Exception('Attendance record not found');

    final old = _attendance[index];
    final updated = old.copyWith(
      status: AttendanceStatus.approved,
      approvedBy: manager.userId,
      approvedByName: '${manager.name} (${manager.role.name})',
      approvedAt: DateTime.now(),
      managerComment: comment,
      rejectionReason: null,
    );

    _attendance[index] = updated;
    _notifyAll();

    AuditService().log(
      actor: manager,
      actionType: 'TL_APPROVED',
      description: 'Approved attendance for ${old.employeeName}.',
      targetEntityId: attendanceId,
    );

    NotificationService().sendNotification(
      title: 'Attendance Approved! 🎉',
      message: 'Your clock-in was approved by ${manager.name}.',
      type: 'approval',
    );

    return updated;
  }

  Future<int> bulkApprovePending(UserModel manager) async {
    int count = 0;
    final now = DateTime.now();

    for (int i = 0; i < _attendance.length; i++) {
      if (_attendance[i].status == AttendanceStatus.pending) {
        _attendance[i] = _attendance[i].copyWith(
          status: AttendanceStatus.approved,
          approvedBy: manager.userId,
          approvedByName: '${manager.name} (${manager.role.name})',
          approvedAt: now,
          managerComment: 'Bulk verified & approved by TL',
        );
        count++;
      }
    }

    if (count > 0) {
      _notifyAll();
      AuditService().log(
        actor: manager,
        actionType: 'TL_BULK_APPROVE',
        description: 'Bulk approved $count pending attendance submissions.',
        targetEntityId: 'batch_${now.millisecondsSinceEpoch}',
      );

      NotificationService().sendNotification(
        title: 'Bulk Approval Complete ⚡',
        message: 'Successfully approved $count pending attendance requests.',
        type: 'approval',
      );
    }

    return count;
  }

  Future<AttendanceModel> rejectAttendance({
    required String attendanceId,
    required UserModel manager,
    required String reason,
  }) async {
    final index = _attendance.indexWhere((a) => a.attendanceId == attendanceId);
    if (index == -1) throw Exception('Attendance record not found');

    final old = _attendance[index];
    final updated = old.copyWith(
      status: AttendanceStatus.rejected,
      approvedBy: manager.userId,
      approvedByName: '${manager.name} (${manager.role.name})',
      approvedAt: DateTime.now(),
      rejectionReason: reason.trim().isEmpty ? 'Photo or geofence verification failed' : reason,
    );

    _attendance[index] = updated;
    _notifyAll();

    AuditService().log(
      actor: manager,
      actionType: 'TL_REJECTED',
      description: 'Rejected attendance for ${old.employeeName}. Reason: ${updated.rejectionReason}',
      targetEntityId: attendanceId,
    );

    NotificationService().sendNotification(
      title: 'Attendance Rejected ⚠️',
      message: 'Your attendance was rejected by ${manager.name}. Reason: ${updated.rejectionReason}',
      type: 'rejection',
    );

    return updated;
  }

  Future<AttendanceModel> submitClockOut({
    required String attendanceId,
    String? clockOutPhotoUrl,
  }) async {
    final index = _attendance.indexWhere((a) => a.attendanceId == attendanceId);
    if (index == -1) throw Exception('Attendance record not found');

    final old = _attendance[index];
    final now = DateTime.now();

    // Auto close any active breaks
    final closedBreaks = old.breaks.map((b) {
      if (b.isActive) {
        final duration = now.difference(b.startTime).inMinutes;
        return b.copyWith(endTime: now, durationMinutes: duration);
      }
      return b;
    }).toList();

    final grossMinutes = old.clockInTime != null ? now.difference(old.clockInTime!).inMinutes : 0;
    int totalBreakMins = 0;
    for (final b in closedBreaks) {
      totalBreakMins += b.currentDurationMinutes;
    }

    final updated = old.copyWith(
      clockOutTime: now,
      clockOutPhotoUrl: clockOutPhotoUrl,
      status: AttendanceStatus.completed,
      breaks: closedBreaks,
      totalBreakMinutes: totalBreakMins,
      totalWorkMinutes: grossMinutes,
    );

    _attendance[index] = updated;
    _notifyAll();

    AuditService().log(
      actor: UserModel(
        userId: old.employeeId,
        name: old.employeeName,
        email: '',
        role: UserRole.employee,
        employeeId: old.employeeCode,
        teamId: old.teamId,
        department: '',
      ),
      actionType: 'CLOCK_OUT',
      description: '${old.employeeName} completed daily shift (Net: ${updated.formattedNetDuration}).',
      targetEntityId: attendanceId,
    );

    NotificationService().sendNotification(
      title: 'Clock-Out Completed 👍',
      message: 'Daily shift completed. Net worked: ${updated.formattedNetDuration}.',
      type: 'info',
    );

    return updated;
  }

  // Leave Management Lifecycle
  List<LeaveRequestModel> getAllLeaves() => List.unmodifiable(_leaves);

  List<LeaveRequestModel> getLeavesForEmployee(String employeeId) {
    return _leaves.where((l) => l.employeeId == employeeId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  LeaveBalanceModel getLeaveBalance(String employeeId) {
    try {
      return _leaveBalances.firstWhere((b) => b.employeeId == employeeId);
    } catch (_) {
      final balance = LeaveBalanceModel(employeeId: employeeId);
      _leaveBalances.add(balance);
      return balance;
    }
  }

  Future<LeaveRequestModel> applyLeave({
    required UserModel employee,
    required LeaveType leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required int totalDays,
    required String reason,
  }) async {
    final leave = LeaveRequestModel(
      leaveId: 'leave_${DateTime.now().millisecondsSinceEpoch}',
      employeeId: employee.userId,
      employeeName: employee.name,
      employeeCode: employee.employeeId,
      department: employee.department,
      leaveType: leaveType,
      startDate: startDate,
      endDate: endDate,
      totalDays: totalDays,
      reason: reason,
      status: LeaveStatus.pending,
    );

    _leaves.insert(0, leave);
    _leavesStreamController.add(List.unmodifiable(_leaves));

    AuditService().log(
      actor: employee,
      actionType: 'LEAVE_APPLY',
      description: '${employee.name} applied for $totalDays days ${leaveType.label}.',
      targetEntityId: leave.leaveId,
    );

    NotificationService().sendNotification(
      title: 'Leave Application Submitted 🌴',
      message: '$totalDays days ${leaveType.label} requested. Sent to Manager for review.',
      type: 'info',
    );

    return leave;
  }

  Future<LeaveRequestModel> reviewLeave({
    required String leaveId,
    required bool isApproved,
    required UserModel manager,
    String? rejectionReason,
  }) async {
    final index = _leaves.indexWhere((l) => l.leaveId == leaveId);
    if (index == -1) throw Exception('Leave request not found');

    final old = _leaves[index];
    final updated = old.copyWith(
      status: isApproved ? LeaveStatus.approved : LeaveStatus.rejected,
      reviewedBy: manager.userId,
      reviewerName: manager.name,
      reviewedAt: DateTime.now(),
      rejectionReason: rejectionReason,
    );

    _leaves[index] = updated;

    // Deduct from balance if approved
    if (isApproved) {
      final bIndex = _leaveBalances.indexWhere((b) => b.employeeId == old.employeeId);
      if (bIndex != -1) {
        final bal = _leaveBalances[bIndex];
        if (old.leaveType == LeaveType.casual) {
          _leaveBalances[bIndex] = bal.copyWith(casualUsed: bal.casualUsed + old.totalDays);
        } else if (old.leaveType == LeaveType.sick) {
          _leaveBalances[bIndex] = bal.copyWith(sickUsed: bal.sickUsed + old.totalDays);
        } else if (old.leaveType == LeaveType.earned) {
          _leaveBalances[bIndex] = bal.copyWith(earnedUsed: bal.earnedUsed + old.totalDays);
        }
      }
    }

    _leavesStreamController.add(List.unmodifiable(_leaves));

    AuditService().log(
      actor: manager,
      actionType: isApproved ? 'LEAVE_APPROVE' : 'LEAVE_REJECT',
      description: '${isApproved ? "Approved" : "Rejected"} leave request for ${old.employeeName}.',
      targetEntityId: leaveId,
    );

    NotificationService().sendNotification(
      title: isApproved ? 'Leave Approved 🎉' : 'Leave Rejected ⚠️',
      message: 'Your ${old.leaveType.label} was ${isApproved ? "approved" : "rejected"} by ${manager.name}.',
      type: isApproved ? 'approval' : 'rejection',
    );

    return updated;
  }

  // Attendance Regularization / Correction
  List<AttendanceCorrectionModel> getAllCorrections() => List.unmodifiable(_corrections);

  Future<AttendanceCorrectionModel> submitCorrectionRequest({
    required UserModel employee,
    required String attendanceId,
    required String date,
    required DateTime requestedClockIn,
    required DateTime requestedClockOut,
    required String reason,
  }) async {
    final corr = AttendanceCorrectionModel(
      correctionId: 'corr_${DateTime.now().millisecondsSinceEpoch}',
      attendanceId: attendanceId,
      employeeId: employee.userId,
      employeeName: employee.name,
      employeeCode: employee.employeeId,
      date: date,
      requestedClockIn: requestedClockIn,
      requestedClockOut: requestedClockOut,
      reason: reason,
      status: CorrectionStatus.pending,
    );

    _corrections.insert(0, corr);
    _correctionsStreamController.add(List.unmodifiable(_corrections));

    AuditService().log(
      actor: employee,
      actionType: 'CORRECTION_REQUEST',
      description: '${employee.name} requested attendance regularization for $date.',
      targetEntityId: corr.correctionId,
    );

    NotificationService().sendNotification(
      title: 'Correction Requested 🔄',
      message: 'Regularization request submitted for $date.',
      type: 'info',
    );

    return corr;
  }

  Future<AttendanceCorrectionModel> reviewCorrection({
    required String correctionId,
    required bool isApproved,
    required UserModel manager,
    String? note,
  }) async {
    final index = _corrections.indexWhere((c) => c.correctionId == correctionId);
    if (index == -1) throw Exception('Correction not found');

    final old = _corrections[index];
    final updated = old.copyWith(
      status: isApproved ? CorrectionStatus.approved : CorrectionStatus.rejected,
      reviewedBy: manager.userId,
      reviewerName: manager.name,
      reviewedAt: DateTime.now(),
      managerNote: note,
    );

    _corrections[index] = updated;

    // Apply correction to attendance record if approved
    if (isApproved) {
      final aIndex = _attendance.indexWhere((a) => a.attendanceId == old.attendanceId);
      if (aIndex != -1) {
        final gross = old.requestedClockOut.difference(old.requestedClockIn).inMinutes;
        _attendance[aIndex] = _attendance[aIndex].copyWith(
          clockInTime: old.requestedClockIn,
          clockOutTime: old.requestedClockOut,
          status: AttendanceStatus.completed,
          totalWorkMinutes: gross,
          managerComment: 'Regularized: ${old.reason}',
        );
        _attendanceStreamController.add(List.unmodifiable(_attendance));
      }
    }

    _correctionsStreamController.add(List.unmodifiable(_corrections));

    AuditService().log(
      actor: manager,
      actionType: isApproved ? 'CORRECTION_APPROVE' : 'CORRECTION_REJECT',
      description: '${isApproved ? "Approved" : "Rejected"} attendance regularization for ${old.employeeName}.',
      targetEntityId: correctionId,
    );

    NotificationService().sendNotification(
      title: isApproved ? 'Attendance Regularized 🎉' : 'Correction Rejected ⚠️',
      message: 'Regularization for ${old.date} was ${isApproved ? "approved" : "rejected"}.',
      type: isApproved ? 'approval' : 'rejection',
    );

    return updated;
  }
}
