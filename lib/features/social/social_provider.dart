import 'package:flutter/foundation.dart';

import '../../services/auth_service.dart';
import '../../services/observability_service.dart';
import 'social_domain.dart';
import 'social_repositories.dart';

enum SocialFeedState {
  initial,
  loading,
  success,
  empty,
  error,
  loadingMore,
}

class SocialProvider extends ChangeNotifier {
  SocialProvider({
    SocialProfileRepository? profileRepository,
    SocialPostRepository? postRepository,
    SocialCommentRepository? commentRepository,
    SocialReactionRepository? reactionRepository,
    SocialRelationRepository? relationRepository,
    SocialNotificationRepository? notificationRepository,
    SocialMediaRepository? mediaRepository,
    SocialStoryRepository? storyRepository,
    SocialConversationRepository? conversationRepository,
    SocialMessageRepository? messageRepository,
    SocialGroupRepository? groupRepository,
    SocialGroupMembershipRepository? groupMembershipRepository,
    SocialGroupMessageRepository? groupMessageRepository,
    AuthService? authService,
  })  : profileRepository =
            profileRepository ?? InMemorySocialProfileRepository(),
        postRepository = postRepository ?? InMemorySocialPostRepository(),
        commentRepository =
            commentRepository ?? InMemorySocialCommentRepository(),
        reactionRepository =
            reactionRepository ?? InMemorySocialReactionRepository(),
        relationRepository =
            relationRepository ?? InMemorySocialRelationRepository(),
        notificationRepository =
            notificationRepository ?? InMemorySocialNotificationRepository(),
        mediaRepository = mediaRepository ?? InMemorySocialMediaRepository(),
        storyRepository = storyRepository ?? InMemorySocialStoryRepository(),
        conversationRepository =
            conversationRepository ?? InMemorySocialConversationRepository(),
        messageRepository =
            messageRepository ?? InMemorySocialMessageRepository(),
        groupRepository = groupRepository ?? InMemorySocialGroupRepository(),
        groupMembershipRepository = groupMembershipRepository ??
            InMemorySocialGroupMembershipRepository(),
        groupMessageRepository =
            groupMessageRepository ?? InMemorySocialGroupMessageRepository(),
        authService = authService ?? AuthService();

  factory SocialProvider.withFirebase() {
    return SocialProvider(
      profileRepository: FirestoreSocialProfileRepository(),
      postRepository: FirestoreSocialPostRepository(),
      commentRepository: FirestoreSocialCommentRepository(),
      reactionRepository: FirestoreSocialReactionRepository(),
      relationRepository: FirestoreSocialRelationRepository(),
      notificationRepository: FirestoreSocialNotificationRepository(),
      mediaRepository: FirestoreSocialMediaRepository(),
      storyRepository: FirestoreSocialStoryRepository(),
      conversationRepository: FirestoreSocialConversationRepository(),
      messageRepository: FirestoreSocialMessageRepository(),
      groupRepository: FirestoreSocialGroupRepository(),
      groupMembershipRepository: FirestoreSocialGroupMembershipRepository(),
      groupMessageRepository: FirestoreSocialGroupMessageRepository(),
      authService: AuthService(),
    );
  }

  final AuthService authService;
  final SocialProfileRepository profileRepository;
  final SocialPostRepository postRepository;
  final SocialCommentRepository commentRepository;
  final SocialReactionRepository reactionRepository;
  final SocialRelationRepository relationRepository;
  final SocialNotificationRepository notificationRepository;
  final SocialMediaRepository mediaRepository;
  final SocialStoryRepository storyRepository;
  final SocialConversationRepository conversationRepository;
  final SocialMessageRepository messageRepository;
  final SocialGroupRepository groupRepository;
  final SocialGroupMembershipRepository groupMembershipRepository;
  final SocialGroupMessageRepository groupMessageRepository;

  final SocialIdFactory _idFactory = const SocialIdFactory();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  SocialProfile? _currentProfile;
  SocialProfile? get currentProfile => _currentProfile;

  SocialFeedState _feedState = SocialFeedState.initial;
  SocialFeedState get feedState => _feedState;

  String? _feedError;
  String? get feedError => _feedError;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  bool get isLoadingMore => _feedState == SocialFeedState.loadingMore;

  SocialFeedFilter _feedFilter = SocialFeedFilter.recent;
  SocialFeedFilter get feedFilter => _feedFilter;

  List<SocialPost> _feed = <SocialPost>[];
  List<SocialPost> get feed => List<SocialPost>.unmodifiable(_feed);

  String? _feedCursor;

  List<SocialNotification> _notifications = <SocialNotification>[];
  List<SocialNotification> get notifications =>
      List<SocialNotification>.unmodifiable(_notifications);

  Future<void> setFeedFilter(
    SocialFeedFilter filter, {
    int limit = 10,
    String? viewerId,
  }) async {
    if (_feedFilter == filter) {
      return;
    }
    _feedFilter = filter;
    _feedCursor = null;
    await refreshFeed(limit: limit, viewerId: viewerId);
  }

  Future<List<SocialProfile>> searchProfiles(
    String query, {
    String? viewerId,
    int limit = 20,
  }) async {
    final resolvedViewerId = viewerId ?? authService.currentUser?.uid;
    final blockedIds = resolvedViewerId == null
        ? <String>{}
        : await _blockedUserIds(resolvedViewerId);
    final results = await profileRepository.searchProfiles(
      query,
      limit: limit,
      viewerId: resolvedViewerId,
    );
    return results
        .where((profile) => !blockedIds.contains(profile.id))
        .where((profile) =>
            resolvedViewerId == null ||
            resolvedViewerId == profile.id ||
            !profile.isPrivate)
        .toList();
  }

  Future<Set<String>> _blockedUserIds(String viewerId) async {
    final relations = await relationRepository.listRelations(
      userId: viewerId,
      kind: SocialRelationKind.block,
    );
    final blocked = <String>{};
    for (final relation in relations) {
      if (relation.sourceId == viewerId) {
        blocked.add(relation.targetId);
      } else if (relation.targetId == viewerId) {
        blocked.add(relation.sourceId);
      }
    }
    return blocked;
  }

