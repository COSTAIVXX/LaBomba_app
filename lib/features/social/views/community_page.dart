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
  FirebaseFirestore get _firestore => widget.firestore ?? FirebaseFirestore.instance;
  String _query = '';
  String? _selectedTag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunidade'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Theme.of(context).cardTheme.color,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    onChanged: (v) => setState(() => _query = v.trim()),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () async {
                    // open simple tag selector dialog
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
                                ChoiceChip(label: const Text('Todos'), selected: _selectedTag == null, onSelected: (_) => Navigator.pop(ctx, null)),
                                for (final t in tags)
                                  ChoiceChip(label: Text(t), selected: _selectedTag == t, onSelected: (_) => Navigator.pop(ctx, t)),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    );
                    setState(() => _selectedTag = sel);
                  },
                )
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore.collection('users').orderBy('displayName').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Erro ao carregar comunidade'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                final filtered = docs.where((d) {
                  final data = d.data();
                  final name = (data['displayName'] as String?) ?? '';
                  final tags = (data['tags'] as List<dynamic>?)?.cast<String>() ?? <String>[];
                  if (_query.isNotEmpty && !name.toLowerCase().contains(_query.toLowerCase())) return false;
                  if (_selectedTag != null && _selectedTag!.isNotEmpty && !tags.contains(_selectedTag)) return false;
                  return true;
                }).toList();

                if (filtered.isEmpty) return const Center(child: Text('Nenhum membro encontrado.'));

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3 / 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final d = doc.data();
                    final displayName = (d['displayName'] as String?) ?? 'Usuário';
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
          )
        ],
      ),
    );
  }

  Future<List<String>> _fetchAvailableTags() async {
    try {
      final snap = await _firestore.collection('users').get();
      final set = <String>{};
      for (final d in snap.docs) {
        final tags = (d.data()['tags'] as List<dynamic>?)?.cast<String>() ?? <String>[];
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

  const MemberCard({super.key, required this.userId, required this.name, this.avatarUrl, required this.presence, this.vip = false, this.bio = ''});

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
                    backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                    backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl!) : null,
                    child: avatarUrl == null ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?') : null,
                  ),
                  if (vip)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        decoration: BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.star, size: 14, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(name, key: Key('member_name_'+userId), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color)),
              const SizedBox(height: 6),
              Text(bio, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: _presenceColor(context, presence), shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(presence, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                    ],
                  ),
                  IconButton(
                    key: Key('member_chat_'+userId),
                    tooltip: 'Abrir chat',
                    onPressed: () => Navigator.pushNamed(context, '/chat', arguments: userId),
                    icon: Icon(Icons.chat_bubble_outline, color: theme.colorScheme.primary),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
