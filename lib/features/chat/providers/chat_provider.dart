import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _service;
  StreamSubscription<List<ChatMessage>>? _sub;

  List<ChatMessage> _messages = [];
  bool _isConnected = false;

  ChatProvider({ChatService? service}) : _service = service ?? ChatService();

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isConnected => _isConnected;

  void connect() {
    _sub = _service.messagesStream().listen((list) {
      _messages = list;
      _isConnected = true;
      notifyListeners();
    }, onError: (_) {
      _isConnected = false;
      notifyListeners();
    });
  }

  Future<void> sendMessage({required String senderId, required String senderName, String? text, String? stickerUrl}) async {
    await _service.sendMessage(senderId: senderId, senderName: senderName, text: text, stickerUrl: stickerUrl);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
