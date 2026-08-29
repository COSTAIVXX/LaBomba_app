import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore;
  ChatService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream(String chatId) {
    return _firestore.collection('chats').doc(chatId).collection('messages').orderBy('createdAt', descending: true).snapshots();
  }

  Future<DocumentReference<Map<String, dynamic>>> sendMessage(String chatId, Map<String, dynamic> payload) async {
    final messages = _firestore.collection('chats').doc(chatId).collection('messages');
    final enriched = Map<String, dynamic>.from(payload);
    enriched.putIfAbsent('createdAt', () => adminTimestamp());
    // delivery/read status are managed by recipients or server functions
    enriched.putIfAbsent('deliveredAt', () => null);
    enriched.putIfAbsent('isRead', () => false);
    final ref = await messages.add(enriched);
    return ref;
  }

  // Helper to return server timestamp placeholder compatible with both client code and tests
  static dynamic adminTimestamp() => FieldValue.serverTimestamp();
}