  Future<Set<String>> _followingUserIds(String viewerId) async {
    final relations = await relationRepository.listRelations(
      userId: viewerId,
      kind: SocialRelationKind.follow,
    );
    final follows = <String>{};
    for (final relation in relations) {
      if (relation.sourceId == viewerId) {
        follows.add(relation.targetId);
      }
    }
    return follows;
  }

  Future<List<SocialPost>> _applyFeedFilter(
    List<SocialPost> posts,
    String? viewerId,
  ) async {
    if (viewerId == null) {
      return posts;
    }

    final blockedIds = await _blockedUserIds(viewerId);
    final followingIds = await _followingUserIds(viewerId);

    return posts.where((post) {
      if (blockedIds.contains(post.authorId)) {
        return false;
      }
      switch (_feedFilter) {
        case SocialFeedFilter.mine:
          return post.authorId == viewerId;
        case SocialFeedFilter.following:
          return post.authorId == viewerId ||
              followingIds.contains(post.authorId);
        case SocialFeedFilter.recent:
        default:
          return true;
      }
    }).toList();
  }

  Future<void> refreshFeed({int limit = 10, String? viewerId}) async {
    await _loadFeed(limit: limit, refresh: true, viewerId: viewerId);
  }

  Future<void> loadMoreFeed({int limit = 10, String? viewerId}) async {
    if (!_hasMore || _feedState == SocialFeedState.loadingMore) {
      return;
    }
    await _loadFeed(limit: limit, refresh: false, viewerId: viewerId);
  }

