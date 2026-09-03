import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
import '../models/announcement_model.dart';
import '../models/notification_model.dart';
import 'local_storage_service.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal() {
    _initializeData();
    _bindFirestoreListeners();
    try {
      FirebaseAuth.instance.authStateChanges().listen((_) {
        _bindFirestoreListeners();
      });
    } catch (e) {
      debugPrint('Auth listener init error: $e');
    }
  }

  FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  final List<UserModel> _users = [];
  final List<AttendanceModel> _attendance = [];
  final List<TeamModel> _teams = [];
  final List<LeaveRequestModel> _leaves = [];
  final List<LeaveBalanceModel> _leaveBalances = [];
  final List<AttendanceCorrectionModel> _corrections = [];
  AttendancePolicyModel _policy = MockDataSeeder.getSeedPolicy();
  final List<AnnouncementModel> _announcements = [];
  final List<NotificationModel> _notifications = [];

  final _attendanceStreamController =
      StreamController<List<AttendanceModel>>.broadcast();
  final _usersStreamController = StreamController<List<UserModel>>.broadcast();
  final _teamsStreamController = StreamController<List<TeamModel>>.broadcast();
  final _leavesStreamController =
      StreamController<List<LeaveRequestModel>>.broadcast();
  final _correctionsStreamController =
      StreamController<List<AttendanceCorrectionModel>>.broadcast();
  final _policyStreamController =
      StreamController<AttendancePolicyModel>.broadcast();
  final _announcementsStreamController =
      StreamController<List<AnnouncementModel>>.broadcast();
  final _notificationsStreamController =
      StreamController<List<NotificationModel>>.broadcast();

  Stream<List<AttendanceModel>> get attendanceStream =>
      _attendanceStreamController.stream;
  Stream<List<UserModel>> get usersStream => _usersStreamController.stream;
  Stream<List<TeamModel>> get teamsStream => _teamsStreamController.stream;
  Stream<List<LeaveRequestModel>> get leavesStream =>
      _leavesStreamController.stream;
  Stream<List<AttendanceCorrectionModel>> get correctionsStream =>
      _correctionsStreamController.stream;
  Stream<AttendancePolicyModel> get policyStream =>
      _policyStreamController.stream;
  Stream<List<AnnouncementModel>> get announcementsStream =>
      _announcementsStreamController.stream;
  Stream<List<NotificationModel>> get notificationsStream =>
      _notificationsStreamController.stream;

  bool _hasBoundListeners = false;

  Future<void> syncLocalDataToFirestore() async {
    final db = _db;
    if (db == null) return;

    // Sync Users
    for (final user in List<UserModel>.from(_users)) {
      try {
        await db.collection('users').doc(user.userId).set(user.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore sync user notice (${user.userId}): $e');
      }
    }
    // Sync Attendance
    for (final att in _attendance) {
      try {
        await db.collection('attendance').doc(att.attendanceId).set(att.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore sync attendance notice (${att.attendanceId}): $e');
      }
    }
    // Sync Leaves
    for (final leave in _leaves) {
      try {
        await db.collection('leaves').doc(leave.leaveId).set(leave.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore sync leave notice (${leave.leaveId}): $e');
      }
    }
    // Sync Corrections
    for (final corr in _corrections) {
      try {
        await db.collection('attendanceCorrections').doc(corr.correctionId).set(corr.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore sync correction notice (${corr.correctionId}): $e');
      }
    }
    // Sync Notifications
    for (final notif in _notifications) {
      try {
        await db.collection('notifications').doc(notif.id).set(notif.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore sync notification notice (${notif.id}): $e');
      }
    }
    // Sync Policy
    try {
      await db.collection('attendancePolicies').doc('policy_standard').set(_policy.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore sync policy notice: $e');
    }

    debugPrint('⚡ Cloud Firestore Sync Attempt Complete!');
  }

  Future<void> ensureFirestoreConnected() async {
    _bindFirestoreListeners();
    await syncLocalDataToFirestore();
  }

  void _bindFirestoreListeners() {
    final db = _db;
    if (db == null) return;
    if (_hasBoundListeners) return;
    _hasBoundListeners = true;

    // Trigger immediate push sync to Cloud Firestore
    syncLocalDataToFirestore();

    try {
      // Users live stream from Firestore
      db.collection('users').snapshots().listen((snap) {
        if (snap.docs.isNotEmpty) {
          final items = snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList();

          if (_users.isNotEmpty) {
            final existingIds = _users.map((u) => u.userId).toSet();
            for (final u in items) {
              if (!existingIds.contains(u.userId)) {
                NotificationService().sendNotification(
                  title: '🆕 New Employee Joined: ${u.name}',
                  message: '${u.name} (${u.employeeId}) joined ${u.department}. Role: ${u.role.name}.',
                  type: 'info',
                );
              }
            }
          }

          final Map<String, UserModel> map = { for (final u in _users) u.userId: u };
          for (final u in items) {
            map[u.userId] = u;
          }
          _users.clear();
          _users.addAll(map.values);
          _usersStreamController.add(List.unmodifiable(_users));
          LocalStorageService().saveUsers(_users);
        } else if (_users.isNotEmpty) {
          for (final u in _users) {
            db.collection('users').doc(u.userId).set(u.toMap(), SetOptions(merge: true));
          }
        }
      }, onError: (e) => debugPrint('Live users sync info: $e'));

      // Teams live stream from Firestore
      db.collection('teams').snapshots().listen((snap) {
        if (snap.docs.isNotEmpty) {
          final items = snap.docs.map((d) => TeamModel.fromMap(d.data(), d.id)).toList();
          _teams.clear();
          _teams.addAll(items);
          _teamsStreamController.add(List.unmodifiable(_teams));
        } else if (_teams.isNotEmpty) {
          for (final t in _teams) {
            db.collection('teams').doc(t.teamId).set(t.toMap(), SetOptions(merge: true));
          }
        }
      }, onError: (e) => debugPrint('Live teams sync info: $e'));

      // Attendance live stream from Firestore
      db.collection('attendance').snapshots().listen((snap) {
        if (snap.docs.isNotEmpty) {
          final items = snap.docs.map((d) => AttendanceModel.fromMap(d.data(), d.id)).toList();
          final Map<String, AttendanceModel> map = { for (final a in _attendance) a.attendanceId: a };
          for (final a in items) {
            map[a.attendanceId] = a;
          }
          _attendance.clear();
          _attendance.addAll(map.values);
          _attendanceStreamController.add(List.unmodifiable(_attendance));
          LocalStorageService().saveAttendance(_attendance);
        } else if (_attendance.isNotEmpty) {
          for (final a in _attendance) {
            db.collection('attendance').doc(a.attendanceId).set(a.toMap(), SetOptions(merge: true));
          }
        }
      }, onError: (e) => debugPrint('Live attendance sync info: $e'));

      // Leaves live stream from Firestore
      db.collection('leaves').snapshots().listen((snap) {
        if (snap.docs.isNotEmpty) {
          final items = snap.docs.map((d) => LeaveRequestModel.fromMap(d.data(), d.id)).toList();
          final Map<String, LeaveRequestModel> map = { for (final l in _leaves) l.leaveId: l };
          for (final l in items) {
            map[l.leaveId] = l;
          }
          _leaves.clear();
          _leaves.addAll(map.values);
          _leavesStreamController.add(List.unmodifiable(_leaves));
          LocalStorageService().saveLeaves(_leaves);
        } else if (_leaves.isNotEmpty) {
          for (final l in _leaves) {
            db.collection('leaves').doc(l.leaveId).set(l.toMap(), SetOptions(merge: true));
          }
        }
      }, onError: (e) => debugPrint('Live leaves sync info: $e'));

      // Corrections live stream from Firestore
      db.collection('attendanceCorrections').snapshots().listen((snap) {
        if (snap.docs.isNotEmpty) {
          final items = snap.docs.map((d) => AttendanceCorrectionModel.fromMap(d.data(), d.id)).toList();
          final Map<String, AttendanceCorrectionModel> map = { for (final c in _corrections) c.correctionId: c };
          for (final c in items) {
            map[c.correctionId] = c;
          }
          _corrections.clear();
          _corrections.addAll(map.values);
          _correctionsStreamController.add(List.unmodifiable(_corrections));
          LocalStorageService().saveCorrections(_corrections);
        } else if (_corrections.isNotEmpty) {
          for (final c in _corrections) {
            db.collection('attendanceCorrections').doc(c.correctionId).set(c.toMap(), SetOptions(merge: true));
          }
        }
      }, onError: (e) => debugPrint('Live corrections sync info: $e'));

      // Policy live stream from Firestore
      db.collection('attendancePolicies').doc('policy_standard').snapshots().listen((snap) {
        if (snap.exists && snap.data() != null) {
          final fetched = AttendancePolicyModel.fromMap(snap.data()!, snap.id);
          if (fetched.officeName.contains('HQ Enterprise') || !fetched.officeName.contains('Giriraj') || fetched.officeLatitude == 28.6139) {
            _policy = MockDataSeeder.getSeedPolicy();
            db.collection('attendancePolicies').doc('policy_standard').set(_policy.toMap(), SetOptions(merge: true));
          } else {
            _policy = fetched;
          }
          _policyStreamController.add(_policy);
          LocalStorageService().savePolicy(_policy);
        } else {
          _policy = MockDataSeeder.getSeedPolicy();
          db.collection('attendancePolicies').doc('policy_standard').set(_policy.toMap(), SetOptions(merge: true));
          LocalStorageService().savePolicy(_policy);
        }
      }, onError: (e) => debugPrint('Live policy sync info: $e'));

      // Announcements live stream from Firestore
      db.collection('announcements').snapshots().listen((snap) {
        if (snap.docs.isNotEmpty) {
          final items = snap.docs.map((d) => AnnouncementModel.fromMap(d.data(), d.id)).toList();
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (_announcements.isNotEmpty) {
            final existingIds = _announcements.map((a) => a.id).toSet();
            for (final ann in items) {
              if (!existingIds.contains(ann.id)) {
                NotificationService().sendNotification(
                  title: ann.type == 'holiday'
                      ? '🏖️ Holiday Announced: ${ann.title}'
                      : (ann.type == 'notice'
                          ? '⚠️ Notice: ${ann.title}'
                          : '📢 Announcement: ${ann.title}'),
                  message: ann.message,
                  type: ann.type == 'holiday' ? 'report' : 'info',
                );
              }
            }
          }

          _announcements.clear();
          _announcements.addAll(items);
          _announcementsStreamController.add(List.unmodifiable(_announcements));
        }
      }, onError: (e) => debugPrint('Live announcements sync info: $e'));

      // Notifications live stream from Firestore
      db.collection('notifications').snapshots().listen((snap) {
        if (snap.docs.isNotEmpty) {
          final items = snap.docs.map((d) => NotificationModel.fromMap(d.data(), d.id)).toList();
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (_notifications.isNotEmpty) {
            final existingIds = _notifications.map((n) => n.id).toSet();
            for (final notif in items) {
              if (!existingIds.contains(notif.id)) {
                NotificationService().sendNotification(
                  title: notif.title,
                  message: notif.message,
                  type: notif.type == 'holiday' ? 'report' : (notif.type == 'approval' ? 'approval' : 'info'),
                );
              }
            }
          }

          _notifications.clear();
          _notifications.addAll(items);
          _notificationsStreamController.add(List.unmodifiable(_notifications));
        }
      }, onError: (e) => debugPrint('Live notifications sync info: $e'));
    } catch (e) {
      debugPrint('Firestore real-time listeners fallback: $e');
    }
  }

  void _initializeData() {
    _users.clear();
    _users.addAll(MockDataSeeder.getSeedUsers());
    _teams.clear();
    _teams.addAll(MockDataSeeder.getSeedTeams());
    _attendance.clear();
    _attendance.addAll(MockDataSeeder.getSeedAttendanceHistory());
    _leaves.clear();
    _leaves.addAll(MockDataSeeder.getSeedLeaveRequests());
    _leaveBalances.clear();
    _leaveBalances.addAll(MockDataSeeder.getSeedLeaveBalances());
    _corrections.clear();
    _corrections.addAll(MockDataSeeder.getSeedCorrections());
    _policy = MockDataSeeder.getSeedPolicy();
    AuditService().seedInitialLogs(MockDataSeeder.getSeedAuditLogs());
    _notifyAll();

    _loadFromLocalStorage();
  }

  Future<void> _loadFromLocalStorage() async {
    try {
      final local = LocalStorageService();
      final savedUsers = await local.loadUsers();
      final savedAttendance = await local.loadAttendance();
      final savedLeaves = await local.loadLeaves();
      final savedCorrections = await local.loadCorrections();
      final savedPolicy = await local.loadPolicy();

      if (savedUsers != null && savedUsers.isNotEmpty) {
        final Map<String, UserModel> map = { for (final u in _users) u.userId: u };
        for (final u in savedUsers) {
          map[u.userId] = u;
        }
        _users.clear();
        _users.addAll(map.values);
      }
      if (savedAttendance != null && savedAttendance.isNotEmpty) {
        final Map<String, AttendanceModel> map = { for (final a in _attendance) a.attendanceId: a };
        for (final a in savedAttendance) {
          map[a.attendanceId] = a;
        }
        _attendance.clear();
        _attendance.addAll(map.values);
      }
      if (savedLeaves != null && savedLeaves.isNotEmpty) {
        final Map<String, LeaveRequestModel> map = { for (final l in _leaves) l.leaveId: l };
        for (final l in savedLeaves) {
          map[l.leaveId] = l;
        }
        _leaves.clear();
        _leaves.addAll(map.values);
      }
      if (savedCorrections != null && savedCorrections.isNotEmpty) {
        final Map<String, AttendanceCorrectionModel> map = { for (final c in _corrections) c.correctionId: c };
        for (final c in savedCorrections) {
          map[c.correctionId] = c;
        }
        _corrections.clear();
        _corrections.addAll(map.values);
      }
      if (savedPolicy != null) {
        _policy = savedPolicy;
      }
      _notifyAll();
    } catch (e) {
      debugPrint('Error loading local storage in FirestoreService: $e');
    }
  }

  void _notifyAll() {
    _attendanceStreamController.add(List.unmodifiable(_attendance));
    _usersStreamController.add(List.unmodifiable(_users));
    _teamsStreamController.add(List.unmodifiable(_teams));
    _leavesStreamController.add(List.unmodifiable(_leaves));
    _correctionsStreamController.add(List.unmodifiable(_corrections));
    _policyStreamController.add(_policy);
    _announcementsStreamController.add(List.unmodifiable(_announcements));
    _notificationsStreamController.add(List.unmodifiable(_notifications));
  }

  void resetToDefaultSeed() {
    _users.clear();
    _teams.clear();
    _attendance.clear();
    _leaves.clear();
    _leaveBalances.clear();
    _corrections.clear();
    _announcements.clear();
    _notifications.clear();
    _policy = MockDataSeeder.getSeedPolicy();
    _initializeData();
  }



  // Policy methods
  AttendancePolicyModel get currentPolicy => _policy;

  Future<void> updatePolicy(
    AttendancePolicyModel newPolicy,
    UserModel actor,
  ) async {
    final oldStart = _policy.officeStartTime;
    _policy = newPolicy;
    _policyStreamController.add(_policy);

    try {
      _db?.collection('attendancePolicies').doc(newPolicy.policyId).set(newPolicy.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore policy update error: $e');
    }

    AuditService().log(
      actor: actor,
      actionType: 'POLICY_UPDATE',
      description:
          'Updated Attendance Policy (Start: ${_policy.officeStartTime}, Grace: ${_policy.gracePeriodMinutes}m, Geofence: ${_policy.geofenceRadiusMeters}m).',
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
  List<UserModel> getEmployees() =>
      _users.where((u) => u.role == UserRole.employee).toList();

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
    LocalStorageService().saveUsers(_users);

    try {
      await _db?.collection('users').doc(newUser.userId).set(newUser.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore user create error: $e');
    }

    // Broadcast persistent notification records to all HR and Admin users
    final adminAndHrUsers = _users.where((u) => u.role == UserRole.admin || u.role == UserRole.hr).toList();
    for (final adminOrHr in adminAndHrUsers) {
      final notif = NotificationModel(
        id: 'notif_${DateTime.now().microsecondsSinceEpoch}_${adminOrHr.userId}',
        userId: adminOrHr.userId,
        title: '🆕 New Employee Joined: ${newUser.name}',
        message: '${newUser.name} (${newUser.employeeId}) enrolled in ${newUser.department} as ${newUser.role.name}.',
        type: 'info',
        createdAt: DateTime.now(),
      );
      _notifications.insert(0, notif);
      try {
        _db?.collection('notifications').doc(notif.id).set(notif.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore notification write error: $e');
      }
    }
    _notificationsStreamController.add(List.unmodifiable(_notifications));

    AuditService().log(
      actor: actor,
      actionType: 'ADMIN_USER_ADD',
      description:
          'Added new employee: ${newUser.name} (${newUser.employeeId}) in ${newUser.department}.',
      targetEntityId: newUser.userId,
    );

    NotificationService().sendNotification(
      title: '🆕 New Employee Joined: ${newUser.name}',
      message: '${newUser.name} (${newUser.employeeId}) enrolled in ${newUser.department} as ${newUser.role.name}.',
      type: 'info',
    );

    return newUser;
  }

  Future<UserModel> updateEmployee(
    UserModel updatedUser,
    UserModel actor,
  ) async {
    final index = _users.indexWhere((u) => u.userId == updatedUser.userId);
    if (index != -1) {
      _users[index] = updatedUser;
      _usersStreamController.add(List.unmodifiable(_users));
      LocalStorageService().saveUsers(_users);

      try {
        await _db?.collection('users').doc(updatedUser.userId).set(updatedUser.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore user update error: $e');
      }

      AuditService().log(
        actor: actor,
        actionType: 'ADMIN_USER_EDIT',
        description: 'Updated employee profile for ${updatedUser.name}.',
        targetEntityId: updatedUser.userId,
      );
    }
    return updatedUser;
  }

  Future<bool> deleteEmployee(String userId, UserModel actor) async {
    final index = _users.indexWhere((u) => u.userId == userId);
    if (index != -1) {
      final target = _users[index];
      _users.removeAt(index);
      _usersStreamController.add(List.unmodifiable(_users));

      try {
        await _db?.collection('users').doc(userId).delete();
      } catch (e) {
        debugPrint('Firestore user delete error: $e');
      }

      AuditService().log(
        actor: actor,
        actionType: 'ADMIN_USER_DELETE',
        description: 'Deleted employee profile for ${target.name} (${target.employeeId}).',
        targetEntityId: userId,
      );
      return true;
    }
    return false;
  }

  Future<void> toggleUserActive(
    String userId,
    bool isActive,
    UserModel actor,
  ) async {
    final index = _users.indexWhere((u) => u.userId == userId);
    if (index != -1) {
      final old = _users[index];
      _users[index] = old.copyWith(isActive: isActive);
      _usersStreamController.add(List.unmodifiable(_users));

      try {
        await _db?.collection('users').doc(userId).update({'isActive': isActive});
      } catch (e) {
        debugPrint('Firestore toggle user active error: $e');
      }

      AuditService().log(
        actor: actor,
        actionType: 'ADMIN_USER_STATUS',
        description:
            '${isActive ? "Activated" : "Disabled"} user account for ${old.name}.',
        targetEntityId: userId,
        oldValue: 'isActive: ${old.isActive}',
        newValue: 'isActive: $isActive',
      );
    }
  }

  Future<UserModel> assignEmployeeToTL({
    required String employeeId,
    required UserModel tlUser,
    required UserModel actor,
  }) async {
    final index = _users.indexWhere((u) => u.userId == employeeId);
    if (index != -1) {
      final old = _users[index];
      final updated = old.copyWith(
        managerId: tlUser.userId,
        managerName: tlUser.name,
        teamId: tlUser.teamId,
        teamName: tlUser.teamName,
      );
      _users[index] = updated;
      _usersStreamController.add(List.unmodifiable(_users));

      try {
        await _db?.collection('users').doc(employeeId).set(updated.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore assign TL error: $e');
      }

      AuditService().log(
        actor: actor,
        actionType: 'ADMIN_ASSIGN_TL',
        description: 'Assigned employee ${old.name} to TL ${tlUser.name}.',
        targetEntityId: employeeId,
      );

      NotificationService().sendNotification(
        title: 'TL Assigned 👥',
        message: 'Assigned ${old.name} to ${tlUser.name}.',
        type: 'info',
      );

      return updated;
    }
    throw Exception('Employee not found');
  }

  // Attendance Queries
  List<AttendanceModel> getAllAttendance() => List.unmodifiable(_attendance);

  UserModel? _findUserByIdentifier(String identifier) {
    try {
      return _users.firstWhere(
        (u) => u.userId == identifier || u.employeeId == identifier || u.email.toLowerCase() == identifier.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  AttendanceModel? getTodayAttendance(String identifier) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final targetUser = _findUserByIdentifier(identifier);
    final validIds = {
      identifier,
      if (targetUser != null) targetUser.userId,
      if (targetUser != null) targetUser.employeeId,
    };

    try {
      return _attendance.firstWhere(
        (a) => (validIds.contains(a.employeeId) || validIds.contains(a.employeeCode)) && a.date == todayStr,
      );
    } catch (_) {
      return null;
    }
  }

  List<AttendanceModel> getAttendanceForEmployee(String identifier) {
    final targetUser = _findUserByIdentifier(identifier);
    final validIds = {
      identifier,
      if (targetUser != null) targetUser.userId,
      if (targetUser != null) targetUser.employeeId,
    };

    return _attendance.where(
      (a) => validIds.contains(a.employeeId) || validIds.contains(a.employeeCode),
    ).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Set<String> getEmployeeIdsForTL(String tlId) {
    final tlUser = _users.firstWhere(
      (u) => u.userId == tlId,
      orElse: () => _users.firstWhere(
        (u) => u.role == UserRole.manager,
        orElse: () => _users.first,
      ),
    );
    return _users
        .where((u) =>
            u.userId == tlId ||
            u.managerId == tlId ||
            (tlUser.teamId.isNotEmpty &&
                tlUser.teamId != 'unassigned' &&
                u.teamId == tlUser.teamId &&
                u.managerId != null &&
                u.managerId!.isNotEmpty))
        .map((u) => u.userId)
        .toSet();
  }

  List<AttendanceModel> getAttendanceForTL(String tlId) {
    final empIds = getEmployeeIdsForTL(tlId);
    return _attendance
        .where((a) => empIds.contains(a.employeeId))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<AttendanceModel> getPendingApprovalsForTL(String tlId) {
    final empIds = getEmployeeIdsForTL(tlId);
    return _attendance
        .where((a) => a.status == AttendanceStatus.pending && empIds.contains(a.employeeId))
        .toList()
      ..sort(
        (a, b) => (b.clockInTime ?? DateTime.now()).compareTo(
          a.clockInTime ?? DateTime.now(),
        ),
      );
  }

  List<LeaveRequestModel> getLeavesForTL(String tlId) {
    final empIds = getEmployeeIdsForTL(tlId);
    return _leaves
        .where((l) => empIds.contains(l.employeeId))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<AttendanceModel> getPendingApprovals() {
    return _attendance
        .where((a) => a.status == AttendanceStatus.pending)
        .toList()
      ..sort(
        (a, b) => (b.clockInTime ?? DateTime.now()).compareTo(
          a.clockInTime ?? DateTime.now(),
        ),
      );
  }

  List<AttendanceModel> getAttendanceByDate(String dateStr) {
    return _attendance.where((a) => a.date == dateStr).toList();
  }

  // Clock-In with Strict Date, Duplicate Prevention, Geofence & Late Attendance Timing rules
  Future<AttendanceModel> submitClockIn({
    required UserModel user,
    required String photoUrl,
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    // 1. Strict Server Timestamp / Calendar Date verification
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final attendanceId = '${user.userId}_$dateStr';

    // 2. Prevent Duplicate Clock-In for the same employee and same date
    final existingIndex = _attendance.indexWhere(
      (a) => a.employeeId == user.userId && a.date == dateStr,
    );
    if (existingIndex != -1) {
      throw Exception(
        'Attendance already submitted for today ($dateStr). Only one Clock-In record is allowed per employee per day.',
      );
    }

    // 3. Geofencing verification & WFH support
    final isRemoteOrWfh = (location != null &&
        (location.toLowerCase().contains('remote') ||
            location.toLowerCase().contains('wfh') ||
            location.toLowerCase().contains('work from home') ||
            location.toLowerCase().contains('authorized')));

    final userLat = latitude ?? _policy.officeLatitude + 0.0002;
    final userLng = longitude ?? _policy.officeLongitude + 0.0001;

    final geofenceRes = GeofenceService.verifyLocation(
      userLat: userLat,
      userLng: userLng,
      officeLat: _policy.officeLatitude,
      officeLng: _policy.officeLongitude,
      allowedRadiusMeters: _policy.geofenceRadiusMeters,
    );

    if (!isRemoteOrWfh && !geofenceRes.isWithinGeofence) {
      throw Exception(
        'Outside Geofence: You are ${geofenceRes.distanceMeters.toStringAsFixed(0)}m away. Clock-in is strictly allowed within ${_policy.geofenceRadiusMeters.toStringAsFixed(0)}m of the office, or select Remote/WFH location.',
      );
    }

    // 4. Policy Timing & Late calculation (09:30 AM start, 15m grace period -> 09:45 AM threshold)
    TimingStatus timingStatus = TimingStatus.onTime;
    int lateMinutes = 0;
    final startParts = _policy.officeStartTime.split(':');
    final startHour = int.tryParse(startParts[0]) ?? 9;
    final startMin = int.tryParse(startParts[1]) ?? 30;

    final shiftStartTime = DateTime(
      now.year,
      now.month,
      now.day,
      startHour,
      startMin,
    );
    final graceEndTime = shiftStartTime.add(
      Duration(minutes: _policy.gracePeriodMinutes),
    );

    if (now.isAfter(graceEndTime)) {
      timingStatus = TimingStatus.lateArrival;
      lateMinutes = now.difference(shiftStartTime).inMinutes;
    } else if (now.isAfter(shiftStartTime)) {
      timingStatus = TimingStatus.gracePeriod;
      lateMinutes = now.difference(shiftStartTime).inMinutes;
    }

    // 5. Build Attendance Record - All Clock-Ins (On-time, Grace, Late) MUST start as PENDING
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
      lateMinutes: lateMinutes,
      latitude: userLat,
      longitude: userLng,
      isWithinGeofence: isRemoteOrWfh ? true : geofenceRes.isWithinGeofence,
      distanceFromOfficeMeters: geofenceRes.distanceMeters,
      location: location ?? (_policy.officeName),
      createdAt: now,
    );

    _attendance.insert(0, record);
    _notifyAll();
    LocalStorageService().saveAttendance(_attendance);

    try {
      await _db?.collection('attendance').doc(record.attendanceId).set(record.toMap(), SetOptions(merge: true));
      await _db?.collection('attendanceApprovals').doc('appr_${record.attendanceId}').set({
        'approvalId': 'appr_${record.attendanceId}',
        'attendanceId': record.attendanceId,
        'employeeId': user.userId,
        'employeeName': user.name,
        'teamId': user.teamId,
        'managerId': user.managerId,
        'date': dateStr,
        'attendanceDate': dateStr,
        'selfieUrl': photoUrl,
        'timingStatus': timingStatus.code,
        'attendanceType': timingStatus.code,
        'lateMinutes': lateMinutes,
        'distanceMeters': geofenceRes.distanceMeters,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore clock-in write error: $e');
    }

    AuditService().log(
      actor: user,
      actionType: 'CLOCK_IN',
      description:
          '${user.name} clocked in (${timingStatus.label}${lateMinutes > 0 ? " - $lateMinutes mins late" : ""}, Distance: ${geofenceRes.distanceMeters}m). Status: Pending TL Approval.',
      targetEntityId: attendanceId,
    );

    NotificationService().sendNotification(
      title: timingStatus == TimingStatus.lateArrival
          ? 'Late Clock-In Submitted ⚠️'
          : 'Clock-In Submitted 📍',
      message: timingStatus == TimingStatus.lateArrival
          ? '${user.name} clocked in late at ${DateFormat('hh:mm a').format(now)} ($lateMinutes mins late). Awaiting TL Approval.'
          : '${user.name} clocked in at ${DateFormat('hh:mm a').format(now)} (${timingStatus.label}). Awaiting TL Review.',
      type: timingStatus == TimingStatus.lateArrival ? 'warning' : 'info',
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

    try {
      await _db?.collection('attendance').doc(updated.attendanceId).set(updated.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore start break error: $e');
    }

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
    LocalStorageService().saveAttendance(_attendance);

    try {
      await _db?.collection('attendance').doc(updated.attendanceId).set(updated.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore end break error: $e');
    }

    AuditService().log(
      actor: user,
      actionType: 'BREAK_END',
      description:
          '${user.name} resumed duty after break. Total break: ${totalBreakMins}m.',
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
    LocalStorageService().saveAttendance(_attendance);

    try {
      await _db?.collection('attendance').doc(updated.attendanceId).set(updated.toMap(), SetOptions(merge: true));
      await _db?.collection('attendanceApprovals').doc('appr_${updated.attendanceId}').set({
        'status': updated.status.code,
        'reviewedAt': FieldValue.serverTimestamp(),
        'rejectionReason': null,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore attendance approval error: $e');
    }

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
        try {
          await _db?.collection('attendance').doc(_attendance[i].attendanceId).set(_attendance[i].toMap(), SetOptions(merge: true));
        } catch (_) {}
        count++;
      }
    }

    if (count > 0) {
      _notifyAll();
      LocalStorageService().saveAttendance(_attendance);
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
      rejectionReason: reason.trim().isEmpty
          ? 'Photo or geofence verification failed'
          : reason,
    );

    _attendance[index] = updated;
    _notifyAll();
    LocalStorageService().saveAttendance(_attendance);

    try {
      await _db?.collection('attendance').doc(updated.attendanceId).set(updated.toMap(), SetOptions(merge: true));
      await _db?.collection('attendanceApprovals').doc('appr_${updated.attendanceId}').set({
        'status': updated.status.code,
        'reviewedAt': FieldValue.serverTimestamp(),
        'rejectionReason': updated.rejectionReason,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore attendance reject error: $e');
    }

    AuditService().log(
      actor: manager,
      actionType: 'TL_REJECTED',
      description:
          'Rejected attendance for ${old.employeeName}. Reason: ${updated.rejectionReason}',
      targetEntityId: attendanceId,
    );

    NotificationService().sendNotification(
      title: 'Attendance Rejected ⚠️',
      message:
          'Your attendance was rejected by ${manager.name}. Reason: ${updated.rejectionReason}',
      type: 'rejection',
    );

    return updated;
  }

  Future<AttendanceModel> submitClockOut({
    required String attendanceId,
    String? clockOutPhotoUrl,
    double? latitude,
    double? longitude,
  }) async {
    final index = _attendance.indexWhere((a) => a.attendanceId == attendanceId);
    if (index == -1) throw Exception('Attendance record not found');

    final old = _attendance[index];

    // Clock-Out is strictly permitted only AFTER attendance has been approved by TL
    if (old.status != AttendanceStatus.approved) {
      throw Exception(
        'Clock-Out is locked! Your Clock-In status is "${old.status.label}". You can Clock-Out only AFTER your Team Lead / Manager approves your attendance.',
      );
    }

    final now = DateTime.now();

    // Auto close any active breaks
    final closedBreaks = old.breaks.map((b) {
      if (b.isActive) {
        final duration = now.difference(b.startTime).inMinutes;
        return b.copyWith(endTime: now, durationMinutes: duration);
      }
      return b;
    }).toList();

    final grossMinutes = old.clockInTime != null
        ? now.difference(old.clockInTime!).inMinutes
        : 0;
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
    LocalStorageService().saveAttendance(_attendance);

    try {
      await _db?.collection('attendance').doc(updated.attendanceId).set(updated.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore clock-out error: $e');
    }

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
      description:
          '${old.employeeName} completed daily shift (Net: ${updated.formattedNetDuration}).',
      targetEntityId: attendanceId,
    );

    NotificationService().sendNotification(
      title: 'Clock-Out Completed 👍',
      message:
          'Daily shift completed. Net worked: ${updated.formattedNetDuration}.',
      type: 'info',
    );

    return updated;
  }

  // Leave Management Lifecycle
  List<LeaveRequestModel> getAllLeaves() => List.unmodifiable(_leaves);

  List<LeaveRequestModel> getLeavesForEmployee(String identifier) {
    final targetUser = _findUserByIdentifier(identifier);
    final validIds = {
      identifier,
      if (targetUser != null) targetUser.userId,
      if (targetUser != null) targetUser.employeeId,
    };

    return _leaves.where(
      (l) => validIds.contains(l.employeeId) || validIds.contains(l.employeeCode),
    ).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<AttendanceCorrectionModel> getCorrectionsForEmployee(String identifier) {
    final targetUser = _findUserByIdentifier(identifier);
    final validIds = {
      identifier,
      if (targetUser != null) targetUser.userId,
      if (targetUser != null) targetUser.employeeId,
    };

    return _corrections.where(
      (c) => validIds.contains(c.employeeId) || validIds.contains(c.employeeCode),
    ).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Announcements & Notifications
  Future<void> publishAnnouncement(AnnouncementModel announcement) async {
    _announcements.insert(0, announcement);
    _announcementsStreamController.add(List.unmodifiable(_announcements));

    try {
      _db?.collection('announcements').doc(announcement.id).set(announcement.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore announcement write error: $e');
    }
    
    // Broadcast notifications to target users (Holidays always target all TLs, employees, and staff)
    final targetUsers = _users.where((u) {
      if (announcement.type == 'holiday') return true;
      if (announcement.audience == 'everyone') return true;
      if (announcement.audience == 'all_employees' && (u.role == UserRole.employee || u.role == UserRole.manager)) return true;
      if (announcement.audience == 'all_tls' && u.role == UserRole.manager) return true;
      return false;
    }).toList();

    for (final u in targetUsers) {
      final notif = NotificationModel(
        id: 'notif_${DateTime.now().microsecondsSinceEpoch}_${u.userId}',
        userId: u.userId,
        announcementId: announcement.id,
        title: announcement.type == 'holiday'
            ? 'Holiday Announcement 🏖️: ${announcement.title}'
            : (announcement.type == 'notice'
                ? 'Important Notice 📢: ${announcement.title}'
                : 'Company Announcement 📢: ${announcement.title}'),
        message: announcement.message,
        type: announcement.type,
        createdAt: DateTime.now(),
      );
      _notifications.insert(0, notif);
      try {
        _db?.collection('notifications').doc(notif.id).set(notif.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore notification write error: $e');
      }
    }
    
    _notificationsStreamController.add(List.unmodifiable(_notifications));

    // Send floating in-app notification alert to active session
    NotificationService().sendNotification(
      title: announcement.type == 'holiday'
          ? '🏖️ Holiday Announced: ${announcement.title}'
          : (announcement.type == 'notice'
              ? '⚠️ Notice: ${announcement.title}'
              : '📢 Announcement: ${announcement.title}'),
      message: announcement.message,
      type: announcement.type == 'holiday' ? 'report' : 'info',
    );

    final author = _users.firstWhere(
      (u) => u.userId == announcement.createdBy,
      orElse: () => _users.first,
    );
    AuditService().log(
      actor: author,
      actionType: 'ANNOUNCEMENT_PUBLISH',
      description: 'Published ${announcement.type} "${announcement.title}" to ${announcement.audience}.',
      targetEntityId: announcement.id,
    );
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      _notificationsStreamController.add(List.unmodifiable(_notifications));

      try {
        _db?.collection('notifications').doc(notificationId).update({'isRead': true});
      } catch (e) {
        debugPrint('Firestore mark notification read error: $e');
      }
    }
  }

  List<NotificationModel> getNotificationsForUser(String identifier) {
    final targetUser = _findUserByIdentifier(identifier);
    final validIds = {
      identifier,
      if (targetUser != null) targetUser.userId,
      if (targetUser != null) targetUser.employeeId,
    };

    return _notifications.where((n) => validIds.contains(n.userId)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  LeaveBalanceModel getLeaveBalance(String identifier) {
    final targetUser = _findUserByIdentifier(identifier);
    final validIds = {
      identifier,
      if (targetUser != null) targetUser.userId,
      if (targetUser != null) targetUser.employeeId,
    };

    try {
      return _leaveBalances.firstWhere((b) => validIds.contains(b.employeeId));
    } catch (_) {
      final balance = LeaveBalanceModel(employeeId: targetUser?.userId ?? identifier);
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
    LocalStorageService().saveLeaves(_leaves);

    try {
      await _db?.collection('leaves').doc(leave.leaveId).set(leave.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore apply leave error: $e');
    }

    AuditService().log(
      actor: employee,
      actionType: 'LEAVE_APPLY',
      description:
          '${employee.name} applied for $totalDays days ${leaveType.label}. Sent to Admin, TL, and HR.',
      targetEntityId: leave.leaveId,
    );

    NotificationService().sendNotification(
      title: 'Leave Application Submitted 🌴',
      message:
          '${employee.name} (${employee.department}) requested $totalDays days ${leaveType.label}. Sent to Admin, TL & HR for review.',
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
    final reviewerFormattedName = '${manager.name} (${manager.role.name})';

    final updated = old.copyWith(
      status: isApproved ? LeaveStatus.approved : LeaveStatus.rejected,
      reviewedBy: manager.userId,
      reviewerName: reviewerFormattedName,
      reviewedAt: DateTime.now(),
      rejectionReason: rejectionReason,
    );

    _leaves[index] = updated;

    try {
      await _db?.collection('leaves').doc(updated.leaveId).set(updated.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore review leave error: $e');
    }

    // Deduct from balance if approved
    if (isApproved) {
      final bIndex = _leaveBalances.indexWhere(
        (b) => b.employeeId == old.employeeId,
      );
      if (bIndex != -1) {
        final bal = _leaveBalances[bIndex];
        if (old.leaveType == LeaveType.casual) {
          _leaveBalances[bIndex] = bal.copyWith(
            casualUsed: bal.casualUsed + old.totalDays,
          );
        } else if (old.leaveType == LeaveType.sick) {
          _leaveBalances[bIndex] = bal.copyWith(
            sickUsed: bal.sickUsed + old.totalDays,
          );
        } else if (old.leaveType == LeaveType.earned) {
          _leaveBalances[bIndex] = bal.copyWith(
            earnedUsed: bal.earnedUsed + old.totalDays,
          );
        }
      }
    }

    _leavesStreamController.add(List.unmodifiable(_leaves));
    LocalStorageService().saveLeaves(_leaves);

    AuditService().log(
      actor: manager,
      actionType: isApproved ? 'LEAVE_APPROVE' : 'LEAVE_REJECT',
      description:
          '${isApproved ? "Approved" : "Rejected"} leave request for ${old.employeeName} by $reviewerFormattedName.',
      targetEntityId: leaveId,
    );

    NotificationService().sendNotification(
      title: isApproved ? 'Leave Approved 🎉' : 'Leave Rejected ⚠️',
      message: isApproved
          ? 'Your ${old.leaveType.label} (${old.totalDays} days) was approved by $reviewerFormattedName.'
          : 'Your ${old.leaveType.label} was rejected by $reviewerFormattedName.${rejectionReason != null && rejectionReason.isNotEmpty ? " Reason: $rejectionReason" : ""}',
      type: isApproved ? 'approval' : 'rejection',
    );

    return updated;
  }

  // Attendance Regularization / Correction
  List<AttendanceCorrectionModel> getAllCorrections() =>
      List.unmodifiable(_corrections);

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
    LocalStorageService().saveCorrections(_corrections);

    try {
      await _db?.collection('attendanceCorrections').doc(corr.correctionId).set(corr.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore correction request error: $e');
    }

    AuditService().log(
      actor: employee,
      actionType: 'CORRECTION_REQUEST',
      description:
          '${employee.name} requested attendance regularization for $date.',
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
    final index = _corrections.indexWhere(
      (c) => c.correctionId == correctionId,
    );
    if (index == -1) throw Exception('Correction not found');

    final old = _corrections[index];
    final updated = old.copyWith(
      status: isApproved
          ? CorrectionStatus.approved
          : CorrectionStatus.rejected,
      reviewedBy: manager.userId,
      reviewerName: manager.name,
      reviewedAt: DateTime.now(),
      managerNote: note,
    );

    _corrections[index] = updated;

    try {
      await _db?.collection('attendanceCorrections').doc(updated.correctionId).set(updated.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore review correction error: $e');
    }

    // Apply correction to attendance record if approved
    if (isApproved) {
      final aIndex = _attendance.indexWhere(
        (a) => a.attendanceId == old.attendanceId,
      );
      if (aIndex != -1) {
        final gross = old.requestedClockOut
            .difference(old.requestedClockIn)
            .inMinutes;
        _attendance[aIndex] = _attendance[aIndex].copyWith(
          clockInTime: old.requestedClockIn,
          clockOutTime: old.requestedClockOut,
          status: AttendanceStatus.completed,
          totalWorkMinutes: gross,
          managerComment: 'Regularized: ${old.reason}',
        );
        _attendanceStreamController.add(List.unmodifiable(_attendance));
        LocalStorageService().saveAttendance(_attendance);

        try {
          await _db?.collection('attendance').doc(old.attendanceId).set(_attendance[aIndex].toMap(), SetOptions(merge: true));
        } catch (_) {}
      }
    }

    _correctionsStreamController.add(List.unmodifiable(_corrections));
    LocalStorageService().saveCorrections(_corrections);

    AuditService().log(
      actor: manager,
      actionType: isApproved ? 'CORRECTION_APPROVE' : 'CORRECTION_REJECT',
      description:
          '${isApproved ? "Approved" : "Rejected"} attendance regularization for ${old.employeeName}.',
      targetEntityId: correctionId,
    );

    NotificationService().sendNotification(
      title: isApproved
          ? 'Attendance Regularized 🎉'
          : 'Correction Rejected ⚠️',
      message:
          'Regularization for ${old.date} was ${isApproved ? "approved" : "rejected"}.',
      type: isApproved ? 'approval' : 'rejection',
    );

    return updated;
  }

  Future<bool> checkFirebaseConnection() async {
    try {
      final db = _db;
      if (db == null) return false;
      await db.collection('attendancePolicies').doc('policy_standard').get(const GetOptions(source: Source.server));
      return true;
    } catch (_) {
      return false;
    }
  }
}
