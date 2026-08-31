import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

enum SocialVisibility { public, followersOnly, private }

enum SocialFeedFilter { recent, following, mine }

enum SocialRelationKind { follow, block }

enum SocialNotificationType { reaction, comment, follow }

class SocialProfile {
  const SocialProfile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.bio,
    required this.createdAt,
    required this.updatedAt,
    this.isPrivate = false,
    this.isBlocked = false,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postCount = 0,
  });

  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPrivate;
  final bool isBlocked;
  final int followersCount;
  final int followingCount;
  final int postCount;

  SocialProfile copyWith({
    String? id,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPrivate,
    bool? isBlocked,
    int? followersCount,
    int? followingCount,
    int? postCount,
  }) {
    return SocialProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPrivate: isPrivate ?? this.isPrivate,
      isBlocked: isBlocked ?? this.isBlocked,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postCount: postCount ?? this.postCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'bio': bio,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'isPrivate': isPrivate,
        'isBlocked': isBlocked,
        'followersCount': followersCount,
        'followingCount': followingCount,
        'postCount': postCount,
      };

  factory SocialProfile.fromJson(Map<String, dynamic> json) {
    return SocialProfile(
      id: json['id'] as String,
      username: json['username'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      createdAt: _dateFromJson(json['createdAt']),
      updatedAt: _dateFromJson(json['updatedAt']),
      isPrivate: json['isPrivate'] as bool? ?? false,
      isBlocked: json['isBlocked'] as bool? ?? false,
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      postCount: json['postCount'] as int? ?? 0,
    );
  }

  static DateTime _dateFromJson(Object? value) {
    if (value is Timestamp) {
      return value.toDate().toUtc();
    }
    if (value is DateTime) {
      return value.toUtc();
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toUtc() ?? DateTime.now().toUtc();
    }
    return DateTime.now().toUtc();
  }
}

class SocialPost {
  const SocialPost({
    required this.id,
    required this.authorId,
    required this.text,
    this.mediaUrls = const <String>[],
    required this.createdAt,
    required this.updatedAt,
    this.visibility = SocialVisibility.public,
    this.reactionCount = 0,
    this.commentCount = 0,
    this.isDeleted = false,
  });

  final String id;
  final String authorId;
  final String text;
  final List<String> mediaUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SocialVisibility visibility;
  final int reactionCount;
  final int commentCount;
  final bool isDeleted;

