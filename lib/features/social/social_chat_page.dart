import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'social_domain.dart';
import 'social_provider.dart';

class SocialChatPage extends StatefulWidget {
  const SocialChatPage({super.key});

  @override
  State<SocialChatPage> createState() => _SocialChatPageState();
}

class _SocialChatPageState extends State<SocialChatPage> {
  final TextEditingController _messageController = TextEditingController();

  bool _loadingConversations = true;
  List<SocialConversation> _conversations = <SocialConversation>[];
  List<SocialMessage> _messages = <SocialMessage>[];
  String? _selectedConversationId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadConversations();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    final provider = context.read<SocialProvider>();
    final currentUser = provider.authService.currentUser;
    if (currentUser == null) {
      setState(() {
        _loadingConversations = false;
        _conversations = const <SocialConversation>[];
      });
      return;
    }

    final conversations = await provider.loadConversations(
      userId: currentUser.uid,
      limit: 50,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _loadingConversations = false;
      _conversations = conversations;
      if (_selectedConversationId == null && conversations.isNotEmpty) {
        _selectedConversationId = conversations.first.id;
      }
    });

    if (_selectedConversationId != null) {
      await _openConversation(_selectedConversationId!);
    }
  }

  Future<void> _openConversation(String conversationId) async {
    final provider = context.read<SocialProvider>();
    final messages =
        await provider.loadConversationMessages(conversationId, limit: 50);
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedConversationId = conversationId;
      _messages = messages;
    });
  }

  Future<void> _sendMessage() async {
    final provider = context.read<SocialProvider>();
    final currentUser = provider.authService.currentUser;
    if (currentUser == null || _selectedConversationId == null) {
      return;
    }

    final selectedConversation = _conversations.firstWhere(
      (conversation) => conversation.id == _selectedConversationId,
      orElse: () => SocialConversation(
        id: '',
        participantIds: const <String>[],
        createdBy: '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      ),
    );

    final otherUserId = selectedConversation.participantIds
        .firstWhere((userId) => userId != currentUser.uid, orElse: () => '');
    final text = _messageController.text.trim();
    if (otherUserId.isEmpty || text.isEmpty) {
      return;
    }

    try {
      await provider.sendDirectMessage(
        senderId: currentUser.uid,
        recipientId: otherUserId,
        text: text,
      );
      _messageController.clear();
      await _openConversation(_selectedConversationId!);
      await _loadConversations();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível enviar a mensagem.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<SocialProvider>().authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensagens'),
        actions: <Widget>[
          IconButton(
            onPressed: _loadConversations,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar mensagens',
          ),
        ],
      ),
      body: currentUser == null
          ? const Center(
              child: Text('Faça login para acessar as mensagens diretas.'))
          : Row(
              children: <Widget>[
                SizedBox(
                  width: 320,
                  child: _loadingConversations
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _conversations.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final conversation = _conversations[index];
                            final otherUserId = conversation.participantIds
                                .firstWhere(
                                    (userId) => userId != currentUser.uid,
                                    orElse: () => '');
                            final isSelected =
                                conversation.id == _selectedConversationId;
                            return ListTile(
                              selected: isSelected,
                              selectedTileColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              title: Text(otherUserId.isNotEmpty
                                  ? otherUserId
                                  : 'Conversão'),
                              subtitle: Text(
                                conversation.lastMessagePreview ??
                                    'Nenhuma mensagem ainda.',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => _openConversation(conversation.id),
                            );
                          },
                        ),
                ),
                Expanded(
                  child: _selectedConversationId == null
                      ? const Center(
                          child:
                              Text('Selecione uma conversa para abrir o chat.'))
                      : Column(
                          children: <Widget>[
                            Expanded(
                              child: ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _messages.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final message = _messages[index];
                                  final isMine =
                                      message.senderId == currentUser.uid;
                                  return Align(
                                    alignment: isMine
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Container(
                                      constraints:
                                          const BoxConstraints(maxWidth: 420),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isMine
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        message.text,
                                        style: TextStyle(
                                          color: isMine
                                              ? Colors.white
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: TextField(
                                      controller: _messageController,
                                      decoration: const InputDecoration(
                                        hintText: 'Digite sua mensagem...',
                                        border: OutlineInputBorder(),
                                      ),
                                      maxLines: 3,
                                      minLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  FilledButton.icon(
                                    onPressed: _sendMessage,
                                    icon: const Icon(Icons.send),
                                    label: const Text('Enviar'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}
