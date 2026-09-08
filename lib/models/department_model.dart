import 'package:cloud_firestore/cloud_firestore.dart';

class DepartmentModel {
  final String departmentId;
  final String name;
  final String code;
  final String? headOfDepartmentId;
  final String? headOfDepartmentName;
  final int totalEmployees;
  final bool isActive;
  final DateTime? createdAt;

  DepartmentModel({
    required this.departmentId,
    required this.name,
    required this.code,
    this.headOfDepartmentId,
    this.headOfDepartmentName,
    this.totalEmployees = 0,
    this.isActive = true,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'departmentId': departmentId,
      'name': name,
      'code': code,
      if (headOfDepartmentId != null) 'headOfDepartmentId': headOfDepartmentId,
      if (headOfDepartmentName != null) 'headOfDepartmentName': headOfDepartmentName,
      'totalEmployees': totalEmployees,
      'isActive': isActive,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory DepartmentModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return DepartmentModel(
      departmentId: id ?? map['departmentId'] ?? '',
      name: map['name'] ?? '',
      code: map['code'] ?? '',
      headOfDepartmentId: map['headOfDepartmentId'],
      headOfDepartmentName: map['headOfDepartmentName'],
      totalEmployees: map['totalEmployees'] ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : null,
    );
  }

  DepartmentModel copyWith({
    String? departmentId,
    String? name,
    String? code,
    String? headOfDepartmentId,
    String? headOfDepartmentName,
    int? totalEmployees,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return DepartmentModel(
      departmentId: departmentId ?? this.departmentId,
      name: name ?? this.name,
      code: code ?? this.code,
      headOfDepartmentId: headOfDepartmentId ?? this.headOfDepartmentId,
      headOfDepartmentName: headOfDepartmentName ?? this.headOfDepartmentName,
      totalEmployees: totalEmployees ?? this.totalEmployees,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
