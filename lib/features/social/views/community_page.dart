import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunidade'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: firestore.collection('users').orderBy('displayName').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Erro ao carregar comunidade'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Nenhum membro encontrado.'));
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3 / 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final d = docs[index].data();
              final displayName = (d['displayName'] as String?) ?? 'Usuário';
              final avatar = d['photoURL'] as String?;
              final presence = (d['presence'] as String?) ?? 'offline';
              return _MemberCard(name: displayName, avatarUrl: avatar, presence: presence);
            },
          );
        },
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final String presence;
  const _MemberCard({required this.name, this.avatarUrl, required this.presence});

  Color _presenceColor(String p) {
    switch (p.toLowerCase()) {
      case 'online':
      case 'present':
        return Colors.greenAccent;
      case 'away':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x9911121A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
        boxShadow: [BoxShadow(color: const Color(0x66000000), blurRadius: 8)],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.grey[800],
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            child: avatarUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
          ),
          const SizedBox(height: 12),
          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: _presenceColor(presence), shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(presence, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
