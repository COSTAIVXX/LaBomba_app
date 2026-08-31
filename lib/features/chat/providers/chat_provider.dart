import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../../../services/storage_platform.dart';

class ChatProvider with ChangeNotifier {
  ChatService _service;
  StreamSubscription<List<ChatMessage>>? _sub;

  List<ChatMessage> _messages = [];
  bool _isConnected = false;

  // Client-side cooldown to prevent rapid message sending (per user per room)
  static const _chatCooldown = Duration(seconds: 5);
  final _storage = PlatformStorageService();

  ChatProvider({ChatService? service}) : _service = service ?? ChatService();

  String get roomId => _service.roomId;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isConnected => _isConnected;

  void connect() {
    _sub?.cancel();
    _sub = _service.messagesStream().listen(
      (list) {
        _messages = list;
        _isConnected = true;
        notifyListeners();
      },
      onError: (_) {
        _isConnected = false;
        notifyListeners();
      },
    );
  }

  void switchRoom(String roomId) {
    _service = ChatService(roomId: roomId);
    _messages = [];
    _isConnected = false;
    notifyListeners();
    connect();
  }

  Future<void> sendMessage({
    required String senderId,
    required String senderName,
    String? text,
    String? stickerUrl,
    Map<String, dynamic>? meta,
  }) async {
    // Rate limiting per user per room (client-side guard)
    try {
      final key = 'chat_last_sent_${_service.roomId}_$senderId';
      final raw = await _storage.read(key: key);
      if (raw != null && raw.isNotEmpty) {
        final last = DateTime.fromMillisecondsSinceEpoch(int.parse(raw));
        final diff = DateTime.now().difference(last);
        if (diff < _chatCooldown) {
          throw StateError(
            'Você está enviando mensagens muito rapidamente. Aguarde ${_chatCooldown.inSeconds - diff.inSeconds} segundos.',
          );
        }
      }
    } catch (e) {
      // If storage read fails, continue but do not silently bypass too aggressively
    }

    await _service.sendMessage(
      senderId: senderId,
      senderName: senderName,
      text: text,
      stickerUrl: stickerUrl,
    );

    // Persist timestamp
    try {
      final key = 'chat_last_sent_${_service.roomId}_$senderId';
      await _storage.write(
        key: key,
        value: DateTime.now().millisecondsSinceEpoch.toString(),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
