import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore;
  ChatService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream(String chatId) {
    return _firestore.collection('chats').doc(chatId).collection('messages').orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> sendMessage(String chatId, Map<String, dynamic> payload) async {
    final messages = _firestore.collection('chats').doc(chatId).collection('messages');
    await messages.add(payload);
  }
}
