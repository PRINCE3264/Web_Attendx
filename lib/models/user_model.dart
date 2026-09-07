enum UserRole {
  employee,
  manager, // Represents TL (Team Lead)
  hr,
  admin,
}

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.employee:
        return 'Employee';
      case UserRole.manager:
        return 'TL';
      case UserRole.hr:
        return 'HR';
      case UserRole.admin:
        return 'Admin';
    }
  }

  String get code {
    switch (this) {
      case UserRole.employee:
        return 'employee';
      case UserRole.manager:
        return 'tl';
      case UserRole.hr:
        return 'hr';
      case UserRole.admin:
        return 'admin';
    }
  }

  static UserRole fromString(String? roleStr) {
    switch (roleStr?.toLowerCase().trim()) {
      case 'tl':
      case 'manager':
      case 'team lead':
        return UserRole.manager;
      case 'admin':
      case 'administrator':
        return UserRole.admin;
      case 'hr':
      case 'human resources':
        return UserRole.hr;
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
  final String? phoneNumber;
  final String? avatarUrl;
  final String? fcmToken;
  final bool isActive;
  final DateTime? createdAt;
  final String? initialPassword;
  final String? assignedProjectId;
  final String? assignedProjectName;
  final String? deviceId;

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
    this.phoneNumber,
    this.avatarUrl,
    this.fcmToken,
    this.isActive = true,
    this.createdAt,
    this.initialPassword,
    this.assignedProjectId,
    this.assignedProjectName,
    this.deviceId,
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
      'phoneNumber': phoneNumber,
      'avatarUrl': avatarUrl,
      'fcmToken': fcmToken,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'initialPassword': initialPassword,
      'assignedProjectId': assignedProjectId,
      'assignedProjectName': assignedProjectName,
      'deviceId': deviceId,
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
      phoneNumber: map['phoneNumber'] ?? map['phone'],
      avatarUrl: map['avatarUrl'],
      fcmToken: map['fcmToken'],
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
      initialPassword: map['initialPassword'] ?? map['password'],
      assignedProjectId: map['assignedProjectId'],
      assignedProjectName: map['assignedProjectName'],
      deviceId: map['deviceId'],
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
    String? phoneNumber,
    String? avatarUrl,
    String? fcmToken,
    bool? isActive,
    DateTime? createdAt,
    String? initialPassword,
    String? assignedProjectId,
    String? assignedProjectName,
    String? deviceId,
    bool resetDeviceId = false,
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
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      initialPassword: initialPassword ?? this.initialPassword,
      assignedProjectId: assignedProjectId ?? this.assignedProjectId,
      assignedProjectName: assignedProjectName ?? this.assignedProjectName,
      deviceId: resetDeviceId ? null : (deviceId ?? this.deviceId),
    );
  }
}
