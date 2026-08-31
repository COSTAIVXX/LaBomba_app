"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.processAdminRequest = exports.assignRoleClaims = exports.submitAdminRequest = exports.onAdminAuditLogCreated = exports.onAdminRequestCreated = exports.submitReport = exports.onGroupMessageCreated = exports.onChatMessageCreated = exports.onCommentReactionCreated = exports.onPostReactionDeleted = exports.onPostReactionCreated = exports.onStoryCreated = exports.onPostCreated = exports.onUserCreated = void 0;
exports.validateAdminActionPayload = validateAdminActionPayload;
exports.normalizeRoleName = normalizeRoleName;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
// Initialize admin if not already
if (!admin.apps.length) {
    admin.initializeApp();
}
const db = admin.firestore();
const systemEventsCollection = 'system_events';
const systemMetricsCollection = 'system_metrics';
const systemMetricsDocumentId = 'overview';
const VALID_ADMIN_ACTIONS = new Set([
    'delete_post',
    'ban_user',
    'mass_fcm',
    'assignRoleClaims',
    'moderate_community',
    'review_story',
    'system_alert',
    'unknown_action',
]);
const VALID_RESOURCE_TYPES = new Set([
    'user',
    'post',
    'story',
    'comment',
    'message',
    'group',
    'community',
    'broadcast',
    'target',
    'unknown',
]);
const MAX_REASON_LENGTH = 500;
const MAX_DETAILS_BYTES = 16384;
const REDACTED_LOG_VALUE = '[REDACTED]';
const SENSITIVE_LOG_KEYS = [
    'password',
    'token',
    'authorization',
    'secret',
    'api_key',
    'apikey',
    'refresh_token',
    'cookie',
    'session',
    'email',
    'phone',
    'cpf',
    'ssn',
];
function sanitizeForLogs(value, maxDepth = 2) {
    if (value === null || value === undefined) {
        return value;
    }
    if (Array.isArray(value)) {
        return value.slice(0, 8).map((entry) => sanitizeForLogs(entry, maxDepth - 1));
    }
    if (typeof value === 'string') {
        return value.length > 256 ? `${value.slice(0, 253)}...` : value;
    }
    if (typeof value === 'number' || typeof value === 'boolean') {
        return value;
    }
    if (typeof value === 'object') {
        if (maxDepth < 0) {
            return '[TRUNCATED]';
        }
        const sanitized = {};
        for (const [key, raw] of Object.entries(value)) {
            const keyLower = key.toLowerCase();
            if (SENSITIVE_LOG_KEYS.some((sensitiveKey) => keyLower.includes(sensitiveKey))) {
                sanitized[key] = REDACTED_LOG_VALUE;
                continue;
            }
            sanitized[key] = sanitizeForLogs(raw, maxDepth - 1);
        }
        return sanitized;
    }
    return String(value);
}
function logStructured(level, event, payload = {}) {
    const entry = {
        ts: new Date().toISOString(),
        level,
        event,
        payload: sanitizeForLogs(payload),
    };
    if (level === 'error') {
        console.error(JSON.stringify(entry));
        return;
    }
    if (level === 'warn') {
        console.warn(JSON.stringify(entry));
        return;
    }
    console.log(JSON.stringify(entry));
}
function sanitizeString(value, maxLength, fallback) {
    if (typeof value !== 'string') {
        return fallback;
    }
    const trimmed = value.trim();
    if (!trimmed) {
        return fallback;
    }
    return trimmed.slice(0, maxLength);
}
function normalizeAdminAction(rawAction) {
    if (typeof rawAction !== 'string') {
        return 'unknown_action';
    }
    const normalized = rawAction.trim().toLowerCase().replace(/[^a-z0-9_]/g, '_');
    if (!normalized || normalized.length > 64) {
        return 'unknown_action';
    }
    return normalized;
}
function normalizeResourceType(rawType) {
    if (typeof rawType !== 'string') {
        return 'unknown';
    }
    const normalized = rawType.trim().toLowerCase();
    return VALID_RESOURCE_TYPES.has(normalized) ? normalized : 'unknown';
}
function isValidResourceId(value) {
    if (typeof value !== 'string') {
        return false;
    }
    const normalized = value.trim();
    if (!normalized || normalized.length > 128) {
        return false;
    }
    return /^[A-Za-z0-9._:-]+$/.test(normalized);
}
const VALID_REPORT_CATEGORIES = new Set([
    'spam',
    'harassment',
    'hate',
    'sexual_content',
    'violence',
    'fraud',
    'impersonation',
    'illegal_content',
    'account_compromised',
    'other',
]);
const VALID_REPORT_TYPES = new Set([
    'user',
    'post',
    'comment',
    'story',
    'message',
    'community',
    'group',
    'event',
    'profile',
    'other',
]);
function normalizeReportCategory(rawCategory) {
    if (typeof rawCategory !== 'string') {
        return 'other';
    }
    const normalized = rawCategory.trim().toLowerCase().replace(/[^a-z0-9_]/g, '_');
    return VALID_REPORT_CATEGORIES.has(normalized) ? normalized : 'other';
}
function normalizeReportType(rawType) {
    if (typeof rawType !== 'string') {
        return 'other';
    }
    const normalized = rawType.trim().toLowerCase();
    return VALID_REPORT_TYPES.has(normalized) ? normalized : 'other';
}
function validateReportPayload(payload) {
    if (!payload || typeof payload !== 'object') {
        return { ok: false, error: 'Report payload is required.' };
    }
    const reportType = normalizeReportType(payload.resourceType ?? payload.type ?? 'other');
    const category = normalizeReportCategory(payload.category ?? 'other');
    const resourceId = sanitizeString(payload.resourceId ?? payload.postId ?? payload.userId ?? payload.commentId ?? payload.storyId ?? payload.messageId ?? payload.targetId ?? '', 128, '');
    const reason = sanitizeString(payload.reason ?? payload.details?.reason ?? 'Report submitted via secure backend', MAX_REASON_LENGTH, 'Report submitted via secure backend');
    if (!VALID_REPORT_TYPES.has(reportType)) {
        return { ok: false, error: 'Unsupported report type.' };
    }
    if (!VALID_REPORT_CATEGORIES.has(category)) {
        return { ok: false, error: 'Unsupported report category.' };
    }
    if (!resourceId || !isValidResourceId(resourceId)) {
        return { ok: false, error: 'A valid resourceId is required.' };
    }
    const details = payload.details && typeof payload.details === 'object' && !Array.isArray(payload.details)
        ? payload.details
        : {};
    const normalizedDetails = JSON.stringify(details);
    if (normalizedDetails.length > MAX_DETAILS_BYTES) {
        return { ok: false, error: 'Report details exceed the maximum size.' };
    }
    return {
        ok: true,
        category,
        resourceType: reportType,
        resourceId,
        reason,
        details,
    };
}
function validateAdminActionPayload(payload) {
    const rawAction = payload?.type ?? payload?.action ?? 'unknown_action';
    const action = normalizeAdminAction(rawAction);
    if (!VALID_ADMIN_ACTIONS.has(action)) {
        return {
            ok: false,
            action,
            resourceType: 'unknown',
            resourceId: '',
            reason: '',
            details: {},
            error: `Unsupported admin action: ${String(rawAction)}`,
        };
    }
    const resourceType = normalizeResourceType(payload?.resourceType ?? inferResourceType(payload ?? {}));
    if (!VALID_RESOURCE_TYPES.has(resourceType)) {
        return {
            ok: false,
            action,
            resourceType,
            resourceId: '',
            reason: '',
            details: {},
            error: 'Invalid resource type for privileged admin action.',
        };
    }
    const rawResourceId = payload?.resourceId ?? payload?.postId ?? payload?.userId ?? payload?.targetId ?? payload?.storyId ?? payload?.messageId ?? 'unknown';
    const resourceId = sanitizeString(rawResourceId, 128, '');
    if (!isValidResourceId(resourceId)) {
        return {
            ok: false,
            action,
            resourceType,
            resourceId: '',
            reason: '',
            details: {},
            error: 'Admin action requires a valid resourceId.',
        };
    }
    const reason = sanitizeString(payload?.reason ?? 'Administrative action requested from control center', MAX_REASON_LENGTH, 'Administrative action requested from control center');
    const rawDetails = payload?.details && typeof payload.details === 'object' && !Array.isArray(payload.details)
        ? payload.details
        : {};
    const detailsJSON = JSON.stringify(rawDetails);
    if (detailsJSON.length > MAX_DETAILS_BYTES) {
        return {
            ok: false,
            action,
            resourceType,
            resourceId,
            reason,
            details: {},
            error: 'Admin action details are too large.',
        };
    }
    return {
        ok: true,
        action,
        resourceType,
        resourceId,
        reason,
        details: rawDetails,
    };
}
function normalizeRoleName(rawRole) {
    if (typeof rawRole !== 'string') {
        return 'user';
    }
    const normalized = rawRole.trim().toLowerCase();
    return ['owner', 'admin', 'moderator', 'user'].includes(normalized) ? normalized : 'user';
}
async function updateOverviewMetric(metricKey, delta, value) {
    const update = {
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (value !== undefined) {
        update[metricKey] = value;
    }
    else {
        update[metricKey] = admin.firestore.FieldValue.increment(delta);
    }
    await db.collection(systemMetricsCollection).doc(systemMetricsDocumentId).set(update, { merge: true });
}
async function writeSystemEvent(eventType, payload, severity = 'info', source = 'backend') {
    const event = {
        eventType,
        severity,
        source,
        payload: payload ?? {},
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    await db.collection(systemEventsCollection).add(event);
}
exports.onUserCreated = functions.firestore
    .document('users/{userId}')
    .onCreate(async (snap, context) => {
    const userId = context.params.userId;
    const payload = {
        userId,
        createdAt: snap.get('createdAt') ?? admin.firestore.Timestamp.now(),
    };
    await writeSystemEvent('user_created', payload, 'info');
    await updateOverviewMetric('newUsersToday', 1);
    return null;
});
exports.onPostCreated = functions.firestore
    .document('posts/{postId}')
    .onCreate(async (snap, context) => {
    const postId = context.params.postId;
    const authorId = snap.data()?.authorId ?? 'unknown';
    await writeSystemEvent('post_created', { postId, authorId }, 'info');
    await updateOverviewMetric('newPostsToday', 1);
    return null;
});
exports.onStoryCreated = functions.firestore
    .document('users/{userId}/stories/{storyId}')
    .onCreate(async (snap, context) => {
    const userId = context.params.userId;
    const storyId = context.params.storyId;
    const payload = {
        userId,
        storyId,
        createdAt: snap.get('createdAt') ?? admin.firestore.Timestamp.now(),
    };
    await writeSystemEvent('story_created', payload, 'info');
    await updateOverviewMetric('storiesPublishedToday', 1);
    return null;
});
// Trigger when a reaction doc is created under posts/{postId}/reactions/{reactionId}
exports.onPostReactionCreated = functions.firestore
    .document('posts/{postId}/reactions/{reactionId}')
    .onCreate(async (snap, context) => {
    try {
        const reaction = snap.data();
        const postId = context.params.postId;
        const type = reaction?.type;
        const actor = reaction?.userId;
        if (!actor || !type)
            return null;
        // read post to determine target user (author)
        const postDoc = await db.collection('posts').doc(postId).get();
        const post = postDoc.data() || {};
        const targetUid = post['authorId'];
        if (!targetUid || targetUid == actor)
            return null; // don't notify self
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
    }
    catch (err) {
        logStructured('error', 'on_post_reaction_created', {
            error: sanitizeForLogs(err),
            postId: context.params.postId,
        });
        return null;
    }
});
// Trigger when a reaction doc is deleted — could be used to remove aggregated notifications or log
exports.onPostReactionDeleted = functions.firestore
    .document('posts/{postId}/reactions/{reactionId}')
    .onDelete(async (snap, context) => {
    // For now: no-op (placeholder for analytics or audit)
    return null;
});
// Trigger when a reaction is created under a comment
exports.onCommentReactionCreated = functions.firestore
    .document('posts/{postId}/comments/{commentId}/reactions/{reactionId}')
    .onCreate(async (snap, context) => {
    try {
        const reaction = snap.data();
        const postId = context.params.postId;
        const commentId = context.params.commentId;
        const type = reaction?.type;
        const actor = reaction?.userId;
        if (!actor || !type)
            return null;
        // fetch the post and comment to find comment author
        const postDoc = await db.collection('posts').doc(postId).get();
        const post = postDoc.data() || {};
        const comments = post['comments'] ?? [];
        let targetUid;
        for (const c of comments) {
            if (c['id'] == commentId) {
                targetUid = c['authorId'];
                break;
            }
        }
        if (!targetUid || targetUid == actor)
            return null;
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
            const token = (userData.fcmToken || userData.fcm_token || (Array.isArray(userData.fcmTokens) ? userData.fcmTokens[0] : null));
            if (token) {
                await admin.messaging().sendToDevice(token, {
                    notification: {
                        title: 'Nova reação',
                        body: `${reaction?.userId} reagiu com ${type}`,
                    },
                    data: { postId, commentId, type: 'reaction' }
                });
            }
        }
        catch (e) {
            logStructured('error', 'fcm_send_failed_comment_reaction', {
                error: sanitizeForLogs(e),
                commentId,
                postId,
            });
        }
        return null;
    }
    catch (err) {
        logStructured('error', 'on_comment_reaction_created', {
            error: sanitizeForLogs(err),
            postId: context.params.postId,
            commentId: context.params.commentId,
        });
        return null;
    }
});
// Trigger when a new chat message is created: send FCM to recipient(s)
exports.onChatMessageCreated = functions.firestore
    .document('chats/{chatId}/messages/{messageId}')
    .onCreate(async (snap, context) => {
    const chatId = context.params.chatId;
    const msg = snap.data();
    const sender = msg?.senderId;
    try {
        const text = msg?.text;
        // Determine recipients: prefer explicit 'to' or 'recipientId', otherwise derive from chatId parts
        let recipients = [];
        if (msg?.recipientId)
            recipients.push(msg.recipientId);
        if (msg?.to)
            recipients.push(msg.to);
        if (recipients.length === 0 && chatId) {
            const parts = chatId.split('_');
            recipients = parts.filter(p => p && p !== sender);
        }
        for (const uid of recipients) {
            try {
                const userDoc = await db.collection('users').doc(uid).get();
                const userData = userDoc.data() || {};
                const token = (userData.fcmToken || userData.fcm_token || (Array.isArray(userData.fcmTokens) ? userData.fcmTokens[0] : null));
                if (token) {
                    await admin.messaging().sendToDevice(token, {
                        notification: { title: 'Nova mensagem', body: text ?? 'Você tem uma nova mensagem' },
                        data: { chatId, type: 'chat_message', sender: sender ?? '' }
                    });
                }
            }
            catch (e) {
                logStructured('error', 'fcm_send_failed_chat_message', {
                    error: sanitizeForLogs(e),
                    chatId,
                    sender,
                });
            }
        }
        await writeSystemEvent('message_sent', {
            chatId,
            senderId: sender ?? 'unknown',
            recipientCount: recipients.length,
        }, 'info');
        await updateOverviewMetric('messagesSentToday', 1);
        return null;
    }
    catch (err) {
        logStructured('error', 'on_chat_message_created', {
            error: sanitizeForLogs(err),
            chatId,
            sender,
        });
        return null;
    }
});
// Trigger when a new group message is created: send FCM to group members
exports.onGroupMessageCreated = functions.firestore
    .document('groups/{groupId}/messages/{messageId}')
    .onCreate(async (snap, context) => {
    const groupId = context.params.groupId;
    try {
        const msg = snap.data();
        const text = msg?.text;
        // try to load the group's members list
        const groupDoc = await db.collection('groups').doc(groupId).get();
        const members = groupDoc.data()?.members;
        if (!members || members.length === 0)
            return null;
        for (const uid of members) {
            // skip notifying sender if present
            if (uid == msg?.senderId)
                continue;
            try {
                const userDoc = await db.collection('users').doc(uid).get();
                const userData = userDoc.data() || {};
                const token = (userData.fcmToken || userData.fcm_token || (Array.isArray(userData.fcmTokens) ? userData.fcmTokens[0] : null));
                if (token) {
                    await admin.messaging().sendToDevice(token, {
                        notification: { title: `Novo no canal ${groupDoc.data()?.name ?? ''}`, body: text ?? 'Nova mensagem no canal' },
                        data: { groupId, type: 'group_message' }
                    });
                }
            }
            catch (e) {
                logStructured('error', 'fcm_send_failed_group_message', {
                    error: sanitizeForLogs(e),
                    groupId,
                });
            }
        }
        return null;
    }
    catch (err) {
        logStructured('error', 'on_group_message_created', {
            error: sanitizeForLogs(err),
            groupId,
        });
        return null;
    }
});
exports.submitReport = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Authentication required to submit a report.');
    }
    const validated = validateReportPayload(data);
    if (!validated.ok) {
        throw new functions.https.HttpsError('invalid-argument', validated.error ?? 'Invalid report payload.');
    }
    const reporterId = context.auth.uid;
    const reportId = `report_${Date.now()}_${reporterId}`;
    const now = admin.firestore.FieldValue.serverTimestamp();
    const reportDoc = {
        reportId,
        reporterId,
        resourceType: validated.resourceType,
        resourceId: validated.resourceId,
        category: validated.category,
        reason: validated.reason,
        details: validated.details,
        status: 'pending',
        priority: 'normal',
        createdAt: now,
        updatedAt: now,
        source: 'app',
    };
    await db.collection('reports').doc(reportId).set(reportDoc);
    await writeSystemEvent('report_submitted', {
        reportId,
        reporterId,
        resourceType: validated.resourceType,
        resourceId: validated.resourceId,
        category: validated.category,
    }, 'info');
    return { ok: true, reportId, status: 'pending' };
});
exports.onAdminRequestCreated = functions.firestore
    .document('admin_requests/{requestId}')
    .onCreate(async (snap, context) => {
    const requestId = context.params.requestId;
    const data = snap.data() ?? {};
    const action = String(data.type ?? 'unknown_action');
    const resourceType = String(data.resourceType ?? 'unknown');
    const actorUid = String(data.createdBy ?? data.actorUid ?? data.requestedBy ?? 'unknown');
    await writeSystemEvent('admin_request_created', {
        requestId,
        actorUid,
        action,
        resourceType,
        reason: String(data.reason ?? 'admin_request_created'),
    }, action === 'mass_fcm' ? 'warning' : 'info');
    await updateOverviewMetric('pendingAdminActions', 1);
    return null;
});
exports.onAdminAuditLogCreated = functions.firestore
    .document('admin_audit_logs/{logId}')
    .onCreate(async (snap, context) => {
    const logId = context.params.logId;
    const data = snap.data() ?? {};
    await writeSystemEvent('admin_action_logged', {
        logId,
        action: String(data.action ?? 'unknown_action'),
        actorUid: String(data.actorUid ?? 'unknown'),
        resourceType: String(data.resourceType ?? 'unknown'),
    }, 'info');
    await updateOverviewMetric('adminActionsToday', 1);
    return null;
});
const CRITICAL_ADMIN_ACTIONS = new Set([
    'delete_post',
    'ban_user',
    'mass_fcm',
    'assignRoleClaims',
    'moderate_community',
    'review_story',
    'system_alert',
]);
const FRESH_AUTH_WINDOW_SECONDS = 15 * 60;
function ensureFreshAdminAuth(context, action) {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
    }
    const authTime = Number(context.auth.token?.auth_time ?? 0);
    const nowSeconds = Math.floor(Date.now() / 1000);
    if (CRITICAL_ADMIN_ACTIONS.has(action) && (!authTime || nowSeconds - authTime > FRESH_AUTH_WINDOW_SECONDS)) {
        throw new functions.https.HttpsError('permission-denied', 'Recent authentication is required before executing this protected action.');
    }
}
exports.submitAdminRequest = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
    }
    const validatedRequest = validateAdminActionPayload(data);
    if (!validatedRequest.ok) {
        throw new functions.https.HttpsError('invalid-argument', validatedRequest.error ?? 'Invalid admin action payload.');
    }
    ensureFreshAdminAuth(context, validatedRequest.action);
    const actorUid = context.auth.uid;
    const { action, resourceType, resourceId, reason, details } = validatedRequest;
    const user = await admin.auth().getUser(actorUid);
    const claims = user.customClaims ?? {};
    const isPrivileged = claims.owner === true || claims.isOwner === true || claims.admin === true || claims.isAdmin === true || claims.role === 'owner' || claims.role === 'admin';
    if (!isPrivileged) {
        throw new functions.https.HttpsError('permission-denied', 'Only authorized admin roles can submit backend actions.');
    }
    const requestId = `admin_req_${Date.now()}_${actorUid}`;
    const doc = {
        id: requestId,
        requestId,
        type: action,
        resourceType,
        resourceId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        createdBy: actorUid,
        requestedBy: actorUid,
        actorUid,
        authTime: context.auth.token?.auth_time ?? Math.floor(Date.now() / 1000),
        requiresFreshAuth: CRITICAL_ADMIN_ACTIONS.has(action),
        status: 'pending',
        result: 'pending',
        reason,
        details: {
            source: 'control_center',
            ...details,
        },
    };
    await db.collection('admin_requests').add(doc);
    await writeSystemEvent('admin_request_submitted', {
        requestId,
        actorUid,
        action,
        resourceType,
        resourceId,
    }, 'warning');
    return { ok: true, requestId, status: 'pending' };
});
exports.assignRoleClaims = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
    }
    ensureFreshAdminAuth(context, 'assignRoleClaims');
    const actorUid = context.auth.uid;
    const requestedRole = normalizeRoleName(data?.role ?? 'user');
    const targetUid = sanitizeString(data?.uid ?? data?.targetUid ?? actorUid, 128, '');
    if (!['owner', 'admin', 'moderator', 'user'].includes(requestedRole)) {
        throw new functions.https.HttpsError('invalid-argument', 'Unsupported role value.');
    }
    if (!targetUid || !isValidResourceId(targetUid)) {
        throw new functions.https.HttpsError('invalid-argument', 'Target user ID is invalid.');
    }
    const actorClaims = (await admin.auth().getUser(actorUid)).customClaims ?? {};
    const actorEffectiveRole = String(actorClaims.role ?? 'user');
    const isOwnerActor = actorEffectiveRole === 'owner' || actorClaims.owner === true || actorClaims.isOwner === true;
    if (!isOwnerActor) {
        throw new functions.https.HttpsError('permission-denied', 'Only the owner can assign authority roles.');
    }
    if (requestedRole !== 'user' && targetUid !== actorUid && requestedRole === 'owner') {
        throw new functions.https.HttpsError('permission-denied', 'Owner role may only be assigned to the owner account.');
    }
    const claims = {
        role: requestedRole,
        owner: requestedRole === 'owner',
        admin: requestedRole === 'admin' || requestedRole === 'owner',
        moderator: requestedRole === 'moderator',
        isOwner: requestedRole === 'owner',
        isAdmin: requestedRole === 'admin' || requestedRole === 'owner',
        isServer: false,
    };
    await admin.auth().setCustomUserClaims(targetUid, claims);
    return { ok: true, uid: targetUid, role: requestedRole };
});
// --- Admin request processor ---
const adminRequestCollection = 'admin_requests';
const auditLogCollection = 'admin_audit_logs';
async function isPrivilegedActor(uid) {
    try {
        const user = await admin.auth().getUser(uid);
        if (user.customClaims?.admin === true || user.customClaims?.isAdmin === true || user.customClaims?.isServer === true) {
            return true;
        }
    }
    catch (e) {
        logStructured('warn', 'admin_actor_claim_lookup_failed', {
            actorUid: uid,
            error: sanitizeForLogs(e),
        });
    }
    try {
        const adminProfile = await db.collection('admin_profiles').doc(uid).get();
        return !!adminProfile.exists && adminProfile.data()?.isAdmin === true;
    }
    catch (e) {
        logStructured('warn', 'admin_actor_profile_lookup_failed', {
            actorUid: uid,
            error: sanitizeForLogs(e),
        });
        return false;
    }
}
async function writeAuditLog(payload) {
    const auditDoc = {
        action: payload.action,
        actorUid: payload.actorUid,
        resourceType: payload.resourceType,
        resourceId: payload.resourceId,
        requestId: payload.requestId,
        status: payload.status,
        result: payload.result,
        reason: payload.reason,
        details: payload.details ?? {},
        executedAt: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        source: 'backend',
    };
    await db.collection(auditLogCollection).add(auditDoc);
}
function inferResourceType(requestData) {
    if (requestData.userId)
        return 'user';
    if (requestData.postId)
        return 'post';
    if (requestData.targetId)
        return 'target';
    if (requestData.broadcast)
        return 'broadcast';
    return 'unknown';
}
exports.processAdminRequest = functions.firestore
    .document(`${adminRequestCollection}/{requestId}`)
    .onCreate(async (snap, context) => {
    const requestId = context.params.requestId;
    const requestData = snap.data();
    if (!requestData) {
        return null;
    }
    const validatedRequest = validateAdminActionPayload(requestData);
    if (!validatedRequest.ok) {
        await snap.ref.update({
            status: 'rejected',
            result: 'invalid_payload',
            decisionBy: 'backend',
            rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
            reason: validatedRequest.error ?? 'Rejected invalid admin request payload.',
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        await writeAuditLog({
            action: normalizeAdminAction(requestData?.type ?? requestData?.action ?? 'unknown_action'),
            actorUid: String(requestData?.createdBy ?? requestData?.actorUid ?? requestData?.requestedBy ?? 'unknown'),
            resourceType: normalizeResourceType(requestData?.resourceType ?? inferResourceType(requestData ?? {})),
            resourceId: sanitizeString(requestData?.resourceId ?? requestData?.postId ?? requestData?.userId ?? requestData?.targetId ?? 'unknown', 128, ''),
            requestId,
            status: 'rejected',
            result: 'invalid_payload',
            reason: validatedRequest.error ?? 'Rejected invalid admin request payload.',
            details: { originalRequest: requestData },
        });
        return null;
    }
    const actorUid = (requestData.createdBy || requestData.actorUid || requestData.requestedBy);
    const action = validatedRequest.action;
    const resourceType = validatedRequest.resourceType;
    const resourceId = validatedRequest.resourceId;
    try {
        if (!actorUid) {
            throw new Error('Missing actorUid on admin request');
        }
        const authTimeSeconds = Number(requestData.authTime ?? 0);
        const actionNeedsFreshAuth = Boolean(requestData.requiresFreshAuth) || CRITICAL_ADMIN_ACTIONS.has(action);
        const nowSeconds = Math.floor(Date.now() / 1000);
        if (actionNeedsFreshAuth && (!authTimeSeconds || nowSeconds - authTimeSeconds > FRESH_AUTH_WINDOW_SECONDS)) {
            const reason = 'Admin action requires recent authentication and was rejected by the backend';
            await snap.ref.update({
                status: 'rejected',
                result: 'fresh_auth_required',
                decisionBy: 'backend',
                rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
                reason,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            await writeAuditLog({
                action,
                actorUid,
                resourceType,
                resourceId,
                requestId,
                status: 'rejected',
                result: 'fresh_auth_required',
                reason,
                details: { originalRequest: requestData },
            });
            return null;
        }
        const authorized = await isPrivilegedActor(actorUid);
        if (!authorized) {
            const reason = 'Actor does not have privileged admin access';
            await snap.ref.update({
                status: 'rejected',
                result: 'denied',
                decisionBy: 'backend',
                rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
                reason,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            await writeAuditLog({
                action,
                actorUid,
                resourceType,
                resourceId,
                requestId,
                status: 'rejected',
                result: 'denied',
                reason,
                details: { originalRequest: requestData },
            });
            return null;
        }
        switch (action) {
            case 'delete_post': {
                const postId = String(requestData.postId || resourceId);
                const postRef = db.collection('posts').doc(postId);
                const postDoc = await postRef.get();
                if (postDoc.exists) {
                    await postRef.update({
                        deleted: true,
                        moderationState: 'deleted',
                        deletedBy: actorUid,
                        deletedAt: admin.firestore.FieldValue.serverTimestamp(),
                        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
                }
                await snap.ref.update({
                    status: 'executed',
                    result: 'success',
                    executedBy: actorUid,
                    executedAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                await writeAuditLog({
                    action,
                    actorUid,
                    resourceType: 'post',
                    resourceId: postId,
                    requestId,
                    status: 'executed',
                    result: 'success',
                    reason: 'Post deletion approved by backend',
                    details: { postId },
                });
                return null;
            }
            case 'ban_user': {
                const userId = String(requestData.userId || resourceId);
                const userRef = db.collection('users').doc(userId);
                await userRef.set({
                    banned: true,
                    moderationState: 'banned',
                    bannedBy: actorUid,
                    bannedAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                }, { merge: true });
                await snap.ref.update({
                    status: 'executed',
                    result: 'success',
                    executedBy: actorUid,
                    executedAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                await writeAuditLog({
                    action,
                    actorUid,
                    resourceType: 'user',
                    resourceId: userId,
                    requestId,
                    status: 'executed',
                    result: 'success',
                    reason: 'User banned by backend-approved admin action',
                    details: { userId },
                });
                return null;
            }
            case 'mass_fcm': {
                const title = String(requestData.title || 'La Bomba');
                const body = String(requestData.body || 'Nova atualização da comunidade');
                const usersSnap = await db.collection('users').get();
                for (const userDoc of usersSnap.docs) {
                    const userData = userDoc.data() ?? {};
                    const token = (userData.fcmToken || userData.fcm_token || (Array.isArray(userData.fcmTokens) ? userData.fcmTokens[0] : null));
                    if (!token)
                        continue;
                    try {
                        await admin.messaging().sendToDevice(token, {
                            notification: { title, body },
                            data: { type: 'admin_broadcast', source: 'admin_requests' },
                        });
                    }
                    catch (error) {
                        logStructured('error', 'admin_broadcast_send_failed', {
                            error: sanitizeForLogs(error),
                            userId: userDoc.id,
                        });
                    }
                }
                await snap.ref.update({
                    status: 'executed',
                    result: 'success',
                    executedBy: actorUid,
                    executedAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                await writeAuditLog({
                    action,
                    actorUid,
                    resourceType: 'broadcast',
                    resourceId: 'mass_fcm',
                    requestId,
                    status: 'executed',
                    result: 'success',
                    reason: 'Mass FCM broadcast executed by backend',
                    details: { title, sentUsers: usersSnap.docs.length },
                });
                return null;
            }
            default: {
                const reason = `Unsupported admin action: ${action}`;
                await snap.ref.update({
                    status: 'rejected',
                    result: 'unsupported_action',
                    rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
                    reason,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                await writeAuditLog({
                    action,
                    actorUid,
                    resourceType,
                    resourceId,
                    requestId,
                    status: 'rejected',
                    result: 'unsupported_action',
                    reason,
                    details: { originalRequest: requestData },
                });
                return null;
            }
        }
    }
    catch (error) {
        const message = error instanceof Error ? error.message : 'Unknown admin request processing error';
        await snap.ref.update({
            status: 'failed',
            result: 'error',
            failureReason: message,
            failedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        await writeAuditLog({
            action,
            actorUid,
            resourceType,
            resourceId,
            requestId,
            status: 'failed',
            result: 'error',
            reason: message,
            details: { originalRequest: requestData },
        });
        logStructured('error', 'process_admin_request_failed', {
            action,
            actorUid,
            resourceType,
            resourceId,
            requestId,
            error: sanitizeForLogs(error),
        });
        return null;
    }
});
//# sourceMappingURL=index.js.map