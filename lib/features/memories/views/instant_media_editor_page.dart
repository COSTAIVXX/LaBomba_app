import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import '../../../providers/google_auth_provider.dart';
import '../models/memory.dart';
import '../providers/memory_provider.dart';

class InstantMediaEditorPage extends StatefulWidget {
  final XFile media;
  final bool isVideo;

  const InstantMediaEditorPage({
    super.key,
    required this.media,
    required this.isVideo,
  });

  @override
  State<InstantMediaEditorPage> createState() => _InstantMediaEditorPageState();
}

class _InstantMediaEditorPageState extends State<InstantMediaEditorPage> {
  final _captionController = TextEditingController();
  VideoPlayerController? _videoController;
  int _filterIndex = 0;
  bool _publishing = false;

  static const _filters = [
    ColorFilter.mode(Colors.transparent, BlendMode.dst),
    ColorFilter.mode(Color(0x553B82F6), BlendMode.color),
    ColorFilter.mode(Color(0x55F59E0B), BlendMode.color),
    ColorFilter.mode(Color(0x55EC4899), BlendMode.color),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.media.path))
        ..initialize().then((_) {
          if (mounted) setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (_publishing) return;
    setState(() => _publishing = true);
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('É necessário entrar para publicar.');
      final extension = widget.isVideo ? 'mp4' : 'jpg';
      final ref = FirebaseStorage.instance.ref(
        'users/${user.uid}/memories/${const Uuid().v4()}.$extension',
      );
      await ref.putData(await widget.media.readAsBytes());
      final url = await ref.getDownloadURL();
      final caption = _captionController.text.trim();
      await context.read<MemoryProvider>().addOrUpdate(
            Memory(
              id: const Uuid().v4(),
              title: caption.isEmpty ? 'Memória da folia' : caption,
              description: caption.isEmpty ? null : caption,
              imageUrls: [url],
              ownerId: context.read<GoogleAuthProvider>().currentUserData?.uid,
            ),
          );
      if (mounted) Navigator.popUntil(context, ModalRoute.withName('/memories'));
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Widget _preview() {
    if (widget.isVideo) {
      final controller = _videoController;
      if (controller == null || !controller.value.isInitialized) {
        return const Center(child: CircularProgressIndicator());
      }
      return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: VideoPlayer(controller),
      );
    }
    return FutureBuilder<Uint8List>(
      future: widget.media.readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return Image.memory(snapshot.data!, fit: BoxFit.contain);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar publicação'),
        actions: [
          IconButton(
            tooltip: 'Publicar',
            onPressed: _publishing ? null : _publish,
            icon: _publishing
                ? const CircularProgressIndicator()
                : const Icon(Icons.send),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ColorFiltered(
              colorFilter: _filters[_filterIndex],
              child: _preview(),
            ),
          ),
          const SizedBox(height: 18),
          const Text('Filtro carnavalesco',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: List.generate(
              _filters.length,
              (index) => ChoiceChip(
                label: Text(index == 0 ? 'Original' : 'Folia $index'),
                selected: _filterIndex == index,
                onSelected: (_) => setState(() => _filterIndex = index),
              ),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _captionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Legenda rápida',
              hintText: 'Conte como foi esse momento...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _publishing ? null : _publish,
            icon: const Icon(Icons.publish),
            label: const Text('Publicar na memória'),
          ),
        ],
      ),
    );
  }
}
