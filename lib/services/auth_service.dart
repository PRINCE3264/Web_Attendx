import 'dart:async';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/audit_service.dart';
import '../services/notification_service.dart';

import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserModel? _currentUser;
  final _authStateController = StreamController<UserModel?>.broadcast();
  final Map<String, String> _passwords = {};
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleSignInInitialized = false;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_isGoogleSignInInitialized) {
      await _googleSignIn.initialize();
      _isGoogleSignInInitialized = true;
    }
  }

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

  Future<UserModel> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) {
        throw Exception('Google sign-in was aborted.');
      }

      final email = googleUser.email.toLowerCase().trim();
      final users = FirestoreService().getAllUsers();
      
      // Strict role-based security: check if user exists in Firestore
      final userIndex = users.indexWhere((u) => u.email.toLowerCase() == email);
      
      if (userIndex == -1) {
        // Not registered
        await _googleSignIn.signOut();
        throw Exception('Your account is not registered. Please contact Admin/HR.');
      }

      final user = users[userIndex];

      if (!user.isActive) {
        await _googleSignIn.signOut();
        throw Exception('This account has been disabled by Administrator.');
      }

      _currentUser = user;
      _authStateController.add(_currentUser);

      AuditService().log(
        actor: user,
        actionType: 'GOOGLE_LOGIN',
        description: '${user.name} logged into system via Google.',
        targetEntityId: user.userId,
      );

      return user;
    } catch (e) {
      await _googleSignIn.signOut();
      rethrow;
    }
  }

  Future<UserModel> adminCreateEmployeeAccount({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    required String employeeId,
    required String department,
    String? teamId,
    String? teamName,
    String? managerId,
    String? managerName,
    DateTime? joiningDate,
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
      managerId: managerId,
      managerName: managerName,
      department: department.trim(),
      isActive: true,
      createdAt: joiningDate ?? DateTime.now(),
    );

    _passwords[cleanEmail] = password;

    await FirestoreService().createEmployee(newUser, _currentUser ?? newUser);

    NotificationService().sendNotification(
      title: 'New Account Created 🎉',
      message: 'Account created for ${newUser.name} as ${role.name}.',
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

  Future<void> updateMyProfile({required String newName, String? newAvatarUrl}) async {
    if (_currentUser == null) return;
    
    final updatedUser = _currentUser!.copyWith(
      name: newName.trim(),
      avatarUrl: newAvatarUrl,
    );
    
    // We update in Firestore
    await FirestoreService().updateEmployee(updatedUser, _currentUser!);
    
    _currentUser = updatedUser;
    _authStateController.add(_currentUser);

    NotificationService().sendNotification(
      title: 'Profile Updated ✅',
      message: 'Your profile information has been saved successfully.',
      type: 'success',
    );
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
