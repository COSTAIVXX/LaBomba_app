import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import 'social_domain.dart';

abstract class SocialProfileRepository {
  Future<SocialProfile?> getProfile(String id);
  Future<void> upsertProfile(SocialProfile profile);
  Future<List<SocialProfile>> searchProfiles(
    String query, {
    int limit = 20,
    String? viewerId,
  });
}

abstract class SocialPostRepository {
  Future<SocialPost?> getPost(String id);
  Future<void> upsertPost(SocialPost post);
  Future<bool> deletePost(String id);
  Future<List<SocialPost>> listFeed({
    int limit = 20,
    String? afterId,
    SocialFeedFilter filter = SocialFeedFilter.recent,
    String? viewerId,
  });
  Future<List<SocialPost>> listPostsByAuthor(String authorId, {int limit = 20});
}

abstract class SocialCommentRepository {
  Future<List<SocialComment>> listComments(String postId, {int limit = 20});
  Future<void> upsertComment(SocialComment comment);
  Future<bool> deleteComment(String postId, String commentId);
}

abstract class SocialReactionRepository {
  Future<SocialReaction?> getReaction(String postId, String userId);
  Future<void> upsertReaction(SocialReaction reaction);
  Future<void> deleteReaction(String postId, String userId);
  Future<List<SocialReaction>> listReactions(String postId, {int limit = 20});
}

abstract class SocialRelationRepository {
  Future<SocialRelation?> getRelation({
    required String sourceId,
    required String targetId,
    required SocialRelationKind kind,
  });
  Future<void> upsertRelation(SocialRelation relation);
  Future<void> deleteRelation({
    required String sourceId,
    required String targetId,
    required SocialRelationKind kind,
  });
  Future<List<SocialRelation>> listRelations({
    required String userId,
    required SocialRelationKind kind,
    int limit = 50,
  });
}

abstract class SocialNotificationRepository {
  Future<List<SocialNotification>> listNotifications(
    String recipientId, {
    int limit = 20,
  });
  Future<void> upsertNotification(SocialNotification notification);
  Future<void> markRead(String notificationId);
}

abstract class SocialMediaRepository {
  Future<SocialMediaMetadata?> getMedia(String id);
  Future<void> upsertMedia(SocialMediaMetadata media);
  Future<void> deleteMedia(String id);
}

abstract class SocialStoryRepository {
  Future<SocialStory?> getStory(String storyId);
  Future<void> upsertStory(SocialStory story);
  Future<bool> deleteStory(String storyId);
  Future<List<SocialStory>> listStoriesByOwner(
    String ownerId, {
    int limit = 20,
  });
  Future<List<SocialStory>> listVisibleStories({
    required String viewerId,
    int limit = 20,
  });
  Stream<List<SocialStory>> watchVisibleStories({
    required String viewerId,
    int limit = 20,
  });
}

abstract class SocialConversationRepository {
  Future<SocialConversation?> getConversation(String conversationId);
  Future<void> upsertConversation(SocialConversation conversation);
  Future<List<SocialConversation>> listConversations(
    String userId, {
    int limit = 50,
  });
  Stream<List<SocialConversation>> watchConversations(
    String userId, {
    int limit = 50,
  });
}

abstract class SocialMessageRepository {
  Future<SocialMessage?> getMessage(String conversationId, String messageId);
  Future<void> upsertMessage(SocialMessage message);
  Future<List<SocialMessage>> listMessages(
    String conversationId, {
    int limit = 50,
  });
  Stream<List<SocialMessage>> watchMessages(
    String conversationId, {
    int limit = 50,
  });
}

abstract class SocialGroupRepository {
  Future<SocialGroup?> getGroup(String groupId);
  Future<void> upsertGroup(SocialGroup group);
  Future<List<SocialGroup>> listGroups({
    String? ownerId,
    int limit = 50,
    bool includePrivate = false,
  });
}

abstract class SocialGroupMembershipRepository {
  Future<SocialGroupMember?> getMembership(String groupId, String userId);
  Future<void> upsertMembership(SocialGroupMember membership);
  Future<void> deleteMembership(String groupId, String userId);
  Future<List<SocialGroupMember>> listMembers(String groupId,
      {int limit = 200});
}

abstract class SocialGroupMessageRepository {
  Future<SocialGroupMessage?> getMessage(String groupId, String messageId);
  Future<void> upsertMessage(SocialGroupMessage message);
  Future<List<SocialGroupMessage>> listMessages(String groupId,
      {int limit = 50});
  Stream<List<SocialGroupMessage>> watchMessages(String groupId,
      {int limit = 50});
}

