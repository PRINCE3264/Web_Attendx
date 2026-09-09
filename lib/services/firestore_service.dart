import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../models/attendance_model.dart';
import '../models/team_model.dart';
import '../models/department_model.dart';
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
import '../models/project_report_model.dart';
import '../models/project_model.dart';
import '../models/community_model.dart';
import 'local_storage_service.dart';
import 'auth_service.dart';
import 'leave_email_template_service.dart';

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
    // Start periodic background auto-sync timer for continuous long-term cloud & local persistence
    Timer.periodic(const Duration(minutes: 5), (_) {
      syncLocalDataToFirestore();
    });
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
  final List<DepartmentModel> _departments = [];
  final List<LeaveRequestModel> _leaves = [];
  final List<LeaveBalanceModel> _leaveBalances = [];
  final List<AttendanceCorrectionModel> _corrections = [];
  AttendancePolicyModel _policy = MockDataSeeder.getSeedPolicy();
  final List<AnnouncementModel> _announcements = [];
  final List<NotificationModel> _notifications = [];
  final List<ProjectReportModel> _projectReports = MockDataSeeder.getSeedProjectReports();
  final List<ProjectModel> _projects = MockDataSeeder.getSeedProjects();
  final List<CommunityGroupModel> _communityGroups = [
    CommunityGroupModel(
      groupId: 'comm_eb_general',
      name: 'Community EB - General Hub',
      description: 'Official workspace community for all Envision Beyond teams.',
      createdBy: 'usr_admin',
      createdAt: DateTime.now(),
      memberUserIds: [],
      isOfficial: true,
    ),
    CommunityGroupModel(
      groupId: 'comm_eb_eng',
      name: 'Engineering & Tech EB',
      description: 'Work updates, technical discussion, and daily collaboration for engineering team.',
      createdBy: 'usr_admin',
      createdAt: DateTime.now(),
      memberUserIds: [],
      isOfficial: true,
    ),
    CommunityGroupModel(
      groupId: 'comm_eb_hr',
      name: 'HR & Management EB',
      description: 'Administrative sync, HR announcements, and leadership discussions.',
      createdBy: 'usr_admin',
      createdAt: DateTime.now(),
      memberUserIds: [],
      isOfficial: true,
    ),
  ];
  final List<CommunityMessageModel> _communityMessages = [];

  final _attendanceStreamController =
      StreamController<List<AttendanceModel>>.broadcast();
  final _usersStreamController = StreamController<List<UserModel>>.broadcast();
  final _teamsStreamController = StreamController<List<TeamModel>>.broadcast();
  final _departmentsStreamController = StreamController<List<DepartmentModel>>.broadcast();
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
  final _projectReportsStreamController =
      StreamController<List<ProjectReportModel>>.broadcast();
  final _projectsStreamController =
      StreamController<List<ProjectModel>>.broadcast();
  final _communityGroupsStreamController =
      StreamController<List<CommunityGroupModel>>.broadcast();
  final _communityMessagesStreamController =
      StreamController<List<CommunityMessageModel>>.broadcast();

  Stream<List<AttendanceModel>> get attendanceStream =>
      _attendanceStreamController.stream;
  Stream<List<UserModel>> get usersStream => _usersStreamController.stream;
  Stream<List<TeamModel>> get teamsStream => _teamsStreamController.stream;
  Stream<List<DepartmentModel>> get departmentsStream => _departmentsStreamController.stream;
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
  Stream<List<ProjectReportModel>> get projectReportsStream =>
      _projectReportsStreamController.stream;
  Stream<List<ProjectModel>> get projectsStream =>
      _projectsStreamController.stream;
  Stream<List<CommunityGroupModel>> get communityGroupsStream =>
      _communityGroupsStreamController.stream;

  Stream<List<CommunityMessageModel>> get allCommunityMessagesStream =>
      _communityMessagesStreamController.stream;

  Stream<List<CommunityMessageModel>> communityMessagesStream(String groupId) =>
      _communityMessagesStreamController.stream.map(
        (list) => list.where((m) => m.groupId == groupId).toList()
          ..sort((a, b) => a.sentAt.compareTo(b.sentAt)),
      );

  List<UserModel> getAllUsers() => List.unmodifiable(_users);
  List<TeamModel> getAllTeams() => List.unmodifiable(_teams);
  List<DepartmentModel> getAllDepartments() => List.unmodifiable(_departments);
  List<CommunityGroupModel> getAllCommunityGroups() => List.unmodifiable(_communityGroups);
  List<CommunityMessageModel> getAllCommunityMessages() => List.unmodifiable(_communityMessages);
  List<CommunityMessageModel> getCommunityMessages(String groupId) {
    return _communityMessages.where((m) => m.groupId == groupId).toList()
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
  }
  List<AttendanceModel> getAllAttendance() => List.unmodifiable(_attendance);
  List<ProjectReportModel> getAllProjectReports() =>
      List.unmodifiable(_projectReports);

  List<ProjectModel> getAllProjects() =>
      List.unmodifiable(_projects);

  Future<void> saveDepartment(DepartmentModel dept) async {
    final index = _departments.indexWhere((d) => d.departmentId == dept.departmentId);
    if (index >= 0) {
      _departments[index] = dept;
    } else {
      _departments.add(dept);
    }
    _departmentsStreamController.add(List.unmodifiable(_departments));
    try {
      await _db?.collection('departments').doc(dept.departmentId).set(dept.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving department: $e');
    }
  }

  Future<void> saveTeam(TeamModel team) async {
    final index = _teams.indexWhere((t) => t.teamId == team.teamId);
    if (index >= 0) {
      _teams[index] = team;
    } else {
      _teams.add(team);
    }
    _teamsStreamController.add(List.unmodifiable(_teams));
    try {
      await _db?.collection('teams').doc(team.teamId).set(team.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving team: $e');
    }
  }

  bool _hasBoundListeners = false;

  Future<void> syncLocalDataToFirestore() async {
    final db = _db;
    if (db == null) return;

    // Sync Users & Employees
    for (final user in List<UserModel>.from(_users)) {
      try {
        await db
            .collection('users')
            .doc(user.userId)
            .set(user.toMap(), SetOptions(merge: true));
        await db.collection('employees').doc(user.employeeId).set({
          'employeeId': user.employeeId,
          'userId': user.userId,
          'fullName': user.name,
          'workEmail': user.email,
          'departmentId': user.department,
          'departmentName': user.department,
          'teamId': user.teamId,
          'teamName': user.teamName,
          'managerId': user.managerId ?? '',
          'managerName': user.managerName ?? '',
          'avatarUrl': user.avatarUrl ?? '',
          'leaveBalance': {'casual': 12, 'sick': 8, 'earned': 15},
          'status': user.isActive ? 'active' : 'disabled',
          'createdAt': user.createdAt,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore sync user/employee notice (${user.userId}): $e');
      }
    }
    // Sync Attendance
    for (final att in _attendance) {
      try {
        await db
            .collection('attendance')
            .doc(att.attendanceId)
            .set(att.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint(
          'Firestore sync attendance notice (${att.attendanceId}): $e',
        );
      }
    }
    // Sync Leaves
    for (final leave in _leaves) {
      try {
        await db
            .collection('leaves')
            .doc(leave.leaveId)
            .set(leave.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore sync leave notice (${leave.leaveId}): $e');
      }
    }
    // Sync Corrections
    for (final corr in _corrections) {
      try {
        await db
            .collection('attendanceCorrections')
            .doc(corr.correctionId)
            .set(corr.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint(
          'Firestore sync correction notice (${corr.correctionId}): $e',
        );
      }
    }
    // Sync Notifications
    for (final notif in _notifications) {
      try {
        await db
            .collection('notifications')
            .doc(notif.id)
            .set(notif.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore sync notification notice (${notif.id}): $e');
      }
    }
    // Sync Project Reports
    for (final report in _projectReports) {
      try {
        await db
            .collection('projectReports')
            .doc(report.reportId)
            .set(report.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore sync project report notice (${report.reportId}): $e');
      }
    }
    // Sync Projects
    for (final project in _projects) {
      try {
        await db
            .collection('projects')
            .doc(project.projectId)
            .set(project.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore sync project notice (${project.projectId}): $e');
      }
    }
    // Sync Policy
    try {
      await db
          .collection('attendancePolicies')
          .doc('policy_standard')
          .set(_policy.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore sync policy notice: $e');
    }

    debugPrint('⚡ Cloud Firestore Sync Attempt Complete!');
  }

  Future<void> ensureFirestoreConnected() async {
    _bindFirestoreListeners();
    await _seedFirestoreIfEmpty();
  }
  
  Future<void> _seedFirestoreIfEmpty() async {
    final db = _db;
    if (db == null) return;
    try {
      final snapshot = await db.collection('users').limit(1).get();
      if (snapshot.docs.isEmpty) {
        debugPrint('Firestore is empty. Seeding with local mock data...');
        await syncLocalDataToFirestore();
      } else {
        debugPrint('Firestore already contains data. Skipping initial sync to preserve dynamic changes.');
      }
    } catch (e) {
      debugPrint('Error checking Firestore emptiness: $e');
    }
  }

  // Session Tracking (1 Hour Continuous Usage feature)
  Future<void> logSessionStart(String userId) async {
    try {
      final db = _db;
      if (db == null) return;
      await db.collection('appSessions').doc(userId).set({
        'userId': userId,
        'openedAt': DateTime.now().toIso8601String(),
        'status': 'active',
        'lastActive': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore session start error: $e');
    }
  }

  Future<void> logSessionEnd(String userId) async {
    try {
      final db = _db;
      if (db == null) return;
      await db.collection('appSessions').doc(userId).set({
        'status': 'closed',
        'closedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore session end error: $e');
    }
  }

  void _bindFirestoreListeners() {
    final db = _db;
    if (db == null) return;
    if (_hasBoundListeners) return;
    _hasBoundListeners = true;

    final DateTime streamStartTime = DateTime.now().subtract(const Duration(seconds: 10));

    // Seed data asynchronously if empty
    _seedFirestoreIfEmpty();

    try {
      bool isFirstUsersSync = true;
      db.collection('users').snapshots().listen((snap) {
        if (snap.docs.isNotEmpty) {
          final items = snap.docs
              .map((d) => UserModel.fromMap(d.data(), d.id))
              .toList();

          if (!isFirstUsersSync && _users.isNotEmpty) {
            final existingIds = _users.map((u) => u.userId).toSet();
            final currentUserRole = AuthService().currentUser?.role;
            final isHrOrAdmin = currentUserRole == UserRole.hr ||
                currentUserRole == UserRole.admin;
            for (final u in items) {
              if (u.createdAt != null && u.createdAt!.isAfter(streamStartTime) && !existingIds.contains(u.userId) && isHrOrAdmin) {
                NotificationService().sendNotification(
                  title: '🆕 New Employee Joined: ${u.name}',
                  message:
                      '${u.name} (${u.employeeId}) joined ${u.department}. Role: ${u.role.name}.',
                  type: 'info',
                );
              }
            }
          }
          isFirstUsersSync = false;

          _users.clear();
          _users.addAll(items);
          _usersStreamController.add(List.unmodifiable(_users));
          LocalStorageService().saveUsers(_users);
        } else {
          isFirstUsersSync = false;
          _usersStreamController.add(List.unmodifiable(_users));
          LocalStorageService().saveUsers(_users);
        }
      }, onError: (e) => debugPrint('Live users sync info: $e'));

      // Departments live stream from Firestore
      db.collection('departments').snapshots().listen((snap) {
        if (snap.docs.isNotEmpty) {
          final items = snap.docs
              .map((d) => DepartmentModel.fromMap(d.data(), d.id))
              .toList();
          _departments.clear();
          _departments.addAll(items);
        }
        _departmentsStreamController.add(List.unmodifiable(_departments));
      }, onError: (e) => debugPrint('Live departments sync info: $e'));

      // Teams live stream from Firestore
      db.collection('teams').snapshots().listen((snap) {
        if (snap.docs.isNotEmpty) {
          final items = snap.docs
              .map((d) => TeamModel.fromMap(d.data(), d.id))
              .toList();
          _teams.clear();
          _teams.addAll(items);
        }
        _teamsStreamController.add(List.unmodifiable(_teams));
      }, onError: (e) => debugPrint('Live teams sync info: $e'));

      // Attendance live stream from Firestore
      db.collection('attendance').snapshots().listen((snap) {
        if (snap.docs.isNotEmpty) {
          final items = snap.docs
              .map((d) => AttendanceModel.fromMap(d.data(), d.id))
              .toList();
          _attendance.clear();
          _attendance.addAll(items);
          _attendanceStreamController.add(List.unmodifiable(_attendance));
          LocalStorageService().saveAttendance(_attendance);
        } else {
          _attendanceStreamController.add(List.unmodifiable(_attendance));
          LocalStorageService().saveAttendance(_attendance);
        }
      }, onError: (e) => debugPrint('Live attendance sync info: $e'));

      // Leaves live stream from Firestore
      db.collection('leaves').snapshots().listen((snap) {
        if (snap.docs.isNotEmpty) {
          final items = snap.docs
              .map((d) => LeaveRequestModel.fromMap(d.data(), d.id))
              .toList();
          _leaves.clear();
          _leaves.addAll(items);
          _leavesStreamController.add(List.unmodifiable(_leaves));
          LocalStorageService().saveLeaves(_leaves);
        } else {
          _leavesStreamController.add(List.unmodifiable(_leaves));
          LocalStorageService().saveLeaves(_leaves);
        }
      }, onError: (e) => debugPrint('Live leaves sync info: $e'));

      // Corrections live stream from Firestore
      db.collection('attendanceCorrections').snapshots().listen((snap) {
        if (snap.docs.isNotEmpty) {
          final items = snap.docs
              .map((d) => AttendanceCorrectionModel.fromMap(d.data(), d.id))
              .toList();
          _corrections.clear();
          _corrections.addAll(items);
          _correctionsStreamController.add(List.unmodifiable(_corrections));
          LocalStorageService().saveCorrections(_corrections);
        } else {
          _correctionsStreamController.add(List.unmodifiable(_corrections));
          LocalStorageService().saveCorrections(_corrections);
        }
      }, onError: (e) => debugPrint('Live corrections sync info: $e'));

      // Project Reports live stream from Firestore
      db.collection('projectReports').snapshots().listen((snap) {
        if (snap.docs.isNotEmpty) {
          final items = snap.docs
              .map((d) => ProjectReportModel.fromMap(d.data(), d.id))
              .toList();
          _projectReports.clear();
          _projectReports.addAll(items);
          _projectReports.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
          _projectReportsStreamController.add(List.unmodifiable(_projectReports));
          LocalStorageService().saveProjectReports(_projectReports);
        } else {
          _projectReportsStreamController.add(List.unmodifiable(_projectReports));
          LocalStorageService().saveProjectReports(_projectReports);
        }
      }, onError: (e) => debugPrint('Live project reports sync info: $e'));

      // Policy live stream from Firestore
      db
          .collection('attendancePolicies')
          .doc('policy_standard')
          .snapshots()
          .listen((snap) {
            if (snap.exists && snap.data() != null) {
              _policy = AttendancePolicyModel.fromMap(
                snap.data()!,
                snap.id,
              );
              _policyStreamController.add(_policy);
              LocalStorageService().savePolicy(_policy);
            }
          }, onError: (e) => debugPrint('Live policy sync info: $e'));

      // Announcements live stream from Firestore
      bool isFirstAnnouncementsSync = true;
      db.collection('announcements').snapshots().listen((snap) {
        if (snap.docs.isNotEmpty) {
          final items = snap.docs
              .map((d) => AnnouncementModel.fromMap(d.data(), d.id))
              .toList();
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (!isFirstAnnouncementsSync && _announcements.isNotEmpty) {
            final existingIds = _announcements.map((a) => a.id).toSet();
            for (final ann in items) {
              if (ann.createdAt.isAfter(streamStartTime) && !existingIds.contains(ann.id)) {
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
          isFirstAnnouncementsSync = false;

          _announcements.clear();
          _announcements.addAll(items);
          _announcementsStreamController.add(List.unmodifiable(_announcements));
        } else {
          isFirstAnnouncementsSync = false;
          _announcements.clear();
          _announcementsStreamController.add(List.unmodifiable(_announcements));
        }
      }, onError: (e) => debugPrint('Live announcements sync info: $e'));

      // Notifications live stream from Firestore
      bool isFirstNotificationsSync = true;
      db.collection('notifications').snapshots().listen((snap) {
        if (snap.docs.isNotEmpty) {
          final items = snap.docs
              .map((d) => NotificationModel.fromMap(d.data(), d.id))
              .toList();
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (!isFirstNotificationsSync && _notifications.isNotEmpty) {
            final existingIds = _notifications.map((n) => n.id).toSet();
            for (final notif in items) {
              if (notif.createdAt.isAfter(streamStartTime) && !existingIds.contains(notif.id)) {
                NotificationService().sendNotification(
                  title: notif.title,
                  message: notif.message,
                  type: notif.type == 'holiday'
                      ? 'report'
                      : (notif.type == 'approval' ? 'approval' : 'info'),
                );
              }
            }
          }
          isFirstNotificationsSync = false;

          final Map<String, NotificationModel> map = {for (final n in _notifications) n.id: n};
          for (final item in items) {
            map[item.id] = item;
          }
          _notifications.clear();
          _notifications.addAll(map.values);
          _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _notificationsStreamController.add(List.unmodifiable(_notifications));
          LocalStorageService().saveFirestoreNotifications(_notifications.map((n) => n.toMap()).toList());
        } else {
          isFirstNotificationsSync = false;
        }
      }, onError: (e) => debugPrint('Live notifications sync info: $e'));

      // Projects live stream from Firestore
      db.collection('projects').snapshots().listen((snap) {
        if (snap.docs.isNotEmpty) {
          final items = snap.docs
              .map((d) => ProjectModel.fromMap(d.data(), d.id))
              .toList();
          _projects.clear();
          _projects.addAll(items);
          _projectsStreamController.add(List.unmodifiable(_projects));
        } else {
          _projects.clear();
          _projectsStreamController.add(List.unmodifiable(_projects));
        }
      }, onError: (e) => debugPrint('Live projects sync info: $e'));

      // Community Groups live stream from Firestore
      db.collection('communityGroups').snapshots().listen((snap) {
        if (snap.docs.isNotEmpty) {
          final items = snap.docs.map((d) {
            try {
              return CommunityGroupModel.fromMap(d.data(), d.id);
            } catch (e) {
              debugPrint('Error parsing community group ${d.id}: $e');
              return null;
            }
          }).whereType<CommunityGroupModel>().toList();

          final Map<String, CommunityGroupModel> map = {for (final g in _communityGroups) g.groupId: g};
          for (final item in items) {
            map[item.groupId] = item;
          }
          _communityGroups.clear();
          _communityGroups.addAll(map.values);
          _communityGroupsStreamController.add(List.unmodifiable(_communityGroups));
        }
      }, onError: (e) => debugPrint('Live community groups sync info: $e'));

      // Community Messages live stream from Firestore
      db.collection('communityMessages').snapshots().listen((snap) {
        if (snap.docs.isNotEmpty) {
          final items = snap.docs.map((d) {
            try {
              return CommunityMessageModel.fromMap(d.data(), d.id);
            } catch (e) {
              debugPrint('Error parsing community message ${d.id}: $e');
              return null;
            }
          }).whereType<CommunityMessageModel>().toList();

          final Map<String, CommunityMessageModel> map = {for (final m in _communityMessages) m.messageId: m};
          for (final item in items) {
            map[item.messageId] = item;
          }
          _communityMessages.clear();
          _communityMessages.addAll(map.values);
          _communityMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
          _communityMessagesStreamController.add(List.unmodifiable(_communityMessages));
        }
      }, onError: (e) => debugPrint('Live community messages sync info: $e'));

    } catch (e) {
      debugPrint('Firestore real-time listeners fallback: $e');
    }
  }

  void _initializeData() {
    _users.clear();
    _users.addAll(MockDataSeeder.getSeedUsers());
    _teams.clear();
    _teams.addAll(MockDataSeeder.getSeedTeams());
    _departments.clear();
    _departments.addAll(MockDataSeeder.getSeedDepartments());
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
    // Seed projects — ensure all 8 enterprise projects are always available
    if (_projects.isEmpty) {
      _projects.addAll(MockDataSeeder.getSeedProjects());
    }
    // Seed initial notifications so screen is never blank on start
    if (_notifications.isEmpty) {
      _notifications.addAll(MockDataSeeder.getSeedNotifications());
    }
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
      final savedNotifications = await local.loadFirestoreNotifications();

      if (savedUsers != null && savedUsers.isNotEmpty) {
        final Map<String, UserModel> map = {
          for (final u in _users) u.userId: u,
        };
        for (final u in savedUsers) {
          map[u.userId] = u;
        }
        _users.clear();
        _users.addAll(map.values);
      }
      if (savedAttendance != null && savedAttendance.isNotEmpty) {
        final Map<String, AttendanceModel> map = {
          for (final a in _attendance) a.attendanceId: a,
        };
        for (final a in savedAttendance) {
          map[a.attendanceId] = a;
        }
        _attendance.clear();
        _attendance.addAll(map.values);
      }
      if (savedLeaves != null && savedLeaves.isNotEmpty) {
        final Map<String, LeaveRequestModel> map = {
          for (final l in _leaves) l.leaveId: l,
        };
        for (final l in savedLeaves) {
          map[l.leaveId] = l;
        }
        _leaves.clear();
        _leaves.addAll(map.values);
      }
      if (savedCorrections != null && savedCorrections.isNotEmpty) {
        final Map<String, AttendanceCorrectionModel> map = {
          for (final c in _corrections) c.correctionId: c,
        };
        for (final c in savedCorrections) {
          map[c.correctionId] = c;
        }
        _corrections.clear();
        _corrections.addAll(map.values);
      }
      if (savedNotifications != null && savedNotifications.isNotEmpty) {
        final Map<String, NotificationModel> map = {
          for (final n in _notifications) n.id: n,
        };
        for (final m in savedNotifications) {
          final notif = NotificationModel.fromMap(m, (m['id'] ?? '').toString());
          map[notif.id] = notif;
        }
        _notifications.clear();
        _notifications.addAll(map.values);
        _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      final savedProjectReports = await local.loadProjectReports();
      if (savedProjectReports != null && savedProjectReports.isNotEmpty) {
        final Map<String, ProjectReportModel> map = {
          for (final r in _projectReports) r.reportId: r,
        };
        for (final r in savedProjectReports) {
          map[r.reportId] = r;
        }
        _projectReports.clear();
        _projectReports.addAll(map.values);
        _projectReports.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
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
    _departmentsStreamController.add(List.unmodifiable(_departments));
    _leavesStreamController.add(List.unmodifiable(_leaves));
    _correctionsStreamController.add(List.unmodifiable(_corrections));
    _policyStreamController.add(_policy);
    _announcementsStreamController.add(List.unmodifiable(_announcements));
    _notificationsStreamController.add(List.unmodifiable(_notifications));
    _projectReportsStreamController.add(List.unmodifiable(_projectReports));
    _projectsStreamController.add(List.unmodifiable(_projects));
  }

  void resetToDefaultSeed() {
    _users.clear();
    _teams.clear();
    _departments.clear();
    _attendance.clear();
    _leaves.clear();
    _leaveBalances.clear();
    _corrections.clear();
    _announcements.clear();
    _notifications.clear();
    _projects.clear();
    _policy = MockDataSeeder.getSeedPolicy();
    LocalStorageService().clearAllData();
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
      _db
          ?.collection('attendancePolicies')
          .doc(newPolicy.policyId)
          .set(newPolicy.toMap(), SetOptions(merge: true));
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
      await _db
          ?.collection('users')
          .doc(newUser.userId)
          .set(newUser.toMap(), SetOptions(merge: true));
      await _db?.collection('employees').doc(newUser.employeeId).set({
        'employeeId': newUser.employeeId,
        'userId': newUser.userId,
        'fullName': newUser.name,
        'workEmail': newUser.email,
        'departmentId': newUser.department,
        'departmentName': newUser.department,
        'teamId': newUser.teamId,
        'teamName': newUser.teamName,
        'managerId': newUser.managerId ?? '',
        'managerName': newUser.managerName ?? '',
        'avatarUrl': newUser.avatarUrl ?? '',
        'leaveBalance': {'casual': 12, 'sick': 8, 'earned': 15},
        'status': newUser.isActive ? 'active' : 'disabled',
        'createdAt': newUser.createdAt,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore user/employee create error: $e');
      rethrow;
    }

    // Broadcast persistent notification records to all HR and Admin users
    final adminAndHrUsers = _users
        .where((u) => u.role == UserRole.admin || u.role == UserRole.hr)
        .toList();
    for (final adminOrHr in adminAndHrUsers) {
      final notif = NotificationModel(
        id: 'notif_${DateTime.now().microsecondsSinceEpoch}_${adminOrHr.userId}',
        userId: adminOrHr.userId,
        title: '🆕 New Employee Joined: ${newUser.name}',
        message:
            '${newUser.name} (${newUser.employeeId}) enrolled in ${newUser.department} as ${newUser.role.name}.',
        type: 'info',
        createdAt: DateTime.now(),
      );
      _notifications.insert(0, notif);
      try {
        _db
            ?.collection('notifications')
            .doc(notif.id)
            .set(notif.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore notification write error: $e');
      }
    }
    _notificationsStreamController.add(List.unmodifiable(_notifications));
    LocalStorageService().saveFirestoreNotifications(_notifications.map((n) => n.toMap()).toList());

    AuditService().log(
      actor: actor,
      actionType: 'ADMIN_USER_ADD',
      description:
          'Added new employee: ${newUser.name} (${newUser.employeeId}) in ${newUser.department}.',
      targetEntityId: newUser.userId,
    );

    // Only show local notification to the HR/Admin who performed the action
    final actorRole = actor.role;
    if (actorRole == UserRole.hr || actorRole == UserRole.admin) {
      NotificationService().sendNotification(
        title: '🆕 New Employee Joined: ${newUser.name}',
        message:
            '${newUser.name} (${newUser.employeeId}) enrolled in ${newUser.department} as ${newUser.role.name}.',
        type: 'info',
      );
    }

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

      if (AuthService().currentUser?.userId == updatedUser.userId) {
        await AuthService().updateSessionUser(updatedUser);
      }

      try {
        await _db
            ?.collection('users')
            .doc(updatedUser.userId)
            .set(updatedUser.toMap(), SetOptions(merge: true));
        await _db?.collection('employees').doc(updatedUser.employeeId).set({
          'employeeId': updatedUser.employeeId,
          'userId': updatedUser.userId,
          'fullName': updatedUser.name,
          'workEmail': updatedUser.email,
          'role': updatedUser.role.code,
          'departmentId': updatedUser.department,
          'departmentName': updatedUser.department,
          'teamId': updatedUser.teamId,
          'teamName': updatedUser.teamName,
          'managerId': updatedUser.managerId ?? '',
          'managerName': updatedUser.managerName ?? '',
          'avatarUrl': updatedUser.avatarUrl ?? '',
          'status': updatedUser.isActive ? 'active' : 'disabled',
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore user/employee update error: $e');
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
      LocalStorageService().saveUsers(_users);

      try {
        await _db?.collection('users').doc(userId).delete();
        await _db?.collection('employees').doc(target.employeeId).delete();
      } catch (e) {
        debugPrint('Firestore user/employee delete error: $e');
      }

      AuditService().log(
        actor: actor,
        actionType: 'ADMIN_USER_DELETE',
        description:
            'Deleted employee profile for ${target.name} (${target.employeeId}).',
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
        await _db?.collection('users').doc(userId).update({
          'isActive': isActive,
        });
        await _db?.collection('employees').doc(old.employeeId).update({
          'status': isActive ? 'active' : 'disabled',
        });
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
    final index = _users.indexWhere((u) => u.userId == employeeId || u.employeeId == employeeId);
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
        await _db
            ?.collection('users')
            .doc(old.userId)
            .set(updated.toMap(), SetOptions(merge: true));
        if (old.employeeId.isNotEmpty) {
          await _db?.collection('employees').doc(old.employeeId).set({
            'managerId': tlUser.userId,
            'managerName': tlUser.name,
            'teamId': tlUser.teamId,
            'teamName': tlUser.teamName,
          }, SetOptions(merge: true));
        }
      } catch (e) {
        debugPrint('Firestore assign TL error: $e');
      }

      // Notify Team Lead (TL)
      final tlNotif = NotificationModel(
        id: 'notif_${DateTime.now().microsecondsSinceEpoch}_${tlUser.userId}',
        userId: tlUser.userId,
        title: '👤 New Team Member Assigned: ${old.name}',
        message: '${old.name} (${old.employeeId}) has been assigned to your team by ${actor.name}.',
        type: 'info',
        createdAt: DateTime.now(),
      );
      _notifications.insert(0, tlNotif);
      try {
        _db?.collection('notifications').doc(tlNotif.id).set(tlNotif.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore notification write error: $e');
      }

      // Notify Employee
      final empNotif = NotificationModel(
        id: 'notif_${DateTime.now().microsecondsSinceEpoch}_${old.userId}',
        userId: old.userId,
        title: '👥 Team Lead Assigned',
        message: 'You have been assigned to Team Lead ${tlUser.name} by ${actor.name}.',
        type: 'info',
        createdAt: DateTime.now(),
      );
      _notifications.insert(0, empNotif);
      try {
        _db?.collection('notifications').doc(empNotif.id).set(empNotif.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore notification write error: $e');
      }

      _notificationsStreamController.add(List.unmodifiable(_notifications));
      LocalStorageService().saveFirestoreNotifications(_notifications.map((n) => n.toMap()).toList());

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

  Future<UserModel> unassignEmployeeFromTL({
    required String employeeId,
    required UserModel actor,
  }) async {
    final index = _users.indexWhere((u) => u.userId == employeeId);
    if (index != -1) {
      final old = _users[index];
      final updated = old.copyWith(
        managerId: 'unassigned',
        managerName: 'Unassigned',
      );
      _users[index] = updated;
      _usersStreamController.add(List.unmodifiable(_users));

      try {
        await _db
            ?.collection('users')
            .doc(employeeId)
            .set(updated.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore unassign TL error: $e');
      }

      AuditService().log(
        actor: actor,
        actionType: 'ADMIN_UNASSIGN_TL',
        description: 'Unassigned employee ${old.name} from TL.',
        targetEntityId: employeeId,
      );

      return updated;
    }
    throw Exception('Employee not found');
  }

  // Attendance Queries

  UserModel? _findUserByIdentifier(String identifier) {
    try {
      return _users.firstWhere(
        (u) =>
            u.userId == identifier ||
            u.employeeId == identifier ||
            u.email.toLowerCase() == identifier.toLowerCase(),
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
        (a) =>
            (validIds.contains(a.employeeId) ||
                validIds.contains(a.employeeCode)) &&
            a.date == todayStr,
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

    return _attendance
        .where(
          (a) =>
              validIds.contains(a.employeeId) ||
              validIds.contains(a.employeeCode),
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Set<String> getEmployeeIdsForTL(String tlId) {
    final tlUser = _users.firstWhere(
      (u) => u.userId == tlId || u.employeeId == tlId,
      orElse: () => _users.firstWhere(
        (u) => u.role == UserRole.manager,
        orElse: () => _users.first,
      ),
    );

    final Set<String> empIds = {};
    for (final u in _users) {
      // Skip the TL themselves
      if (u.userId == tlUser.userId ||
          (tlUser.employeeId.isNotEmpty && u.employeeId == tlUser.employeeId)) {
        continue;
      }
      // Only include employees explicitly assigned to this TL
      final isAssigned =
          u.managerId == tlId ||
          u.managerId == tlUser.userId ||
          (tlUser.employeeId.isNotEmpty && u.managerId == tlUser.employeeId) ||
          (tlUser.name.isNotEmpty && u.managerId == tlUser.name) ||
          (tlUser.email.isNotEmpty && u.managerId == tlUser.email) ||
          (u.managerName != null &&
              u.managerName!.isNotEmpty &&
              u.managerName!.trim().toLowerCase() == tlUser.name.trim().toLowerCase());

      if (isAssigned) {
        empIds.add(u.userId);
        if (u.employeeId.isNotEmpty) {
          empIds.add(u.employeeId);
        }
      }
    }

    return empIds;
  }

  List<AttendanceModel> getAttendanceForTL(String tlId) {
    final empIds = getEmployeeIdsForTL(tlId);
    return _attendance.where((a) => empIds.contains(a.employeeId)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<AttendanceModel> getPendingApprovalsForTL(String tlId) {
    final empIds = getEmployeeIdsForTL(tlId);
    return _attendance
        .where(
          (a) =>
              a.status == AttendanceStatus.pending &&
              empIds.contains(a.employeeId),
        )
        .toList()
      ..sort(
        (a, b) => (b.clockInTime ?? DateTime.now()).compareTo(
          a.clockInTime ?? DateTime.now(),
        ),
      );
  }

  List<LeaveRequestModel> getLeavesForTL(String tlId) {
    final empIds = getEmployeeIdsForTL(tlId);
    return _leaves.where((l) => empIds.contains(l.employeeId)).toList()
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
    final isRemoteOrWfh =
        (location != null &&
        (location.toLowerCase().contains('remote') ||
            location.toLowerCase().contains('wfh') ||
            location.toLowerCase().contains('work from home') ||
            location.toLowerCase().contains('authorized')));

    if (latitude == null || longitude == null) {
      if (!isRemoteOrWfh) {
        throw Exception(
          'GPS location coordinates are required to verify office geofence for clock-in. Please enable GPS and try again.',
        );
      }
    }

    final userLat = latitude ?? _policy.officeLatitude;
    final userLng = longitude ?? _policy.officeLongitude;

    final geofenceRes = GeofenceService.verifyLocation(
      userLat: userLat,
      userLng: userLng,
      officeLat: _policy.officeLatitude,
      officeLng: _policy.officeLongitude,
      allowedRadiusMeters: _policy.geofenceRadiusMeters,
    );

    if (!isRemoteOrWfh && !geofenceRes.isWithinGeofence) {
      final distStr = geofenceRes.distanceMeters >= 1000
          ? '${(geofenceRes.distanceMeters / 1000).toStringAsFixed(1)} km'
          : '${geofenceRes.distanceMeters.toStringAsFixed(0)} m';
      throw Exception(
        'Outside Geofence: You are $distStr away from office. Clock-in is strictly allowed within ${_policy.geofenceRadiusMeters.toStringAsFixed(0)}m of ${_policy.officeName}, or select Authorized WFH / Remote location.',
      );
    }

    // 4. Shift & Policy Timing calculation (General Shift: 09:30 AM - 06:30 PM, Morning Shift: 07:00 AM - 04:00 PM)
    TimingStatus timingStatus = TimingStatus.onTime;
    int lateMinutes = 0;

    String effectiveStartTime = _policy.officeStartTime;
    if (user.shiftId == 'shift_morning' || user.shiftName.toLowerCase().contains('morning')) {
      effectiveStartTime = '07:00';
    } else if (user.shiftId == 'shift_general' || user.shiftName.toLowerCase().contains('general')) {
      effectiveStartTime = '09:30';
    }

    final startParts = effectiveStartTime.split(':');
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
      await _db
          ?.collection('attendance')
          .doc(record.attendanceId)
          .set(record.toMap(), SetOptions(merge: true));
      await _db
          ?.collection('attendanceApprovals')
          .doc('appr_${record.attendanceId}')
          .set({
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
      await _db
          ?.collection('attendance')
          .doc(updated.attendanceId)
          .set(updated.toMap(), SetOptions(merge: true));
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
      await _db
          ?.collection('attendance')
          .doc(updated.attendanceId)
          .set(updated.toMap(), SetOptions(merge: true));
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

    // Strict Rule: Employee clock-in -> TL, HR, Admin can approve.
    //              TL/Manager clock-in -> HR, Admin ONLY! (Self-approval blocked)
    final isSelf = (old.employeeId == manager.userId || old.employeeCode == manager.employeeId) ||
        (manager.name.isNotEmpty && old.employeeName.trim().toLowerCase() == manager.name.trim().toLowerCase());
    if (isSelf && manager.role != UserRole.admin) {
      throw Exception(
        'Self-approval blocked! Clock-in for Team Leads and Managers must be approved by HR or Admin.',
      );
    }

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
      await _db
          ?.collection('attendance')
          .doc(updated.attendanceId)
          .set(updated.toMap(), SetOptions(merge: true));
      await _db
          ?.collection('attendanceApprovals')
          .doc('appr_${updated.attendanceId}')
          .set({
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
        // Skip self-approval for TL unless manager is Admin
        final isSelf = (_attendance[i].employeeId == manager.userId || _attendance[i].employeeCode == manager.employeeId) ||
            (manager.name.isNotEmpty && _attendance[i].employeeName.trim().toLowerCase() == manager.name.trim().toLowerCase());
        if (isSelf && manager.role != UserRole.admin) {
          continue;
        }

        _attendance[i] = _attendance[i].copyWith(
          status: AttendanceStatus.approved,
          approvedBy: manager.userId,
          approvedByName: '${manager.name} (${manager.role.name})',
          approvedAt: now,
          managerComment: 'Bulk verified & approved',
        );
        try {
          await _db
              ?.collection('attendance')
              .doc(_attendance[i].attendanceId)
              .set(_attendance[i].toMap(), SetOptions(merge: true));
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

    // Self-rejection restriction for TL/Manager
    final isSelf = (old.employeeId == manager.userId || old.employeeCode == manager.employeeId) ||
        (manager.name.isNotEmpty && old.employeeName.trim().toLowerCase() == manager.name.trim().toLowerCase());
    if (isSelf && manager.role != UserRole.admin) {
      throw Exception(
        'Self-action blocked! Attendance for Team Leads and Managers must be reviewed by HR or Admin.',
      );
    }

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
      await _db
          ?.collection('attendance')
          .doc(updated.attendanceId)
          .set(updated.toMap(), SetOptions(merge: true));
      await _db
          ?.collection('attendanceApprovals')
          .doc('appr_${updated.attendanceId}')
          .set({
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

    // Clock-Out is strictly permitted 1 time per day
    if (old.status == AttendanceStatus.completed || old.clockOutTime != null) {
      throw Exception(
        'Shift already completed for today (${old.date})! 1 Clock-In and 1 Clock-Out limit reached per day.',
      );
    }

    // Clock-Out is strictly permitted only AFTER attendance has been approved by TL
    if (old.status != AttendanceStatus.approved) {
      throw Exception(
        'Clock-Out is locked! Your Clock-In status is "${old.status.label}". You can Clock-Out only AFTER your Team Lead / Manager approves your attendance.',
      );
    }

    // Geofence verification for Clock-Out (within 300 meters of office)
    final userLat = latitude ?? _policy.officeLatitude + 0.0001;
    final userLng = longitude ?? _policy.officeLongitude + 0.0001;
    final geofenceRes = GeofenceService.verifyLocation(
      userLat: userLat,
      userLng: userLng,
      officeLat: _policy.officeLatitude,
      officeLng: _policy.officeLongitude,
      allowedRadiusMeters: _policy.geofenceRadiusMeters,
    );

    final isRemoteOrWfh = old.location != null &&
        (old.location!.toLowerCase().contains('remote') ||
            old.location!.toLowerCase().contains('wfh') ||
            old.location!.toLowerCase().contains('work from home') ||
            old.location!.toLowerCase().contains('authorized'));

    if (!isRemoteOrWfh && !geofenceRes.isWithinGeofence) {
      throw Exception(
        'Outside Geofence for Clock-Out: You are ${geofenceRes.distanceMeters.toStringAsFixed(0)}m away. Clock-Out is strictly allowed within ${_policy.geofenceRadiusMeters.toStringAsFixed(0)}m of the office (${_policy.officeName}).',
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
      await _db
          ?.collection('attendance')
          .doc(updated.attendanceId)
          .set(updated.toMap(), SetOptions(merge: true));
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

    return _leaves
        .where(
          (l) =>
              validIds.contains(l.employeeId) ||
              validIds.contains(l.employeeCode),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<AttendanceCorrectionModel> getCorrectionsForEmployee(String identifier) {
    final targetUser = _findUserByIdentifier(identifier);
    final validIds = {
      identifier,
      if (targetUser != null) targetUser.userId,
      if (targetUser != null) targetUser.employeeId,
    };

    return _corrections
        .where(
          (c) =>
              validIds.contains(c.employeeId) ||
              validIds.contains(c.employeeCode),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Announcements & Notifications
  Future<void> publishAnnouncement(AnnouncementModel announcement) async {
    _announcements.insert(0, announcement);
    _announcementsStreamController.add(List.unmodifiable(_announcements));

    try {
      _db
          ?.collection('announcements')
          .doc(announcement.id)
          .set(announcement.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore announcement write error: $e');
    }

    // Broadcast notifications to target users (Holidays always target all TLs, employees, and staff)
    final targetUsers = _users.where((u) {
      if (announcement.type == 'holiday') return true;
      if (announcement.audience == 'everyone') return true;
      if (announcement.audience == 'all_employees' &&
          (u.role == UserRole.employee || u.role == UserRole.manager)) {
        return true;
      }
      if (announcement.audience == 'all_tls' && u.role == UserRole.manager) {
        return true;
      }
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
        _db
            ?.collection('notifications')
            .doc(notif.id)
            .set(notif.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore notification write error: $e');
      }
    }

    _notificationsStreamController.add(List.unmodifiable(_notifications));
    LocalStorageService().saveFirestoreNotifications(_notifications.map((n) => n.toMap()).toList());

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
      description:
          'Published ${announcement.type} "${announcement.title}" to ${announcement.audience}.',
      targetEntityId: announcement.id,
    );
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      _notificationsStreamController.add(List.unmodifiable(_notifications));
      LocalStorageService().saveFirestoreNotifications(_notifications.map((n) => n.toMap()).toList());

      try {
        _db?.collection('notifications').doc(notificationId).update({
          'isRead': true,
        });
      } catch (e) {
        debugPrint('Firestore mark notification read error: $e');
      }
    }
  }

  List<NotificationModel> getNotificationsForUser(String identifier) {
    final targetUser = _findUserByIdentifier(identifier);
    final roleName = targetUser?.role.name.toUpperCase() ?? '';
    final validIds = {
      identifier,
      if (targetUser != null) targetUser.userId,
      if (targetUser != null) targetUser.employeeId,
      'ALL',
      'ALL_EMPLOYEES',
      'EMPLOYEES',
      'EVERYONE',
      if (roleName.isNotEmpty) roleName,
      '',
    };

    return _notifications.where((n) {
      if (n.userId.isEmpty) return true;
      final targetUpper = n.userId.toUpperCase();
      return validIds.contains(n.userId) || validIds.contains(targetUpper);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  LeaveBalanceModel getLeaveBalance(String identifier) {
    final targetUser = _findUserByIdentifier(identifier);
    final validIds = {
      identifier.toLowerCase(),
      if (targetUser != null) targetUser.userId.toLowerCase(),
      if (targetUser != null && targetUser.employeeId.isNotEmpty)
        targetUser.employeeId.toLowerCase(),
      if (targetUser != null && targetUser.email.isNotEmpty)
        targetUser.email.toLowerCase(),
    };

    // Calculate leaves used dynamically from approved leaves in _leaves
    int casualUsed = 0;
    int sickUsed = 0;
    int earnedUsed = 0;

    for (final l in _leaves) {
      final match = validIds.contains(l.employeeId.toLowerCase()) ||
          (l.employeeCode.isNotEmpty && validIds.contains(l.employeeCode.toLowerCase()));
      if (match && l.status == LeaveStatus.approved) {
        if (l.leaveType == LeaveType.casual) {
          casualUsed += l.totalDays;
        } else if (l.leaveType == LeaveType.sick) {
          sickUsed += l.totalDays;
        } else if (l.leaveType == LeaveType.earned) {
          earnedUsed += l.totalDays;
        }
      }
    }

    try {
      final existing = _leaveBalances.firstWhere(
        (b) => validIds.contains(b.employeeId.toLowerCase()),
      );
      return existing.copyWith(
        casualUsed: casualUsed > 0 ? casualUsed : existing.casualUsed,
        sickUsed: sickUsed > 0 ? sickUsed : existing.sickUsed,
        earnedUsed: earnedUsed > 0 ? earnedUsed : existing.earnedUsed,
      );
    } catch (_) {
      final balance = LeaveBalanceModel(
        employeeId: targetUser?.userId ?? identifier,
        casualUsed: casualUsed,
        sickUsed: sickUsed,
        earnedUsed: earnedUsed,
      );
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
      await _db
          ?.collection('leaves')
          .doc(leave.leaveId)
          .set(leave.toMap(), SetOptions(merge: true));
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

    // Create & dispatch persistent notification records for TL, HR, and Admin users
    final Set<UserModel> targetRecipients = {};
    for (final u in _users) {
      if (u.role == UserRole.admin || u.role == UserRole.hr) {
        targetRecipients.add(u);
      } else if (u.role == UserRole.manager) {
        final isManagerOfEmp = (employee.managerId != null &&
                employee.managerId!.isNotEmpty &&
                (u.userId == employee.managerId ||
                    u.employeeId == employee.managerId ||
                    u.name.toLowerCase() == employee.managerId!.toLowerCase() ||
                    u.email.toLowerCase() == employee.managerId!.toLowerCase())) ||
            (employee.teamId.isNotEmpty && u.teamId == employee.teamId);
        if (isManagerOfEmp) {
          targetRecipients.add(u);
        }
      }
    }

    for (final recipient in targetRecipients) {
      final notif = NotificationModel(
        id: 'notif_leave_${leave.leaveId}_${recipient.userId}_${DateTime.now().microsecondsSinceEpoch}',
        userId: recipient.userId,
        title: '🌴 New Leave Request: ${employee.name}',
        message: '${employee.name} (${employee.department}) requested $totalDays days ${leaveType.label} (${DateFormat('dd MMM').format(startDate)} - ${DateFormat('dd MMM').format(endDate)}). Sent for your review & approval.',
        type: 'approval',
        createdAt: DateTime.now(),
      );
      _notifications.insert(0, notif);
      try {
        await _db?.collection('notifications').doc(notif.id).set(notif.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore leave notification dispatch error: $e');
      }
    }
    _notificationsStreamController.add(List.unmodifiable(_notifications));

    // Dispatch branded email notification template
    LeaveEmailTemplateService.sendLeaveStatusEmail(
      leave: leave,
      employee: employee,
      actionType: 'applied',
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
    final reviewerRoleLabel = manager.role == UserRole.manager
        ? 'Team Lead (TL)'
        : (manager.role == UserRole.hr ? 'HR' : 'Admin');
    final reviewerFormattedName = '${manager.name} ($reviewerRoleLabel)';

    final updated = old.copyWith(
      status: isApproved ? LeaveStatus.approved : LeaveStatus.rejected,
      reviewedBy: manager.userId,
      reviewerName: reviewerFormattedName,
      reviewedAt: DateTime.now(),
      rejectionReason: rejectionReason,
    );

    _leaves[index] = updated;

    try {
      await _db
          ?.collection('leaves')
          .doc(updated.leaveId)
          .set(updated.toMap(), SetOptions(merge: true));
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

    // Dispatch targeted notification to Employee who requested the leave
    final empUser = _users.firstWhere(
      (u) => u.userId == old.employeeId || u.employeeId == old.employeeId,
      orElse: () => _users.firstWhere(
        (u) => u.name.toLowerCase() == old.employeeName.toLowerCase(),
        orElse: () => _users.first,
      ),
    );

    final notifToEmployee = NotificationModel(
      id: 'notif_leavereview_${updated.leaveId}_${DateTime.now().microsecondsSinceEpoch}',
      userId: empUser.userId,
      title: isApproved ? 'Leave Approved 🎉' : 'Leave Rejected ⚠️',
      message: isApproved
          ? 'Your ${old.leaveType.label} (${old.totalDays} days) was APPROVED by $reviewerFormattedName.'
          : 'Your ${old.leaveType.label} was REJECTED by $reviewerFormattedName.${rejectionReason != null && rejectionReason.isNotEmpty ? " Reason: $rejectionReason" : ""}',
      type: isApproved ? 'approval' : 'rejection',
      createdAt: DateTime.now(),
    );

    _notifications.insert(0, notifToEmployee);
    try {
      await _db?.collection('notifications').doc(notifToEmployee.id).set(notifToEmployee.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore review notification dispatch error: $e');
    }
    _notificationsStreamController.add(List.unmodifiable(_notifications));

    // Dispatch branded email notification template to Employee
    LeaveEmailTemplateService.sendLeaveStatusEmail(
      leave: updated,
      employee: empUser,
      actionType: isApproved ? 'approved' : 'rejected',
      reviewerName: reviewerFormattedName,
      rejectionReason: rejectionReason,
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
      await _db
          ?.collection('attendanceCorrections')
          .doc(corr.correctionId)
          .set(corr.toMap(), SetOptions(merge: true));
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
      await _db
          ?.collection('attendanceCorrections')
          .doc(updated.correctionId)
          .set(updated.toMap(), SetOptions(merge: true));
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
          await _db
              ?.collection('attendance')
              .doc(old.attendanceId)
              .set(_attendance[aIndex].toMap(), SetOptions(merge: true));
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

  Future<ProjectReportModel> submitProjectReport(
    ProjectReportModel report,
  ) async {
    final idx = _projectReports.indexWhere((r) => r.reportId == report.reportId);
    if (idx != -1) {
      _projectReports[idx] = report;
    } else {
      _projectReports.insert(0, report);
    }
    _projectReports.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    _projectReportsStreamController.add(List.unmodifiable(_projectReports));
    LocalStorageService().saveProjectReports(_projectReports);

    try {
      final db = _db;
      if (db != null) {
        await db
            .collection('projectReports')
            .doc(report.reportId)
            .set(report.toMap(), SetOptions(merge: true));
        debugPrint('🔥 Project report successfully written to Cloud Firestore DB: ${report.reportId}');
      } else {
        debugPrint('⚠️ Cloud Firestore DB reference is null during report submit');
      }
    } catch (e) {
      debugPrint('❌ Firestore submit project report error: $e');
    }

    // Broadcast in-app notification to Admin, HR, and TLs
    final notif = NotificationModel(
      id: 'notif_rep_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'ALL',
      title: '📝 Daily Work Report Submitted',
      message: '${report.employeeName} submitted work report for "${report.projectName}" (${report.hoursSpent} hrs logged).',
      type: 'announcement',
      createdAt: DateTime.now(),
    );
    _notifications.insert(0, notif);
    _notificationsStreamController.add(List.unmodifiable(_notifications));
    LocalStorageService().saveFirestoreNotifications(_notifications.map((n) => n.toMap()).toList());
    try {
      await _db?.collection('notifications').doc(notif.id).set(notif.toMap(), SetOptions(merge: true));
    } catch (_) {}

    AuditService().log(
      actor: _users.firstWhere(
        (u) => u.userId == report.employeeId || u.employeeId == report.employeeId,
        orElse: () => _users.first,
      ),
      actionType: 'PROJECT_REPORT_SUBMIT',
      description:
          'Submitted daily work report for project "${report.projectName}" (${report.hoursSpent} hrs logged).',
      targetEntityId: report.reportId,
    );

    NotificationService().sendNotification(
      title: 'Daily Project Report Submitted 📝',
      message:
          '${report.employeeName} submitted work report for "${report.projectName}" (${report.hoursSpent} hrs).',
      type: 'info',
    );

    return report;
  }

  Future<void> assignProjectToUser({
    required String userId,
    required String projectId,
    required String projectName,
  }) async {
    final idx = _users.indexWhere((u) => u.userId == userId || u.employeeId == userId);
    if (idx != -1) {
      final oldUser = _users[idx];
      final updated = oldUser.copyWith(
        assignedProjectId: projectId,
        assignedProjectName: projectName,
      );
      _users[idx] = updated;
      _usersStreamController.add(List.unmodifiable(_users));

      // Update in-memory _projects assignedEmployeeIds
      final projIdx = _projects.indexWhere((p) =>
          p.projectId == projectId ||
          p.projectName.toLowerCase() == projectName.toLowerCase());
      if (projIdx != -1) {
        final proj = _projects[projIdx];
        final newIds = Set<String>.from(proj.assignedEmployeeIds)
          ..add(updated.userId);
        if (updated.employeeId.isNotEmpty) {
          newIds.add(updated.employeeId);
        }
        _projects[projIdx] = proj.copyWith(
          assignedEmployeeIds: newIds.toList(),
        );
        _projectsStreamController.add(List.unmodifiable(_projects));
      }

      try {
        await _db?.collection('users').doc(updated.userId).set({
          'assignedProjectId': projectId,
          'assignedProjectName': projectName,
        }, SetOptions(merge: true));

        if (updated.employeeId.isNotEmpty) {
          await _db?.collection('employees').doc(updated.employeeId).set({
            'assignedProjectId': projectId,
            'assignedProjectName': projectName,
          }, SetOptions(merge: true));
        }

        if (projIdx != -1) {
          final targetProjId = _projects[projIdx].projectId;
          await _db?.collection('projects').doc(targetProjId).update({
            'assignedEmployeeIds': FieldValue.arrayUnion(
              [updated.userId, if (updated.employeeId.isNotEmpty) updated.employeeId],
            )
          });
        }
      } catch (e) {
        debugPrint('Firestore assign project error: $e');
      }

      AuditService().log(
        actor: _users.first,
        actionType: 'PROJECT_ASSIGN',
        description:
            'Assigned employee ${updated.name} (${updated.employeeId}) to project "$projectName".',
        targetEntityId: userId,
      );
    }
  }

  void _syncAssignedProjectToUsers(ProjectModel project) {
    for (int i = 0; i < _users.length; i++) {
      final u = _users[i];
      final isAssigned = project.assignedEmployeeIds.contains(u.userId) ||
          (u.employeeId.isNotEmpty && project.assignedEmployeeIds.contains(u.employeeId)) ||
          project.assignedLeadId == u.userId ||
          (u.employeeId.isNotEmpty && project.assignedLeadId == u.employeeId);
      if (isAssigned) {
        _users[i] = u.copyWith(
          assignedProjectId: project.projectId,
          assignedProjectName: project.projectName,
        );
        try {
          _db?.collection('users').doc(u.userId).set({
            'assignedProjectId': project.projectId,
            'assignedProjectName': project.projectName,
          }, SetOptions(merge: true));
          if (u.employeeId.isNotEmpty) {
            _db?.collection('employees').doc(u.employeeId).set({
              'assignedProjectId': project.projectId,
              'assignedProjectName': project.projectName,
            }, SetOptions(merge: true));
          }
        } catch (_) {}
      }
    }
    _usersStreamController.add(List.unmodifiable(_users));
  }

  Future<ProjectModel> createProject(ProjectModel newProject, UserModel actor) async {
    _projects.add(newProject);
    _syncAssignedProjectToUsers(newProject);
    _projectsStreamController.add(List.unmodifiable(_projects));

    try {
      await _db?.collection('projects').doc(newProject.projectId).set(newProject.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore create project error: $e');
    }

    AuditService().log(
      actor: actor,
      actionType: 'PROJECT_CREATE',
      description: 'Created new project "${newProject.projectName}" (${newProject.department}).',
      targetEntityId: newProject.projectId,
    );

    NotificationService().sendNotification(
      title: '📁 New Project Created: ${newProject.projectName}',
      message: 'New project "${newProject.projectName}" added under ${newProject.department}.',
      type: 'info',
    );

    return newProject;
  }

  Future<ProjectModel> updateProject(ProjectModel updatedProject, UserModel actor) async {
    final idx = _projects.indexWhere((p) => p.projectId == updatedProject.projectId);
    if (idx != -1) {
      _projects[idx] = updatedProject;
      _syncAssignedProjectToUsers(updatedProject);
      _projectsStreamController.add(List.unmodifiable(_projects));

      try {
        await _db?.collection('projects').doc(updatedProject.projectId).set(updatedProject.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore update project error: $e');
      }

      AuditService().log(
        actor: actor,
        actionType: 'PROJECT_UPDATE',
        description: 'Updated project details for "${updatedProject.projectName}". Status: ${updatedProject.status}.',
        targetEntityId: updatedProject.projectId,
      );
    }
    return updatedProject;
  }

  Future<bool> deleteProject(String projectId, UserModel actor) async {
    final idx = _projects.indexWhere((p) => p.projectId == projectId);
    if (idx != -1) {
      final target = _projects[idx];
      _projects.removeAt(idx);
      _projectsStreamController.add(List.unmodifiable(_projects));

      try {
        await _db?.collection('projects').doc(projectId).delete();
      } catch (e) {
        debugPrint('Firestore delete project error: $e');
      }

      AuditService().log(
        actor: actor,
        actionType: 'PROJECT_DELETE',
        description: 'Deleted project "${target.projectName}".',
        targetEntityId: projectId,
      );
      return true;
    }
    return false;
  }

  Future<bool> deleteProjectReport(String reportId, UserModel actor) async {
    final idx = _projectReports.indexWhere((r) => r.reportId == reportId);
    if (idx != -1) {
      final target = _projectReports[idx];
      _projectReports.removeAt(idx);
      _projectReportsStreamController.add(List.unmodifiable(_projectReports));

      try {
        await _db?.collection('projectReports').doc(reportId).delete();
      } catch (e) {
        debugPrint('Firestore delete project report error: $e');
      }

      AuditService().log(
        actor: actor,
        actionType: 'PROJECT_REPORT_DELETE',
        description: 'Deleted daily work report for project "${target.projectName}" submitted by ${target.employeeName}.',
        targetEntityId: reportId,
      );
      return true;
    }
    return false;
  }

  Future<bool> deleteAttendanceRecord(String attendanceId, UserModel actor) async {
    final idx = _attendance.indexWhere((a) => a.attendanceId == attendanceId);
    if (idx != -1) {
      final target = _attendance[idx];
      _attendance.removeAt(idx);
      _attendanceStreamController.add(List.unmodifiable(_attendance));
      LocalStorageService().saveAttendance(_attendance);

      try {
        await _db?.collection('attendance').doc(attendanceId).delete();
      } catch (e) {
        debugPrint('Firestore delete attendance record error: $e');
      }

      AuditService().log(
        actor: actor,
        actionType: 'ATTENDANCE_DELETE',
        description: 'Deleted attendance record (${target.date}) for ${target.employeeName}.',
        targetEntityId: attendanceId,
      );
      return true;
    }
    return false;
  }

  Future<bool> deleteLeaveRequest(String leaveId, UserModel actor) async {
    final idx = _leaves.indexWhere((l) => l.leaveId == leaveId);
    if (idx != -1) {
      final target = _leaves[idx];
      _leaves.removeAt(idx);
      _leavesStreamController.add(List.unmodifiable(_leaves));
      LocalStorageService().saveLeaves(_leaves);

      try {
        await _db?.collection('leaves').doc(leaveId).delete();
      } catch (e) {
        debugPrint('Firestore delete leave request error: $e');
      }

      AuditService().log(
        actor: actor,
        actionType: 'LEAVE_DELETE',
        description: 'Deleted leave request for ${target.employeeName} (${target.leaveType.label}).',
        targetEntityId: leaveId,
      );
      return true;
    }
    return false;
  }

  Future<bool> deleteAnnouncement(String announcementId, UserModel actor) async {
    final idx = _announcements.indexWhere((a) => a.id == announcementId);
    if (idx != -1) {
      final target = _announcements[idx];
      _announcements.removeAt(idx);
      _announcementsStreamController.add(List.unmodifiable(_announcements));

      try {
        await _db?.collection('announcements').doc(announcementId).delete();
      } catch (e) {
        debugPrint('Firestore delete announcement error: $e');
      }

      AuditService().log(
        actor: actor,
        actionType: 'ANNOUNCEMENT_DELETE',
        description: 'Deleted announcement "${target.title}".',
        targetEntityId: announcementId,
      );
      return true;
    }
    return false;
  }

  // --- Community EB Services ---
  Future<CommunityGroupModel> createCommunityGroup(
    CommunityGroupModel group,
    UserModel actor,
  ) async {
    _communityGroups.add(group);
    _communityGroupsStreamController.add(List.unmodifiable(_communityGroups));

    try {
      final db = _db;
      if (db != null) {
        await db
            .collection('communityGroups')
            .doc(group.groupId)
            .set(group.toMap(), SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Firestore create community group error: $e');
    }

    AuditService().log(
      actor: actor,
      actionType: 'COMMUNITY_GROUP_CREATE',
      description: 'Created new Community EB group "${group.name}".',
      targetEntityId: group.groupId,
    );

    return group;
  }

  Future<void> updateCommunityGroupMembers(
    String groupId,
    List<String> memberUserIds,
    UserModel actor,
  ) async {
    final idx = _communityGroups.indexWhere((g) => g.groupId == groupId);
    if (idx != -1) {
      final updated = _communityGroups[idx].copyWith(memberUserIds: memberUserIds);
      _communityGroups[idx] = updated;
      _communityGroupsStreamController.add(List.unmodifiable(_communityGroups));

      try {
        final db = _db;
        if (db != null) {
          await db
              .collection('communityGroups')
              .doc(groupId)
              .update({'memberUserIds': memberUserIds});
        }
      } catch (e) {
        debugPrint('Firestore update community members error: $e');
      }

      AuditService().log(
        actor: actor,
        actionType: 'COMMUNITY_GROUP_MEMBERS_UPDATE',
        description: 'Updated members list for Community EB group "${updated.name}".',
        targetEntityId: groupId,
      );
    }
  }

  Future<void> updateCommunityGroup(
    CommunityGroupModel updatedGroup,
    UserModel actor,
  ) async {
    final idx = _communityGroups.indexWhere((g) => g.groupId == updatedGroup.groupId);
    if (idx != -1) {
      _communityGroups[idx] = updatedGroup;
      _communityGroupsStreamController.add(List.unmodifiable(_communityGroups));

      try {
        final db = _db;
        if (db != null) {
          await db
              .collection('communityGroups')
              .doc(updatedGroup.groupId)
              .set(updatedGroup.toMap(), SetOptions(merge: true));
        }
      } catch (e) {
        debugPrint('Firestore update community group error: $e');
      }

      AuditService().log(
        actor: actor,
        actionType: 'COMMUNITY_GROUP_UPDATE',
        description: 'Updated Community EB group "${updatedGroup.name}".',
        targetEntityId: updatedGroup.groupId,
      );
    }
  }

  Future<bool> deleteCommunityGroup(
    String groupId,
    UserModel actor,
  ) async {
    final idx = _communityGroups.indexWhere((g) => g.groupId == groupId);
    if (idx != -1) {
      final target = _communityGroups[idx];
      _communityGroups.removeAt(idx);
      _communityGroupsStreamController.add(List.unmodifiable(_communityGroups));

      try {
        final db = _db;
        if (db != null) {
          await db.collection('communityGroups').doc(groupId).delete();
        }
      } catch (e) {
        debugPrint('Firestore delete community group error: $e');
      }

      AuditService().log(
        actor: actor,
        actionType: 'COMMUNITY_GROUP_DELETE',
        description: 'Deleted Community EB group "${target.name}".',
        targetEntityId: groupId,
      );
      return true;
    }
    return false;
  }

  Future<CommunityMessageModel> sendCommunityMessage(
    CommunityMessageModel message,
  ) async {
    _communityMessages.add(message);
    _communityMessagesStreamController.add(List.unmodifiable(_communityMessages));

    try {
      final db = _db;
      if (db != null) {
        await db
            .collection('communityMessages')
            .doc(message.messageId)
            .set(message.toMap(), SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Firestore send community message error: $e');
    }

    return message;
  }

  Future<void> toggleMessageReaction({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    final index = _communityMessages.indexWhere((m) => m.messageId == messageId);
    if (index == -1) return;

    final existingMsg = _communityMessages[index];
    final updatedReactions = Map<String, String>.from(existingMsg.reactions);

    if (updatedReactions[userId] == emoji) {
      updatedReactions.remove(userId);
    } else {
      updatedReactions[userId] = emoji;
    }

    final updatedMsg = existingMsg.copyWith(reactions: updatedReactions);
    _communityMessages[index] = updatedMsg;
    _communityMessagesStreamController.add(List.unmodifiable(_communityMessages));

    try {
      final db = _db;
      if (db != null) {
        await db
            .collection('communityMessages')
            .doc(messageId)
            .set({'reactions': updatedReactions}, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Firestore toggle message reaction error: $e');
    }
  }

  Future<void> editCommunityMessage({
    required String messageId,
    required String newContent,
  }) async {
    final index = _communityMessages.indexWhere((m) => m.messageId == messageId);
    if (index == -1) return;

    final existingMsg = _communityMessages[index];
    final updatedMsg = existingMsg.copyWith(
      content: newContent,
      isEdited: true,
    );
    _communityMessages[index] = updatedMsg;
    _communityMessagesStreamController.add(List.unmodifiable(_communityMessages));

    try {
      final db = _db;
      if (db != null) {
        await db.collection('communityMessages').doc(messageId).update({
          'content': newContent,
          'isEdited': true,
        });
      }
    } catch (e) {
      debugPrint('Firestore edit community message error: $e');
    }
  }

  Future<bool> deleteCommunityMessage(String messageId) async {
    final index = _communityMessages.indexWhere((m) => m.messageId == messageId);
    if (index == -1) return false;

    _communityMessages.removeAt(index);
    _communityMessagesStreamController.add(List.unmodifiable(_communityMessages));

    try {
      final db = _db;
      if (db != null) {
        await db.collection('communityMessages').doc(messageId).delete();
      }
    } catch (e) {
      debugPrint('Firestore delete community message error: $e');
    }
    return true;
  }

  Future<bool> checkFirebaseConnection() async {
    try {
      final db = _db;
      if (db == null) return false;
      await db
          .collection('attendancePolicies')
          .doc('policy_standard')
          .get(const GetOptions(source: Source.server));
      return true;
    } catch (_) {
      return false;
    }
  }
}
