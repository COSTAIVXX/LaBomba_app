const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const admin = require('firebase-admin');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');

const rulesPath = path.resolve(__dirname, '..', '..', '..', 'firestore.rules');

let testEnv;

const makeUser = (uid, extra = {}) => ({
  displayName: 'User ' + uid,
  bio: 'bio',
  avatarUrl: null,
  private: false,
  settings: {},
  updatedAt: new Date(),
  language: 'pt-BR',
  following: [],
  followers: [],
  outgoingFollowRequests: [],
  incomingFollowRequests: [],
  blocked: [],
  muted: [],
  ...extra,
});

test.before(async () => {
  admin.initializeApp({ projectId: 'demo-labomba-rules' });
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-labomba-rules',
    firestore: {
      rules: fs.readFileSync(rulesPath, 'utf8'),
    },
  });
});

test.after(async () => {
  if (testEnv) {
    await testEnv.cleanup();
  }
});

test.beforeEach(async () => {
  await testEnv.clearFirestore();
});

test('user A cannot alter user B profile', async () => {
  const alice = testEnv.authenticatedContext('alice', { email: 'alice@example.com' });
  const bob = testEnv.authenticatedContext('bob', { email: 'bob@example.com' });

  await assertSucceeds(
    bob.firestore().collection('users').doc('bob').set(makeUser('bob')),
  );

  await assertFails(
    alice.firestore().collection('users').doc('bob').update({
      displayName: 'Hacked Profile',
    }),
  );
});

test('user A cannot delete post of user B', async () => {
  const alice = testEnv.authenticatedContext('alice', { email: 'alice@example.com' });
  const bob = testEnv.authenticatedContext('bob', { email: 'bob@example.com' });

  await assertSucceeds(
    bob.firestore().collection('posts').doc('post-b').set({
      authorId: 'bob',
      content: 'Post seguro',
      createdAt: new Date(),
      updatedAt: new Date(),
    }),
  );

  await assertFails(alice.firestore().collection('posts').doc('post-b').delete());
});

test('user A cannot edit story of user B', async () => {
  const alice = testEnv.authenticatedContext('alice', { email: 'alice@example.com' });

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    await adminDb.collection('users').doc('bob').collection('stories').doc('story-b').set({
      userId: 'bob',
      type: 'image',
      mediaUrl: 'https://example.com/story.jpg',
      createdAt: new Date(),
      duration: 5,
    });
  });

  await assertFails(
    alice.firestore().collection('users').doc('bob').collection('stories').doc('story-b').update({
      mediaUrl: 'https://evil.example/owned-story.jpg',
    }),
  );
});

test('non-admin user cannot execute administrative action', async () => {
  const alice = testEnv.authenticatedContext('alice', { email: 'alice@example.com' });

  await assertFails(
    alice.firestore().collection('admin_requests').add({
      type: 'delete_post',
      createdBy: 'alice',
      actorUid: 'alice',
      createdAt: new Date(),
      status: 'pending',
      resourceType: 'post',
      resourceId: 'post-123',
      reason: 'Exploit attempt',
    }),
  );
});

test('non-participant cannot read private conversation', async () => {
  const alice = testEnv.authenticatedContext('alice', { email: 'alice@example.com' });
  const bob = testEnv.authenticatedContext('bob', { email: 'bob@example.com' });
  const charlie = testEnv.authenticatedContext('charlie', { email: 'charlie@example.com' });

  await assertSucceeds(
    alice.firestore().collection('chats').doc('chat-1').set({
      members: ['alice', 'bob'],
      createdAt: new Date(),
      title: 'Private chat',
    }),
  );

  await assertFails(charlie.firestore().collection('chats').doc('chat-1').get());
  await assertSucceeds(bob.firestore().collection('chats').doc('chat-1').get());
});

test('user cannot change authorId in a post', async () => {
  const alice = testEnv.authenticatedContext('alice', { email: 'alice@example.com' });

  await assertSucceeds(
    alice.firestore().collection('posts').doc('post-author-guard').set({
      authorId: 'alice',
      content: 'Texto',
      createdAt: new Date(),
      updatedAt: new Date(),
    }),
  );

  await assertFails(
    alice.firestore().collection('posts').doc('post-author-guard').update({
      authorId: 'mallory',
    }),
  );
});

test('user cannot modify roles field on own user document', async () => {
  const alice = testEnv.authenticatedContext('alice', { email: 'alice@example.com' });

  await assertSucceeds(
    alice.firestore().collection('users').doc('alice').set(makeUser('alice')),
  );

  await assertFails(
    alice.firestore().collection('users').doc('alice').update({
      roles: ['admin'],
    }),
  );
});

test('private profile is not readable by unrelated user', async () => {
  const alice = testEnv.authenticatedContext('alice', { email: 'alice@example.com' });
  const bob = testEnv.authenticatedContext('bob', { email: 'bob@example.com' });

  await assertSucceeds(
    bob.firestore().collection('users').doc('bob').set(makeUser('bob', {
      private: true,
      followers: [],
    })),
  );

  await assertFails(alice.firestore().collection('users').doc('bob').get());
});

test('user can create follow relationship docs in subcollections', async () => {
  const alice = testEnv.authenticatedContext('alice', { email: 'alice@example.com' });

  await assertSucceeds(
    alice.firestore().collection('users').doc('bob').collection('followers').doc('alice').set({
      userId: 'bob',
      followerId: 'alice',
      createdAt: new Date(),
    }),
  );

  await assertSucceeds(
    alice.firestore().collection('users').doc('alice').collection('following').doc('bob').set({
      userId: 'alice',
      followingId: 'bob',
      createdAt: new Date(),
    }),
  );
});

test('user cannot create follow relationship for another user', async () => {
  const alice = testEnv.authenticatedContext('alice', { email: 'alice@example.com' });
  const charlie = testEnv.authenticatedContext('charlie', { email: 'charlie@example.com' });

  await assertFails(
    charlie.firestore().collection('users').doc('alice').collection('followers').doc('bob').set({
      userId: 'alice',
      followerId: 'bob',
      createdAt: new Date(),
    }),
  );
});
