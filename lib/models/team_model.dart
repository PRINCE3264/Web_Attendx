import 'package:cloud_firestore/cloud_firestore.dart';

class TeamModel {
  final String teamId;
  final String name;
  final String departmentId;
  final String managerId;
  final String managerName;
  final int memberCount;
  final bool isActive;
  final DateTime? createdAt;

  TeamModel({
    required this.teamId,
    required this.name,
    required this.departmentId,
    required this.managerId,
    required this.managerName,
    this.memberCount = 0,
    this.isActive = true,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'name': name,
      'departmentId': departmentId,
      'managerId': managerId,
      'managerName': managerName,
      'memberCount': memberCount,
      'isActive': isActive,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory TeamModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return TeamModel(
      teamId: id ?? map['teamId'] ?? '',
      name: map['name'] ?? '',
      departmentId: map['departmentId'] ?? '',
      managerId: map['managerId'] ?? '',
      managerName: map['managerName'] ?? '',
      memberCount: map['memberCount'] ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : null,
    );
  }

  TeamModel copyWith({
    String? teamId,
    String? name,
    String? departmentId,
    String? managerId,
    String? managerName,
    int? memberCount,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return TeamModel(
      teamId: teamId ?? this.teamId,
      name: name ?? this.name,
      departmentId: departmentId ?? this.departmentId,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
      memberCount: memberCount ?? this.memberCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
