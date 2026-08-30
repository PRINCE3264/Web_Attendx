enum UserRole {
  employee,
  manager,
  hr,
  admin,
}

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.employee:
        return 'Employee';
      case UserRole.manager:
        return 'TL / Manager';
      case UserRole.hr:
        return 'HR Executive';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  String get code {
    switch (this) {
      case UserRole.employee:
        return 'employee';
      case UserRole.manager:
        return 'manager';
      case UserRole.hr:
        return 'hr';
      case UserRole.admin:
        return 'admin';
    }
  }

  static UserRole fromString(String? roleStr) {
    switch (roleStr?.toLowerCase().trim()) {
      case 'manager':
      case 'tl':
      case 'team lead':
        return UserRole.manager;
      case 'hr':
      case 'human resources':
        return UserRole.hr;
      case 'admin':
        return UserRole.admin;
      case 'employee':
      default:
        return UserRole.employee;
    }
  }
}

class UserModel {
  final String userId;
  final String name;
  final String email;
  final UserRole role;
  final String employeeId;
  final String teamId;
  final String teamName;
  final String? managerId;
  final String? managerName;
  final String department;
  final String? avatarUrl;
  final String? fcmToken;
  final bool isActive;
  final DateTime? createdAt;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.employeeId,
    required this.teamId,
    this.teamName = 'Engineering',
    this.managerId,
    this.managerName,
    required this.department,
    this.avatarUrl,
    this.fcmToken,
    this.isActive = true,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'role': role.code,
      'employeeId': employeeId,
      'teamId': teamId,
      'teamName': teamName,
      'managerId': managerId,
      'managerName': managerName,
      'department': department,
      'avatarUrl': avatarUrl,
      'fcmToken': fcmToken,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return UserModel(
      userId: id ?? map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: UserRoleExtension.fromString(map['role']),
      employeeId: map['employeeId'] ?? '',
      teamId: map['teamId'] ?? '',
      teamName: map['teamName'] ?? 'General Team',
      managerId: map['managerId'],
      managerName: map['managerName'],
      department: map['department'] ?? 'General',
      avatarUrl: map['avatarUrl'],
      fcmToken: map['fcmToken'],
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
    );
  }

  UserModel copyWith({
    String? userId,
    String? name,
    String? email,
    UserRole? role,
    String? employeeId,
    String? teamId,
    String? teamName,
    String? managerId,
    String? managerName,
    String? department,
    String? avatarUrl,
    String? fcmToken,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      employeeId: employeeId ?? this.employeeId,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
      department: department ?? this.department,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
