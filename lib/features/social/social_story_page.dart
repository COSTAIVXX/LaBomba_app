import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'social_domain.dart';
import 'social_provider.dart';

class SocialStoryPage extends StatefulWidget {
  const SocialStoryPage({super.key});

  @override
  State<SocialStoryPage> createState() => _SocialStoryPageState();
}

class _SocialStoryPageState extends State<SocialStoryPage> {
  final TextEditingController _storyController = TextEditingController();
  bool _loading = true;
  bool _creating = false;
  List<SocialStory> _stories = <SocialStory>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadStories();
    });
  }

  @override
  void dispose() {
    _storyController.dispose();
    super.dispose();
  }

  Future<void> _loadStories() async {
    final provider = context.read<SocialProvider>();
    final stories = await provider.loadVisibleStories(limit: 20);
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = false;
      _stories = stories;
    });
  }

  Future<void> _publishStory() async {
    final provider = context.read<SocialProvider>();
    final currentUser = provider.authService.currentUser;
    if (currentUser == null) {
      return;
    }

    final text = _storyController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Escreva uma mensagem para publicar o story.')),
      );
      return;
    }

    setState(() => _creating = true);
    try {
      await provider.createStory(
        ownerId: currentUser.uid,
        contentType: SocialStoryType.text,
        text: text,
        visibility: SocialVisibility.public,
      );
      _storyController.clear();
      await _loadStories();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story publicado com sucesso.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível publicar o story: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }

  Future<void> _deleteOwnStory(SocialStory story) async {
    final provider = context.read<SocialProvider>();
    final currentUser = provider.authService.currentUser;
    if (currentUser == null) {
      return;
    }
    try {
      await provider.deleteStory(
          storyId: story.storyId, ownerId: currentUser.uid);
      await _loadStories();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível excluir o story: $error')),
      );
    }
  }

  Future<void> _openViewer(SocialStory story) async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      'Story de ${story.ownerId}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: SelectableText(
                        story.text ?? 'Story de mídia',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<SocialProvider>().authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stories'),
        actions: <Widget>[
          IconButton(
            onPressed: _loadStories,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar stories',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            if (currentUser != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _storyController,
                        maxLength: 280,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Compartilhe uma atualização curta...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _creating ? null : _publishStory,
                      icon: _creating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      label: Text(_creating ? 'Publicando...' : 'Publicar'),
                    ),
                  ],
                ),
              ),
            SizedBox(
              height: 110,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _stories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final story = _stories[index];
                        final isOwner = currentUser != null &&
                            story.ownerId == currentUser.uid;
                        return GestureDetector(
                          onTap: () => _openViewer(story),
                          child: SizedBox(
                            width: 84,
                            child: Column(
                              children: <Widget>[
                                Stack(
                                  children: <Widget>[
                                    CircleAvatar(
                                      radius: 32,
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      child: Text(
                                        story.ownerId
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    if (isOwner)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: GestureDetector(
                                          onTap: () => _deleteOwnStory(story),
                                          child: const CircleAvatar(
                                            radius: 12,
                                            backgroundColor: Colors.red,
                                            child: Icon(Icons.close, size: 14),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  story.ownerId,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (!_loading && _stories.isEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Icon(Icons.auto_stories_outlined, size: 48),
                        const SizedBox(height: 12),
                        const Text('Nenhum story ativo no momento.'),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
