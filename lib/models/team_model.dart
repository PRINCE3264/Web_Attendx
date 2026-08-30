class TeamModel {
  final String teamId;
  final String name;
  final String managerId;
  final String managerName;
  final int memberCount;

  TeamModel({
    required this.teamId,
    required this.name,
    required this.managerId,
    required this.managerName,
    this.memberCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'name': name,
      'managerId': managerId,
      'managerName': managerName,
      'memberCount': memberCount,
    };
  }

  factory TeamModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return TeamModel(
      teamId: id ?? map['teamId'] ?? '',
      name: map['name'] ?? '',
      managerId: map['managerId'] ?? '',
      managerName: map['managerName'] ?? '',
      memberCount: map['memberCount'] ?? 0,
    );
  }
}