  SocialPost copyWith({
    String? id,
    String? authorId,
    String? text,
    List<String>? mediaUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    SocialVisibility? visibility,
    int? reactionCount,
    int? commentCount,
    bool? isDeleted,
  }) {
    return SocialPost(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      text: text ?? this.text,
      mediaUrls: mediaUrls ?? List<String>.from(this.mediaUrls),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      visibility: visibility ?? this.visibility,
      reactionCount: reactionCount ?? this.reactionCount,
      commentCount: commentCount ?? this.commentCount,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorId': authorId,
        'text': text,
        'mediaUrls': mediaUrls,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'visibility': visibility.name,
        'reactionCount': reactionCount,
        'commentCount': commentCount,
        'isDeleted': isDeleted,
      };

  factory SocialPost.fromJson(Map<String, dynamic> json) {
    return SocialPost(
      id: json['id'] as String,
      authorId: json['authorId'] as String,
      text: json['text'] as String? ?? '',
      mediaUrls: List<String>.from(
          (json['mediaUrls'] as List<dynamic>? ?? const <dynamic>[])),
      createdAt: SocialProfile._dateFromJson(json['createdAt']),
      updatedAt: SocialProfile._dateFromJson(json['updatedAt']),
      visibility:
          _visibilityFromJson(json['visibility'] as String? ?? 'public'),
      reactionCount: json['reactionCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  static SocialVisibility _visibilityFromJson(String raw) {
    switch (raw) {
      case 'followersOnly':
        return SocialVisibility.followersOnly;
      case 'private':
        return SocialVisibility.private;
      case 'public':
      default:
        return SocialVisibility.public;
    }
  }
}

class SocialComment {
  const SocialComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  final String id;
  final String postId;
  final String authorId;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  SocialComment copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? text,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return SocialComment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'postId': postId,
        'authorId': authorId,
        'text': text,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'isDeleted': isDeleted,
      };

  factory SocialComment.fromJson(Map<String, dynamic> json) {
    return SocialComment(
      id: json['id'] as String,
      postId: json['postId'] as String,
      authorId: json['authorId'] as String,
      text: json['text'] as String? ?? '',
      createdAt: SocialProfile._dateFromJson(json['createdAt']),
      updatedAt: SocialProfile._dateFromJson(json['updatedAt']),
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}

class SocialReaction {
  const SocialReaction({
    required this.id,
    required this.postId,
    required this.userId,
    required this.kind,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final String userId;
  final String kind;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'postId': postId,
        'userId': userId,
        'kind': kind,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  factory SocialReaction.fromJson(Map<String, dynamic> json) {
    return SocialReaction(
      id: json['id'] as String,
      postId: json['postId'] as String,
      userId: json['userId'] as String,
      kind: json['kind'] as String? ?? 'like',
      createdAt: SocialProfile._dateFromJson(json['createdAt']),
    );
  }

  static String buildReactionId(String postId, String userId) =>
      '${postId}:$userId';
}

class SocialRelation {
  const SocialRelation({
    required this.id,
    required this.sourceId,
    required this.targetId,
    required this.kind,
    required this.createdAt,
  });

  final String id;
  final String sourceId;
  final String targetId;
  final SocialRelationKind kind;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceId': sourceId,
        'targetId': targetId,
        'kind': kind.name,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  factory SocialRelation.fromJson(Map<String, dynamic> json) {
    return SocialRelation(
      id: json['id'] as String,
      sourceId: json['sourceId'] as String,
      targetId: json['targetId'] as String,
      kind: _kindFromJson(json['kind'] as String? ?? 'follow'),
      createdAt: SocialProfile._dateFromJson(json['createdAt']),
    );
  }

  static SocialRelationKind _kindFromJson(String raw) {
    switch (raw) {
      case 'block':
        return SocialRelationKind.block;
      case 'follow':
      default:
        return SocialRelationKind.follow;
    }
  }

  static String buildRelationId(
    String sourceId,
    String targetId,
    SocialRelationKind kind,
  ) =>
      '${kind.name}:$sourceId:$targetId';
}

class SocialNotification {
  const SocialNotification({
    required this.id,
    required this.recipientId,
    required this.actorId,
    required this.type,
    required this.entityId,
    required this.createdAt,
    this.dedupeKey,
    this.readAt,
    this.isRead = false,
  });

  final String id;
  final String recipientId;
  final String actorId;
  final SocialNotificationType type;
  final String entityId;
  final DateTime createdAt;
  final String? dedupeKey;
  final DateTime? readAt;
  final bool isRead;

  SocialNotification copyWith({
    String? id,
    String? recipientId,
    String? actorId,
    SocialNotificationType? type,
    String? entityId,
    DateTime? createdAt,
    String? dedupeKey,
    DateTime? readAt,
    bool? isRead,
  }) {
    return SocialNotification(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      actorId: actorId ?? this.actorId,
      type: type ?? this.type,
      entityId: entityId ?? this.entityId,
      createdAt: createdAt ?? this.createdAt,
      dedupeKey: dedupeKey ?? this.dedupeKey,
      readAt: readAt ?? this.readAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipientId': recipientId,
        'actorId': actorId,
        'type': type.name,
        'entityId': entityId,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'dedupeKey': dedupeKey,
        'readAt': readAt?.toUtc().toIso8601String(),
        'isRead': isRead,
      };

  factory SocialNotification.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String? ?? 'reaction';
    return SocialNotification(
      id: json['id'] as String,
      recipientId: json['recipientId'] as String,
      actorId: json['actorId'] as String,
      type: _notificationTypeFromJson(rawType),
      entityId: json['entityId'] as String,
      createdAt: SocialProfile._dateFromJson(json['createdAt']),
      dedupeKey: json['dedupeKey'] as String?,
      readAt: json['readAt'] == null
          ? null
          : SocialProfile._dateFromJson(json['readAt']),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  static SocialNotificationType _notificationTypeFromJson(String raw) {
    switch (raw) {
      case 'comment':
        return SocialNotificationType.comment;
      case 'follow':
        return SocialNotificationType.follow;
      case 'reaction':
      default:
        return SocialNotificationType.reaction;
    }
  }

  static String buildNotificationId(
    String recipientId,
    String actorId,
    String entityId,
    SocialNotificationType type, {
    String? dedupeKey,
  }) {
    final base = '${recipientId}:${actorId}:${entityId}:${type.name}';
    return dedupeKey == null ? base : '$base:$dedupeKey';
  }
}

class SocialMediaMetadata {
  const SocialMediaMetadata({
    required this.id,
    required this.ownerId,
    required this.storagePath,
    required this.url,
    required this.contentType,
    required this.createdAt,
    this.sizeBytes,
  });

  final String id;
  final String ownerId;
  final String storagePath;
  final String url;
  final String contentType;
  final DateTime createdAt;
  final int? sizeBytes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerId': ownerId,
        'storagePath': storagePath,
        'url': url,
        'contentType': contentType,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'sizeBytes': sizeBytes,
      };

  factory SocialMediaMetadata.fromJson(Map<String, dynamic> json) {
    return SocialMediaMetadata(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      storagePath: json['storagePath'] as String,
      url: json['url'] as String,
      contentType: json['contentType'] as String? ?? 'application/octet-stream',
      createdAt: SocialProfile._dateFromJson(json['createdAt']),
      sizeBytes: json['sizeBytes'] as int?,
    );
  }
}

enum SocialStoryType { text, image, video }

enum SocialStoryStatus { created, active, expired, deleted }

class SocialStory {
  const SocialStory({
    required this.storyId,
    required this.ownerId,
    required this.contentType,
    required this.createdAt,
    required this.expiresAt,
    this.text,
    this.mediaUrl,
    this.storagePath,
    this.mimeType,
    this.sizeBytes,
    this.visibility = SocialVisibility.public,
    this.status = SocialStoryStatus.active,
    this.isDeleted = false,
  });

  final String storyId;
  final String ownerId;
  final SocialStoryType contentType;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? text;
  final String? mediaUrl;
  final String? storagePath;
  final String? mimeType;
  final int? sizeBytes;
  final SocialVisibility visibility;
  final SocialStoryStatus status;
  final bool isDeleted;

  bool get isExpired =>
      status == SocialStoryStatus.expired ||
      status == SocialStoryStatus.deleted ||
      isDeleted ||
      DateTime.now().toUtc().isAfter(expiresAt.toUtc());

  SocialStory copyWith({
    String? storyId,
    String? ownerId,
    SocialStoryType? contentType,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? text,
    String? mediaUrl,
    String? storagePath,
    String? mimeType,
    int? sizeBytes,
    SocialVisibility? visibility,
    SocialStoryStatus? status,
    bool? isDeleted,
  }) {
    return SocialStory(
      storyId: storyId ?? this.storyId,
      ownerId: ownerId ?? this.ownerId,
      contentType: contentType ?? this.contentType,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      text: text ?? this.text,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      storagePath: storagePath ?? this.storagePath,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      visibility: visibility ?? this.visibility,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'storyId': storyId,
        'ownerId': ownerId,
        'contentType': contentType.name,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'expiresAt': expiresAt.toUtc().toIso8601String(),
        'text': text,
        'mediaUrl': mediaUrl,
        'storagePath': storagePath,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
        'visibility': visibility.name,
        'status': status.name,
        'isDeleted': isDeleted,
      };

  factory SocialStory.fromJson(Map<String, dynamic> json) {
    return SocialStory(
      storyId: json['storyId'] as String? ?? json['id'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      contentType: _storyTypeFromJson(json['contentType'] as String? ?? 'text'),
      createdAt: SocialProfile._dateFromJson(json['createdAt']),
      expiresAt: SocialProfile._dateFromJson(json['expiresAt']),
      text: json['text'] as String?,
      mediaUrl: json['mediaUrl'] as String?,
      storagePath: json['storagePath'] as String?,
      mimeType: json['mimeType'] as String?,
      sizeBytes: json['sizeBytes'] as int?,
      visibility: SocialPost._visibilityFromJson(
          json['visibility'] as String? ?? 'public'),
      status: _storyStatusFromJson(json['status'] as String? ?? 'active'),
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  static SocialStoryType _storyTypeFromJson(String raw) {
    switch (raw) {
      case 'image':
        return SocialStoryType.image;
      case 'video':
        return SocialStoryType.video;
      case 'text':
      default:
        return SocialStoryType.text;
    }
  }

  static SocialStoryStatus _storyStatusFromJson(String raw) {
    switch (raw) {
      case 'created':
        return SocialStoryStatus.created;
      case 'expired':
        return SocialStoryStatus.expired;
      case 'deleted':
        return SocialStoryStatus.deleted;
      case 'active':
      default:
        return SocialStoryStatus.active;
    }
  }

  static String buildStoryId(String ownerId, DateTime createdAt) {
    final stamp = createdAt.toUtc().millisecondsSinceEpoch;
    return 'story:$ownerId:$stamp';
  }

  static String sanitizeText(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'text', 'Story text cannot be empty.');
    }
    if (trimmed.length > 280) {
      throw ArgumentError.value(
        value,
        'text',
        'Story text exceeds the 280-character limit.',
      );
    }
    return trimmed;
  }
}

class SocialConversation {
  const SocialConversation({
    required this.id,
    required this.participantIds,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageId,
    this.lastMessagePreview,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.blocked = false,
  });

  final String id;
  final List<String> participantIds;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastMessageId;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool blocked;

  SocialConversation copyWith({
    String? id,
    List<String>? participantIds,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastMessageId,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    int? unreadCount,
    bool? blocked,
  }) {
    return SocialConversation(
      id: id ?? this.id,
      participantIds: participantIds ?? List<String>.from(this.participantIds),
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      blocked: blocked ?? this.blocked,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'participantIds': participantIds,
        'createdBy': createdBy,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'lastMessageId': lastMessageId,
        'lastMessagePreview': lastMessagePreview,
        'lastMessageAt': lastMessageAt?.toUtc().toIso8601String(),
        'unreadCount': unreadCount,
        'blocked': blocked,
      };

  factory SocialConversation.fromJson(Map<String, dynamic> json) {
    return SocialConversation(
      id: json['id'] as String,
      participantIds: List<String>.from(
          (json['participantIds'] as List<dynamic>? ?? const <dynamic>[])),
      createdBy: json['createdBy'] as String? ?? '',
      createdAt: SocialProfile._dateFromJson(json['createdAt']),
      updatedAt: SocialProfile._dateFromJson(json['updatedAt']),
      lastMessageId: json['lastMessageId'] as String?,
      lastMessagePreview: json['lastMessagePreview'] as String?,
      lastMessageAt: json['lastMessageAt'] == null
          ? null
          : SocialProfile._dateFromJson(json['lastMessageAt']),
      unreadCount: json['unreadCount'] as int? ?? 0,
      blocked: json['blocked'] as bool? ?? false,
    );
  }

  static String buildConversationId(String userA, String userB) {
    final ids = <String>[userA, userB]..sort();
    return 'dm:${ids.first}:${ids.last}';
  }
}

class SocialMessage {
  const SocialMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  SocialMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? text,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return SocialMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'text': text,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'isDeleted': isDeleted,
      };

  factory SocialMessage.fromJson(Map<String, dynamic> json) {
    return SocialMessage(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      text: json['text'] as String? ?? '',
      createdAt: SocialProfile._dateFromJson(json['createdAt']),
      updatedAt: SocialProfile._dateFromJson(json['updatedAt']),
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  static String sanitizeText(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'text', 'Message text cannot be empty.');
    }
    if (trimmed.length > 2000) {
      throw ArgumentError.value(
        value,
        'text',
        'Message text exceeds the 2000-character limit.',
      );
    }
    return trimmed;
  }

  static String buildMessageId(
      String conversationId, String senderId, DateTime createdAt) {
    return 'msg:$conversationId:$senderId:${createdAt.millisecondsSinceEpoch}';
  }
}

enum SocialGroupRole { owner, admin, moderator, member, banned }

class SocialGroup {
  const SocialGroup({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.isPrivate = false,
    this.memberRoles = const <String, String>{},
    this.bannedUserIds = const <String>[],
  });

  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPrivate;
  final Map<String, String> memberRoles;
  final List<String> bannedUserIds;

  List<String> get memberIds => memberRoles.keys.toList()..sort();

  bool isMember(String userId) => memberRoles.containsKey(userId);

  bool isBanned(String userId) => bannedUserIds.contains(userId);

  String? roleFor(String userId) => memberRoles[userId];

  SocialGroup copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPrivate,
    Map<String, String>? memberRoles,
    List<String>? bannedUserIds,
  }) {
    return SocialGroup(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPrivate: isPrivate ?? this.isPrivate,
      memberRoles: memberRoles ?? Map<String, String>.from(this.memberRoles),
      bannedUserIds: bannedUserIds ?? List<String>.from(this.bannedUserIds),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerId': ownerId,
        'name': name,
        'description': description,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'isPrivate': isPrivate,
        'memberRoles': memberRoles,
        'bannedUserIds': bannedUserIds,
      };

  factory SocialGroup.fromJson(Map<String, dynamic> json) {
    final rolesMap = json['memberRoles'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final normalizedRoles = <String, String>{};
    for (final entry in rolesMap.entries) {
      normalizedRoles[entry.key] = entry.value.toString();
    }
    return SocialGroup(
      id: json['id'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      name: json['name'] as String? ?? 'Group',
      description: json['description'] as String?,
      createdAt: SocialProfile._dateFromJson(json['createdAt']),
      updatedAt: SocialProfile._dateFromJson(json['updatedAt']),
      isPrivate: json['isPrivate'] as bool? ?? false,
      memberRoles: normalizedRoles,
      bannedUserIds: List<String>.from(
        (json['bannedUserIds'] as List<dynamic>? ?? const <dynamic>[]),
      ),
    );
  }

  static String buildGroupId(String ownerId, DateTime createdAt) =>
      'group:$ownerId:${createdAt.millisecondsSinceEpoch}';

  static String sanitizeName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'name', 'Group name cannot be empty.');
    }
    if (trimmed.length > 80) {
      throw ArgumentError.value(
        value,
        'name',
        'Group name exceeds the 80-character limit.',
      );
    }
    return trimmed;
  }
}

class SocialGroupMember {
  const SocialGroupMember({
    required this.groupId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.isBanned = false,
  });

  final String groupId;
  final String userId;
  final SocialGroupRole role;
  final DateTime joinedAt;
  final bool isBanned;

  SocialGroupMember copyWith({
    String? groupId,
    String? userId,
    SocialGroupRole? role,
    DateTime? joinedAt,
    bool? isBanned,
  }) {
    return SocialGroupMember(
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      isBanned: isBanned ?? this.isBanned,
    );
  }

  Map<String, dynamic> toJson() => {
        'groupId': groupId,
        'userId': userId,
        'role': role.name,
        'joinedAt': joinedAt.toUtc().toIso8601String(),
        'isBanned': isBanned,
      };

  factory SocialGroupMember.fromJson(Map<String, dynamic> json) {
    return SocialGroupMember(
      groupId: json['groupId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      role: _roleFromJson(json['role'] as String? ?? 'member'),
      joinedAt: SocialProfile._dateFromJson(json['joinedAt']),
      isBanned: json['isBanned'] as bool? ?? false,
    );
  }

  static SocialGroupRole _roleFromJson(String raw) {
    switch (raw) {
      case 'owner':
        return SocialGroupRole.owner;
      case 'admin':
        return SocialGroupRole.admin;
      case 'moderator':
        return SocialGroupRole.moderator;
      case 'banned':
        return SocialGroupRole.banned;
      case 'member':
      default:
        return SocialGroupRole.member;
    }
  }
}

class SocialGroupMessage {
  const SocialGroupMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  final String id;
  final String groupId;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  SocialGroupMessage copyWith({
    String? id,
    String? groupId,
    String? senderId,
    String? text,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return SocialGroupMessage(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'senderId': senderId,
        'text': text,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'isDeleted': isDeleted,
      };

  factory SocialGroupMessage.fromJson(Map<String, dynamic> json) {
    return SocialGroupMessage(
      id: json['id'] as String? ?? '',
      groupId: json['groupId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      text: json['text'] as String? ?? '',
      createdAt: SocialProfile._dateFromJson(json['createdAt']),
      updatedAt: SocialProfile._dateFromJson(json['updatedAt']),
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  static String sanitizeText(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(
          value, 'text', 'Group message cannot be empty.');
    }
    if (trimmed.length > 2000) {
      throw ArgumentError.value(
        value,
        'text',
        'Group message exceeds the 2000-character limit.',
      );
    }
    return trimmed;
  }

  static String buildMessageId(
          String groupId, String senderId, DateTime createdAt) =>
      'group-msg:$groupId:$senderId:${createdAt.millisecondsSinceEpoch}';
}

class SocialRepositoryException implements Exception {
  const SocialRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'SocialRepositoryException: $message';
}

String socialJsonEncode(Object value) => jsonEncode(value);

Object? socialJsonDecode(String source) => jsonDecode(source);
