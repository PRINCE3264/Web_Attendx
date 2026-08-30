import 'dart:async';
import '../models/audit_log_model.dart';
import '../models/user_model.dart';

class AuditService {
  static final AuditService _instance = AuditService._internal();
  factory AuditService() => _instance;
  AuditService._internal();

  final List<AuditLogModel> _logs = [];
  final _auditStreamController = StreamController<List<AuditLogModel>>.broadcast();

  Stream<List<AuditLogModel>> get auditStream => _auditStreamController.stream;
  List<AuditLogModel> get allLogs => List.unmodifiable(_logs);

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
  }

  void seedInitialLogs(List<AuditLogModel> seedLogs) {
    _logs.clear();
    _logs.addAll(seedLogs);
    _auditStreamController.add(List.unmodifiable(_logs));
  }
}
