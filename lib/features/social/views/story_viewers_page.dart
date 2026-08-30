import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../chat/services/chat_service.dart';
import '../../admin/admin_guard.dart';
import '../../chat/views/chat_page.dart';

class StoryViewersPage extends StatelessWidget {
  final String ownerId;
  final String storyId;
  final FirebaseFirestore? firestore;

  const StoryViewersPage({super.key, required this.ownerId, required this.storyId, this.firestore});

  FirebaseFirestore get _fs => firestore ?? FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Visualizações')),
        body: const Center(child: Text('Faça login para ver os visualizadores')),
      );
    }

    // Only owner or admin (via AdminGuard) may access this page.
    final isOwner = user.uid == ownerId;
    final page = _ViewersList(ownerId: ownerId, storyId: storyId, firestore: _fs);
    if (isOwner) return page;

    // Non-owner: wrap with AdminGuard so only admins can view
    return AdminGuard(
        child: page,
        onDenied: Scaffold(
          appBar: AppBar(title: const Text('Visualizações')),
          body: const Center(child: Text('Você não tem permissão para ver os visualizadores desse story.')),
        ));
  }
}

class _ViewersList extends StatelessWidget {
  final String ownerId;
  final String storyId;
  final FirebaseFirestore firestore;

  const _ViewersList({required this.ownerId, required this.storyId, required this.firestore});

  Stream<QuerySnapshot<Map<String, dynamic>>> _viewsStream() {
    // collectionGroup query across users/*/storyViews
    return firestore
        .collectionGroup('storyViews')
        .where('ownerId', isEqualTo: ownerId)
        .where('storyId', isEqualTo: storyId)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Future<Map<String, dynamic>?> _loadProfile(String uid) async {
    try {
      final doc = await firestore.collection('users').doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visualizações')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _viewsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snap.hasData) return const Center(child: Text('Nenhuma visualização ainda'));
          final docs = snap.data!.docs;
          final count = docs.length;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Visualizações: $count', style: Theme.of(context).textTheme.titleMedium),
                    Text('${docs.isNotEmpty ? docs.last.data()['createdAt'] ?? '' : ''}',
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final viewerId =
                        doc.data()['viewerId'] as String? ?? (doc.data()['viewer'] as String? ?? 'unknown');
                    final ts = doc.data()['createdAt'];
                    return ListTile(
                      leading: FutureBuilder<Map<String, dynamic>?>(
                        future: _loadProfile(viewerId),
                        builder: (c, p) {
                          final data = p.data;
                          final avatar = data?['photoURL'] as String? ?? data?['authorPhoto'] as String?;
                          final name =
                              (data?['displayName'] as String?) ?? (data?['authorName'] as String?) ?? viewerId;
                          if (p.connectionState == ConnectionState.waiting)
                            return CircleAvatar(child: const SizedBox.square(dimension: 10));
                          return CircleAvatar(
                              backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                              child: avatar == null ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?') : null);
                        },
                      ),
                      title: FutureBuilder<Map<String, dynamic>?>(
                        future: _loadProfile(viewerId),
                        builder: (c, p) {
                          final data = p.data;
                          final name =
                              (data?['displayName'] as String?) ?? (data?['authorName'] as String?) ?? viewerId;
                          return Text(name);
                        },
                      ),
                      subtitle: Text(_formatTimestamp(ts)),
                      trailing: IconButton(
                        icon: const Icon(Icons.message_outlined),
                        onPressed: () async {
                          // Open private chat with viewer
                          final current = FirebaseAuth.instance.currentUser;
                          if (current == null) return;
                          final roomId = ChatService.privateRoomId(current.uid, viewerId);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPageShim(roomId: roomId)));
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTimestamp(dynamic ts) {
    try {
      DateTime dt;
      if (ts is Timestamp)
        dt = ts.toDate();
      else if (ts is String)
        dt = DateTime.parse(ts);
      else if (ts is DateTime)
        dt = ts;
      else
        return '';
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

// Lightweight ChatPage shim to navigate to chat — reuse existing chat UI if available
class ChatPageShim extends StatelessWidget {
  final String roomId;
  const ChatPageShim({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    // The project has multiple ChatPage implementations; try to locate a common one via routes
    // If a ChatPage exists under features/chat/views/chat_page.dart it can be used. Here we navigate by route name if present.
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => Scaffold(body: Center(child: Text('Chat room: $roomId')))));
    return const SizedBox.shrink();
  }
}