  Future<void> _loadFeed({
    required int limit,
    required bool refresh,
    String? viewerId,
  }) async {
    if (_feedState == SocialFeedState.loading ||
        (_feedState == SocialFeedState.loadingMore && !refresh)) {
      return;
    }

    final resolvedViewerId = viewerId ?? authService.currentUser?.uid;
    final shouldLoadMore = !refresh && _feed.isNotEmpty;
    _feedState =
        shouldLoadMore ? SocialFeedState.loadingMore : SocialFeedState.loading;
    _feedError = null;
    _isLoading = true;
    notifyListeners();

    final correlationId = ObservabilityService.nextCorrelationId();
    final start = DateTime.now();
    try {
      final rawPage =
          await ObservabilityService.observeOperation<List<SocialPost>>(
        'social_feed_load',
        () => postRepository.listFeed(
          limit: limit,
          afterId: refresh ? null : _feedCursor,
          filter: _feedFilter,
          viewerId: resolvedViewerId,
        ),
        eventName: 'social_feed_load',
        operation: refresh ? 'refresh_feed' : 'load_more_feed',
        component: 'social_provider',
        correlationId: correlationId,
        context: <String, Object?>{
          'limit': limit,
          'refresh': refresh,
          'cursor': _feedCursor,
          'feedFilter': _feedFilter.name,
        },
      );
      final nextPage = await _applyFeedFilter(rawPage, resolvedViewerId);

      if (refresh || _feedCursor == null) {
        _feed = nextPage;
      } else {
        final existingIds = _feed.map((post) => post.id).toSet();
        final merged = <SocialPost>[]
          ..addAll(_feed)
          ..addAll(nextPage.where((post) => !existingIds.contains(post.id)));
        _feed = merged;
      }

      _hasMore = nextPage.length >= limit || rawPage.length >= limit;
      if (nextPage.isNotEmpty) {
        _feedCursor = nextPage.last.id;
      } else {
        _feedCursor = null;
      }

      _feedState =
          _feed.isEmpty ? SocialFeedState.empty : SocialFeedState.success;
      final latencyMs = DateTime.now().difference(start).inMilliseconds;
      ObservabilityService.recordMetric(
        'social_feed_load',
        status: 'success',
        latencyMs: latencyMs,
        correlationId: correlationId,
        dimensions: <String, Object?>{
          'pageSize': nextPage.length,
          'hasMore': _hasMore,
          'refresh': refresh,
        },
      );
    } catch (error, stack) {
      final latencyMs = DateTime.now().difference(start).inMilliseconds;
      _feedError = error.toString();
      _feedState = SocialFeedState.error;
      await ObservabilityService.reportError(
        error,
        stack,
        reason: 'social_feed_load',
        correlationId: correlationId,
        context: <String, Object?>{
          'limit': limit,
          'refresh': refresh,
          'cursor': _feedCursor,
          'state': _feedState.name,
        },
      );
      ObservabilityService.recordMetric(
        'social_feed_load',
        status: 'failure',
        latencyMs: latencyMs,
        correlationId: correlationId,
        dimensions: <String, Object?>{
          'limit': limit,
          'refresh': refresh,
          'error': error.toString(),
        },
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFeed({int limit = 10}) async {
    await refreshFeed(limit: limit);
  }

  Future<bool> _isFollowing(String viewerId, String ownerId) async {
    final relation = await relationRepository.getRelation(
      sourceId: viewerId,
      targetId: ownerId,
      kind: SocialRelationKind.follow,
    );
    return relation != null;
  }

  Future<List<SocialStory>> loadVisibleStories({
    String? viewerId,
    int limit = 20,
  }) async {
    final resolvedViewerId = viewerId ?? authService.currentUser?.uid;
    if (resolvedViewerId == null) {
      return const <SocialStory>[];
    }

    final blockedIds = await _blockedUserIds(resolvedViewerId);
    final stories = await storyRepository.listVisibleStories(
      viewerId: resolvedViewerId,
      limit: limit,
    );

    final visibleStories = <SocialStory>[];
    for (final story in stories) {
      if (blockedIds.contains(story.ownerId)) {
        continue;
      }
      final profile = await profileRepository.getProfile(story.ownerId);
      if (profile == null) {
        continue;
      }
      if (profile.isPrivate && story.ownerId != resolvedViewerId) {
        final followsOwner =
            await _isFollowing(resolvedViewerId, story.ownerId);
        if (!followsOwner) {
          continue;
        }
      }
      if (story.visibility == SocialVisibility.private &&
          story.ownerId != resolvedViewerId) {
        continue;
      }
      if (story.visibility == SocialVisibility.followersOnly &&
          story.ownerId != resolvedViewerId) {
        final followsOwner =
            await _isFollowing(resolvedViewerId, story.ownerId);
        if (!followsOwner) {
          continue;
        }
      }
      if (!story.isExpired) {
        visibleStories.add(story);
      }
    }
    return visibleStories;
  }

  Future<SocialStory> createStory({
    required String ownerId,
    required SocialStoryType contentType,
    required String? text,
    String? mediaUrl,
    String? storagePath,
    String? mimeType,
    int? sizeBytes,
    SocialVisibility visibility = SocialVisibility.public,
    Duration ttl = const Duration(hours: 24),
  }) async {
    _assertCurrentUserMatches(ownerId, 'ownerId');

    final now = DateTime.now().toUtc();
    final createdText = contentType == SocialStoryType.text
        ? SocialStory.sanitizeText(text ?? '')
        : (text ?? '').trim();
    if (contentType == SocialStoryType.text && createdText.isEmpty) {
      throw ArgumentError.value(text, 'text', 'Text stories require content.');
    }
    if (mediaUrl != null && mediaUrl.trim().isEmpty) {
      throw ArgumentError.value(
          mediaUrl, 'mediaUrl', 'Media URL cannot be empty.');
    }

    final story = SocialStory(
      storyId: SocialStory.buildStoryId(ownerId, now),
      ownerId: ownerId,
      contentType: contentType,
      createdAt: now,
      expiresAt: now.add(ttl),
      text: contentType == SocialStoryType.text ? createdText : null,
      mediaUrl: mediaUrl,
      storagePath: storagePath,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      visibility: visibility,
      status: SocialStoryStatus.active,
      isDeleted: false,
    );

    final correlationId = ObservabilityService.nextCorrelationId();
    await ObservabilityService.observeOperation<SocialStory>(
      'social_story_create',
      () async {
        await storyRepository.upsertStory(story);
        notifyListeners();
        return story;
      },
      eventName: 'social_story_create',
      operation: 'create_story',
      component: 'social_provider',
      correlationId: correlationId,
      context: <String, Object?>{
        'ownerId': ownerId,
        'contentType': contentType.name,
        'visibility': visibility.name,
      },
    );
    return story;
  }

  Future<void> deleteStory({
    required String storyId,
    required String ownerId,
  }) async {
    _assertCurrentUserMatches(ownerId, 'ownerId');
    final existing = await storyRepository.getStory(storyId);
    if (existing == null || existing.ownerId != ownerId) {
      throw StateError('Story not found or you do not own this story.');
    }
    final updated = existing.copyWith(
      status: SocialStoryStatus.deleted,
      isDeleted: true,
    );
    await storyRepository.upsertStory(updated);
    notifyListeners();
  }

  SocialGroupRole? _groupRoleFromValue(String? raw) {
    if (raw == null) {
      return null;
    }
    try {
      return SocialGroupRole.values.byName(raw);
    } on ArgumentError {
      return null;
    }
  }

  void _assertCurrentUserMatches(String? userId, String fieldName) {
    final currentUserId = authService.currentUser?.uid;
    if (currentUserId != null && userId != null && currentUserId != userId) {
      throw ArgumentError.value(
        userId,
        fieldName,
        'Social actions must use the authenticated Firebase user uid.',
      );
    }
  }

  Future<void> createProfile({
    required String userId,
    required String username,
    required String displayName,
    String? avatarUrl,
    String? bio,
  }) async {
    _assertCurrentUserMatches(userId, 'userId');

    final now = DateTime.now().toUtc();
    final profile = SocialProfile(
      id: userId,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      bio: bio,
      createdAt: now,
      updatedAt: now,
    );
    await profileRepository.upsertProfile(profile);
    notifyListeners();
  }

  Future<void> _updateProfileCounters(
    String userId, {
    int followerDelta = 0,
    int followingDelta = 0,
    int postDelta = 0,
  }) async {
    final current = await profileRepository.getProfile(userId) ??
        SocialProfile(
          id: userId,
          username: userId,
          displayName: userId,
          avatarUrl: null,
          bio: null,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );
    final updated = current.copyWith(
      followersCount:
          (current.followersCount + followerDelta).clamp(0, 1 << 31),
      followingCount:
          (current.followingCount + followingDelta).clamp(0, 1 << 31),
      postCount: (current.postCount + postDelta).clamp(0, 1 << 31),
      updatedAt: DateTime.now().toUtc(),
    );
    await profileRepository.upsertProfile(updated);
  }

  Future<SocialProfile?> loadCurrentProfile() async {
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      _currentProfile = null;
      notifyListeners();
      return null;
    }

    final profile = await profileRepository.getProfile(currentUser.uid);
    _currentProfile = profile;
    notifyListeners();
    return profile;
  }

  Future<SocialProfile?> ensureCurrentProfile({
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) async {
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      _currentProfile = null;
      notifyListeners();
      return null;
    }

    final existing = await profileRepository.getProfile(currentUser.uid);
    final now = DateTime.now().toUtc();
    final fallbackDisplayName =
        (currentUser.displayName ?? existing?.displayName ?? 'Usuário').trim();
    final fallbackUsername = _normalizeUsername(
      username ?? existing?.username ?? currentUser.email ?? currentUser.uid,
    );

    final profile = (existing ??
            SocialProfile(
              id: currentUser.uid,
              username: fallbackUsername,
              displayName:
                  fallbackDisplayName.isEmpty ? 'Usuário' : fallbackDisplayName,
              avatarUrl:
                  avatarUrl ?? currentUser.photoURL ?? existing?.avatarUrl,
              bio: bio ?? existing?.bio ?? '',
              createdAt: now,
              updatedAt: now,
              followersCount: existing?.followersCount ?? 0,
              followingCount: existing?.followingCount ?? 0,
              postCount: existing?.postCount ?? 0,
            ))
        .copyWith(
      id: currentUser.uid,
      username: _normalizeUsername(
        username ?? existing?.username ?? fallbackUsername,
      ),
      displayName: (displayName ?? existing?.displayName ?? fallbackDisplayName)
              .trim()
              .isEmpty
          ? (existing?.displayName ?? fallbackDisplayName)
          : (displayName ?? existing?.displayName ?? fallbackDisplayName)
              .trim(),
      avatarUrl: avatarUrl ?? existing?.avatarUrl ?? currentUser.photoURL,
      bio: bio ?? existing?.bio ?? '',
      updatedAt: now,
    );

    await profileRepository.upsertProfile(profile);
    _currentProfile = profile;
    notifyListeners();
    return profile;
  }

  Future<SocialProfile?> updateCurrentProfile({
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    bool? isPrivate,
  }) async {
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      return null;
    }

    final existing = await profileRepository.getProfile(currentUser.uid) ??
        await ensureCurrentProfile();
    if (existing == null) {
      return null;
    }

    final updated = existing.copyWith(
      username:
          username == null ? existing.username : _normalizeUsername(username),
      displayName: displayName == null
          ? existing.displayName
          : displayName.trim().isEmpty
              ? existing.displayName
              : displayName.trim(),
      avatarUrl: avatarUrl ?? existing.avatarUrl,
      bio: bio ?? existing.bio,
      isPrivate: isPrivate ?? existing.isPrivate,
      updatedAt: DateTime.now().toUtc(),
    );

    await profileRepository.upsertProfile(updated);
    _currentProfile = updated;
    notifyListeners();
    return updated;
  }

  String _normalizeUsername(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '')
        .replaceAll(RegExp(r'_+'), '_');
    return normalized.isEmpty ? 'usuario' : normalized;
  }

