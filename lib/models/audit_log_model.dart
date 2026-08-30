class AuditLogModel {
  final String logId;
  final String actorId;
  final String actorName;
  final String actorRole;
  final String actionType; // 'CLOCK_IN', 'TL_APPROVED', 'TL_REJECTED', 'LEAVE_APPLY', 'LEAVE_APPROVE', 'ADMIN_USER_ADD', 'POLICY_UPDATE', 'BREAK_LOG'
  final String description;
  final String targetEntityId;
  final String? oldValue;
  final String? newValue;
  final DateTime timestamp;

  AuditLogModel({
    required this.logId,
    required this.actorId,
    required this.actorName,
    required this.actorRole,
    required this.actionType,
    required this.description,
    required this.targetEntityId,
    this.oldValue,
    this.newValue,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'logId': logId,
      'actorId': actorId,
      'actorName': actorName,
      'actorRole': actorRole,
      'actionType': actionType,
      'description': description,
      'targetEntityId': targetEntityId,
      'oldValue': oldValue,
      'newValue': newValue,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AuditLogModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return AuditLogModel(
      logId: id ?? map['logId'] ?? '',
      actorId: map['actorId'] ?? '',
      actorName: map['actorName'] ?? 'System',
      actorRole: map['actorRole'] ?? 'system',
      actionType: map['actionType'] ?? 'EVENT',
      description: map['description'] ?? '',
      targetEntityId: map['targetEntityId'] ?? '',
      oldValue: map['oldValue'],
      newValue: map['newValue'],
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
