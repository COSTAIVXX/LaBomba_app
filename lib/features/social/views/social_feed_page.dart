import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/auth_service.dart';
import '../../../services/storage_platform.dart';
import '../../../services/storage_service.dart';
import '../../../services/outbox_service.dart';
import '../../social/models/post_interaction_model.dart';
import '../services/reaction_service.dart';
import '../../../widgets/reaction_bar.dart';
import 'stories_carousel.dart';
import '../../../services/post_service.dart';
import 'package:flutter/services.dart';

/// Social feed page. Shows posts from 'posts' collection and allows simple
/// interactions (add reaction, add comment, delete by author).
class SocialFeedPage extends StatefulWidget {
  const SocialFeedPage({super.key});

  @override
  State<SocialFeedPage> createState() => _SocialFeedPageState();
}

class _SocialFeedPageState extends State<SocialFeedPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storage = PlatformStorageService();
  bool _onlyCloseFriends = false;

  // pagination
  static const int _pageSize = 20;
  int _limit = _pageSize;

  String? get _currentUid => context.read<AuthService>().currentUser?.uid;

  // Keys for cached posts
  String _postsCacheKey() => 'social:posts_cache_v1';

  Future<void> _refresh() async {
    setState(() {
      _limit = _pageSize;
    });
    await Future.delayed(const Duration(milliseconds: 200));
  }

  void _loadMore() {
    setState(() {
      _limit += _pageSize;
    });
  }

  Future<void> _persistPostsCache(List<QueryDocumentSnapshot> docs) async {
    try {
      final list = docs.map((d) {
        final data =
            Map<String, dynamic>.from(d.data() as Map<String, dynamic>);
        // Normalize nested timestamps inside comments/reactions to ISO strings
        if (data['comments'] is List) {
          data['comments'] = (data['comments'] as List).map((c) {
            final m = Map<String, dynamic>.from(c as Map);
            final created = m['createdAt'];
            if (created is Timestamp)
              m['createdAt'] = created.toDate().toIso8601String();
            return m;
          }).toList();
        }
        if (data['reactions'] is List) {
          data['reactions'] = (data['reactions'] as List).map((r) {
            final m = Map<String, dynamic>.from(r as Map);
            final created = m['createdAt'];
            if (created is Timestamp)
              m['createdAt'] = created.toDate().toIso8601String();
            return m;
          }).toList();
        }
        return {'id': d.id, 'data': data};
      }).toList(growable: false);
      await _storage.write(key: _postsCacheKey(), value: jsonEncode(list));
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> _readCachedPosts() async {
    try {
      final raw = await _storage.read(key: _postsCacheKey());
      if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
      final decoded =
          (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
      return decoded
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  PostInteraction _mapToInteractionFromCache(Map<String, dynamic> entry) {
    final id = entry['id'] as String? ?? '';
    final data =
        Map<String, dynamic>.from(entry['data'] as Map<String, dynamic>? ?? {});

    final commentsRaw = data['comments'] as List<dynamic>? ?? [];
    final reactionsRaw = data['reactions'] as List<dynamic>? ?? [];

    final comments = commentsRaw.map((c) {
      final map = Map<String, dynamic>.from(c as Map);
      final createdStr = map['createdAt'] as String?;
      final createdAt = createdStr != null
          ? DateTime.tryParse(createdStr) ?? DateTime.now()
          : DateTime.now();
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
      final createdStr = map['createdAt'] as String?;
      final createdAt = createdStr != null
          ? DateTime.tryParse(createdStr) ?? DateTime.now()
          : DateTime.now();
      return Reaction(
        id: map['id'] as String,
        userId: map['userId'] as String,
        type: map['type'] as String,
        createdAt: createdAt,
      );
    }).toList();

    return PostInteraction(
        postId: id, comments: comments, reactions: reactions);
  }

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
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('posts')
              .orderBy('isPinned', descending: true)
              .orderBy('createdAt', descending: true)
              .limit(_limit)
              .snapshots()
              .map((snap) {
            // persist fresh snapshot into local cache for fast fallback
            _persistPostsCache(snap.docs);
            return snap;
          }),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            // If remote stream has error or no data, fall back to cached posts
            if (snapshot.hasError || snapshot.data == null) {
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: _readCachedPosts(),
                builder: (context, cacheSnap) {
                  if (cacheSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final cached = cacheSnap.data ?? <Map<String, dynamic>>[];
                  if (cached.isEmpty) {
                    if (snapshot.hasError)
                      return Center(
                          child:
                              Text('Erro ao carregar feed: ${snapshot.error}'));
                    return const Center(
                        child: Text('Nenhuma postagem encontrada'));
                  }

                  return FutureBuilder<List<String>>(
                    future: _fetchCloseFriends(),
                    builder: (context, cfSnap) {
                      final closeFriends = cfSnap.data ?? <String>[];
                      final entries = cached
                          .map<MapEntry<Map<String, dynamic>, PostInteraction>>(
                              (e) => MapEntry<Map<String, dynamic>,
                                      PostInteraction>(
                                  Map<String, dynamic>.from(e),
                                  _mapToInteractionFromCache(e)))
                          .toList();
                      final filtered = entries.where((entry) {
                        if (!_onlyCloseFriends) return true;
                        final data = entry.key['data'] as Map<String, dynamic>?;
                        final author =
                            data != null ? data['authorId'] as String? : null;
                        return author != null && closeFriends.contains(author);
                      }).toList();

                      if (filtered.isEmpty)
                        return const Center(
                            child: Text('Nenhuma postagem encontrada'));

                      // Include Stories carousel above the posts list
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            StoriesCarousel(),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filtered.length +
                                  (filtered.length >= _limit ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == filtered.length) {
                                  return Center(
                                    child: TextButton(
                                        onPressed: _loadMore,
                                        child: const Text('Carregar mais')),
                                  );
                                }
                                final entry = filtered[index].key;
                                final post = filtered[index].value;
                                final docId = entry['id'] as String;
                                return _buildPostCard(post, docId);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            }

            final docs = snapshot.data?.docs ?? [];

            return FutureBuilder<List<String>>(
              future: _fetchCloseFriends(),
              builder: (context, cfSnap) {
                final closeFriends = cfSnap.data ?? <String>[];

                final entries =
                    docs.map((d) => MapEntry(d, _docToInteraction(d))).toList();

                final filtered = entries.where((entry) {
                  if (!_onlyCloseFriends) return true;
                  final d = entry.key;
                  final author = (d.data()
                      as Map<String, dynamic>?)?['authorId'] as String?;
                  return author != null && closeFriends.contains(author);
                }).toList();

                if (filtered.isEmpty)
                  return const Center(
                      child: Text('Nenhuma postagem encontrada'));

                // Include Stories carousel above the posts list
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      StoriesCarousel(),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length +
                            (filtered.length >= _limit ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == filtered.length) {
                            return Center(
                              child: TextButton(
                                  onPressed: _loadMore,
                                  child: const Text('Carregar mais')),
                            );
                          }
                          final doc = filtered[index].key;
                          final post = filtered[index].value;
                          return _buildPostCard(post, doc.id);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
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

    return PostInteraction(
        postId: postId, comments: comments, reactions: reactions);
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
                Text('Post: ${post.postId}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${post.activeCommentsCount} comentários',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            // Placeholder for post content if available in Firestore
            FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('posts').doc(docId).get(),
              builder: (context, snap) {
                final data = snap.data?.data() as Map<String, dynamic>?;
                final content = data != null && data.containsKey('content')
                    ? data['content'] as String
                    : '';
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
                  onSelected: (v) async {
                    if (v == 'refresh')
                      setState(() {});
                    else if (v == 'edit')
                      await _editPost(docId);
                    else if (v == 'delete')
                      await _deletePost(docId);
                    else if (v == 'save')
                      await _savePost(docId);
                    else if (v == 'hide')
                      await _hidePost(docId);
                    else if (v == 'report')
                      await _reportPost(docId);
                    else if (v == 'share') await _sharePost(docId);
                  },
                  itemBuilder: (c) => [
                    const PopupMenuItem(
                        value: 'refresh', child: Text('Atualizar')),
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    const PopupMenuItem(
                        value: 'delete', child: Text('Excluir')),
                    const PopupMenuItem(value: 'save', child: Text('Salvar')),
                    const PopupMenuItem(value: 'hide', child: Text('Ocultar')),
                    const PopupMenuItem(
                        value: 'report', child: Text('Denunciar')),
                    const PopupMenuItem(
                        value: 'share', child: Text('Compartilhar')),
                  ],
                ),
              ],
            ),
            const Divider(),
            // Show a couple of recent comments
            ...post.comments.where((c) => !c.deleted).take(3).map((c) {
              return Column(
                children: [
                  ListTile(
                    dense: true,
                    title: Text(c.text),
                    subtitle:
                        Text('por ${c.authorId} - ${c.createdAt.toLocal()}'),
                    trailing: _canDeleteComment(c, post)
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent),
                            onPressed: () => _deleteComment(docId, c),
                          )
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 72.0, right: 8.0, bottom: 8.0),
                    child: StreamBuilder<Map<String, int>>(
                      stream: ReactionService()
                          .reactionsCountStreamForComment(docId, c.id),
                      builder: (context, rsnap) {
                        final counts = rsnap.data ?? <String, int>{};
                        return ReactionBar(
                          initialCounts: counts,
                          onChanged: (emoji, added) async {
                            final uid = _currentUid;
                            if (uid == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Faça login para reagir.')));
                              return;
                            }
                            try {
                              await ReactionService().toggleReactionOnComment(
                                  postId: docId,
                                  commentId: c.id,
                                  userId: uid,
                                  emoji: emoji);
                            } catch (e) {
                              debugPrint('Comment reaction failed: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Falha ao reagir no comentário')));
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            }).toList(),
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

  // --- Post actions: edit/delete/save/hide/report/share
  Future<void> _editPost(String postId) async {
    final uid = _currentUid;
    try {
      final doc = await _firestore.collection('posts').doc(postId).get();
      final data = doc.data();
      if (data == null) return;
      if (uid != data['userId']) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sem permissão para editar')));
        return;
      }
      final current = data['content'] as String? ?? '';
      final controller = TextEditingController(text: current);
      final save = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Editar postagem'),
          content: TextField(controller: controller, maxLines: 5),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Salvar')),
          ],
        ),
      );
      if (save != true) return;
      final newContent = controller.text.trim();
      await _firestore
          .collection('posts')
          .doc(postId)
          .update({'content': newContent});
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Post atualizado')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Falha ao editar post')));
    }
  }

  Future<void> _deletePost(String postId) async {
    final uid = _currentUid;
    try {
      final doc = await _firestore.collection('posts').doc(postId).get();
      final data = doc.data();
      if (data == null) return;
      if (uid != data['userId']) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sem permissão para excluir')));
        return;
      }
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Excluir postagem'),
          content: const Text('Tem certeza que deseja excluir esta postagem?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Excluir')),
          ],
        ),
      );
      if (confirm != true) return;
      await PostService().deletePost(postId);
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Post excluído')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Falha ao excluir post')));
    }
  }

  Future<void> _savePost(String postId) async {
    final uid = _currentUid;
    if (uid == null) return;
    try {
      final meRef = _firestore.collection('users').doc(uid);
      await meRef.update({
        'savedPosts': FieldValue.arrayUnion([postId])
      });
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Post salvo')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Falha ao salvar post')));
    }
  }

  Future<void> _hidePost(String postId) async {
    final uid = _currentUid;
    if (uid == null) return;
    try {
      final meRef = _firestore.collection('users').doc(uid);
      await meRef.update({
        'hiddenPosts': FieldValue.arrayUnion([postId])
      });
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Post ocultado')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Falha ao ocultar post')));
    }
  }

  Future<void> _reportPost(String postId) async {
    final uid = _currentUid;
    try {
      final doc = await _firestore.collection('posts').doc(postId).get();
      final data = doc.data();
      final content = data?['content'] as String?;
      final report = {
        'type': 'post',
        'postId': postId,
        'reporterId': uid,
        'content': content,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      };
      await _firestore.collection('reports').add(report);
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Denúncia enviada')));
    } catch (e) {
      try {
        await OutboxService.instance.enqueue({
          'type': 'report_post',
          'payload': {'postId': postId, 'reporterId': _currentUid}
        });
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Denúncia agendada')));
      } catch (_) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Falha ao denunciar')));
      }
    }
  }

  Future<void> _sharePost(String postId) async {
    try {
      final doc = await _firestore.collection('posts').doc(postId).get();
      final data = doc.data();
      final content = data?['content'] as String? ?? '';
      await Clipboard.setData(ClipboardData(text: content));
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Conteúdo copiado para área de transferência')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Falha ao compartilhar')));
    }
  }

  Future<void> _addReaction(String postId, String type) async {
    final uid = _currentUid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Faça login para reagir.')));
      return;
    }
    try {
      await ReactionService()
          .toggleReactionOnPost(postId: postId, userId: uid, emoji: type);
    } catch (e) {
      // enqueue to outbox as fallback for offline
      try {
        final id = '$uid:${DateTime.now().millisecondsSinceEpoch}';
        await OutboxService.instance.enqueue({
          'id': 'post_reaction_add:${postId}:$id',
          'type': 'post_reaction_add',
          'payload': {
            'postId': postId,
            'reaction': {
              'id': id,
              'userId': uid,
              'type': type,
              'createdAt': DateTime.now().toIso8601String()
            }
          },
          'createdAt': DateTime.now().toIso8601String(),
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Reação enfileirada e será sincronizada quando online')));
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Não foi possível registrar a reação.')));
      }
    }
  }

  Future<void> _showAddCommentDialog(String postId) async {
    final uid = _currentUid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Faça login para comentar.')));
      return;
    }
    final controller = TextEditingController();
    final send = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adicionar comentário'),
        content:
            TextField(controller: controller, autofocus: true, maxLines: 3),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Enviar')),
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

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Comentário enviado')));
    } catch (e) {
      try {
        await OutboxService.instance.enqueue({
          'id': 'post_comment_add:${postId}:${map['id']}',
          'type': 'post_comment_add',
          'payload': {'postId': postId, 'comment': map},
          'createdAt': DateTime.now().toIso8601String(),
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Comentário enfileirado e será sincronizado quando online')));
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Falha ao enviar comentário')));
      }
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Comentário removido')));
    } catch (e) {
      // If arrayRemove fails (e.g., timestamp mismatch), fallback to marking as deleted
      try {
        await _firestore.collection('posts').doc(postId).update({
          'deletedCommentIds': FieldValue.arrayUnion([comment.id])
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Comentário marcado como removido')));
      } catch (_) {
        // enqueue delete attempt
        try {
          final fallbackMap = {
            'id': comment.id,
            'authorId': comment.authorId,
            'text': comment.text,
            'createdAt': comment.createdAt.toIso8601String(),
            'deleted': comment.deleted,
          };
          await OutboxService.instance.enqueue({
            'id':
                'post_comment_delete:${postId}:${comment.id}:${DateTime.now().millisecondsSinceEpoch}',
            'type': 'post_comment_delete',
            'payload': {'postId': postId, 'comment': fallbackMap},
            'createdAt': DateTime.now().toIso8601String(),
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Remoção enfileirada e será sincronizada quando online')));
        } catch (_) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Falha ao remover comentário')));
        }
      }
    }
  }
}
