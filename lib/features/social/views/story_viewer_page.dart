import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StoryViewerPage extends StatefulWidget {
  final String userId;
  final FirebaseFirestore? firestore;
  const StoryViewerPage({super.key, required this.userId, this.firestore});

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage> {
  FirebaseFirestore get _fs => widget.firestore ?? FirebaseFirestore.instance;
  int _index = 0;
  List<Map<String, dynamic>> _stories = [];

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    try {
      final snap = await _fs.collection('users').doc(widget.userId).collection('stories').orderBy('createdAt', descending: true).get();
      setState(() {
        _stories = snap.docs.map((d) => d.data()).toList(growable: false);
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_stories.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text('Story')), body: const Center(child: Text('Nenhum story disponível')));
    }
    final current = _stories[_index];
    final url = current['mediaUrl'] as String?;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: url != null ? Image.network(url, fit: BoxFit.contain) : const SizedBox.shrink(),
            ),
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Column(
                children: [
                  LinearProgressIndicator(value: (_index + 1) / (_stories.length)),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(onTap: () => setState(() => _index = (_index - 1).clamp(0, _stories.length - 1))),
                  ),
                  Expanded(
                    child: GestureDetector(onTap: () => setState(() => _index = (_index + 1).clamp(0, _stories.length - 1))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
