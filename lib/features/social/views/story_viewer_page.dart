import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

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
  List<Map<String, dynamic>> _stories = []; // each story will include '__id' key for doc id

  VideoPlayerController? _videoController;
  Timer? _progressTimer;
  double _progress = 0.0;
  Duration _currentDuration = const Duration(seconds: 5);
  DateTime? _startedAt;

  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  @override
  void dispose() {
    _disposeVideo();
    _progressTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _disposeVideo() {
    try {
      _videoController?.removeListener(_onVideoUpdate);
      _videoController?.pause();
      _videoController?.dispose();
    } catch (_) {}
    _videoController = null;
  }

  Future<void> _loadStories() async {
    try {
      final snap = await _fs
          .collection('users')
          .doc(widget.userId)
          .collection('stories')
          .orderBy('createdAt', descending: false)
          .get();
      setState(() {
        _stories = snap.docs.map((d) {
          final m = Map<String, dynamic>.from(d.data());
          m['__id'] = d.id;
          return m;
        }).toList(growable: false);
      });
      if (_stories.isNotEmpty) {
        // start at first
        _startForIndex(0);
      }
    } catch (e) {
      // ignore
    }
  }

  void _onVideoUpdate() {
    if (!mounted) return;
    final ctrl = _videoController;
    if (ctrl == null) return;
    if (!ctrl.value.isInitialized) return;
    final dur = ctrl.value.duration;
    final pos = ctrl.value.position;
    if (dur.inMilliseconds > 0) {
      setState(() {
        _currentDuration = dur;
        _progress = pos.inMilliseconds / dur.inMilliseconds;
      });
      if (pos >= dur) {
        _next();
      }
    }
  }

  void _startForIndex(int idx) async {
    _progressTimer?.cancel();
    _disposeVideo();
    _progress = 0.0;
    _index = idx;
    if (idx < 0 || idx >= _stories.length) return;
    final story = _stories[idx];
    final mediaUrl = story['mediaUrl'] as String?;
    final type = (story['type'] as String?) ?? 'image';

    // mark viewed
    _markViewed(story['__id']);

    if (type == 'video' && mediaUrl != null) {
      try {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(mediaUrl));
        await _videoController!.initialize();
        _videoController!.addListener(_onVideoUpdate);
        await _videoController!.play();
        setState(() {
          _currentDuration = _videoController!.value.duration;
        });
      } catch (_) {
        // fallback to image-like timeout
        _startImageTimer(story);
      }
    } else {
      _startImageTimer(story);
    }
  }

  void _startImageTimer(Map<String, dynamic> story) {
    _currentDuration = Duration(seconds: (story['duration'] as int?) ?? 5);
    _progress = 0.0;
    _startedAt = DateTime.now();
    const tickMs = 50;
    _progressTimer = Timer.periodic(const Duration(milliseconds: tickMs), (t) {
      if (!mounted) return;
      final elapsed = DateTime.now().difference(_startedAt!).inMilliseconds;
      final total = _currentDuration.inMilliseconds;
      setState(() {
        _progress = (elapsed / total).clamp(0.0, 1.0);
      });
      if (elapsed >= total) {
        t.cancel();
        _next();
      }
    });
  }

  void _next() {
    if (_index < _stories.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _prev() {
    if (_index > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
    } else {
      // at first — do nothing or exit
      Navigator.of(context).pop();
    }
  }

  Future<void> _markViewed(String? storyId) async {
    if (storyId == null) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final docRef = _fs.collection('users').doc(widget.userId).collection('stories').doc(storyId);
      await docRef.update({
        'viewedBy': FieldValue.arrayUnion([user.uid])
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_stories.isEmpty) {
      return Scaffold(
          appBar: AppBar(title: const Text('Story')), body: const Center(child: Text('Nenhum story disponível')));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onVerticalDragUpdate: (d) {
            if (d.delta.dy > 12) Navigator.of(context).pop();
          },
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: _stories.length,
                onPageChanged: (p) {
                  // start the media for new page
                  _startForIndex(p);
                },
                itemBuilder: (context, i) {
                  final story = _stories[i];
                  final mediaUrl = story['mediaUrl'] as String?;
                  final type = (story['type'] as String?) ?? 'image';
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                      child: type == 'video' && mediaUrl != null && _videoController != null && i == _index
                          ? AspectRatio(
                              aspectRatio: _videoController!.value.aspectRatio, child: VideoPlayer(_videoController!))
                          : (mediaUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: mediaUrl,
                                  fit: BoxFit.contain,
                                  placeholder: (c, u) => const Center(child: CircularProgressIndicator()))
                              : const SizedBox.shrink()),
                    ),
                  );
                },
              ),

              // Progress bars
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Column(
                  children: [
                    Row(
                      children: List.generate(_stories.length, (i) {
                        final filled = i < _index;
                        final current = i == _index;
                        return Expanded(
                          child: Container(
                            height: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: filled ? 1.0 : (current ? _progress : 0.0),
                              child: Container(
                                  decoration:
                                      BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // Top-left: author and close
              Positioned(
                top: 16,
                left: 12,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: _stories[_index]['authorPhoto'] != null
                          ? NetworkImage(_stories[_index]['authorPhoto'])
                          : null,
                      child: _stories[_index]['authorPhoto'] == null
                          ? Text((_stories[_index]['authorName'] ?? '')[0] ?? '?')
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_stories[_index]['authorName'] ?? '',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        if (_stories[_index]['createdAt'] != null)
                          Text(_relativeTime(_stories[_index]['createdAt']),
                              style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    )
                  ],
                ),
              ),

              // Left/right tap areas
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _prev,
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _next,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeTime(dynamic ts) {
    try {
      DateTime dt;
      if (ts is Timestamp)
        dt = ts.toDate();
      else if (ts is int)
        dt = DateTime.fromMillisecondsSinceEpoch(ts);
      else if (ts is DateTime)
        dt = ts;
      else
        return '';
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'agora';
      if (diff.inHours < 1) return '${diff.inMinutes}m';
      if (diff.inDays < 1) return '${diff.inHours}h';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