  Future<void> _requireNoBlock(String userA, String userB) async {
    final sourceBlocked = await relationRepository.getRelation(
      sourceId: userA,
      targetId: userB,
      kind: SocialRelationKind.block,
    );
    final targetBlocked = await relationRepository.getRelation(
      sourceId: userB,
      targetId: userA,
      kind: SocialRelationKind.block,
    );

    if (sourceBlocked != null || targetBlocked != null) {
      throw StateError(
        'Direct messages are not allowed while a block relationship is active.',
      );
    }
  }

  Future<SocialConversation> ensureConversation({
    required String userA,
    required String userB,
    String? createdBy,
  }) async {
    if (userA == userB) {
      throw ArgumentError.value(
          userB, 'userB', 'A DM requires two different users.');
    }

    final resolvedCreatedBy =
        createdBy ?? authService.currentUser?.uid ?? userA;
    if (resolvedCreatedBy != userA && resolvedCreatedBy != userB) {
      throw StateError(
          'Conversation ownership must be tied to the authenticated user.');
    }

    await _requireNoBlock(userA, userB);

    final conversationId = SocialConversation.buildConversationId(userA, userB);
    final existing =
        await conversationRepository.getConversation(conversationId);
    if (existing != null) {
      return existing;
    }

    final participants = <String>[userA, userB]..sort();
    final now = DateTime.now().toUtc();
    final conversation = SocialConversation(
      id: conversationId,
      participantIds: participants,
      createdBy: resolvedCreatedBy,
      createdAt: now,
      updatedAt: now,
      unreadCount: 0,
      blocked: false,
    );
    await conversationRepository.upsertConversation(conversation);
    notifyListeners();
    return conversation;
  }

  Future<List<SocialConversation>> loadConversations({
    int limit = 50,
    String? userId,
  }) async {
    final currentUserId = userId ?? authService.currentUser?.uid;
    if (currentUserId == null) {
      return const <SocialConversation>[];
    }
    final conversations = await conversationRepository.listConversations(
      currentUserId,
      limit: limit,
    );
    notifyListeners();
    return conversations;
  }

  Future<List<SocialMessage>> loadConversationMessages(
    String conversationId, {
    int limit = 50,
  }) async {
    final messages = await messageRepository.listMessages(
      conversationId,
      limit: limit,
    );
    notifyListeners();
    return messages;
  }

  Stream<List<SocialConversation>> watchConversations({
    String? userId,
    int limit = 50,
  }) {
    final currentUserId = userId ?? authService.currentUser?.uid;
    if (currentUserId == null) {
      return const Stream<List<SocialConversation>>.empty();
    }
    return conversationRepository.watchConversations(currentUserId,
        limit: limit);
  }

  Stream<List<SocialMessage>> watchConversationMessages(
    String conversationId, {
    int limit = 50,
  }) {
    return messageRepository.watchMessages(conversationId, limit: limit);
  }

  Future<SocialMessage> sendDirectMessage({
    required String senderId,
    required String recipientId,
    required String text,
  }) async {
    final currentUserId = authService.currentUser?.uid;
    if (currentUserId != null && currentUserId != senderId) {
      throw ArgumentError.value(senderId, 'senderId',
          'The sender must match the authenticated Firebase user uid.');
    }
    if (senderId == recipientId) {
      throw ArgumentError.value(recipientId, 'recipientId',
          'A direct message cannot be sent to the same user.');
    }

    final sanitizedText = SocialMessage.sanitizeText(text);
    await _requireNoBlock(senderId, recipientId);

    final conversationId =
        SocialConversation.buildConversationId(senderId, recipientId);
    final conversation = await ensureConversation(
      userA: senderId,
      userB: recipientId,
      createdBy: senderId,
    );

    final now = DateTime.now().toUtc();
    final message = SocialMessage(
      id: SocialMessage.buildMessageId(conversationId, senderId, now),
      conversationId: conversationId,
      senderId: senderId,
      text: sanitizedText,
      createdAt: now,
      updatedAt: now,
    );

    final correlationId = ObservabilityService.nextCorrelationId();
    return ObservabilityService.observeOperation<SocialMessage>(
      'social_direct_message_send',
      () async {
        await messageRepository.upsertMessage(message);
        await conversationRepository.upsertConversation(
          conversation.copyWith(
            lastMessageId: message.id,
            lastMessagePreview: sanitizedText,
            lastMessageAt: now,
            updatedAt: now,
            unreadCount: 0,
          ),
        );
        notifyListeners();
        return message;
      },
      eventName: 'social_direct_message_send',
      operation: 'send_direct_message',
      component: 'social_provider',
      correlationId: correlationId,
      context: <String, Object?>{
        'conversationId': conversationId,
        'senderId': senderId,
        'recipientId': recipientId,
        'messageLength': sanitizedText.length,
      },
    );
  }