class InMemorySocialProfileRepository implements SocialProfileRepository {
  final Map<String, SocialProfile> _profiles = <String, SocialProfile>{};

  @override
  Future<SocialProfile?> getProfile(String id) async => _profiles[id];

  @override
  Future<void> upsertProfile(SocialProfile profile) async {
    _profiles[profile.id] = profile;
  }

  @override
  Future<List<SocialProfile>> searchProfiles(
    String query, {
    int limit = 20,
    String? viewerId,
  }) async {
    final normalized = query.trim().toLowerCase();
    final matches = _profiles.values.where((profile) {
      if (profile.isBlocked) {
        return false;
      }
      if (profile.isPrivate && viewerId != profile.id) {
        return false;
      }
      if (normalized.isEmpty) {
        return true;
      }
      final username = profile.username.toLowerCase();
      final displayName = profile.displayName.toLowerCase();
      return username.contains(normalized) || displayName.contains(normalized);
    }).toList();

    matches.sort((left, right) => left.displayName
        .toLowerCase()
        .compareTo(right.displayName.toLowerCase()));
    return matches.take(limit).toList();
  }
}

class InMemorySocialPostRepository implements SocialPostRepository {
  final Map<String, SocialPost> _posts = <String, SocialPost>{};

  @override
  Future<SocialPost?> getPost(String id) async => _posts[id];

  @override
  Future<void> upsertPost(SocialPost post) async {
    _posts[post.id] = post;
  }

  @override
  Future<bool> deletePost(String id) async {
    final existed = _posts.containsKey(id);
    if (existed) {
      _posts.remove(id);
    }
    return existed;
  }

  @override
  Future<List<SocialPost>> listFeed({
    int limit = 20,
    String? afterId,
    SocialFeedFilter filter = SocialFeedFilter.recent,
    String? viewerId,
  }) async {
    final posts = _posts.values.where((post) => !post.isDeleted).toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));

    final filteredPosts = posts.where((post) {
      if (filter == SocialFeedFilter.mine && viewerId != null) {
        return post.authorId == viewerId;
      }
      return true;
    }).toList();

    if (afterId == null) {
      return filteredPosts.take(limit).toList();
    }

    final skipIndex = filteredPosts.indexWhere((post) => post.id == afterId);
    if (skipIndex < 0) {
      return filteredPosts.take(limit).toList();
    }

    return filteredPosts.skip(skipIndex + 1).take(limit).toList();
  }

  @override
  Future<List<SocialPost>> listPostsByAuthor(String authorId,
      {int limit = 20}) async {
    final posts = _posts.values
        .where((post) => post.authorId == authorId && !post.isDeleted)
        .toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return posts.take(limit).toList();
  }
}

class InMemorySocialCommentRepository implements SocialCommentRepository {
  final Map<String, Map<String, SocialComment>> _comments =
      <String, Map<String, SocialComment>>{};

  @override
  Future<List<SocialComment>> listComments(String postId,
      {int limit = 20}) async {
    final postComments = _comments[postId] ?? <String, SocialComment>{};
    final values = postComments.values
        .where((comment) => !comment.isDeleted)
        .toList()
      ..sort((left, right) => left.createdAt.compareTo(right.createdAt));
    return values.take(limit).toList();
  }

  @override
  Future<void> upsertComment(SocialComment comment) async {
    final bucket =
        _comments.putIfAbsent(comment.postId, () => <String, SocialComment>{});
    bucket[comment.id] = comment;
  }

  @override
  Future<bool> deleteComment(String postId, String commentId) async {
    final bucket = _comments[postId];
    if (bucket == null) {
      return false;
    }
    final existed = bucket.containsKey(commentId);
    if (existed) {
      bucket.remove(commentId);
    }
    return existed;
  }
}

class InMemorySocialReactionRepository implements SocialReactionRepository {
  final Map<String, Map<String, SocialReaction>> _reactions =
      <String, Map<String, SocialReaction>>{};

  @override
  Future<SocialReaction?> getReaction(String postId, String userId) async {
    final postReactions = _reactions[postId] ?? <String, SocialReaction>{};
    return postReactions[SocialReaction.buildReactionId(postId, userId)];
  }

  @override
  Future<void> upsertReaction(SocialReaction reaction) async {
    final bucket = _reactions.putIfAbsent(
        reaction.postId, () => <String, SocialReaction>{});
    bucket[reaction.id] = reaction;
  }

