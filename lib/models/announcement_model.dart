class AnnouncementModel {
  final String id;
  final String title;
  final String message;
  final String type; // 'holiday', 'announcement', 'notice'
  final String audience; // 'all_employees', 'all_tls', 'everyone'
  final DateTime date;
  final String createdBy; // userId
  final DateTime createdAt;
  final bool isActive;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.audience,
    required this.date,
    required this.createdBy,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'type': type,
      'audience': audience,
      'date': date.toIso8601String(),
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory AnnouncementModel.fromMap(Map<String, dynamic> map, String id) {
    return AnnouncementModel(
      id: id,
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? 'notice',
      audience: map['audience'] ?? 'everyone',
      date: map['date'] != null ? DateTime.tryParse(map['date']) ?? DateTime.now() : DateTime.now(),
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) ?? DateTime.now() : DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }
}
