class ProjectModel {
  final String projectId;
  final String projectName;
  final String description;
  final String department;
  final String status; // 'active', 'completed', 'on_hold', 'planning'
  final DateTime startDate;
  final DateTime? targetDate;
  final String? assignedLeadId;
  final String? assignedLeadName;
  final List<String> assignedEmployeeIds;
  final DateTime createdAt;

  ProjectModel({
    required this.projectId,
    required this.projectName,
    required this.description,
    required this.department,
    this.status = 'active',
    required this.startDate,
    this.targetDate,
    this.assignedLeadId,
    this.assignedLeadName,
    this.assignedEmployeeIds = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'projectName': projectName,
      'description': description,
      'department': department,
      'status': status,
      'startDate': startDate.toIso8601String(),
      'targetDate': targetDate?.toIso8601String(),
      'assignedLeadId': assignedLeadId,
      'assignedLeadName': assignedLeadName,
      'assignedEmployeeIds': assignedEmployeeIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return ProjectModel(
      projectId: id ?? map['projectId'] ?? '',
      projectName: map['projectName'] ?? '',
      description: map['description'] ?? '',
      department: map['department'] ?? 'Engineering',
      status: map['status'] ?? 'active',
      startDate: map['startDate'] != null
          ? DateTime.tryParse(map['startDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      targetDate: map['targetDate'] != null
          ? DateTime.tryParse(map['targetDate'].toString())
          : null,
      assignedLeadId: map['assignedLeadId'],
      assignedLeadName: map['assignedLeadName'],
      assignedEmployeeIds: List<String>.from(map['assignedEmployeeIds'] ?? []),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  ProjectModel copyWith({
    String? projectId,
    String? projectName,
    String? description,
    String? department,
    String? status,
    DateTime? startDate,
    DateTime? targetDate,
    String? assignedLeadId,
    String? assignedLeadName,
    List<String>? assignedEmployeeIds,
    DateTime? createdAt,
  }) {
    return ProjectModel(
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      description: description ?? this.description,
      department: department ?? this.department,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      assignedLeadId: assignedLeadId ?? this.assignedLeadId,
      assignedLeadName: assignedLeadName ?? this.assignedLeadName,
      assignedEmployeeIds: assignedEmployeeIds ?? this.assignedEmployeeIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
