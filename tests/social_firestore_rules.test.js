const test = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');

const rules = fs.readFileSync(
  path.join(__dirname, '..', 'firestore.rules'),
  'utf8',
);

function makeProjectId() {
  return `labomba-social-${Date.now()}-${Math.random().toString(16).slice(2, 10)}`;
}

async function makeEnv() {
  return initializeTestEnvironment({
    projectId: makeProjectId(),
    firestore: {
      rules,
      host: '127.0.0.1',
      port: 8080,
    },
  });
}

test('allows authenticated user to create their own profile', async () => {
  const env = await makeEnv();
  try {
    const alice = env.authenticatedContext('alice');
    await assertSucceeds(
      alice.firestore().collection('profiles').doc('alice').set({
        id: 'alice',
        username: 'alice',
        displayName: 'Alice',
        createdAt: new Date('2025-01-10T00:00:00Z').toISOString(),
        updatedAt: new Date('2025-01-10T00:00:00Z').toISOString(),
        followersCount: 0,
        followingCount: 0,
        postCount: 0,
      }),
    );
  } finally {
    await env.cleanup();
  }
});

test('denies user creating profile for another uid', async () => {
  const env = await makeEnv();
  try {
    const bob = env.authenticatedContext('bob');
    await assertFails(
      bob.firestore().collection('profiles').doc('alice').set({
        id: 'alice',
        username: 'alice',
        displayName: 'Alice',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        followersCount: 0,
        followingCount: 0,
        postCount: 0,
      }),
    );
  } finally {
    await env.cleanup();
  }
});

test('denies user editing someone else profile', async () => {
  const env = await makeEnv();
  try {
    const bob = env.authenticatedContext('bob');
    await assertFails(
      bob.firestore().collection('profiles').doc('alice').set({
        id: 'alice',
        username: 'alice',
        displayName: 'Alice',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        followersCount: 0,
        followingCount: 0,
        postCount: 0,
      }),
    );
  } finally {
    await env.cleanup();
  }
});

test('allows authenticated user to update their own profile while preserving createdAt', async () => {
  const env = await makeEnv();
  try {
    const alice = env.authenticatedContext('alice');
    const createdAt = new Date('2025-01-10T00:00:00Z').toISOString();
    await alice.firestore().collection('profiles').doc('alice').set({
      id: 'alice',
      username: 'alice',
      displayName: 'Alice',
      createdAt,
      updatedAt: createdAt,
      followersCount: 0,
      followingCount: 0,
      postCount: 0,
    });

    await assertSucceeds(
      alice.firestore().collection('profiles').doc('alice').update({
        displayName: 'Alice Updated',
        updatedAt: new Date('2025-01-12T00:00:00Z').toISOString(),
      }),
    );
  } finally {
    await env.cleanup();
  }
});

test('denies unauthenticated profile access', async () => {
  const env = await makeEnv();
  try {
    const unauth = env.unauthenticatedContext();
    await assertFails(
      unauth.firestore().collection('profiles').doc('alice').get(),
    );
  } finally {
    await env.cleanup();
  }
});

test('allows authenticated user to create their own post', async () => {
  const env = await makeEnv();
  try {
    const alice = env.authenticatedContext('alice');
    await assertSucceeds(
      alice.firestore().collection('posts').doc('post-1').set({
        id: 'post-1',
        authorId: 'alice',
        text: 'Hello social foundation',
        mediaUrls: [],
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        visibility: 'public',
        reactionCount: 0,
        commentCount: 0,
        isDeleted: false,
      }),
    );
  } finally {
    await env.cleanup();
  }
});

test('allows authenticated user to create their own media metadata', async () => {
  const env = await makeEnv();
  try {
    const alice = env.authenticatedContext('alice');
    await assertSucceeds(
      alice.firestore().collection('media').doc('media-1').set({
        id: 'media-1',
        ownerId: 'alice',
        storagePath: 'users/alice/uploads/img.jpg',
        url: 'https://example.com/alice/img.jpg',
        contentType: 'image/jpeg',
        createdAt: new Date().toISOString(),
      }),
    );
  } finally {
    await env.cleanup();
  }
});

test('denies creating media metadata for another user', async () => {
  const env = await makeEnv();
  try {
    const bob = env.authenticatedContext('bob');
    await assertFails(
      bob.firestore().collection('media').doc('media-2').set({
        id: 'media-2',
        ownerId: 'alice',
        storagePath: 'users/alice/uploads/img.jpg',
        url: 'https://example.com/alice/img.jpg',
        contentType: 'image/jpeg',
        createdAt: new Date().toISOString(),
      }),
    );
  } finally {
    await env.cleanup();
  }
});

test('denies foreign reaction creation', async () => {
  const env = await makeEnv();
  try {
    const bob = env.authenticatedContext('bob');
    await assertFails(
      bob.firestore().collection('posts').doc('post-1').collection('reactions').doc('post-1:bob').set({
        id: 'post-1:bob',
        postId: 'post-1',
        userId: 'alice',
        kind: 'like',
        createdAt: new Date().toISOString(),
      }),
    );
  } finally {
    await env.cleanup();
  }
});

