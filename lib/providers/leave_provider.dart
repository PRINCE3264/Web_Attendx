import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/leave_model.dart';
import '../services/firestore_service.dart';

class LeaveProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<LeaveRequestModel> _allLeaves = [];
  bool _isProcessing = false;
  String? _errorMessage;

  LeaveProvider() {
    _init();
  }

  void _init() {
    _allLeaves = _firestoreService.getAllLeaves();
    _firestoreService.leavesStream.listen((leaves) {
      _allLeaves = leaves;
      notifyListeners();
    });
  }

  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  List<LeaveRequestModel> get allLeaves => _allLeaves;

  List<LeaveRequestModel> getLeavesForEmployee(String employeeId) {
    return _allLeaves.where((l) => l.employeeId == employeeId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<LeaveRequestModel> getPendingLeaves() {
    return _allLeaves.where((l) => l.status == LeaveStatus.pending).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<LeaveRequestModel> getLeavesForTL(String tlId) {
    return _firestoreService.getLeavesForTL(tlId);
  }

  List<LeaveRequestModel> getPendingLeavesForTL(String tlId) {
    return _firestoreService.getLeavesForTL(tlId).where((l) => l.status == LeaveStatus.pending).toList();
  }

  LeaveBalanceModel getLeaveBalance(String employeeId) {
    return _firestoreService.getLeaveBalance(employeeId);
  }

  Future<bool> applyLeave({
    required UserModel employee,
    required LeaveType leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required int totalDays,
    required String reason,
  }) async {
    try {
      _isProcessing = true;
      _errorMessage = null;
      notifyListeners();

      await _firestoreService.applyLeave(
        employee: employee,
        leaveType: leaveType,
        startDate: startDate,
        endDate: endDate,
        totalDays: totalDays,
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

  Future<bool> reviewLeave({
    required String leaveId,
    required bool isApproved,
    required UserModel manager,
    String? rejectionReason,
  }) async {
    try {
      _isProcessing = true;
      notifyListeners();

      await _firestoreService.reviewLeave(
        leaveId: leaveId,
        isApproved: isApproved,
        manager: manager,
        rejectionReason: rejectionReason,
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
