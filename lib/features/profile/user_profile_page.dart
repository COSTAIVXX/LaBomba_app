import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/media_service.dart';
import '../../services/storage_upload_service.dart';
import './user_profile_service.dart';

class UserProfilePage extends StatefulWidget {
  final String? userId;

  const UserProfilePage({super.key, this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late final UserProfileService _service;
  String? _uid;
  UserProfile? _profile;
  bool _loading = true;
  final _editNameController = TextEditingController();
  final _editBioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _service = UserProfileService(storage: Provider.of(context, listen: false));
    // determine uid: provided or current user
    final auth = Provider.of<AuthService>(context, listen: false);
    _uid = widget.userId ?? auth.currentUser?.uid;
    if (_uid != null) {
      _loadProfile(_uid!);
      _service.userProfileStream(_uid!).listen((p) {
        if (p != null) setState(() => _profile = p);
      });
    } else {
      _loading = false;
    }
  }

  Future<void> _loadProfile(String uid) async {
    setState(() => _loading = true);
    final p = await _service.getUserProfile(uid);
    setState(() {
      _profile = p;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _editNameController.dispose();
    _editBioController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_uid == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 2400, imageQuality: 90);
    if (picked == null) return;

    setState(() => _loading = true);
    try {
      final file = File(picked.path);
      // compress
      final compressed = await MediaService().compressImageFile(file, maxWidth: 1200, quality: 80);
      final thumb = await MediaService().createThumbnail(file, maxWidth: 300, quality: 60);

      // upload
      final storage = StorageUploadService();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final avatarPath = storage.userAvatarPath(_uid!);
      final avatarUrl = await storage.uploadFile(avatarPath, compressed);

      // optionally upload thumbnail
      final thumbPath = 'users/${_uid}/thumb_avatar_$timestamp.jpg';
      await storage.uploadFile(thumbPath, thumb);

      // update profile
      final updated = _profile!.copyWith(avatarUrl: avatarUrl);
      await _service.updateProfile(updated);
      // ensure local reload
      await _loadProfile(_uid!);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar atualizado')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falha ao enviar avatar')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showEditDialog() async {
    if (_profile == null) return;
    _editNameController.text = _profile!.displayName;
    _editBioController.text = _profile!.bio ?? '';
    final updated = await showDialog<UserProfile?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _editNameController, decoration: const InputDecoration(labelText: 'Nome'), maxLength: 60),
            TextField(
                controller: _editBioController,
                decoration: const InputDecoration(labelText: 'Bio'),
                maxLength: 1000,
                maxLines: 4),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final newProfile =
                  _profile!.copyWith(displayName: _editNameController.text.trim(), bio: _editBioController.text.trim());
              Navigator.of(ctx).pop(newProfile);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (updated != null) {
      setState(() => _loading = true);
      try {
        await _service.updateProfile(updated);
        // reload locally
        await _loadProfile(updated.id);
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falha ao salvar perfil')));
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text('Usuário não encontrado'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                              radius: 48,
                              backgroundImage: _profile!.avatarUrl != null ? NetworkImage(_profile!.avatarUrl!) : null,
                              child: _profile!.avatarUrl == null ? const Icon(Icons.person, size: 48) : null),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: IconButton(
                              tooltip: 'Alterar avatar',
                              icon: const Icon(Icons.camera_alt, size: 20),
                              onPressed: _pickAndUploadAvatar,
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(_profile!.displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if ((_profile!.bio ?? '').isNotEmpty) Text(_profile!.bio!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _statTile('Posts', _profile!.stats['posts'] ?? 0),
                          _statTile('Seguidores', _profile!.stats['followers'] ?? 0),
                          _statTile('Seguindo', _profile!.stats['following'] ?? 0),
                        ],
                      ),
                      const SizedBox(height: 20),
                      FilledButton(onPressed: _showEditDialog, child: const Text('Editar perfil')),
                    ],
                  ),
                ),
    );
  }

  Widget _statTile(String label, int value) {
    return Column(
      children: [
        Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