  Future<void> createPost({
    required String authorId,
    required String text,
    List<String> mediaUrls = const <String>[],
    SocialVisibility visibility = SocialVisibility.public,
  }) async {
    final currentUserId = authService.currentUser?.uid;
    if (currentUserId != null && authorId != currentUserId) {
      throw ArgumentError.value(
        authorId,
        'authorId',
        'Post author must match the authenticated Firebase user uid.',
      );
    }

    final now = DateTime.now().toUtc();
    final resolvedAuthorId = currentUserId ?? authorId;
    final post = SocialPost(
      id: _idFactory.makePostId(),
      authorId: resolvedAuthorId,
      text: text,
      mediaUrls: List<String>.from(mediaUrls),
      createdAt: now,
      updatedAt: now,
      visibility: visibility,
    );
    await postRepository.upsertPost(post);
    await _updateProfileCounters(resolvedAuthorId, postDelta: 1);
    await loadFeed();
  }

  Future<SocialPost> createCurrentPost({
    required String text,
    List<String> mediaUrls = const <String>[],
    SocialVisibility visibility = SocialVisibility.public,
  }) async {
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      throw StateError(
          'A signed-in Firebase user is required to create a post.');
    }

    final now = DateTime.now().toUtc();
    final post = SocialPost(
      id: _idFactory.makePostId(),
      authorId: currentUser.uid,
      text: text,
      mediaUrls: List<String>.from(mediaUrls),
      createdAt: now,
      updatedAt: now,
      visibility: visibility,
    );

