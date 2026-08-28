import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/auth_service.dart';
import '../../social/models/post_interaction_model.dart';

/// Social feed page. Shows posts from 'posts' collection and allows simple
/// interactions (add reaction, add comment, delete by author).
class SocialFeedPage extends StatefulWidget {
  const SocialFeedPage({super.key});

  @override
  State<SocialFeedPage> createState() => _SocialFeedPageState();
}

class _SocialFeedPageState extends State<SocialFeedPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _onlyCloseFriends = false;

  String? get _currentUid => context.read<AuthService>().currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed Social'),
        actions: [
          Row(
            children: [
              const Text('Melhores amigos', style: TextStyle(fontSize: 12)),
              Switch(
                value: _onlyCloseFriends,
                onChanged: (v) => setState(() => _onlyCloseFriends = v),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('posts').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar feed: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];

          return FutureBuilder<List<String>>(
            future: _fetchCloseFriends(),
            builder: (context, cfSnap) {
              final closeFriends = cfSnap.data ?? <String>[];

              final entries = docs.map((d) => MapEntry(d, _docToInteraction(d))).toList();

              final filtered = entries.where((entry) {
                if (!_onlyCloseFriends) return true;
                final d = entry.key;
                final author = (d.data() as Map<String, dynamic>?)?['authorId'] as String?;
                return author != null && closeFriends.contains(author);
              }).toList();

              if (filtered.isEmpty) return const Center(child: Text('Nenhuma postagem encontrada'));

              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final doc = filtered[index].key;
                  final post = filtered[index].value;
                  return _buildPostCard(post, doc.id);
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<String>> _fetchCloseFriends() async {
    try {
      final uid = _currentUid;
      if (uid == null) return <String>[];
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data() ?? {};
      final raw = data['closeFriends'] as List<dynamic>?;
      return raw?.map((e) => e as String).toList() ?? <String>[];
    } catch (_) {
      return <String>[];
    }
  }

  PostInteraction _docToInteraction(QueryDocumentSnapshot d) {
    final data = d.data() as Map<String, dynamic>;
    final postId = d.id;
    final commentsRaw = data['comments'] as List<dynamic>? ?? [];
    final reactionsRaw = data['reactions'] as List<dynamic>? ?? [];

    final comments = commentsRaw.map((c) {
      final map = Map<String, dynamic>.from(c as Map);
      final created = map['createdAt'];
      DateTime createdAt;
      if (created is Timestamp) {
        createdAt = created.toDate();
      } else if (created is String) {
        createdAt = DateTime.tryParse(created) ?? DateTime.now();
      } else {
        createdAt = DateTime.now();
      }
      return Comment(
        id: map['id'] as String,
        authorId: map['authorId'] as String,
        text: map['text'] as String,
        createdAt: createdAt,
        deleted: map['deleted'] as bool? ?? false,
      );
    }).toList();

    final reactions = reactionsRaw.map((r) {
      final map = Map<String, dynamic>.from(r as Map);
      final created = map['createdAt'];
      DateTime createdAt;
      if (created is Timestamp) {
        createdAt = created.toDate();
      } else if (created is String) {
        createdAt = DateTime.tryParse(created) ?? DateTime.now();
      } else {
        createdAt = DateTime.now();
      }
      return Reaction(
        id: map['id'] as String,
        userId: map['userId'] as String,
        type: map['type'] as String,
        createdAt: createdAt,
      );
    }).toList();

    return PostInteraction(postId: postId, comments: comments, reactions: reactions);
  }

  Widget _buildPostCard(PostInteraction post, String docId) {
    final summary = post.reactionsSummary();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post header (author and timestamp) - basic
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Post: ${post.postId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${post.activeCommentsCount} comentários', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            // Placeholder for post content if available in Firestore
            FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('posts').doc(docId).get(),
              builder: (context, snap) {
                final data = snap.data?.data() as Map<String, dynamic>?;
                final content = data != null && data.containsKey('content') ? data['content'] as String : '';
                return Text(content);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.thumb_up_alt_outlined),
                  onPressed: () => _addReaction(docId, 'like'),
                ),
                Text('${summary['like'] ?? 0}'),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: () => _showAddCommentDialog(docId),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'refresh') setState(() {});
                  },
                  itemBuilder: (c) => const [PopupMenuItem(value: 'refresh', child: Text('Atualizar'))],
                ),
              ],
            ),
            const Divider(),
            // Show a couple of recent comments
            ...post.comments.where((c) => !c.deleted).take(3).map((c) => ListTile(
                  dense: true,
                  title: Text(c.text),
                  subtitle: Text('por ${c.authorId} - ${c.createdAt.toLocal()}'),
                  trailing: _canDeleteComment(c, post)
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _deleteComment(docId, c),
                        )
                      : null,
                )),
          ],
        ),
      ),
    );
  }

  bool _canDeleteComment(Comment c, PostInteraction post) {
    final uid = _currentUid;
    if (uid == null) return false;
    // author of comment or author of post (post.postId used as identifier here)
    return c.authorId == uid || post.postId == uid;
  }

  Future<void> _addReaction(String postId, String type) async {
    final uid = _currentUid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Faça login para reagir.')));
      return;
    }
    final id = '$uid:${DateTime.now().millisecondsSinceEpoch}';
    final map = {
      'id': id,
      'userId': uid,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
    };
    try {
      await _firestore.collection('posts').doc(postId).update({
        'reactions': FieldValue.arrayUnion([map])
      });
    } catch (e) {
      // best effort fallback - could persist locally or show error
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível registrar a reação.')));
    }
  }

  Future<void> _showAddCommentDialog(String postId) async {
    final uid = _currentUid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Faça login para comentar.')));
      return;
    }
    final controller = TextEditingController();
    final send = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adicionar comentário'),
        content: TextField(controller: controller, autofocus: true, maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Enviar')),
        ],
      ),
    );
    if (send != true) return;
    final text = controller.text.trim();
    if (text.isEmpty) return;
    final id = '$uid:${DateTime.now().millisecondsSinceEpoch}';
    final map = {
      'id': id,
      'authorId': uid,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'deleted': false,
    };
    try {
      await _firestore.collection('posts').doc(postId).update({
        'comments': FieldValue.arrayUnion([map])
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comentário enviado')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falha ao enviar comentário')));
    }
  }

  Future<void> _deleteComment(String postId, Comment comment) async {
    // Attempt to remove the exact comment object from the array (requires exact match)
    final map = {
      'id': comment.id,
      'authorId': comment.authorId,
      'text': comment.text,
      'createdAt': Timestamp.fromDate(comment.createdAt),
      'deleted': comment.deleted,
    };
    try {
      await _firestore.collection('posts').doc(postId).update({
        'comments': FieldValue.arrayRemove([map])
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comentário removido')));
    } catch (e) {
      // If arrayRemove fails (e.g., timestamp mismatch), fallback to marking as deleted
      try {
        await _firestore.collection('posts').doc(postId).update({
          'deletedCommentIds': FieldValue.arrayUnion([comment.id])
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comentário marcado como removido')));
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falha ao remover comentário')));
      }
    }
  }
}
