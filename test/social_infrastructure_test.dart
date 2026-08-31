import 'package:flutter_test/flutter_test.dart';
import 'package:labomba_app/features/social/social.dart';

void main() {
  group('social infrastructure', () {
    test('profile serializes and deserializes', () {
      final createdAt = DateTime.utc(2025, 1, 10, 12, 30, 0);
      final updatedAt = DateTime.utc(2025, 1, 12, 14, 00, 0);

      final profile = SocialProfile(
        id: 'user-1',
        username: 'labomba',
        displayName: 'LaBomba',
        avatarUrl: 'https://cdn.example.com/avatar.png',
        bio: 'Comunidade e festival',
        createdAt: createdAt,
        updatedAt: updatedAt,
        isPrivate: true,
        followersCount: 10,
        followingCount: 4,
        postCount: 7,
      );

      final json = profile.toJson();
      final roundTrip = SocialProfile.fromJson(json);

      expect(roundTrip.id, profile.id);
      expect(roundTrip.username, profile.username);
      expect(roundTrip.displayName, profile.displayName);
      expect(roundTrip.isPrivate, isTrue);
      expect(roundTrip.followersCount, 10);
      expect(roundTrip.updatedAt.toUtc().toIso8601String(),
          updatedAt.toUtc().toIso8601String());
    });

    test('reaction and relation ids are deterministic', () {
      final reactionId = SocialReaction.buildReactionId('post-1', 'user-1');
      final relationId = SocialRelation.buildRelationId(
          'user-1', 'user-2', SocialRelationKind.follow);
      final notificationId = SocialNotification.buildNotificationId(
        'user-2',
        'user-1',
        'post-1',
        SocialNotificationType.reaction,
      );
      final dedupedNotificationId = SocialNotification.buildNotificationId(
        'user-2',
        'user-1',
        'post-1',
        SocialNotificationType.reaction,
        dedupeKey: 'reaction:post-1:user-1',
      );

      expect(reactionId, 'post-1:user-1');
      expect(relationId, 'follow:user-1:user-2');
      expect(notificationId, 'user-2:user-1:post-1:reaction');
      expect(dedupedNotificationId,
          'user-2:user-1:post-1:reaction:reaction:post-1:user-1');
      expect(
        SocialNotification.buildNotificationId(
          'user-2',
          'user-1',
          'post-1',
          SocialNotificationType.reaction,
        ),
        notificationId,
      );
    });

    test('empty collections and partial json remain stable', () {
      final provider = SocialProvider();
      expect(provider.feed, isEmpty);
      expect(provider.notifications, isEmpty);

      final profile = SocialProfile.fromJson({
        'id': 'user-1',
        'username': 'demo',
        'displayName': 'Demo',
      });

      expect(profile.username, 'demo');
      expect(profile.isPrivate, isFalse);
      expect(profile.followersCount, 0);
      expect(profile.createdAt, isA<DateTime>());
    });

    test('profile updates preserve createdAt and refresh updatedAt', () async {
      final createdAt = DateTime.utc(2025, 1, 10, 12, 30, 0);
      final initial = SocialProfile(
        id: 'user-1',
        username: 'labomba',
        displayName: 'LaBomba',
        avatarUrl: 'https://cdn.example.com/avatar.png',
        bio: 'Comunidade e festival',
        createdAt: createdAt,
        updatedAt: createdAt,
      );

      final updated = initial.copyWith(
        displayName: 'LaBomba Social',
        updatedAt: DateTime.utc(2025, 1, 12, 12, 30, 0),
      );

      expect(updated.createdAt, createdAt);
      expect(updated.displayName, 'LaBomba Social');
      expect(updated.updatedAt, DateTime.utc(2025, 1, 12, 12, 30, 0));
    });

    test('provider paginates and refreshes feed deterministically', () async {
      final provider = SocialProvider();
      await provider.createPost(authorId: 'user-1', text: 'post 1');
      await provider.createPost(authorId: 'user-2', text: 'post 2');
      await provider.refreshFeed(limit: 1);

      expect(provider.feedState, SocialFeedState.success);
      expect(provider.feed, hasLength(1));
      expect(provider.hasMore, isTrue);

      await provider.loadMoreFeed(limit: 1);
      expect(provider.feed, hasLength(2));
      expect(provider.feed.first.text, isNotEmpty);
      expect(provider.feedState, SocialFeedState.success);
    });

    test('provider creates posts, comments, and updates feed', () async {
      final provider = SocialProvider();

      await provider.createProfile(
        userId: 'user-1',
        username: 'alb',
        displayName: 'Alberto',
      );

      await provider.createPost(
        authorId: 'user-1',
        text: 'Primeiro post',
      );

      expect(provider.feed, hasLength(1));
      expect(provider.feed.first.text, 'Primeiro post');

      final postId = provider.feed.first.id;
      final comment = await provider.addComment(
        postId: postId,
        authorId: 'user-2',
        text: 'Ótimo post!',
      );

      final persistedPost = await provider.postRepository.getPost(postId);
      expect(comment.text, 'Ótimo post!');
      expect(persistedPost, isNotNull);
      expect(persistedPost!.commentCount, 1);

      await provider.toggleReaction(postId: postId, userId: 'user-2');
      final reactedPost = await provider.postRepository.getPost(postId);
      expect(reactedPost, isNotNull);
      expect(reactedPost!.reactionCount, 1);

      await provider.followUser(followerId: 'user-1', targetId: 'user-2');
      final afterFollow = await provider.relationRepository.getRelation(
        sourceId: 'user-1',
        targetId: 'user-2',
        kind: SocialRelationKind.follow,
      );
      expect(afterFollow, isNotNull);
      expect(afterFollow!.sourceId, 'user-1');
      expect(afterFollow.targetId, 'user-2');
    });

    test('relationship actions reject self-follow and self-block', () async {
      final provider = SocialProvider();

      await expectLater(
        () => provider.followUser(followerId: 'user-1', targetId: 'user-1'),
        throwsA(isA<ArgumentError>()),
      );

      await expectLater(
        () => provider.blockUser(blockerId: 'user-1', blockedId: 'user-1'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
        'search excludes blocked and private profiles while preserving safe matches',
        () async {
      final provider = SocialProvider();
      await provider.createProfile(
        userId: 'user-1',
        username: 'alberto',
        displayName: 'Alberto',
      );
      await provider.createProfile(
        userId: 'user-2',
        username: 'bruna',
        displayName: 'Bruna',
      );
      await provider.createProfile(
        userId: 'user-3',
        username: 'carlos',
        displayName: 'Carlos',
      );
      await provider.profileRepository.upsertProfile(
        (await provider.profileRepository.getProfile('user-3'))!.copyWith(
          isPrivate: true,
        ),
      );
      await provider.blockUser(blockerId: 'user-1', blockedId: 'user-2');

      final results = await provider.searchProfiles('', viewerId: 'user-1');
      expect(results.map((profile) => profile.id), isNot(contains('user-2')));
      expect(results.map((profile) => profile.id), isNot(contains('user-3')));
      expect(results.map((profile) => profile.id), contains('user-1'));
    });

    test('feed filters support recent, following and mine views', () async {
      final provider = SocialProvider();
      await provider.createProfile(
        userId: 'user-1',
        username: 'alberto',
        displayName: 'Alberto',
      );
      await provider.createProfile(
        userId: 'user-2',
        username: 'bruna',
        displayName: 'Bruna',
      );
      await provider.createProfile(
        userId: 'user-3',
        username: 'carlos',
        displayName: 'Carlos',
      );

      await provider.createPost(authorId: 'user-1', text: 'meu post');
      await provider.createPost(authorId: 'user-2', text: 'post da bruna');
      await provider.createPost(authorId: 'user-3', text: 'post do carlos');
      await provider.followUser(followerId: 'user-1', targetId: 'user-2');

      await provider.setFeedFilter(SocialFeedFilter.mine,
          limit: 10, viewerId: 'user-1');
      expect(provider.feed, isNotEmpty);
      expect(provider.feed.every((post) => post.authorId == 'user-1'), isTrue);

      await provider.setFeedFilter(SocialFeedFilter.following,
          limit: 10, viewerId: 'user-1');
      expect(provider.feed.any((post) => post.authorId == 'user-2'), isTrue);
      expect(provider.feed.any((post) => post.authorId == 'user-3'), isFalse);
    });

    test('story lifecycle and expiration rules are stable', () {
      final createdAt = DateTime.now().toUtc();
      final story = SocialStory(
        storyId: 'story:user-1:1',
        ownerId: 'user-1',
        contentType: SocialStoryType.text,
        createdAt: createdAt,
        expiresAt: createdAt.add(const Duration(hours: 24)),
        text: 'Hoje no LaBomba',
        visibility: SocialVisibility.public,
      );

      expect(story.isExpired, isFalse);
      expect(story.text, 'Hoje no LaBomba');

      final expired = story.copyWith(
        expiresAt: createdAt.add(const Duration(minutes: -1)),
        status: SocialStoryStatus.expired,
      );
      expect(expired.isExpired, isTrue);
    });

    test('provider create and delete story flows work', () async {
      final provider = SocialProvider();
      final story = await provider.createStory(
        ownerId: 'user-1',
        contentType: SocialStoryType.text,
        text: 'Story novo',
      );

      expect(story.storyId, isNotEmpty);
      expect(await provider.storyRepository.getStory(story.storyId), isNotNull);

      await provider.deleteStory(storyId: story.storyId, ownerId: 'user-1');
      final deleted = await provider.storyRepository.getStory(story.storyId);
      expect(deleted, isNotNull);
      expect(deleted!.status, SocialStoryStatus.deleted);
      expect(deleted.isDeleted, isTrue);
    });

    test('visible stories exclude blocked and private profiles', () async {
      final provider = SocialProvider();
      await provider.createProfile(
        userId: 'user-1',
        username: 'alberto',
        displayName: 'Alberto',
        bio: 'Public',
      );
      await provider.createProfile(
        userId: 'user-2',
        username: 'bruna',
        displayName: 'Bruna',
        bio: 'Private',
      );
      await provider.profileRepository.upsertProfile(
        (await provider.profileRepository.getProfile('user-2'))!.copyWith(
          isPrivate: true,
        ),
      );
      await provider.createStory(
        ownerId: 'user-1',
        contentType: SocialStoryType.text,
        text: 'story publico',
      );
      await provider.createStory(
        ownerId: 'user-2',
        contentType: SocialStoryType.text,
        text: 'story privado',
        visibility: SocialVisibility.private,
      );
      await provider.blockUser(blockerId: 'user-3', blockedId: 'user-1');

      final stories = await provider.loadVisibleStories(viewerId: 'user-3');
      expect(stories.any((story) => story.ownerId == 'user-1'), isFalse);
      final followerStories =
          await provider.loadVisibleStories(viewerId: 'user-1');
      expect(
          followerStories.any((story) => story.ownerId == 'user-2'), isFalse);
    });

    test('group creation and message sending stay within member permissions',
        () async {
      final provider = SocialProvider();
      final owner = await provider.createGroup(
        ownerId: 'user-1',
        name: 'Grupo da festa',
        description: 'Comunidade local',
      );

      expect(owner.memberRoles['user-1'], SocialGroupRole.owner.name);

      final joined = await provider.joinGroup(
        userId: 'user-2',
        groupId: owner.id,
      );
      expect(joined.isMember('user-2'), isTrue);

      final message = await provider.sendGroupMessage(
        groupId: owner.id,
        senderId: 'user-1',
        text: 'Bem-vindos ao grupo',
      );
      expect(message.text, 'Bem-vindos ao grupo');

      final byMember = await provider.sendGroupMessage(
        groupId: owner.id,
        senderId: 'user-2',
        text: 'Olá pessoal',
      );
      expect(byMember.senderId, 'user-2');

      final loaded = await provider.loadGroupMessages(owner.id, limit: 10);
      expect(loaded.length, 2);

      await provider.banGroupMember(
        groupId: owner.id,
        actorId: 'user-1',
        targetUserId: 'user-2',
      );
      final bannedGroup = await provider.groupRepository.getGroup(owner.id);
      expect(bannedGroup!.isBanned('user-2'), isTrue);
    });
  });
}
