import 'package:cloud_firestore/cloud_firestore.dart';

class MemoryComment {
  final String id;
  final String authorId;
  final String authorName;
  final String text;
  final String? parentId;
  final DateTime createdAt;

  const MemoryComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.text,
    this.parentId,
    required this.createdAt,
  });

  factory MemoryComment.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final timestamp = data['createdAt'];
    return MemoryComment(
      id: doc.id,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Usuário',
      text: data['text'] as String? ?? '',
      parentId: data['parentId'] as String?,
      createdAt: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
    );
  }
}

class MemorySocialService {
  final FirebaseFirestore _firestore;

  MemorySocialService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _likes(String memoryId) =>
      _firestore.collection('memories').doc(memoryId).collection('likes');

  CollectionReference<Map<String, dynamic>> _comments(String memoryId) =>
      _firestore.collection('memories').doc(memoryId).collection('comments');

  Stream<QuerySnapshot<Map<String, dynamic>>> likesStream(String memoryId) =>
      _likes(memoryId).snapshots();

  Future<int> engagementCount(String memoryId) async {
    final results = await Future.wait([
      _likes(memoryId).get(),
      _comments(memoryId).get(),
    ]);
    return results[0].size + results[1].size;
  }

  Stream<List<MemoryComment>> commentsStream(String memoryId) =>
      _comments(memoryId)
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map(MemoryComment.fromDocument)
              .toList(growable: false));

  Future<void> toggleLike({
    required String memoryId,
    required String userId,
  }) async {
    final like = _likes(memoryId).doc(userId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(like);
      if (snapshot.exists) {
        transaction.delete(like);
      } else {
        transaction.set(like, {
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> addComment({
    required String memoryId,
    required String authorId,
    required String authorName,
    required String text,
    String? parentId,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _comments(memoryId).add({
      'authorId': authorId,
      'authorName': authorName,
      'text': trimmed,
      'parentId': parentId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteComment({
    required String memoryId,
    required String commentId,
  }) async {
    await _comments(memoryId).doc(commentId).delete();
  }
}
