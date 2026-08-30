import 'dart:async';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/audit_service.dart';
import '../services/notification_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserModel? _currentUser;
  final _authStateController = StreamController<UserModel?>.broadcast();
  final Map<String, String> _passwords = {};

  Stream<UserModel?> get authStateChanges => _authStateController.stream;
  UserModel? get currentUser => _currentUser;

  Future<UserModel> signInWithEmailAndPassword(String email, String password) async {
    final users = FirestoreService().getAllUsers();
    final user = users.firstWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase().trim(),
      orElse: () => throw Exception('No account found with this email.'),
    );

    if (!user.isActive) {
      throw Exception('This account has been disabled by Administrator.');
    }

    _currentUser = user;
    _authStateController.add(_currentUser);

    AuditService().log(
      actor: user,
      actionType: 'LOGIN',
      description: '${user.name} logged into system.',
      targetEntityId: user.userId,
    );

    return user;
  }

  Future<UserModel> signUpWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    required String employeeId,
    required String department,
    String? teamId,
    String? teamName,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final users = FirestoreService().getAllUsers();

    if (users.any((u) => u.email.toLowerCase() == cleanEmail)) {
      throw Exception('An account with email $cleanEmail already exists.');
    }

    if (users.any((u) => u.employeeId.toLowerCase() == employeeId.trim().toLowerCase())) {
      throw Exception('Employee ID $employeeId is already assigned to another user.');
    }

    final newUser = UserModel(
      userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: cleanEmail,
      role: role,
      employeeId: employeeId.trim().toUpperCase(),
      teamId: teamId ?? (role == UserRole.employee ? 'team_mobile' : 'team_mgmt'),
      teamName: teamName ?? (role == UserRole.employee ? 'Mobile App Team' : 'Management'),
      managerId: 'mgr_01',
      managerName: 'Vikram Mehta (TL)',
      department: department.trim(),
      isActive: true,
      createdAt: DateTime.now(),
    );

    _passwords[cleanEmail] = password;

    await FirestoreService().createEmployee(newUser, newUser);

    _currentUser = newUser;
    _authStateController.add(_currentUser);

    NotificationService().sendNotification(
      title: 'Welcome to Smart Attendance 🎉',
      message: 'Your account has been created as ${role.name}.',
      type: 'info',
    );

    return newUser;
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final users = FirestoreService().getAllUsers();
    final user = users.firstWhere(
      (u) => u.email.toLowerCase() == cleanEmail,
      orElse: () => throw Exception('No registered account found with email $cleanEmail.'),
    );

    NotificationService().sendNotification(
      title: 'Password Reset Code 🔑',
      message: 'Password reset OTP code (849201) sent to ${user.email}.',
      type: 'info',
    );

    return true;
  }

  Future<bool> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final users = FirestoreService().getAllUsers();
    final user = users.firstWhere(
      (u) => u.email.toLowerCase() == cleanEmail,
      orElse: () => throw Exception('User not found.'),
    );

    _passwords[cleanEmail] = newPassword;

    AuditService().log(
      actor: user,
      actionType: 'PASSWORD_RESET',
      description: '${user.name} successfully reset account password.',
      targetEntityId: user.userId,
    );

    NotificationService().sendNotification(
      title: 'Password Changed Successfully 🔒',
      message: 'Your password has been updated. Please sign in.',
      type: 'info',
    );

    return true;
  }

  Future<void> switchUser(UserModel user) async {
    _currentUser = user;
    _authStateController.add(_currentUser);
  }

  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
  }

  void initializeDefaultUser() {
    final users = FirestoreService().getAllUsers();
    if (users.isNotEmpty && _currentUser == null) {
      _currentUser = users.first; // Rahul Sharma (Employee)
      _authStateController.add(_currentUser);
    }
  }
}
