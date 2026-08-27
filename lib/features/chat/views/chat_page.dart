import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../../../services/auth_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  late ChatProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<ChatProvider>();
    // connect to stream
    WidgetsBinding.instance.addPostFrameCallback((_) => _provider.connect());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final auth = context.read<AuthService>();
    final user = auth.currentUser;
    await _provider.sendMessage(senderId: user?.uid ?? 'anon', senderName: user?.displayName ?? 'Anon', text: text);
    _controller.clear();
  }

  void _openEmojiPicker() async {
    final emoji = await showModalBottomSheet<String>(context: context, builder: (_) {
      final emojis = ['😀','🎉','❤️','🔥','🥳','💃','🕺','🎭','🎶','📸'];
      return GridView.count(
        crossAxisCount: 5,
        padding: const EdgeInsets.all(12),
        children: emojis.map((e) => GestureDetector(onTap: () => Navigator.pop(context, e), child: Center(child: Text(e, style: const TextStyle(fontSize: 24))))).toList(),
      );
    });
    if (emoji != null) {
      final newText = _controller.text + emoji;
      _controller.text = newText;
      _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
    }
  }

  void _openStickers() async {
    final sticker = await showModalBottomSheet<String>(context: context, builder: (_) {
      final stickers = [
        'https://via.placeholder.com/150/FF6A00/ffffff?text=ST1',
        'https://via.placeholder.com/150/7C1AFF/ffffff?text=ST2',
        'https://via.placeholder.com/150/00C2FF/ffffff?text=ST3',
      ];
      return GridView.count(
        crossAxisCount: 3,
        padding: const EdgeInsets.all(12),
        children: stickers.map((s) => GestureDetector(onTap: () => Navigator.pop(context, s), child: Padding(padding: const EdgeInsets.all(8), child: Image.network(s)))).toList(),
      );
    });
    if (sticker != null) {
      final auth = context.read<AuthService>();
      final user = auth.currentUser;
      await _provider.sendMessage(senderId: user?.uid ?? 'anon', senderName: user?.displayName ?? 'Anon', stickerUrl: sticker);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(builder: (context, chat, _) {
      final messages = chat.messages;
      return Scaffold(
        appBar: AppBar(title: const Text('La Bomba • Chat'), backgroundColor: const Color(0xFF7C1AFF)),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(12),
                itemCount: messages.length,
                itemBuilder: (context, idx) {
                  final m = messages[messages.length - 1 - idx];
                  final isMe = m.senderId == (context.read<AuthService>().currentUser?.uid ?? '');
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isMe ? const Color(0xFFFF6A00) : Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (m.stickerUrl != null) Image.network(m.stickerUrl!, width: 160),
                          if (m.text != null) Text(m.text!, style: const TextStyle(color: Colors.white)),
                          const SizedBox(height: 6),
                          Text(m.senderName, style: const TextStyle(fontSize: 11, color: Colors.white38)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.emoji_emotions), onPressed: _openEmojiPicker),
                    IconButton(icon: const Icon(Icons.sticky_note_2), onPressed: _openStickers),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(hintText: 'Digite uma mensagem...', border: OutlineInputBorder()),
                        onSubmitted: (_) => _sendText(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(icon: const Icon(Icons.send), onPressed: _sendText),
                  ],
                ),
              ),
            )
          ],
        ),
      );
    });
  }
}
