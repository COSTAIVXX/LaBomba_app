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

      // send FCM to the target if token available
      try {
        const userDoc = await db.collection('users').doc(targetUid).get();
        const userData = userDoc.data() || {};
        const token = (userData.fcmToken || userData.fcm_token || (Array.isArray(userData.fcmTokens) ? userData.fcmTokens[0] : null)) as string | undefined;
        if (token) {
          await admin.messaging().sendToDevice(token, {
            notification: {
              title: 'Nova reação',
              body: `${reaction?.userId} reagiu com ${type}`,
            },
            data: { postId, commentId, type: 'reaction' }
          });
        }
      } catch (e) {
        console.error('fcm send failed for comment reaction', e);
      }

      return null;
    } catch (err) {
      console.error('onCommentReactionCreated error', err);
      return null;
    }
  });


// Trigger when a new chat message is created: send FCM to recipient(s)
export const onChatMessageCreated = functions.firestore
  .document('chats/{chatId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    try {
      const msg = snap.data();
      const chatId = context.params.chatId as string;
      const sender = msg?.senderId as string | undefined;
      const text = msg?.text as string | undefined;

      // Determine recipients: prefer explicit 'to' or 'recipientId', otherwise derive from chatId parts
      let recipients: string[] = [];
      if (msg?.recipientId) recipients.push(msg.recipientId as string);
      if (msg?.to) recipients.push(msg.to as string);
      if (recipients.length === 0 && chatId) {
        const parts = chatId.split('_');
        recipients = parts.filter(p => p && p !== sender);
      }

      for (const uid of recipients) {
        try {
          const userDoc = await db.collection('users').doc(uid).get();
          const userData = userDoc.data() || {};
          const token = (userData.fcmToken || userData.fcm_token || (Array.isArray(userData.fcmTokens) ? userData.fcmTokens[0] : null)) as string | undefined;
          if (token) {
            await admin.messaging().sendToDevice(token, {
              notification: { title: 'Nova mensagem', body: text ?? 'Você tem uma nova mensagem' },
              data: { chatId, type: 'chat_message', sender: sender ?? '' }
            });
          }
        } catch (e) {
          console.error('fcm send failed for chat message', e);
        }
      }

      return null;
    } catch (err) {
      console.error('onChatMessageCreated error', err);
      return null;
    }
  });

// Trigger when a new group message is created: send FCM to group members
export const onGroupMessageCreated = functions.firestore
  .document('groups/{groupId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    try {
      const msg = snap.data();
      const groupId = context.params.groupId as string;
      const text = msg?.text as string | undefined;

      // try to load the group's members list
      const groupDoc = await db.collection('groups').doc(groupId).get();
      const members = groupDoc.data()?.members as string[] | undefined;
      if (!members || members.length === 0) return null;

      for (const uid of members) {
        // skip notifying sender if present
        if (uid == msg?.senderId) continue;
        try {
          const userDoc = await db.collection('users').doc(uid).get();
          const userData = userDoc.data() || {};
          const token = (userData.fcmToken || userData.fcm_token || (Array.isArray(userData.fcmTokens) ? userData.fcmTokens[0] : null)) as string | undefined;
          if (token) {
            await admin.messaging().sendToDevice(token, {
              notification: { title: `Novo no canal ${groupDoc.data()?.name ?? ''}`, body: text ?? 'Nova mensagem no canal' },
              data: { groupId, type: 'group_message' }
            });
          }
        } catch (e) {
          console.error('fcm send failed for group message', e);
        }
      }

      return null;
    } catch (err) {
      console.error('onGroupMessageCreated error', err);
      return null;
    }
  });
