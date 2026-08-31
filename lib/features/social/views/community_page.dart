import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CommunityPage extends StatefulWidget {
  final FirebaseFirestore? firestore;

  const CommunityPage({super.key, this.firestore});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  FirebaseFirestore get _firestore =>
      widget.firestore ?? FirebaseFirestore.instance;
  String _query = '';
  String? _selectedTag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comunidade')),
      body: Container(
        color: const Color(0xFFF8F9FA),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Presence radar (horizontal avatars for online users)
            SizedBox(
              height: 88,
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _firestore
                    .collection('users')
                    .where('presence', isEqualTo: 'online')
                    .orderBy('displayName')
                    .limit(30)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.hasError) return const SizedBox.shrink();
                  if (!snap.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final users = snap.data!.docs;
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    scrollDirection: Axis.horizontal,
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final d = users[index].data();
                      final avatar = d['photoURL'] as String?;
                      final uid = users[index].id;
                      final name = (d['displayName'] as String?) ?? '';
                      return GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, '/profile/$uid'),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundImage: avatar != null
                                      ? CachedNetworkImageProvider(avatar)
                                      : null,
                                  child: avatar == null
                                      ? Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : '?',
                                        )
                                      : null,
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 64,
                              child: Text(
                                name,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Pinned announcement banner
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _firestore
                    .collection('broadcasts')
                    .where('pinned', isEqualTo: true)
                    .orderBy('createdAt', descending: true)
                    .limit(1)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.hasError) return const SizedBox.shrink();
                  if (!snap.hasData) return const SizedBox.shrink();
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) return const SizedBox.shrink();
                  final b = docs.first.data();
                  final title = (b['title'] as String?) ?? 'Aviso';
                  final bodyText = (b['body'] as String?) ?? '';
                  return Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      subtitle: Text(
                        bodyText,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.emoji_emotions_outlined),
                        onPressed: () {
                          // quick reaction placeholder — could open reaction sheet
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Reagir ao aviso')),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            // Filter chips (categories)
            SizedBox(
              height: 48,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                children: [
                  const SizedBox(width: 4),
                  _categoryChip('Todos'),
                  _categoryChip('Bateria'),
                  _categoryChip('Churrasco'),
                  _categoryChip('Fotos Oficiais'),
                  const SizedBox(width: 8),
                ],
              ),
            ),

            // Search row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar por nome...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Theme.of(context).cardTheme.color,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) => setState(() => _query = v.trim()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () async {
                      final tags = await _fetchAvailableTags();
                      if (!mounted) return;
                      final sel = await showModalBottomSheet<String?>(
                        context: context,
                        builder: (ctx) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(title: const Text('Filtrar por tag')),
                              Wrap(
                                spacing: 8,
                                children: [
                                  ChoiceChip(
                                    label: const Text('Todos'),
                                    selected: _selectedTag == null,
                                    onSelected: (_) => Navigator.pop(ctx, null),
                                  ),
                                  for (final t in tags)
                                    ChoiceChip(
                                      label: Text(t),
                                      selected: _selectedTag == t,
                                      onSelected: (_) => Navigator.pop(ctx, t),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      );
                      setState(() => _selectedTag = sel);
                    },
                  ),
                ],
              ),
            ),

            // Members grid (kept for backward compatibility and tests)
            Flexible(
              flex: 2,
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _firestore
                    .collection('users')
                    .orderBy('displayName')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError)
                    return const Center(
                      child: Text('Erro ao carregar comunidade'),
                    );
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs;
                  final filtered = docs.where((d) {
                    final data = d.data();
                    final name = (data['displayName'] as String?) ?? '';
                    final tags =
                        (data['tags'] as List<dynamic>?)?.cast<String>() ??
                            <String>[];
                    if (_query.isNotEmpty &&
                        !name.toLowerCase().contains(_query.toLowerCase()))
                      return false;
                    if (_selectedTag != null &&
                        _selectedTag!.isNotEmpty &&
                        !tags.contains(_selectedTag)) return false;
                    return true;
                  }).toList();

                  if (filtered.isEmpty)
                    return const Center(
                      child: Text('Nenhum membro encontrado.'),
                    );

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 3 / 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      final d = doc.data();
                      final displayName =
                          (d['displayName'] as String?) ?? 'Usuário';
                      final avatar = d['photoURL'] as String?;
                      final presence = (d['presence'] as String?) ?? 'offline';
                      final vip = (d['vip'] as bool?) ?? false;
                      final userId = doc.id;
                      final bio = (d['bio'] as String?) ?? '';
                      return MemberCard(
                        userId: userId,
                        name: displayName,
                        avatarUrl: avatar,
                        presence: presence,
                        vip: vip,
                        bio: bio,
                      );
                    },
                  );
                },
              ),
            ),

            // Feed
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: (_selectedTag == null || _selectedTag == 'Todos')
                    ? _firestore
                        .collection('posts')
                        .orderBy('createdAt', descending: true)
                        .snapshots()
                    : _firestore
                        .collection('posts')
                        .where('tags', arrayContains: _selectedTag)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError)
                    return const Center(child: Text('Erro ao carregar feed'));
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs.where((d) {
                    final data = d.data();
                    final name = (data['authorName'] as String?) ?? '';
                    if (_query.isNotEmpty &&
                        !name.toLowerCase().contains(_query.toLowerCase()))
                      return false;
                    return true;
                  }).toList();

                  if (docs.isEmpty)
                    return const Center(
                      child: Text('Nenhuma publicação encontrada.'),
                    );

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final d = docs[index].data();
                      final author = (d['authorName'] as String?) ?? 'Usuário';
                      final avatar = d['authorPhoto'] as String?;
                      final text = (d['text'] as String?) ?? '';
                      final image = d['imageUrl'] as String?;
                      final ts = d['createdAt'];
                      return Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundImage: avatar != null
                                        ? CachedNetworkImageProvider(avatar)
                                        : null,
                                    child: avatar == null
                                        ? Text(
                                            author.isNotEmpty ? author[0] : '?',
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      author,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                  ),
                                  if (ts != null)
                                    Text(
                                      _formatTimestamp(ts),
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                ],
                              ),
                              if (text.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  text,
                                  style: const TextStyle(
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                              ],
                              if (image != null) ...[
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: image,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    onPressed: () {},
                                    icon: const Icon(Icons.thumb_up_off_alt),
                                  ),
                                  IconButton(
                                    onPressed: () {},
                                    icon: const Icon(Icons.comment_outlined),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String label) {
    final selected = (label == 'Todos' &&
            (_selectedTag == null || _selectedTag == 'Todos')) ||
        (_selectedTag == label);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) =>
            setState(() => _selectedTag = label == 'Todos' ? null : label),
      ),
    );
  }

  String _formatTimestamp(dynamic ts) {
    try {
      DateTime dt;
      if (ts == null) return '';
      if (ts is Timestamp) {
        dt = ts.toDate();
      } else if (ts is int) {
        dt = DateTime.fromMillisecondsSinceEpoch(ts);
      } else if (ts is DateTime) {
        dt = ts;
      } else {
        return '';
      }
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'agora';
      if (diff.inHours < 1) return '${diff.inMinutes}m';
      if (diff.inDays < 1) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  Future<List<String>> _fetchAvailableTags() async {
    try {
      final snap = await _firestore.collection('users').get();
      final set = <String>{};
      for (final d in snap.docs) {
        final tags =
            (d.data()['tags'] as List<dynamic>?)?.cast<String>() ?? <String>[];
        set.addAll(tags);
      }
      return set.toList()..sort();
    } catch (_) {
      return <String>[];
    }
  }
}

class MemberCard extends StatelessWidget {
  final String userId;
  final String name;
  final String? avatarUrl;
  final String presence;
  final bool vip;
  final String bio;

  const MemberCard({
    super.key,
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.presence,
    this.vip = false,
    this.bio = '',
  });

  Color _presenceColor(BuildContext context, String p) {
    switch (p.toLowerCase()) {
      case 'online':
      case 'present':
        return Colors.green;
      case 'away':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/profile/${userId}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: theme.colorScheme.onSurface.withValues(
                      alpha: 0.04,
                    ),
                    backgroundImage: avatarUrl != null
                        ? CachedNetworkImageProvider(avatarUrl!)
                        : null,
                    child: avatarUrl == null
                        ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?')
                        : null,
                  ),
                  if (vip)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                name,
                key: Key('member_name_' + userId),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                bio,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _presenceColor(context, presence),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        presence,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    key: Key('member_chat_' + userId),
                    tooltip: 'Abrir chat',
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/chat',
                      arguments: userId,
                    ),
                    icon: Icon(
                      Icons.chat_bubble_outline,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
