import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String roomId;

  ChatService({this.roomId = 'lobby'});

  Stream<List<ChatMessage>> messagesStream() {
    return _firestore
        .collection('chats')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChatMessage.fromDoc(d)).toList());
  }

  Future<void> sendMessage({required String senderId, required String senderName, String? text, String? stickerUrl}) async {
    final col = _firestore.collection('chats').doc(roomId).collection('messages');
    final doc = col.doc();
    final msg = ChatMessage(
      id: doc.id,
      senderId: senderId,
      senderName: senderName,
      text: text,
      stickerUrl: stickerUrl,
      createdAt: DateTime.now(),
    );
    await doc.set(msg.toMap());
  }
}
