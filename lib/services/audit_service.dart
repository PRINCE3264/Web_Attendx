import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/audit_log_model.dart';
import '../models/user_model.dart';

class AuditService {
  static final AuditService _instance = AuditService._internal();
  factory AuditService() => _instance;
  AuditService._internal() {
    _bindFirestoreListener();
  }

  FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  final List<AuditLogModel> _logs = [];
  final _auditStreamController = StreamController<List<AuditLogModel>>.broadcast();

  Stream<List<AuditLogModel>> get auditStream => _auditStreamController.stream;
  List<AuditLogModel> get allLogs => List.unmodifiable(_logs);

  void _bindFirestoreListener() {
    try {
      final db = _db;
      if (db == null) return;
      if (FirebaseAuth.instance.currentUser == null) return;

      db.collection('auditLogs').snapshots().listen((snap) {
        if (snap.docs.isNotEmpty) {
          final items = snap.docs.map((d) => AuditLogModel.fromMap(d.data(), d.id)).toList();
          items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          _logs.clear();
          _logs.addAll(items);
          _auditStreamController.add(List.unmodifiable(_logs));
        }
      }, onError: (e) => debugPrint('Live auditLogs sync info: $e'));
    } catch (e) {
      debugPrint('Firestore auditLogs listener setup error: $e');
    }
  }

  void log({
    required UserModel actor,
    required String actionType,
    required String description,
    required String targetEntityId,
    String? oldValue,
    String? newValue,
  }) {
    final entry = AuditLogModel(
      logId: 'log_${DateTime.now().millisecondsSinceEpoch}',
      actorId: actor.userId,
      actorName: actor.name,
      actorRole: actor.role.name,
      actionType: actionType,
      description: description,
      targetEntityId: targetEntityId,
      oldValue: oldValue,
      newValue: newValue,
      timestamp: DateTime.now(),
    );

    _logs.insert(0, entry);
    _auditStreamController.add(List.unmodifiable(_logs));

    try {
      _db?.collection('auditLogs').doc(entry.logId).set(entry.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore audit log write error: $e');
    }
  }

  void seedInitialLogs(List<AuditLogModel> seedLogs) {
    if (_logs.isEmpty) {
      _logs.addAll(seedLogs);
      _auditStreamController.add(List.unmodifiable(_logs));
    }
  }
}