  @override
  Future<void> deleteReaction(String postId, String userId) async {
    final bucket = _reactions[postId];
    if (bucket == null) {
      return;
    }
    final id = SocialReaction.buildReactionId(postId, userId);
    bucket.remove(id);
  }

  @override
  Future<List<SocialReaction>> listReactions(String postId,
      {int limit = 20}) async {
    final bucket = _reactions[postId] ?? <String, SocialReaction>{};
    final values = bucket.values.toList()
      ..sort((left, right) => left.createdAt.compareTo(right.createdAt));
    return values.take(limit).toList();
  }
}

class InMemorySocialRelationRepository implements SocialRelationRepository {
  final Map<String, SocialRelation> _relations = <String, SocialRelation>{};

  @override
  Future<SocialRelation?> getRelation({
    required String sourceId,
    required String targetId,
    required SocialRelationKind kind,
  }) async {
    final id = SocialRelation.buildRelationId(sourceId, targetId, kind);
    return _relations[id];
  }

  @override
  Future<void> upsertRelation(SocialRelation relation) async {
    _relations[relation.id] = relation;
  }

  @override
  Future<void> deleteRelation({
    required String sourceId,
    required String targetId,
    required SocialRelationKind kind,
  }) async {
    final id = SocialRelation.buildRelationId(sourceId, targetId, kind);
    _relations.remove(id);
  }

  @override
  Future<List<SocialRelation>> listRelations({
    required String userId,
    required SocialRelationKind kind,
    int limit = 50,
  }) async {
    final values = _relations.values
        .where((relation) =>
            relation.kind == kind &&
            (relation.sourceId == userId || relation.targetId == userId))
        .toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return values.take(limit).toList();
  }
}

class InMemorySocialNotificationRepository
    implements SocialNotificationRepository {
  final Map<String, SocialNotification> _notifications =
      <String, SocialNotification>{};

  @override
  Future<List<SocialNotification>> listNotifications(
    String recipientId, {
    int limit = 20,
  }) async {
    final values = _notifications.values
        .where((notification) => notification.recipientId == recipientId)
        .toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return values.take(limit).toList();
  }

  @override
  Future<void> upsertNotification(SocialNotification notification) async {
    _notifications[notification.id] = notification;
  }

  @override
  Future<void> markRead(String notificationId) async {
    final notification = _notifications[notificationId];
    if (notification == null) {
      return;
    }
    _notifications[notificationId] = notification.copyWith(
      isRead: true,
      readAt: DateTime.now().toUtc(),
    );
  }
}

class InMemorySocialMediaRepository implements SocialMediaRepository {
  final Map<String, SocialMediaMetadata> _media =
      <String, SocialMediaMetadata>{};

  @override
  Future<SocialMediaMetadata?> getMedia(String id) async => _media[id];

  @override
  Future<void> upsertMedia(SocialMediaMetadata media) async {
    _media[media.id] = media;
  }

  @override
  Future<void> deleteMedia(String id) async {
    _media.remove(id);
  }
}

class InMemorySocialStoryRepository implements SocialStoryRepository {
  final Map<String, SocialStory> _stories = <String, SocialStory>{};

  @override
  Future<SocialStory?> getStory(String storyId) async => _stories[storyId];

  @override
  Future<void> upsertStory(SocialStory story) async {
    _stories[story.storyId] = story;
  }

  @override
  Future<bool> deleteStory(String storyId) async {
    final existed = _stories.containsKey(storyId);
    if (existed) {
      _stories.remove(storyId);
    }
    return existed;
  }

  @override
  Future<List<SocialStory>> listStoriesByOwner(
    String ownerId, {
    int limit = 20,
  }) async {
    final values = _stories.values
        .where((story) => story.ownerId == ownerId && !story.isDeleted)
        .toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return values.take(limit).toList();
  }

  @override
  Future<List<SocialStory>> listVisibleStories({
    required String viewerId,
    int limit = 20,
  }) async {
    final values = _stories.values
        .where((story) =>
            !story.isDeleted &&
            story.status == SocialStoryStatus.active &&
            !story.isExpired &&
            story.ownerId != viewerId)
        .toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return values.take(limit).toList();
  }

  @override
  Stream<List<SocialStory>> watchVisibleStories({
    required String viewerId,
    int limit = 20,
  }) async* {
    yield await listVisibleStories(viewerId: viewerId, limit: limit);
  }
}

