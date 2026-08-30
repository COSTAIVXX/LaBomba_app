import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class _SimpleUserTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _SimpleUserTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final name = (data['displayName'] as String?) ?? (data['name'] as String?) ?? 'Usuário';
    final avatar = data['avatarUrl'] as String? ?? data['photoURL'] as String?;
    return ListTile(
      leading: CircleAvatar(
          backgroundImage: avatar != null ? NetworkImage(avatar) : null,
          child: avatar == null ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?') : null),
      title: Text(name),
      subtitle: Text(data['bio'] as String? ?? ''),
      onTap: () {},
    );
  }
}

class FollowersListPage extends StatelessWidget {
  final String targetId;
  const FollowersListPage({super.key, required this.targetId});

  @override
  Widget build(BuildContext context) {
    // Query users where following array contains targetId
    final stream =
        FirebaseFirestore.instance.collection('users').where('following', arrayContains: targetId).snapshots();
    return Scaffold(
      appBar: AppBar(title: const Text('Seguidores')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Nenhum seguidor ainda'));
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) => _SimpleUserTile(data: docs[index].data()),
          );
        },
      ),
    );
  }
}

class FollowingListPage extends StatelessWidget {
  final String targetId;
  const FollowingListPage({super.key, required this.targetId});

  Future<List<Map<String, dynamic>>> _loadFollowing(String targetId) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(targetId).get();
    if (!doc.exists) return [];
    final following = (doc.data()?['following'] as List<dynamic>?)?.cast<String>() ?? [];
    if (following.isEmpty) return [];
    final batch = <Future<DocumentSnapshot<Map<String, dynamic>>>>[];
    for (final uid in following) {
      batch.add(FirebaseFirestore.instance.collection('users').doc(uid).get());
    }
    final snaps = await Future.wait(batch);
    return snaps.where((s) => s.exists).map((s) => s.data() as Map<String, dynamic>).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seguindo')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadFollowing(targetId),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = snap.data!;
          if (list.isEmpty) return const Center(child: Text('Não está seguindo ninguém'));
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) => _SimpleUserTile(data: list[index]),
          );
        },
      ),
    );
  }
}
