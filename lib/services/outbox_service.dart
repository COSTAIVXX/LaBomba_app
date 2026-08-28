import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'storage_platform.dart';
import 'storage_service.dart';

/// OutboxService: persist social write operations locally and sync them when
/// connectivity is restored. Uses StorageService as durable backing store.
class OutboxService {
  static final OutboxService instance = OutboxService._internal();

  final FirebaseFirestore _firestore;
  final StorageService _storage;
  StreamSubscription<ConnectivityResult>? _connSub;
  final String _key = 'social:outbox_v1';
  bool _processing = false;

  OutboxService._internal()
      : _firestore = FirebaseFirestore.instance,
        _storage = PlatformStorageService() {
    _listenConnectivity();
    // try processing at startup (best-effort)
    _processQueue();
  }

  void _listenConnectivity() {
    try {
      _connSub = Connectivity().onConnectivityChanged.listen((result) {
        if (result != ConnectivityResult.none) {
          _processQueue();
        }
      });
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _connSub?.cancel();
  }

  Future<List<Map<String, dynamic>>> _readQueue() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null || raw.isEmpty) return [];
      final decoded = (jsonDecode(raw) as List<dynamic>);
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList(growable: false);
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeQueue(List<Map<String, dynamic>> items) async {
    try {
      await _storage.write(key: _key, value: jsonEncode(items));
    } catch (_) {}
  }

  Future<void> enqueue(Map<String, dynamic> action) async {
    final list = await _readQueue();
    list.add(action);
    await _writeQueue(list);
  }

  Future<void> _processQueue() async {
    if (_processing) return;
    _processing = true;
    try {
      var queue = await _readQueue();
      if (queue.isEmpty) return;

      final remaining = <Map<String, dynamic>>[];

      for (final item in queue) {
        final type = item['type'] as String? ?? '';
        final payload = item['payload'] as Map<String, dynamic>? ?? {};
        try {
          if (type == 'mem_like') {
            final memoryId = payload['memoryId'] as String;
            final userId = payload['userId'] as String;
            final likeDoc = _firestore.collection('memories').doc(memoryId).collection('likes').doc(userId);
            final snapshot = await likeDoc.get();
            if (snapshot.exists) {
              await likeDoc.delete();
            } else {
              await likeDoc.set({'userId': userId, 'createdAt': FieldValue.serverTimestamp()});
            }
          } else if (type == 'mem_comment_add') {
            final memoryId = payload['memoryId'] as String;
            final map = Map<String, dynamic>.from(payload['comment'] as Map<String, dynamic>);
            await _firestore.collection('memories').doc(memoryId).collection('comments').add(map);
          } else if (type == 'mem_comment_delete') {
            final memoryId = payload['memoryId'] as String;
            final commentId = payload['commentId'] as String;
            await _firestore.collection('memories').doc(memoryId).collection('comments').doc(commentId).delete();
          } else if (type == 'post_comment_add') {
            final postId = payload['postId'] as String;
            final map = Map<String, dynamic>.from(payload['comment'] as Map<String, dynamic>);
            await _firestore.collection('posts').doc(postId).update({
              'comments': FieldValue.arrayUnion([map])
            });
          } else if (type == 'post_reaction_add') {
            final postId = payload['postId'] as String;
            final map = Map<String, dynamic>.from(payload['reaction'] as Map<String, dynamic>);
            await _firestore.collection('posts').doc(postId).update({
              'reactions': FieldValue.arrayUnion([map])
            });
          } else if (type == 'post_comment_delete') {
            final postId = payload['postId'] as String;
            final map = Map<String, dynamic>.from(payload['comment'] as Map<String, dynamic>);
            // try arrayRemove; if fails, mark deleted id
            try {
              await _firestore.collection('posts').doc(postId).update({
                'comments': FieldValue.arrayRemove([map])
              });
            } catch (_) {
              await _firestore.collection('posts').doc(postId).update({
                'deletedCommentIds': FieldValue.arrayUnion([map['id'] as String])
              });
            }
          } else {
            // unknown type: skip
            remaining.add(item);
          }
        } catch (e) {
          // keep item for retry later
          remaining.add(item);
        }
      }

      // persist remaining
      await _writeQueue(remaining);
    } finally {
      _processing = false;
    }
  }
}