class InMemorySocialConversationRepository
    implements SocialConversationRepository {
  final Map<String, SocialConversation> _conversations =
      <String, SocialConversation>{};

  @override
  Future<SocialConversation?> getConversation(String conversationId) async =>
      _conversations[conversationId];

  @override
  Future<void> upsertConversation(SocialConversation conversation) async {
    _conversations[conversation.id] = conversation;
  }

  @override
  Future<List<SocialConversation>> listConversations(
    String userId, {
    int limit = 50,
  }) async {
    final items = _conversations.values
        .where((conversation) => conversation.participantIds.contains(userId))
        .toList()
      ..sort((left, right) => (right.lastMessageAt ?? right.updatedAt)
          .compareTo(left.lastMessageAt ?? left.updatedAt));
    return items.take(limit).toList();
  }

  @override
  Stream<List<SocialConversation>> watchConversations(
    String userId, {
    int limit = 50,
  }) async* {
    yield await listConversations(userId, limit: limit);
  }
}

class InMemorySocialMessageRepository implements SocialMessageRepository {
  final Map<String, Map<String, SocialMessage>> _messages =
      <String, Map<String, SocialMessage>>{};

  @override
  Future<SocialMessage?> getMessage(
          String conversationId, String messageId) async =>
      (_messages[conversationId] ?? <String, SocialMessage>{})[messageId];

  @override
  Future<void> upsertMessage(SocialMessage message) async {
    final bucket = _messages.putIfAbsent(
        message.conversationId, () => <String, SocialMessage>{});
    bucket[message.id] = message;
  }

  @override
  Future<List<SocialMessage>> listMessages(
    String conversationId, {
    int limit = 50,
  }) async {
    final values = (_messages[conversationId] ?? <String, SocialMessage>{})
        .values
        .where((message) => !message.isDeleted)
        .toList()
      ..sort((left, right) => left.createdAt.compareTo(right.createdAt));
    return values.take(limit).toList();
  }

  @override
  Stream<List<SocialMessage>> watchMessages(String conversationId,
      {int limit = 50}) async* {
    yield await listMessages(conversationId, limit: limit);
  }
}

class FirestoreSocialStoryRepository implements SocialStoryRepository {
  FirestoreSocialStoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _stories =>
      _firestore.collection('stories');

  @override
  Future<SocialStory?> getStory(String storyId) async {
    final snapshot = await _stories.doc(storyId).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return SocialStory.fromJson({'storyId': snapshot.id, ...snapshot.data()!});
  }

  @override
  Future<void> upsertStory(SocialStory story) async {
    await _stories
        .doc(story.storyId)
        .set(story.toJson(), SetOptions(merge: true));
  }

  @override
  Future<bool> deleteStory(String storyId) async {
    final doc = await _stories.doc(storyId).get();
    if (!doc.exists) {
      return false;
    }
    await _stories.doc(storyId).delete();
    return true;
  }

  @override
  Future<List<SocialStory>> listStoriesByOwner(
    String ownerId, {
    int limit = 20,
  }) async {
    final snapshot =
        await _stories.where('ownerId', isEqualTo: ownerId).limit(limit).get();
    return snapshot.docs
        .map((doc) => SocialStory.fromJson({'storyId': doc.id, ...doc.data()}))
        .where((story) => !story.isDeleted)
        .toList();
  }

  @override
  Future<List<SocialStory>> listVisibleStories({
    required String viewerId,
    int limit = 20,
  }) async {
    final snapshot = await _stories
        .where('status', isEqualTo: SocialStoryStatus.active.name)
        .limit(limit * 5)
        .get();
    return snapshot.docs
        .map((doc) => SocialStory.fromJson({'storyId': doc.id, ...doc.data()}))
        .where((story) =>
            !story.isDeleted && !story.isExpired && story.ownerId != viewerId)
        .take(limit)
        .toList();
  }

  @override
  Stream<List<SocialStory>> watchVisibleStories({
    required String viewerId,
    int limit = 20,
  }) {
    return _stories
        .where('status', isEqualTo: SocialStoryStatus.active.name)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                SocialStory.fromJson({'storyId': doc.id, ...doc.data()}))
            .where((story) =>
                !story.isDeleted &&
                !story.isExpired &&
                story.ownerId != viewerId)
            .toList());
  }
}

class FirestoreSocialProfileRepository implements SocialProfileRepository {
  FirestoreSocialProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _firestore.collection('profiles');

