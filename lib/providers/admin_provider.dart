import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/policy_model.dart';
import '../models/audit_log_model.dart';
import '../services/firestore_service.dart';
import '../services/audit_service.dart';
import '../services/mock_data_seeder.dart';

class AdminProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final AuditService _auditService = AuditService();

  List<UserModel> _users = [];
  List<AuditLogModel> _auditLogs = [];
  AttendancePolicyModel _policy = MockDataSeeder.getSeedPolicy();
  bool _isProcessing = false;
  String? _errorMessage;

  AdminProvider() {
    _init();
  }
  void _init() {
    _users = _firestoreService.getAllUsers();
    _policy = _firestoreService.currentPolicy;
    _auditLogs = _auditService.allLogs;

    _firestoreService.usersStream.listen((users) {
      _users = users;
      notifyListeners();
    });

    _firestoreService.policyStream.listen((policy) {
      _policy = policy;
      notifyListeners();
    });

    _auditService.auditStream.listen((logs) {
      _auditLogs = logs;
      notifyListeners();
    });
  }

  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  List<UserModel> get users => _users;
  List<AuditLogModel> get auditLogs => _auditLogs;
  AttendancePolicyModel get policy => _policy;

  // Add Employee
  Future<bool> addEmployee(UserModel newUser, UserModel admin) async {
    try {
      _isProcessing = true;
      _errorMessage = null;
      notifyListeners();

      await _firestoreService.createEmployee(newUser, admin);
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

  // Edit Employee
  Future<bool> updateEmployee(UserModel updatedUser, UserModel admin) async {
    try {
      _isProcessing = true;
      notifyListeners();

      await _firestoreService.updateEmployee(updatedUser, admin);
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

  // Delete Employee
  Future<bool> deleteEmployee(String userId, UserModel admin) async {
    try {
      _isProcessing = true;
      notifyListeners();

      final success = await _firestoreService.deleteEmployee(userId, admin);
      _isProcessing = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  // Toggle user active
  Future<void> toggleUserStatus(String userId, bool isActive, UserModel admin) async {
    await _firestoreService.toggleUserActive(userId, isActive, admin);
  }

  // Assign Employee to TL
  Future<bool> assignEmployeeToTL({
    required String employeeId,
    required UserModel tlUser,
    required UserModel admin,
  }) async {
    try {
      _isProcessing = true;
      notifyListeners();

      await _firestoreService.assignEmployeeToTL(
        employeeId: employeeId,
        tlUser: tlUser,
        actor: admin,
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

  // Update Policy
  Future<bool> updatePolicy(AttendancePolicyModel newPolicy, UserModel admin) async {
    try {
      _isProcessing = true;
      notifyListeners();

      await _firestoreService.updatePolicy(newPolicy, admin);
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