test('allows authenticated participants to create a direct-message conversation', async () => {
  const env = await makeEnv();
  try {
    const alice = env.authenticatedContext('alice');
    const now = new Date();
    await assertSucceeds(
      alice.firestore().collection('conversations').doc('dm:alice:bob').set({
        id: 'dm:alice:bob',
        participantIds: ['alice', 'bob'],
        createdBy: 'alice',
        createdAt: now.toISOString(),
        updatedAt: now.toISOString(),
        lastMessageId: null,
        lastMessagePreview: null,
        unreadCount: 0,
        blocked: false,
      }),
    );
  } finally {
    await env.cleanup();
  }
});

test('denies direct messages to users outside the conversation participants', async () => {
  const env = await makeEnv();
  try {
    const alice = env.authenticatedContext('alice');
    const charlie = env.authenticatedContext('charlie');
    const now = new Date();
    await alice.firestore().collection('conversations').doc('dm:alice:bob').set({
      id: 'dm:alice:bob',
      participantIds: ['alice', 'bob'],
      createdBy: 'alice',
      createdAt: now.toISOString(),
      updatedAt: now.toISOString(),
      lastMessageId: null,
      lastMessagePreview: null,
      unreadCount: 0,
      blocked: false,
    });

    await assertFails(
      charlie.firestore().collection('conversations').doc('dm:alice:bob').collection('messages').doc('msg-1').set({
        id: 'msg-1',
        conversationId: 'dm:alice:bob',
        senderId: 'charlie',
        text: 'hello',
        createdAt: now.toISOString(),
        updatedAt: now.toISOString(),
        isDeleted: false,
      }),
    );
  } finally {
    await env.cleanup();
  }
});

test('denies direct messages when the chat has been marked as blocked', async () => {
  const env = await makeEnv();
  try {
    const alice = env.authenticatedContext('alice');
    const bob = env.authenticatedContext('bob');
    const now = new Date();
    await alice.firestore().collection('conversations').doc('dm:alice:bob').set({
      id: 'dm:alice:bob',
      participantIds: ['alice', 'bob'],
      createdBy: 'alice',
      createdAt: now.toISOString(),
      updatedAt: now.toISOString(),
      lastMessageId: null,
      lastMessagePreview: null,
      unreadCount: 0,
      blocked: true,
    });

    await assertFails(
      bob.firestore().collection('conversations').doc('dm:alice:bob').collection('messages').doc('msg-2').set({
        id: 'msg-2',
        conversationId: 'dm:alice:bob',
        senderId: 'bob',
        text: 'blocked message',
        createdAt: now.toISOString(),
        updatedAt: now.toISOString(),
        isDeleted: false,
      }),
    );
  } finally {
    await env.cleanup();
  }
});

test('allows authenticated user to create their own story', async () => {
  const env = await makeEnv();
  try {
    const alice = env.authenticatedContext('alice');
    const now = new Date();
    const expiresAt = new Date(now.getTime() + 86400000);
    await assertSucceeds(
      alice.firestore().collection('stories').doc('story:alice:1').set({
        storyId: 'story:alice:1',
        ownerId: 'alice',
        contentType: 'text',
        createdAt: now.toISOString(),
        expiresAt: expiresAt.toISOString(),
        text: 'Hoje no LaBomba',
        visibility: 'public',
        status: 'active',
        isDeleted: false,
      }),
    );
  } finally {
    await env.cleanup();
  }
});

test('denies story creation for another user', async () => {
  const env = await makeEnv();
  try {
    const bob = env.authenticatedContext('bob');
    const now = new Date();
    const expiresAt = new Date(now.getTime() + 86400000);
    await assertFails(
      bob.firestore().collection('stories').doc('story:alice:1').set({
        storyId: 'story:alice:1',
        ownerId: 'alice',
        contentType: 'text',
        createdAt: now.toISOString(),
        expiresAt: expiresAt.toISOString(),
        text: 'Story improprio',
        visibility: 'public',
        status: 'active',
        isDeleted: false,
      }),
    );
  } finally {
    await env.cleanup();
  }
});

test('denies unauthorized read of a private story', async () => {
  const env = await makeEnv();
  try {
    const alice = env.authenticatedContext('alice');
    const charlie = env.authenticatedContext('charlie');
    const now = new Date();
    const expiresAt = new Date(now.getTime() + 86400000);
    await alice.firestore().collection('stories').doc('story:alice:private').set({
      storyId: 'story:alice:private',
      ownerId: 'alice',
      contentType: 'text',
      createdAt: now.toISOString(),
      expiresAt: expiresAt.toISOString(),
      text: 'Privado',
      visibility: 'private',
      status: 'active',
      isDeleted: false,
    });

    await assertFails(
      charlie.firestore().collection('stories').doc('story:alice:private').get(),
    );
  } finally {
    await env.cleanup();
  }
});