  @override
  Future<SocialProfile?> getProfile(String id) async {
    final snapshot = await _profiles.doc(id).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return SocialProfile.fromJson({
      'id': snapshot.id,
      ...snapshot.data()!,
    });
  }

  @override
  Future<void> upsertProfile(SocialProfile profile) async {
    await _profiles
        .doc(profile.id)
        .set(profile.toJson(), SetOptions(merge: true));
  }

  @override
  Future<List<SocialProfile>> searchProfiles(
    String query, {
    int limit = 20,
    String? viewerId,
  }) async {
    final normalized = query.trim().toLowerCase();
    final snapshot = await _profiles.limit(limit * 3).get();
    final values = snapshot.docs
        .map((doc) => SocialProfile.fromJson({'id': doc.id, ...doc.data()}))
        .where((profile) {
      if (profile.isBlocked) {
        return false;
      }
      if (profile.isPrivate && viewerId != profile.id) {
        return false;
      }
      if (normalized.isEmpty) {
        return true;
      }
      final username = profile.username.toLowerCase();
      final displayName = profile.displayName.toLowerCase();
      return username.contains(normalized) || displayName.contains(normalized);
    }).toList();
    return values.take(limit).toList();
  }
}

class FirestoreSocialPostRepository implements SocialPostRepository {
  FirestoreSocialPostRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('posts');

  @override
  Future<SocialPost?> getPost(String id) async {
    final snapshot = await _posts.doc(id).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return SocialPost.fromJson({'id': snapshot.id, ...snapshot.data()!});
  }

  @override
  Future<void> upsertPost(SocialPost post) async {
    await _posts.doc(post.id).set(post.toJson(), SetOptions(merge: true));
  }

  @override
  Future<bool> deletePost(String id) async {
    final doc = await _posts.doc(id).get();
    if (!doc.exists) {
      return false;
    }
    await _posts.doc(id).delete();
    return true;
  }

  @override
  Future<List<SocialPost>> listFeed({
    int limit = 20,
    String? afterId,
    SocialFeedFilter filter = SocialFeedFilter.recent,
    String? viewerId,
  }) async {
    Query<Map<String, dynamic>> query =
        _posts.orderBy('createdAt', descending: true);

    if (filter == SocialFeedFilter.mine && viewerId != null) {
      query = query.where('authorId', isEqualTo: viewerId);
    }

    query = query.limit(limit);

    if (afterId != null) {
      final cursorDoc = await _posts.doc(afterId).get();
      if (cursorDoc.exists) {
        query = query.startAfterDocument(cursorDoc);
      }
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => SocialPost.fromJson({'id': doc.id, ...doc.data()}))
        .where((post) => !post.isDeleted)
        .toList();
  }

  @override
  Future<List<SocialPost>> listPostsByAuthor(String authorId,
      {int limit = 20}) async {
    final snapshot = await _posts
        .where('authorId', isEqualTo: authorId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => SocialPost.fromJson({'id': doc.id, ...doc.data()}))
        .where((post) => !post.isDeleted)
        .toList();
  }
}

class FirestoreSocialCommentRepository implements SocialCommentRepository {
  FirestoreSocialCommentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> commentsFor(String postId) =>
      _firestore.collection('posts').doc(postId).collection('comments');

  @override
  Future<List<SocialComment>> listComments(String postId,
      {int limit = 20}) async {
    final snapshot = await commentsFor(postId)
        .orderBy('createdAt', descending: false)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => SocialComment.fromJson({'id': doc.id, ...doc.data()}))
        .where((comment) => !comment.isDeleted)
        .toList();
  }

  @override
  Future<void> upsertComment(SocialComment comment) async {
    await commentsFor(comment.postId)
        .doc(comment.id)
        .set(comment.toJson(), SetOptions(merge: true));
  }

  @override
  Future<bool> deleteComment(String postId, String commentId) async {
    final doc = await commentsFor(postId).doc(commentId).get();
    if (!doc.exists) {
      return false;
    }
    await commentsFor(postId).doc(commentId).delete();
    return true;
  }
}

