import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'story_viewer_page.dart';

class StoriesCarousel extends StatelessWidget {
  final FirebaseFirestore? firestore;
  const StoriesCarousel({super.key, this.firestore});

  FirebaseFirestore get _fs => firestore ?? FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _fs.collection('users').orderBy('displayName').limit(20).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: SizedBox(height: 60));
          final docs = snap.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final d = docs[index];
              final name = (d.data()['displayName'] as String?) ?? 'Usuário';
              final avatar = d.data()['photoURL'] as String?;
              final userId = d.id;
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoryViewerPage(userId: userId, firestore: _fs))),
                child: Column(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [Colors.pinkAccent, Colors.orangeAccent]),
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.08 * 255).round()), blurRadius: 4)],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                          child: avatar == null ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?') : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(width: 72, child: Text(name, overflow: TextOverflow.ellipsis, maxLines: 1, textAlign: TextAlign.center)),
                  ],
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: docs.length,
          );
        },
      ),
    );
  }
}