    final correlationId = ObservabilityService.nextCorrelationId();
    final created = await ObservabilityService.observeOperation<SocialPost>(
      'social_post_create',
      () async {
        await postRepository.upsertPost(post);
        await _updateProfileCounters(currentUser.uid, postDelta: 1);
        await loadFeed();
        return post;
      },
      eventName: 'social_post_create',
      operation: 'create_post',
      component: 'social_provider',
      correlationId: correlationId,
      context: <String, Object?>{
        'authorId': currentUser.uid,
        'mediaCount': mediaUrls.length,
        'visibility': visibility.name,
      },
    );
    return created;
  }

  Future<SocialMediaMetadata> createMediaMetadata({
    String? id,
    required String storagePath,
    required String url,
    required String contentType,
    int? sizeBytes,
  }) async {
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      throw StateError(
          'A signed-in Firebase user is required to attach media.');
    }

    final media = SocialMediaMetadata(
      id: id ?? _idFactory.makeMediaId(),
      ownerId: currentUser.uid,
      storagePath: storagePath,
      url: url,
      contentType: contentType,
      createdAt: DateTime.now().toUtc(),
      sizeBytes: sizeBytes,
    );

    await mediaRepository.upsertMedia(media);
    notifyListeners();
    return media;
  }

  Future<SocialComment> addComment({
    required String postId,
    required String authorId,
    required String text,
  }) async {
    _assertCurrentUserMatches(authorId, 'authorId');
    if (text.trim().isEmpty) {
      throw ArgumentError.value(text, 'text', 'Comment text cannot be empty.');
    }

    final now = DateTime.now().toUtc();
    final comment = SocialComment(
      id: _idFactory.makeCommentId(),
      postId: postId,
      authorId: authorId,
      text: text,
      createdAt: now,
      updatedAt: now,
    );
    await commentRepository.upsertComment(comment);
    final post = await postRepository.getPost(postId);
    if (post != null) {
      final updated = post.copyWith(
        commentCount: post.commentCount + 1,
        updatedAt: now,
      );
      await postRepository.upsertPost(updated);
    }
    notifyListeners();
    return comment;
  }

  Future<SocialComment> addCurrentComment({
    required String postId,
    required String text,
  }) async {
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      throw StateError(
          'A signed-in Firebase user is required to add a comment.');
    }
    return addComment(postId: postId, authorId: currentUser.uid, text: text);
  }

  Future<void> toggleReaction({
    required String postId,
    required String userId,
    String kind = 'like',
  }) async {
    _assertCurrentUserMatches(userId, 'userId');
    final correlationId = ObservabilityService.nextCorrelationId();
    await ObservabilityService.observeOperation<void>(
      'social_reaction_toggle',
      () async {
        final existing = await reactionRepository.getReaction(postId, userId);
        final now = DateTime.now().toUtc();
        if (existing != null) {
          await reactionRepository.deleteReaction(postId, userId);
          final post = await postRepository.getPost(postId);
          if (post != null) {
            await postRepository.upsertPost(post.copyWith(
              reactionCount:
                  post.reactionCount > 0 ? post.reactionCount - 1 : 0,
              updatedAt: now,
            ));
          }
        } else {
          final reaction = SocialReaction(
            id: SocialReaction.buildReactionId(postId, userId),
            postId: postId,
            userId: userId,
            kind: kind,
            createdAt: now,
          );
          await reactionRepository.upsertReaction(reaction);
          final post = await postRepository.getPost(postId);
          if (post != null) {
            await postRepository.upsertPost(post.copyWith(
              reactionCount: post.reactionCount + 1,
              updatedAt: now,
            ));
          }
        }
        notifyListeners();
      },
      eventName: 'social_reaction_toggle',
      operation: 'toggle_reaction',
      component: 'social_provider',
      correlationId: correlationId,
      context: <String, Object?>{
        'postId': postId,
        'userId': userId,
        'kind': kind,
      },
    );
  }

  Future<void> toggleCurrentReaction({
    required String postId,
    String kind = 'like',
  }) async {
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      throw StateError(
          'A signed-in Firebase user is required to toggle a reaction.');
    }
    await toggleReaction(postId: postId, userId: currentUser.uid, kind: kind);
  }

  Future<SocialNotification> createNotification({
    required String recipientId,
    required String actorId,
    required SocialNotificationType type,
    required String entityId,
    String? dedupeKey,
  }) async {
    final correlationId = ObservabilityService.nextCorrelationId();
    final now = DateTime.now().toUtc();
    final notification = SocialNotification(
      id: SocialNotification.buildNotificationId(
        recipientId,
        actorId,
        entityId,
        type,
        dedupeKey: dedupeKey ?? '${type.name}:${entityId}',
      ),
      recipientId: recipientId,
      actorId: actorId,
      type: type,
      entityId: entityId,
      createdAt: now,
      dedupeKey: dedupeKey ?? '${type.name}:${entityId}',
      isRead: false,
    );
    await ObservabilityService.observeOperation<SocialNotification>(
      'social_notification_create',
      () async {
        await notificationRepository.upsertNotification(notification);
        notifyListeners();
        return notification;
      },
      eventName: 'social_notification_create',
      operation: 'create_notification',
      component: 'social_provider',
      correlationId: correlationId,
      context: <String, Object?>{
        'recipientId': recipientId,
        'actorId': actorId,
        'type': type.name,
        'entityId': entityId,
      },
    );
    return notification;
  }

  Future<SocialNotification> createCurrentNotification({
    required String recipientId,
    required SocialNotificationType type,
    required String entityId,
    String? dedupeKey,
  }) async {
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      throw StateError(
          'A signed-in Firebase user is required to create a notification.');
    }
    return createNotification(
      recipientId: recipientId,
      actorId: currentUser.uid,
      type: type,
      entityId: entityId,
      dedupeKey: dedupeKey,
    );
  }

  Future<void> _syncFollowCounts(String followerId, String targetId,
      {required int delta}) async {
    final currentFollower = await profileRepository.getProfile(followerId) ??
        SocialProfile(
          id: followerId,
          username: followerId,
          displayName: followerId,
          avatarUrl: null,
          bio: null,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );
    final currentTarget = await profileRepository.getProfile(targetId) ??
        SocialProfile(
          id: targetId,
          username: targetId,
          displayName: targetId,
          avatarUrl: null,
          bio: null,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );

    await profileRepository.upsertProfile(
      currentFollower.copyWith(
        followingCount:
            (currentFollower.followingCount + delta).clamp(0, 1 << 31),
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    await profileRepository.upsertProfile(
      currentTarget.copyWith(
        followersCount:
            (currentTarget.followersCount + delta).clamp(0, 1 << 31),
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> followUser({
    required String followerId,
    required String targetId,
  }) async {
    _assertCurrentUserMatches(followerId, 'followerId');
    if (followerId == targetId) {
      throw ArgumentError.value(
        targetId,
        'targetId',
        'A user cannot follow or block themselves.',
      );
    }

    final existingBlocked = await relationRepository.getRelation(
      sourceId: followerId,
      targetId: targetId,
      kind: SocialRelationKind.block,
    );
    final targetBlocked = await relationRepository.getRelation(
      sourceId: targetId,
      targetId: followerId,
      kind: SocialRelationKind.block,
    );
    if (existingBlocked != null || targetBlocked != null) {
      throw StateError('Follow blocked by an existing relationship block.');
    }

    final correlationId = ObservabilityService.nextCorrelationId();
    await ObservabilityService.observeOperation<void>(
      'social_follow',
      () async {
        final now = DateTime.now().toUtc();
        final relation = SocialRelation(
          id: SocialRelation.buildRelationId(
              followerId, targetId, SocialRelationKind.follow),
          sourceId: followerId,
          targetId: targetId,
          kind: SocialRelationKind.follow,
          createdAt: now,
        );
        await relationRepository.upsertRelation(relation);
        await _syncFollowCounts(followerId, targetId, delta: 1);
        await createNotification(
          recipientId: targetId,
          actorId: followerId,
          type: SocialNotificationType.follow,
          entityId: targetId,
          dedupeKey: 'follow:${followerId}:${targetId}',
        );
        notifyListeners();
      },
      eventName: 'social_follow',
      operation: 'follow_user',
      component: 'social_provider',
      correlationId: correlationId,
      context: <String, Object?>{
        'followerId': followerId,
        'targetId': targetId,
      },
    );
  }

  Future<void> followCurrentUser({
    required String targetId,
  }) async {
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      throw StateError(
          'A signed-in Firebase user is required to follow another user.');
    }
    await followUser(followerId: currentUser.uid, targetId: targetId);
  }

  Future<void> unfollowUser({
    required String followerId,
    required String targetId,
  }) async {
    _assertCurrentUserMatches(followerId, 'followerId');
    final correlationId = ObservabilityService.nextCorrelationId();
    await ObservabilityService.observeOperation<void>(
      'social_unfollow',
      () async {
        await relationRepository.deleteRelation(
          sourceId: followerId,
          targetId: targetId,
          kind: SocialRelationKind.follow,
        );
        await _syncFollowCounts(followerId, targetId, delta: -1);
        notifyListeners();
      },
      eventName: 'social_unfollow',
      operation: 'unfollow_user',
      component: 'social_provider',
      correlationId: correlationId,
      context: <String, Object?>{
        'followerId': followerId,
        'targetId': targetId,
      },
    );
  }

  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    _assertCurrentUserMatches(blockerId, 'blockerId');
    if (blockerId == blockedId) {
      throw ArgumentError.value(
        blockedId,
        'blockedId',
        'A user cannot block themselves.',
      );
    }

    final correlationId = ObservabilityService.nextCorrelationId();
    await ObservabilityService.observeOperation<void>(
      'social_block',
      () async {
        final now = DateTime.now().toUtc();
        final relation = SocialRelation(
          id: SocialRelation.buildRelationId(
              blockerId, blockedId, SocialRelationKind.block),
          sourceId: blockerId,
          targetId: blockedId,
          kind: SocialRelationKind.block,
          createdAt: now,
        );
        await relationRepository.upsertRelation(relation);
        await relationRepository.deleteRelation(
          sourceId: blockerId,
          targetId: blockedId,
          kind: SocialRelationKind.follow,
        );
        await relationRepository.deleteRelation(
          sourceId: blockedId,
          targetId: blockerId,
          kind: SocialRelationKind.follow,
        );
        notifyListeners();
      },
      eventName: 'social_block',
      operation: 'block_user',
      component: 'social_provider',
      correlationId: correlationId,
      context: <String, Object?>{
        'blockerId': blockerId,
        'blockedId': blockedId,
      },
    );
  }

  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    _assertCurrentUserMatches(blockerId, 'blockerId');
    final correlationId = ObservabilityService.nextCorrelationId();
    await ObservabilityService.observeOperation<void>(
      'social_unblock',
      () async {
        await relationRepository.deleteRelation(
          sourceId: blockerId,
          targetId: blockedId,
          kind: SocialRelationKind.block,
        );
        notifyListeners();
      },
      eventName: 'social_unblock',
      operation: 'unblock_user',
      component: 'social_provider',
      correlationId: correlationId,
      context: <String, Object?>{
        'blockerId': blockerId,
        'blockedId': blockedId,
      },
    );
  }

  Future<void> blockCurrentUser({
    required String blockedId,
  }) async {
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      throw StateError(
          'A signed-in Firebase user is required to block another user.');
    }
    await blockUser(blockerId: currentUser.uid, blockedId: blockedId);
  }

  Future<void> loadNotifications(String recipientId, {int limit = 20}) async {
    _notifications = await notificationRepository.listNotifications(recipientId,
        limit: limit);
    notifyListeners();
  }

  Future<void> loadCurrentNotifications({int limit = 20}) async {
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      _notifications = <SocialNotification>[];
      notifyListeners();
      return;
    }
    await loadNotifications(currentUser.uid, limit: limit);
  }

  Future<void> markNotificationRead(String notificationId) async {
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      return;
    }

    final correlationId = ObservabilityService.nextCorrelationId();
    await ObservabilityService.observeOperation<void>(
      'social_notification_mark_read',
      () async {
        final recipientNotifications = await notificationRepository
            .listNotifications(currentUser.uid, limit: 200);
        final exists =
            recipientNotifications.any((n) => n.id == notificationId);
        if (!exists) {
          return;
        }

        await notificationRepository.markRead(notificationId);
        notifyListeners();
      },
      eventName: 'social_notification_mark_read',
      operation: 'mark_notification_read',
      component: 'social_provider',
      correlationId: correlationId,
      context: <String, Object?>{
        'notificationId': notificationId,
        'recipientId': currentUser.uid,
      },
    );
  }

  Future<void> markCurrentNotificationRead(String notificationId) async {
    await markNotificationRead(notificationId);
  }

  Future<SocialGroup> createGroup({
    required String ownerId,
    required String name,
    String? description,
    bool isPrivate = false,
  }) async {
    _assertCurrentUserMatches(ownerId, 'ownerId');
    final sanitizedName = SocialGroup.sanitizeName(name);
    final now = DateTime.now().toUtc();
    final groupId = SocialGroup.buildGroupId(ownerId, now);
    final group = SocialGroup(
      id: groupId,
      ownerId: ownerId,
      name: sanitizedName,
      description: description?.trim(),
      createdAt: now,
      updatedAt: now,
      isPrivate: isPrivate,
      memberRoles: <String, String>{ownerId: SocialGroupRole.owner.name},
      bannedUserIds: const <String>[],
    );

    final correlationId = ObservabilityService.nextCorrelationId();
    await ObservabilityService.observeOperation<SocialGroup>(
      'social_group_create',
      () async {
        await groupRepository.upsertGroup(group);
        await groupMembershipRepository.upsertMembership(
          SocialGroupMember(
            groupId: groupId,
            userId: ownerId,
            role: SocialGroupRole.owner,
            joinedAt: now,
          ),
        );
        notifyListeners();
        return group;
      },
      eventName: 'social_group_create',
      operation: 'create_group',
      component: 'social_provider',
      correlationId: correlationId,
      context: <String, Object?>{
        'groupId': groupId,
        'ownerId': ownerId,
        'isPrivate': isPrivate,
      },
    );
    return group;
  }

  Future<SocialGroup> joinGroup({
    required String userId,
    required String groupId,
  }) async {
    _assertCurrentUserMatches(userId, 'userId');
    final group = await groupRepository.getGroup(groupId);
    if (group == null) {
      throw StateError('Group not found.');
    }
    if (group.isBanned(userId)) {
      throw StateError('This user is banned from the group.');
    }
    if (group.isMember(userId)) {
      return group;
    }
    if (group.isPrivate) {
      throw StateError(
          'Private groups require an admin action to approve membership.');
    }

    final updatedGroup = group.copyWith(
      memberRoles: <String, String>{
        ...group.memberRoles,
        userId: SocialGroupRole.member.name
      },
      updatedAt: DateTime.now().toUtc(),
    );
    await groupRepository.upsertGroup(updatedGroup);
    await groupMembershipRepository.upsertMembership(
      SocialGroupMember(
        groupId: groupId,
        userId: userId,
        role: SocialGroupRole.member,
        joinedAt: DateTime.now().toUtc(),
      ),
    );
    notifyListeners();
    return updatedGroup;
  }

  Future<SocialGroup> leaveGroup({
    required String userId,
    required String groupId,
  }) async {
    _assertCurrentUserMatches(userId, 'userId');
    final group = await groupRepository.getGroup(groupId);
    if (group == null) {
      throw StateError('Group not found.');
    }
    if (group.ownerId == userId) {
      throw StateError(
          'The owner cannot leave a group without transferring ownership.');
    }
    if (!group.isMember(userId)) {
      return group;
    }
    final updatedMemberRoles = <String, String>{...group.memberRoles};
    updatedMemberRoles.remove(userId);
    final updatedGroup = group.copyWith(
      memberRoles: updatedMemberRoles,
      updatedAt: DateTime.now().toUtc(),
    );
    await groupRepository.upsertGroup(updatedGroup);
    await groupMembershipRepository.deleteMembership(groupId, userId);
    notifyListeners();
    return updatedGroup;
  }

  Future<SocialGroup> addGroupMember({
    required String groupId,
    required String actorId,
    required String targetUserId,
    SocialGroupRole role = SocialGroupRole.member,
  }) async {
    _assertCurrentUserMatches(actorId, 'actorId');
    final group = await groupRepository.getGroup(groupId);
    if (group == null) {
      throw StateError('Group not found.');
    }
    final actorRole = _groupRoleFromValue(group.roleFor(actorId));
    final allowedRoles = <SocialGroupRole>{
      SocialGroupRole.owner,
      SocialGroupRole.admin,
      SocialGroupRole.moderator
    };
    if (!allowedRoles.contains(actorRole)) {
      throw StateError(
          'You do not have permission to add members to this group.');
    }
    if (targetUserId == group.ownerId) {
      throw StateError('The owner is already linked to this group.');
    }
    final updatedRoles = <String, String>{...group.memberRoles};
    updatedRoles[targetUserId] = role.name;
    final updatedGroup = group.copyWith(
      memberRoles: updatedRoles,
      updatedAt: DateTime.now().toUtc(),
    );
    await groupRepository.upsertGroup(updatedGroup);
    await groupMembershipRepository.upsertMembership(
      SocialGroupMember(
        groupId: groupId,
        userId: targetUserId,
        role: role,
        joinedAt: DateTime.now().toUtc(),
      ),
    );
    notifyListeners();
    return updatedGroup;
  }

  Future<SocialGroup> removeGroupMember({
    required String groupId,
    required String actorId,
    required String targetUserId,
  }) async {
    _assertCurrentUserMatches(actorId, 'actorId');
    final group = await groupRepository.getGroup(groupId);
    if (group == null) {
      throw StateError('Group not found.');
    }
    final actorRole = _groupRoleFromValue(group.roleFor(actorId));
    final targetRole = _groupRoleFromValue(group.roleFor(targetUserId));
    final allowedRoles = <SocialGroupRole>{
      SocialGroupRole.owner,
      SocialGroupRole.admin,
      SocialGroupRole.moderator
    };
    if (actorRole == null || !allowedRoles.contains(actorRole)) {
      throw StateError('You cannot manage this group membership.');
    }
    if (targetUserId == group.ownerId || targetRole == SocialGroupRole.owner) {
      throw StateError('The group owner cannot be removed by a member action.');
    }
    final updatedRoles = <String, String>{...group.memberRoles};
    updatedRoles.remove(targetUserId);
    final updatedGroup = group.copyWith(
      memberRoles: updatedRoles,
      updatedAt: DateTime.now().toUtc(),
    );
    await groupRepository.upsertGroup(updatedGroup);
    await groupMembershipRepository.deleteMembership(groupId, targetUserId);
    notifyListeners();
    return updatedGroup;
  }

  Future<SocialGroup> banGroupMember({
    required String groupId,
    required String actorId,
    required String targetUserId,
  }) async {
    _assertCurrentUserMatches(actorId, 'actorId');
    final group = await groupRepository.getGroup(groupId);
    if (group == null) {
      throw StateError('Group not found.');
    }
    final actorRole = _groupRoleFromValue(group.roleFor(actorId));
    final allowedRoles = <SocialGroupRole>{
      SocialGroupRole.owner,
      SocialGroupRole.admin,
      SocialGroupRole.moderator
    };
    if (actorRole == null || !allowedRoles.contains(actorRole)) {
      throw StateError('You cannot ban users from this group.');
    }
    if (targetUserId == group.ownerId) {
      throw StateError('The owner cannot be banned.');
    }

    final updatedBans = <String>{...group.bannedUserIds};
    updatedBans.add(targetUserId);
    final updatedRoles = <String, String>{...group.memberRoles};
    updatedRoles.remove(targetUserId);
    final updatedGroup = group.copyWith(
      memberRoles: updatedRoles,
      bannedUserIds: updatedBans.toList()..sort(),
      updatedAt: DateTime.now().toUtc(),
    );
    await groupRepository.upsertGroup(updatedGroup);
    await groupMembershipRepository.deleteMembership(groupId, targetUserId);
    notifyListeners();
    return updatedGroup;
  }

  Future<SocialGroup> unbanGroupMember({
    required String groupId,
    required String actorId,
    required String targetUserId,
  }) async {
    _assertCurrentUserMatches(actorId, 'actorId');
    final group = await groupRepository.getGroup(groupId);
    if (group == null) {
      throw StateError('Group not found.');
    }
    final actorRole = _groupRoleFromValue(group.roleFor(actorId));
    final allowedRoles = <SocialGroupRole>{
      SocialGroupRole.owner,
      SocialGroupRole.admin,
      SocialGroupRole.moderator
    };
    if (actorRole == null || !allowedRoles.contains(actorRole)) {
      throw StateError('You cannot unban users from this group.');
    }
    if (!group.isBanned(targetUserId)) {
      return group;
    }
    final updatedBans = <String>[...group.bannedUserIds]..remove(targetUserId);
    final updatedGroup = group.copyWith(
      bannedUserIds: updatedBans,
      updatedAt: DateTime.now().toUtc(),
    );
    await groupRepository.upsertGroup(updatedGroup);
    notifyListeners();
    return updatedGroup;
  }

  Future<SocialGroupMessage> sendGroupMessage({
    required String groupId,
    required String senderId,
    required String text,
  }) async {
    _assertCurrentUserMatches(senderId, 'senderId');
    final group = await groupRepository.getGroup(groupId);
    if (group == null) {
      throw StateError('Group not found.');
    }
    if (!group.isMember(senderId)) {
      throw StateError('Only group members can send messages.');
    }
    if (group.isBanned(senderId)) {
      throw StateError('Banned users cannot send messages to this group.');
    }

    final sanitizedText = SocialGroupMessage.sanitizeText(text);
    final now = DateTime.now().toUtc();
    final message = SocialGroupMessage(
      id: SocialGroupMessage.buildMessageId(groupId, senderId, now),
      groupId: groupId,
      senderId: senderId,
      text: sanitizedText,
      createdAt: now,
      updatedAt: now,
    );

    final correlationId = ObservabilityService.nextCorrelationId();
    return ObservabilityService.observeOperation<SocialGroupMessage>(
      'social_group_message_send',
      () async {
        await groupMessageRepository.upsertMessage(message);
        notifyListeners();
        return message;
      },
      eventName: 'social_group_message_send',
      operation: 'send_group_message',
      component: 'social_provider',
      correlationId: correlationId,
      context: <String, Object?>{
        'groupId': groupId,
        'senderId': senderId,
        'messageLength': sanitizedText.length,
      },
    );
  }

  Future<List<SocialGroupMessage>> loadGroupMessages(String groupId,
      {int limit = 50}) async {
    final messages =
        await groupMessageRepository.listMessages(groupId, limit: limit);
    notifyListeners();
    return messages;
  }

  Future<List<SocialGroup>> listGroups({
    String? ownerId,
    int limit = 50,
    bool includePrivate = false,
  }) async {
    return groupRepository.listGroups(
      ownerId: ownerId,
      limit: limit,
      includePrivate: includePrivate,
    );
  }
}
