class CommunityGroupModel {
  final String groupId;
  final String name;
  final String description;
  final String createdBy;
  final DateTime createdAt;
  final List<String> memberUserIds;
  final bool isOfficial;
  final String? groupLogoUrl;

  CommunityGroupModel({
    required this.groupId,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    required this.memberUserIds,
    this.isOfficial = true,
    this.groupLogoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'memberUserIds': memberUserIds,
      'isOfficial': isOfficial,
      'groupLogoUrl': groupLogoUrl,
    };
  }

  factory CommunityGroupModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return CommunityGroupModel(
      groupId: id ?? map['groupId'] ?? '',
      name: map['name'] ?? 'General Community',
      description: map['description'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt'] != null
          ? (DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      memberUserIds: map['memberUserIds'] is List
          ? (map['memberUserIds'] as List).map((e) => e.toString()).toList()
          : [],
      isOfficial: map['isOfficial'] ?? true,
      groupLogoUrl: map['groupLogoUrl'],
    );
  }

  CommunityGroupModel copyWith({
    String? groupId,
    String? name,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    List<String>? memberUserIds,
    bool? isOfficial,
    String? groupLogoUrl,
  }) {
    return CommunityGroupModel(
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      memberUserIds: memberUserIds ?? this.memberUserIds,
      isOfficial: isOfficial ?? this.isOfficial,
      groupLogoUrl: groupLogoUrl ?? this.groupLogoUrl,
    );
  }
}

class CommunityMessageModel {
  final String messageId;
  final String groupId;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String? senderAvatar;
  final String content;
  final DateTime sentAt;
  final String? mediaUrl;
  final Map<String, String> reactions; // userId -> emoji
  final String? replyToMessageId;
  final String? replyToSenderName;
  final String? replyToContent;
  final bool isEdited;

  CommunityMessageModel({
    required this.messageId,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    this.senderAvatar,
    required this.content,
    required this.sentAt,
    this.mediaUrl,
    Map<String, String>? reactions,
    this.replyToMessageId,
    this.replyToSenderName,
    this.replyToContent,
    this.isEdited = false,
  }) : reactions = reactions ?? {};

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'groupId': groupId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'senderAvatar': senderAvatar,
      'content': content,
      'sentAt': sentAt.toIso8601String(),
      'mediaUrl': mediaUrl,
      'reactions': reactions,
      'replyToMessageId': replyToMessageId,
      'replyToSenderName': replyToSenderName,
      'replyToContent': replyToContent,
      'isEdited': isEdited,
    };
  }

  factory CommunityMessageModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return CommunityMessageModel(
      messageId: id ?? map['messageId'] ?? '',
      groupId: map['groupId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Member',
      senderRole: map['senderRole'] ?? 'EMPLOYEE',
      senderAvatar: map['senderAvatar'],
      content: map['content'] ?? '',
      sentAt: map['sentAt'] != null
          ? (DateTime.tryParse(map['sentAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      mediaUrl: map['mediaUrl'],
      reactions: map['reactions'] is Map
          ? (map['reactions'] as Map).map((k, v) => MapEntry(k.toString(), v.toString()))
          : {},
      replyToMessageId: map['replyToMessageId'],
      replyToSenderName: map['replyToSenderName'],
      replyToContent: map['replyToContent'],
      isEdited: map['isEdited'] ?? false,
    );
  }

  CommunityMessageModel copyWith({
    String? messageId,
    String? groupId,
    String? senderId,
    String? senderName,
    String? senderRole,
    String? senderAvatar,
    String? content,
    DateTime? sentAt,
    String? mediaUrl,
    Map<String, String>? reactions,
    String? replyToMessageId,
    String? replyToSenderName,
    String? replyToContent,
    bool? isEdited,
  }) {
    return CommunityMessageModel(
      messageId: messageId ?? this.messageId,
      groupId: groupId ?? this.groupId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      reactions: reactions ?? this.reactions,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToSenderName: replyToSenderName ?? this.replyToSenderName,
      replyToContent: replyToContent ?? this.replyToContent,
      isEdited: isEdited ?? this.isEdited,
    );
  }
}
