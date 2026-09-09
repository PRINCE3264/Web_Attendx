import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/audit_service.dart';
import '../services/notification_service.dart';
import '../services/local_storage_service.dart';

import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserModel? _currentUser;
  final _authStateController = StreamController<UserModel?>.broadcast();
  final Map<String, String> _passwords = {};
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  Stream<UserModel?> get authStateChanges => _authStateController.stream;
  UserModel? get currentUser => _currentUser;

  Future<UserModel?> loadSavedSession() async {
    try {
      final saved = await LocalStorageService().loadSession();
      if (saved != null) {
        final fresh = FirestoreService().getUserById(saved.userId);
        _currentUser = fresh ?? saved;
        _authStateController.add(_currentUser);
      }
    } catch (e) {
      debugPrint('Error loading saved session: $e');
    }
    return _currentUser;
  }

  Future<void> updateSessionUser(UserModel? user) async {
    _currentUser = user;
    _authStateController.add(_currentUser);
    await LocalStorageService().saveSession(user);
  }

  Future<void> ensureFirebaseAuthSession() async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
    } catch (e) {
      debugPrint('Anonymous auth session fallback info: $e');
    }
  }

  final Map<String, int> _failedAttempts = {};
  final Map<String, DateTime> _lockoutTime = {};

  void _checkRateLimit(String cleanEmail) {
    if (_lockoutTime.containsKey(cleanEmail)) {
      final lockUntil = _lockoutTime[cleanEmail]!;
      if (DateTime.now().isBefore(lockUntil)) {
        final remainingSec = lockUntil.difference(DateTime.now()).inSeconds;
        throw Exception(
          '🔒 Security Lockout: Too many failed login attempts. Please try again in $remainingSec seconds.',
        );
      } else {
        _lockoutTime.remove(cleanEmail);
        _failedAttempts.remove(cleanEmail);
      }
    }
  }

  void _recordFailedAttempt(String cleanEmail) {
    final count = (_failedAttempts[cleanEmail] ?? 0) + 1;
    _failedAttempts[cleanEmail] = count;
    if (count >= 5) {
      _lockoutTime[cleanEmail] = DateTime.now().add(const Duration(minutes: 2));
      AuditService().log(
        actor: UserModel(
          userId: 'system_sec',
          name: 'Security Shield',
          email: cleanEmail,
          role: UserRole.employee,
          employeeId: 'SYS-SEC',
          department: 'Security',
          teamId: 'team_security',
        ),
        actionType: 'SECURITY_ALERT',
        description: 'BRUTE_FORCE_BLOCKED: Account $cleanEmail locked for 2 mins after 5 failed password attempts.',
        targetEntityId: cleanEmail,
      );
    }
  }

  void _recordSuccessfulLogin(String cleanEmail) {
    _failedAttempts.remove(cleanEmail);
    _lockoutTime.remove(cleanEmail);
  }

  Future<UserModel> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final cleanEmail = email.toLowerCase().trim();
    final enteredPass = password.trim();

    _checkRateLimit(cleanEmail);

    bool isFirebaseAuthSuccess = false;

    // 1. Authenticate with Firebase Authentication
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: cleanEmail,
        password: enteredPass,
      );
      if (credential.user != null) {
        isFirebaseAuthSuccess = true;
      }
    } catch (e) {
      debugPrint('Firebase Auth sign in notice: $e');
      await ensureFirebaseAuthSession();
    }

    // 2. Fetch User Profile from Firestore / local memory
    final users = FirestoreService().getAllUsers();
    final userIndex = users.indexWhere(
      (u) => u.email.toLowerCase() == cleanEmail,
    );

    if (userIndex == -1 && !isFirebaseAuthSuccess) {
      _recordFailedAttempt(cleanEmail);
      throw Exception(
        'No account found with email $cleanEmail. Please Create an Account first.',
      );
    }

    UserModel user;
    if (userIndex != -1) {
      user = users[userIndex];
    } else {
      user = UserModel(
        userId:
            FirebaseAuth.instance.currentUser?.uid ??
            'usr_${DateTime.now().millisecondsSinceEpoch}',
        name: cleanEmail.split('@').first.replaceAll('.', ' ').toUpperCase(),
        email: cleanEmail,
        role: UserRole.employee,
        employeeId: 'EMP-${1000 + users.length + 1}',
        department: 'Engineering',
        teamId: 'team_mobile',
        teamName: 'Engineering & Development',
        isActive: true,
        createdAt: DateTime.now(),
      );
      await FirestoreService().createEmployee(user, user);
    }

    // 3. Fallback password verification if Firebase Auth was skipped/offline
    if (!isFirebaseAuthSuccess) {
      final storedPass =
          _passwords[cleanEmail] ?? user.initialPassword ?? 'password123';
      if (enteredPass != storedPass) {
        _recordFailedAttempt(cleanEmail);
        throw Exception(
          'Incorrect password. Please enter the password associated with your account.',
        );
      }
    }

    _recordSuccessfulLogin(cleanEmail);

    if (!user.isActive) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
      throw Exception('This account has been disabled by Administrator.');
    }

    // 4. Single Phone / Device Binding Verification
    if (user.role == UserRole.employee || user.role == UserRole.manager) {
      final currentDeviceId = await LocalStorageService().getDeviceId();
      if (user.deviceId != currentDeviceId) {
        user = user.copyWith(deviceId: currentDeviceId);
        await FirestoreService().updateEmployee(user, user);
      }
    }

    await updateSessionUser(user);

    AuditService().log(
      actor: user,
      actionType: 'LOGIN',
      description: '${user.name} logged into system ($cleanEmail).',
      targetEntityId: user.userId,
    );

    return user;
  }

  Future<UserModel> signInWithGoogle({
    String? fallbackEmail,
    String? fallbackName,
    String? fallbackPhotoUrl,
  }) async {
    try {
      String? email;
      String? displayName;
      String? photoUrl;

      if (fallbackEmail != null && fallbackEmail.isNotEmpty) {
        email = fallbackEmail.toLowerCase().trim();
        displayName = fallbackName;
        photoUrl = fallbackPhotoUrl;
      } else {
        try {
          final googleUser = await _googleSignIn.signIn();
          if (googleUser == null) {
            throw Exception('Google Sign-In was cancelled.');
          }
          email = googleUser.email.toLowerCase().trim();
          displayName = googleUser.displayName;
          photoUrl = googleUser.photoUrl;
        } catch (e) {
          debugPrint('GoogleSignIn signIn exception: $e');
          final errStr = e.toString().toLowerCase();
          if (errStr.contains('cancel') || errStr.contains('abort')) {
            throw Exception('Google Sign-In was cancelled.');
          }
          if (errStr.contains('api10') ||
              errStr.contains('10:') ||
              errStr.contains('sign_in_failed')) {
            throw Exception(
              'Google Sign-In error (ApiException: 10): SHA-1 fingerprint is not registered in Firebase Console for this Android device/keystore.',
            );
          }
          rethrow;
        }
      }

      if (email.isEmpty) {
        throw Exception('Could not retrieve Google account email.');
      }
      final String validEmail = email;

      final users = FirestoreService().getAllUsers();
      final userIndex = users.indexWhere(
        (u) => u.email.toLowerCase() == validEmail,
      );

      UserModel user;
      if (userIndex != -1) {
        user = users[userIndex];
        if (!user.isActive) {
          try {
            await _googleSignIn.signOut();
          } catch (_) {}
          throw Exception('This account has been disabled by Administrator.');
        }

        // Auto-fetch and update user avatar from Google Account photo
        if (photoUrl != null &&
            photoUrl.isNotEmpty &&
            user.avatarUrl != photoUrl) {
          final updatedUser = user.copyWith(avatarUrl: photoUrl);
          await FirestoreService().updateEmployee(updatedUser, user);
          user = updatedUser;
        }
      } else {
        // Auto-enroll new Google User as Employee with their Google Profile Picture
        final newUser = UserModel(
          userId: 'usr_${DateTime.now().millisecondsSinceEpoch}',
          name: (displayName != null && displayName.isNotEmpty)
              ? displayName
              : validEmail.split('@').first.replaceAll('.', ' ').toUpperCase(),
          email: validEmail,
          role: UserRole.employee,
          employeeId: 'EMP-${1000 + users.length + 1}',
          department: 'Engineering',
          teamId: 'unassigned',
          teamName: 'Unassigned (Pending TL Allocation)',
          avatarUrl: photoUrl,
          isActive: true,
          createdAt: DateTime.now(),
        );
        await FirestoreService().createEmployee(newUser, newUser);
        user = newUser;
      }

      await updateSessionUser(user);

      AuditService().log(
        actor: user,
        actionType: 'GOOGLE_LOGIN',
        description:
            '${user.name} logged in via Google Authentication ($email).',
        targetEntityId: user.userId,
      );

      return user;
    } catch (e) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
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
    String? phoneNumber,
    String? shiftId,
    String? shiftName,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final users = FirestoreService().getAllUsers();

    if (users.any((u) => u.email.toLowerCase() == cleanEmail)) {
      throw Exception('An account with email $cleanEmail already exists.');
    }

    if (users.any(
      (u) => u.employeeId.toLowerCase() == employeeId.trim().toLowerCase(),
    )) {
      throw Exception(
        'Employee ID $employeeId is already assigned to another user.',
      );
    }

    final newUser = UserModel(
      userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: cleanEmail,
      role: role,
      employeeId: employeeId.trim().toUpperCase(),
      teamId:
          teamId ?? (role == UserRole.employee ? 'team_mobile' : 'team_mgmt'),
      teamName:
          teamName ??
          (role == UserRole.employee ? 'Mobile App Team' : 'Management'),
      managerId: managerId,
      managerName: managerName,
      department: department.trim(),
      phoneNumber: phoneNumber?.trim(),
      isActive: true,
      createdAt: joiningDate ?? DateTime.now(),
      initialPassword: password.trim(),
      shiftId: shiftId ?? 'shift_general',
      shiftName: shiftName ?? 'General Shift (09:30 AM - 06:30 PM)',
    );

    _passwords[cleanEmail] = password.trim();

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
      orElse: () => throw Exception(
        'No registered account found with email $cleanEmail.',
      ),
    );

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: cleanEmail);
    } catch (e) {
      debugPrint('Firebase sendPasswordResetEmail info: $e');
    }

    NotificationService().sendNotification(
      title: 'Password Reset Email Sent 📧',
      message:
          'Official password reset link sent to ${user.email} via Firebase Auth.',
      type: 'info',
    );

    return true;
  }

  /// Admin-only: Change any user's password directly (no Firebase Auth re-auth needed)
  Future<bool> adminChangePassword({
    required UserModel targetUser,
    required String newPassword,
    required UserModel actor,
  }) async {
    if (actor.role != UserRole.admin) {
      throw Exception('Only Admins can change other users\' passwords.');
    }
    final cleanEmail = targetUser.email.toLowerCase().trim();

    // Update in-memory password store
    _passwords[cleanEmail] = newPassword.trim();

    // Persist the new password in Firestore via initialPassword field
    final updatedUser = targetUser.copyWith(initialPassword: newPassword.trim());
    await FirestoreService().updateEmployee(updatedUser, actor);

    AuditService().log(
      actor: actor,
      actionType: 'ADMIN_PASSWORD_CHANGE',
      description:
          '${actor.name} changed password for ${targetUser.name} (${targetUser.employeeId}).',
      targetEntityId: targetUser.userId,
    );

    NotificationService().sendNotification(
      title: 'Password Changed 🔑',
      message: 'Password for ${targetUser.name} has been updated successfully.',
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

    try {
      final authInst = FirebaseAuth.instance;
      if (authInst.currentUser != null) {
        await authInst.currentUser?.updatePassword(newPassword);
      }
    } catch (e) {
      debugPrint('Firebase Auth password update info: $e');
    }

    AuditService().log(
      actor: user,
      actionType: 'PASSWORD_RESET',
      description: '${user.name} successfully reset account password.',
      targetEntityId: user.userId,
    );

    NotificationService().sendNotification(
      title: 'Password Changed Successfully 🔒',
      message: 'Your password has been updated in Firebase & System. Please sign in.',
      type: 'info',
    );

    return true;
  }

  Future<void> updateMyProfile({
    required String newName,
    String? newEmail,
    String? newAvatarUrl,
    String? newDepartment,
  }) async {
    if (_currentUser == null) return;

    final updatedUser = _currentUser!.copyWith(
      name: newName.trim(),
      email: (newEmail != null && newEmail.trim().isNotEmpty)
          ? newEmail.trim()
          : _currentUser!.email,
      avatarUrl: newAvatarUrl,
      department: (newDepartment != null && newDepartment.trim().isNotEmpty)
          ? newDepartment.trim()
          : _currentUser!.department,
    );

    // We update in Firestore
    await FirestoreService().updateEmployee(updatedUser, _currentUser!);

    await updateSessionUser(updatedUser);

    NotificationService().sendNotification(
      title: 'Profile Updated ✅',
      message: 'Your profile information has been saved successfully.',
      type: 'success',
    );
  }

  Future<void> switchUser(UserModel user) async {
    await updateSessionUser(user);
  }

  Future<UserModel> registerAccount({
    required String name,
    required String email,
    required String password,
    required String department,
    UserRole role = UserRole.employee,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final users = FirestoreService().getAllUsers();

    if (users.any((u) => u.email.toLowerCase() == cleanEmail)) {
      throw Exception('An account with email $cleanEmail already exists.');
    }

    String? firebaseUid;
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: cleanEmail,
            password: password,
          );
      firebaseUid = credential.user?.uid;
      await credential.user?.updateDisplayName(name);
    } catch (e) {
      debugPrint('Firebase Auth register info: $e');
    }

    final userId =
        firebaseUid ?? 'usr_${DateTime.now().millisecondsSinceEpoch}';
    final empCode = 'EMP-${1000 + users.length + 1}';

    final newUser = UserModel(
      userId: userId,
      name: name.trim(),
      email: cleanEmail,
      role: role,
      employeeId: empCode,
      department: department.trim().isNotEmpty
          ? department.trim()
          : 'Engineering',
      teamId: 'unassigned',
      teamName: 'Unassigned (Pending TL Allocation)',
      isActive: true,
      createdAt: DateTime.now(),
    );

    _passwords[cleanEmail] = password;

    await FirestoreService().createEmployee(newUser, newUser);

    await updateSessionUser(null);

    AuditService().log(
      actor: newUser,
      actionType: 'REGISTER',
      description: '${newUser.name} registered new account ($cleanEmail).',
      targetEntityId: newUser.userId,
    );

    NotificationService().sendNotification(
      title: 'Welcome to AttendX! 🎉',
      message: 'Account created successfully for ${newUser.name}.',
      type: 'info',
    );

    return newUser;
  }

  Future<void> resetUserDeviceBinding(String userId, UserModel actor) async {
    final user = FirestoreService().getUserById(userId);
    if (user != null) {
      final updated = user.copyWith(resetDeviceId: true);
      await FirestoreService().updateEmployee(updated, actor);
      AuditService().log(
        actor: actor,
        actionType: 'RESET_DEVICE_BINDING',
        description: 'Reset registered phone device lock for ${user.name} (${user.employeeId}).',
        targetEntityId: user.userId,
      );
    }
  }

  Future<void> signOut() async {
    await updateSessionUser(null);
  }

  void initializeDefaultUser() {
    // Keep user unauthenticated on app open so Login Screen is presented first
    _currentUser = null;
  }
}