test('allows group owner to create a group and member message', async () => {
  const env = await makeEnv();
  try {
    const alice = env.authenticatedContext('alice');
    const now = new Date();
    await assertSucceeds(
      alice.firestore().collection('groups').doc('group:alice:1').set({
        id: 'group:alice:1',
        ownerId: 'alice',
        name: 'Grupo da festa',
        description: 'Comunidade local',
        createdAt: now.toISOString(),
        updatedAt: now.toISOString(),
        isPrivate: false,
        memberRoles: { alice: 'owner' },
        bannedUserIds: [],
      }),
    );

    await assertSucceeds(
      alice.firestore().collection('groups').doc('group:alice:1').collection('messages').doc('msg-1').set({
        id: 'msg-1',
        groupId: 'group:alice:1',
        senderId: 'alice',
        text: 'Bem-vindos ao grupo',
        createdAt: now.toISOString(),
        updatedAt: now.toISOString(),
        isDeleted: false,
      }),
    );
  } finally {
    await env.cleanup();
  }
});

test('denies non-member from writing to group messages', async () => {
  const env = await makeEnv();
  try {
    const alice = env.authenticatedContext('alice');
    const bob = env.authenticatedContext('bob');
    const now = new Date();
    await alice.firestore().collection('groups').doc('group:alice:1').set({
      id: 'group:alice:1',
      ownerId: 'alice',
      name: 'Grupo da festa',
      description: 'Comunidade local',
      createdAt: now.toISOString(),
      updatedAt: now.toISOString(),
      isPrivate: false,
      memberRoles: { alice: 'owner' },
      bannedUserIds: [],
    });

    await assertFails(
      bob.firestore().collection('groups').doc('group:alice:1').collection('messages').doc('msg-2').set({
        id: 'msg-2',
        groupId: 'group:alice:1',
        senderId: 'bob',
        text: 'Eu quero escrever',
        createdAt: now.toISOString(),
        updatedAt: now.toISOString(),
        isDeleted: false,
      }),
    );
  } finally {
    await env.cleanup();
  }
});

test('denies reading a profile when the user has been blocked in either direction', async () => {
  const env = await makeEnv();
  try {
    const alice = env.authenticatedContext('alice');
    const bob = env.authenticatedContext('bob');
    const now = new Date();

    await alice.firestore().collection('profiles').doc('alice').set({
      id: 'alice',
      username: 'alice',
      displayName: 'Alice',
      createdAt: now.toISOString(),
      updatedAt: now.toISOString(),
      followersCount: 0,
      followingCount: 0,
      postCount: 0,
      isPrivate: false,
    });

    await alice.firestore().collection('relations').doc('block:alice:bob').set({
      id: 'block:alice:bob',
      sourceId: 'alice',
      targetId: 'bob',
      kind: 'block',
      createdAt: now.toISOString(),
    });

    await assertFails(
      bob.firestore().collection('profiles').doc('alice').get(),
    );
  } finally {
    await env.cleanup();
  }
});

test('denies mutating protected ownerId keys on profile updates', async () => {
  const env = await makeEnv();
  try {
    const alice = env.authenticatedContext('alice');
    const now = new Date();

    await alice.firestore().collection('profiles').doc('alice').set({
      id: 'alice',
      username: 'alice',
      displayName: 'Alice',
      createdAt: now.toISOString(),
      updatedAt: now.toISOString(),
      followersCount: 0,
      followingCount: 0,
      postCount: 0,
      isPrivate: false,
    });

    await assertFails(
      alice.firestore().collection('profiles').doc('alice').update({
        ownerId: 'mallory',
        updatedAt: new Date().toISOString(),
      }),
    );
  } finally {
    await env.cleanup();
  }
});

test('denies mutating protected role keys on group member updates', async () => {
  const env = await makeEnv();
  try {
    const alice = env.authenticatedContext('alice');
    const now = new Date();

    await alice.firestore().collection('groups').doc('group:alice:1').set({
      id: 'group:alice:1',
      ownerId: 'alice',
      name: 'Grupo da festa',
      description: 'Comunidade local',
      createdAt: now.toISOString(),
      updatedAt: now.toISOString(),
      isPrivate: false,
      memberRoles: { alice: 'owner' },
      bannedUserIds: [],
    });

    await alice.firestore().collection('groups').doc('group:alice:1').collection('members').doc('alice').set({
      groupId: 'group:alice:1',
      userId: 'alice',
      role: 'owner',
      createdAt: now.toISOString(),
      updatedAt: now.toISOString(),
    });

    await assertFails(
      alice.firestore().collection('groups').doc('group:alice:1').collection('members').doc('alice').update({
        role: 'admin',
        updatedAt: new Date().toISOString(),
      }),
    );
  } finally {
    await env.cleanup();
  }
});
