import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Initialize admin if not already
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

// Trigger when a reaction doc is created under posts/{postId}/reactions/{reactionId}
export const onPostReactionCreated = functions.firestore
  .document('posts/{postId}/reactions/{reactionId}')
  .onCreate(async (snap, context) => {
    try {
      const reaction = snap.data();
      const postId = context.params.postId as string;
      const type = reaction?.type as string | undefined;
      const actor = reaction?.userId as string | undefined;

      if (!actor || !type) return null;

      // read post to determine target user (author)
      const postDoc = await db.collection('posts').doc(postId).get();
      const post = postDoc.data() || {};
      const targetUid = post['authorId'] as string?;

      if (!targetUid || targetUid == actor) return null; // don't notify self

      // create notification
      const n = {
        'type': 'reaction',
        'subtype': 'post',
        'actor': actor,
        'emoji': type,
        'postId': postId,
        'createdAt': admin.firestore.FieldValue.serverTimestamp(),
        'read': false
      };

      await db.collection('users').doc(targetUid).collection('notifications').add(n);
      return null;
    } catch (err) {
      console.error('onPostReactionCreated error', err);
      return null;
    }
  });

// Trigger when a reaction doc is deleted — could be used to remove aggregated notifications or log
export const onPostReactionDeleted = functions.firestore
  .document('posts/{postId}/reactions/{reactionId}')
  .onDelete(async (snap, context) => {
    // For now: no-op (placeholder for analytics or audit)
    return null;
  });

// Trigger when a reaction is created under a comment
export const onCommentReactionCreated = functions.firestore
  .document('posts/{postId}/comments/{commentId}/reactions/{reactionId}')
  .onCreate(async (snap, context) => {
    try {
      const reaction = snap.data();
      const postId = context.params.postId as string;
      const commentId = context.params.commentId as string;
      const type = reaction?.type as string | undefined;
      const actor = reaction?.userId as string | undefined;

      if (!actor || !type) return null;

      // fetch the post and comment to find comment author
      const postDoc = await db.collection('posts').doc(postId).get();
      const post = postDoc.data() || {};
      const comments = post['comments'] as any[]? ?? [];
            let targetUid: string | undefined;
            for (const c of comments) {
              if (c['id'] == commentId) {
                targetUid = c['authorId'] as string | undefined;
                break;
              }
            }

      if (!targetUid || targetUid == actor) return null;

      const n = {
        'type': 'reaction',
        'subtype': 'comment',
        'actor': actor,
        'emoji': type,
        'postId': postId,
        'commentId': commentId,
        'createdAt': admin.firestore.FieldValue.serverTimestamp(),
        'read': false
      };

      await db.collection('users').doc(targetUid).collection('notifications').add(n);
      return null;
    } catch (err) {
      console.error('onCommentReactionCreated error', err);
      return null;
    }
  });