class FirestoreSocialConversationRepository
    implements SocialConversationRepository {
  FirestoreSocialConversationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _firestore.collection('conversations');

  @override
  Future<SocialConversation?> getConversation(String conversationId) async {
    final snapshot = await _conversations.doc(conversationId).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return SocialConversation.fromJson(
        {'id': snapshot.id, ...snapshot.data()!});
  }

  @override
  Future<void> upsertConversation(SocialConversation conversation) async {
    await _conversations
        .doc(conversation.id)
        .set(conversation.toJson(), SetOptions(merge: true));
  }

  @override
  Future<List<SocialConversation>> listConversations(
    String userId, {
    int limit = 50,
  }) async {
    final snapshot = await _conversations
        .where('participantIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map(
            (doc) => SocialConversation.fromJson({'id': doc.id, ...doc.data()}))
        .toList();
  }

  @override
  Stream<List<SocialConversation>> watchConversations(
    String userId, {
    int limit = 50,
  }) {
    return _conversations
        .where('participantIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                SocialConversation.fromJson({'id': doc.id, ...doc.data()}))
            .toList());
  }
}

class FirestoreSocialMessageRepository implements SocialMessageRepository {
  FirestoreSocialMessageRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> messagesFor(
          String conversationId) =>
      _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages');

  @override
  Future<SocialMessage?> getMessage(
      String conversationId, String messageId) async {
    final snapshot = await messagesFor(conversationId).doc(messageId).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return SocialMessage.fromJson({'id': snapshot.id, ...snapshot.data()!});
  }

  @override
  Future<void> upsertMessage(SocialMessage message) async {
    await messagesFor(message.conversationId)
        .doc(message.id)
        .set(message.toJson(), SetOptions(merge: true));
  }

  @override
  Future<List<SocialMessage>> listMessages(
    String conversationId, {
    int limit = 50,
  }) async {
    final snapshot = await messagesFor(conversationId)
        .orderBy('createdAt', descending: false)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => SocialMessage.fromJson({'id': doc.id, ...doc.data()}))
        .where((message) => !message.isDeleted)
        .toList();
  }

  @override
  Stream<List<SocialMessage>> watchMessages(
    String conversationId, {
    int limit = 50,
  }) {
    return messagesFor(conversationId)
        .orderBy('createdAt', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SocialMessage.fromJson({'id': doc.id, ...doc.data()}))
            .where((message) => !message.isDeleted)
            .toList());
  }
}

class FirestoreSocialReactionRepository implements SocialReactionRepository {
  FirestoreSocialReactionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> reactionsFor(String postId) =>
      _firestore.collection('posts').doc(postId).collection('reactions');

  @override
  Future<SocialReaction?> getReaction(String postId, String userId) async {
    final id = SocialReaction.buildReactionId(postId, userId);
    final snapshot = await reactionsFor(postId).doc(id).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return SocialReaction.fromJson({'id': snapshot.id, ...snapshot.data()!});
  }

  @override
  Future<void> upsertReaction(SocialReaction reaction) async {
    await reactionsFor(reaction.postId)
        .doc(reaction.id)
        .set(reaction.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteReaction(String postId, String userId) async {
    final id = SocialReaction.buildReactionId(postId, userId);
    final doc = await reactionsFor(postId).doc(id).get();
    if (!doc.exists) {
      return;
    }
    await reactionsFor(postId).doc(id).delete();
  }

  @override
  Future<List<SocialReaction>> listReactions(String postId,
      {int limit = 20}) async {
    final snapshot = await reactionsFor(postId)
        .orderBy('createdAt', descending: false)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => SocialReaction.fromJson({'id': doc.id, ...doc.data()}))
        .toList();
  }
}

class FirestoreSocialRelationRepository implements SocialRelationRepository {
  FirestoreSocialRelationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _relations =>
      _firestore.collection('relations');

  @override
  Future<SocialRelation?> getRelation({
    required String sourceId,
    required String targetId,
    required SocialRelationKind kind,
  }) async {
    final id = SocialRelation.buildRelationId(sourceId, targetId, kind);
    final snapshot = await _relations.doc(id).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return SocialRelation.fromJson({'id': snapshot.id, ...snapshot.data()!});
  }

