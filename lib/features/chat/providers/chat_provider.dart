import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  ChatService _service;
  StreamSubscription<List<ChatMessage>>? _sub;

  List<ChatMessage> _messages = [];
  bool _isConnected = false;

  ChatProvider({ChatService? service}) : _service = service ?? ChatService();

  String get roomId => _service.roomId;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isConnected => _isConnected;

  void connect() {
    _sub?.cancel();
    _sub = _service.messagesStream().listen((list) {
      _messages = list;
      _isConnected = true;
      notifyListeners();
    }, onError: (_) {
      _isConnected = false;
      notifyListeners();
    });
  }

  void switchRoom(String roomId) {
    _service = ChatService(roomId: roomId);
    _messages = [];
    _isConnected = false;
    notifyListeners();
    connect();
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