  @override
  Future<void> upsertRelation(SocialRelation relation) async {
    await _relations
        .doc(relation.id)
        .set(relation.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteRelation({
    required String sourceId,
    required String targetId,
    required SocialRelationKind kind,
  }) async {
    final id = SocialRelation.buildRelationId(sourceId, targetId, kind);
    final doc = await _relations.doc(id).get();
    if (!doc.exists) {
      return;
    }
    await _relations.doc(id).delete();
  }

  @override
  Future<List<SocialRelation>> listRelations({
    required String userId,
    required SocialRelationKind kind,
    int limit = 50,
  }) async {
    final snapshot = await _relations
        .where('sourceId', isEqualTo: userId)
        .where('kind', isEqualTo: kind.name)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => SocialRelation.fromJson({'id': doc.id, ...doc.data()}))
        .toList();
  }
}

class FirestoreSocialNotificationRepository
    implements SocialNotificationRepository {
  FirestoreSocialNotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> notificationsFor(
          String recipientId) =>
      _firestore
          .collection('users')
          .doc(recipientId)
          .collection('notifications');

  @override
  Future<List<SocialNotification>> listNotifications(String recipientId,
      {int limit = 20}) async {
    final snapshot = await notificationsFor(recipientId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map(
            (doc) => SocialNotification.fromJson({'id': doc.id, ...doc.data()}))
        .toList();
  }

  @override
  Future<void> upsertNotification(SocialNotification notification) async {
    await notificationsFor(notification.recipientId)
        .doc(notification.id)
        .set(notification.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> markRead(String notificationId) async {
    final document = await _firestore
        .collectionGroup('notifications')
        .where('id', isEqualTo: notificationId)
        .limit(1)
        .get();

    if (document.docs.isEmpty) {
      return;
    }

    await document.docs.first.reference.update({
      'isRead': true,
      'readAt': DateTime.now().toUtc().toIso8601String(),
    });
  }
}

class FirestoreSocialMediaRepository implements SocialMediaRepository {
  FirestoreSocialMediaRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _media =>
      _firestore.collection('media');

  @override
  Future<SocialMediaMetadata?> getMedia(String id) async {
    final snapshot = await _media.doc(id).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return SocialMediaMetadata.fromJson(
        {'id': snapshot.id, ...snapshot.data()!});
  }

  @override
  Future<void> upsertMedia(SocialMediaMetadata media) async {
    await _media.doc(media.id).set(media.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteMedia(String id) async {
    final doc = await _media.doc(id).get();
    if (!doc.exists) {
      return;
    }
    await _media.doc(id).delete();
  }
}

class InMemorySocialGroupRepository implements SocialGroupRepository {
  final Map<String, SocialGroup> _groups = <String, SocialGroup>{};

  @override
  Future<SocialGroup?> getGroup(String groupId) async => _groups[groupId];

  @override
  Future<void> upsertGroup(SocialGroup group) async {
    _groups[group.id] = group;
  }

  @override
  Future<List<SocialGroup>> listGroups({
    String? ownerId,
    int limit = 50,
    bool includePrivate = false,
  }) async {
    final groups = _groups.values.where((group) {
      if (ownerId != null && group.ownerId != ownerId) {
        return false;
      }
      if (group.isPrivate && !includePrivate) {
        return false;
      }
      return true;
    }).toList()
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    return groups.take(limit).toList();
  }
}

class InMemorySocialGroupMembershipRepository
    implements SocialGroupMembershipRepository {
  final Map<String, SocialGroupMember> _members = <String, SocialGroupMember>{};

  @override
  Future<SocialGroupMember?> getMembership(
      String groupId, String userId) async {
    return _members['${groupId}:$userId'];
  }

  @override
  Future<void> upsertMembership(SocialGroupMember membership) async {
    _members['${membership.groupId}:${membership.userId}'] = membership;
  }

  @override
  Future<void> deleteMembership(String groupId, String userId) async {
    _members.remove('${groupId}:$userId');
  }

  @override
  Future<List<SocialGroupMember>> listMembers(String groupId,
      {int limit = 200}) async {
    final members = _members.values
        .where((member) => member.groupId == groupId)
        .toList()
      ..sort((left, right) => right.joinedAt.compareTo(left.joinedAt));
    return members.take(limit).toList();
  }
}

class InMemorySocialGroupMessageRepository
    implements SocialGroupMessageRepository {
  final Map<String, Map<String, SocialGroupMessage>> _messages =
      <String, Map<String, SocialGroupMessage>>{};

  @override
  Future<SocialGroupMessage?> getMessage(
      String groupId, String messageId) async {
    return (_messages[groupId] ?? <String, SocialGroupMessage>{})[messageId];
  }

  @override
  Future<void> upsertMessage(SocialGroupMessage message) async {
    final bucket = _messages.putIfAbsent(
      message.groupId,
      () => <String, SocialGroupMessage>{},
    );
    bucket[message.id] = message;
  }

  @override
  Future<List<SocialGroupMessage>> listMessages(String groupId,
      {int limit = 50}) async {
    final values = (_messages[groupId] ?? <String, SocialGroupMessage>{})
        .values
        .where((message) => !message.isDeleted)
        .toList()
      ..sort((left, right) => left.createdAt.compareTo(right.createdAt));
    return values.take(limit).toList();
  }

  @override
  Stream<List<SocialGroupMessage>> watchMessages(String groupId,
      {int limit = 50}) async* {
    yield await listMessages(groupId, limit: limit);
  }
}

class FirestoreSocialGroupRepository implements SocialGroupRepository {
  FirestoreSocialGroupRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _groups =>
      _firestore.collection('groups');

  @override
  Future<SocialGroup?> getGroup(String groupId) async {
    final snapshot = await _groups.doc(groupId).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return SocialGroup.fromJson({'id': snapshot.id, ...snapshot.data()!});
  }

  @override
  Future<void> upsertGroup(SocialGroup group) async {
    await _groups.doc(group.id).set(group.toJson(), SetOptions(merge: true));
  }

  @override
  Future<List<SocialGroup>> listGroups({
    String? ownerId,
    int limit = 50,
    bool includePrivate = false,
  }) async {
    Query<Map<String, dynamic>> query =
        _groups.orderBy('updatedAt', descending: true);
    if (ownerId != null) {
      query = query.where('ownerId', isEqualTo: ownerId);
    }
    if (!includePrivate) {
      query = query.where('isPrivate', isEqualTo: false);
    }
    final snapshot = await query.limit(limit).get();
    return snapshot.docs
        .map((doc) => SocialGroup.fromJson({'id': doc.id, ...doc.data()}))
        .toList();
  }
}

class FirestoreSocialGroupMembershipRepository
    implements SocialGroupMembershipRepository {
  FirestoreSocialGroupMembershipRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> membershipsFor(String groupId) =>
      _firestore.collection('groups').doc(groupId).collection('members');

  @override
  Future<SocialGroupMember?> getMembership(
      String groupId, String userId) async {
    final snapshot = await membershipsFor(groupId).doc(userId).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return SocialGroupMember.fromJson(
        {'groupId': groupId, ...snapshot.data()!});
  }

  @override
  Future<void> upsertMembership(SocialGroupMember membership) async {
    await membershipsFor(membership.groupId)
        .doc(membership.userId)
        .set(membership.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteMembership(String groupId, String userId) async {
    final doc = await membershipsFor(groupId).doc(userId).get();
    if (!doc.exists) {
      return;
    }
    await membershipsFor(groupId).doc(userId).delete();
  }

  @override
  Future<List<SocialGroupMember>> listMembers(String groupId,
      {int limit = 200}) async {
    final snapshot = await membershipsFor(groupId)
        .orderBy('joinedAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) =>
            SocialGroupMember.fromJson({'groupId': groupId, ...doc.data()}))
        .toList();
  }
}

class FirestoreSocialGroupMessageRepository
    implements SocialGroupMessageRepository {
  FirestoreSocialGroupMessageRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> messagesFor(String groupId) =>
      _firestore.collection('groups').doc(groupId).collection('messages');

  @override
  Future<SocialGroupMessage?> getMessage(
      String groupId, String messageId) async {
    final snapshot = await messagesFor(groupId).doc(messageId).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return SocialGroupMessage.fromJson(
        {'id': snapshot.id, ...snapshot.data()!});
  }

  @override
  Future<void> upsertMessage(SocialGroupMessage message) async {
    await messagesFor(message.groupId)
        .doc(message.id)
        .set(message.toJson(), SetOptions(merge: true));
  }

  @override
  Future<List<SocialGroupMessage>> listMessages(String groupId,
      {int limit = 50}) async {
    final snapshot = await messagesFor(groupId)
        .orderBy('createdAt', descending: false)
        .limit(limit)
        .get();
    return snapshot.docs
        .map(
            (doc) => SocialGroupMessage.fromJson({'id': doc.id, ...doc.data()}))
        .where((message) => !message.isDeleted)
        .toList();
  }

  @override
  Stream<List<SocialGroupMessage>> watchMessages(String groupId,
      {int limit = 50}) {
    return messagesFor(groupId)
        .orderBy('createdAt', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                SocialGroupMessage.fromJson({'id': doc.id, ...doc.data()}))
            .where((message) => !message.isDeleted)
            .toList());
  }
}

class SocialIdFactory {
  const SocialIdFactory();

  String makePostId() => const Uuid().v4();
  String makeCommentId() => const Uuid().v4();
  String makeNotificationId() => const Uuid().v4();
  String makeMediaId() => const Uuid().v4();
  String makeGroupId() => const Uuid().v4();
}
