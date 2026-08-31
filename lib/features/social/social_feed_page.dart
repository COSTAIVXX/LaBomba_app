import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'social_provider.dart';

class SocialFeedPage extends StatefulWidget {
  const SocialFeedPage({super.key});

  @override
  State<SocialFeedPage> createState() => _SocialFeedPageState();
}

class _SocialFeedPageState extends State<SocialFeedPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<SocialProvider>().refreshFeed();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final provider = context.read<SocialProvider>();
    if (_scrollController.position.extentAfter < 300) {
      provider.loadMoreFeed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed principal'),
        actions: <Widget>[
          Semantics(
            label: 'Atualizar feed',
            button: true,
            child: Tooltip(
              message: 'Atualizar feed',
              child: IconButton(
                onPressed: () => context.read<SocialProvider>().refreshFeed(),
                icon: const Icon(Icons.refresh),
                tooltip: 'Atualizar feed',
              ),
            ),
          ),
        ],
      ),
      body: Consumer<SocialProvider>(
        builder: (context, provider, child) {
          final state = provider.feedState;

          if (state == SocialFeedState.initial ||
              state == SocialFeedState.loading) {
            return Semantics(
              label: 'Carregando feed social',
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          if (state == SocialFeedState.error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Semantics(
                  label: provider.feedError ?? 'Falha ao carregar o feed.',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        provider.feedError ?? 'Falha ao carregar o feed.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => provider.refreshFeed(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (state == SocialFeedState.empty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Semantics(
                  label: 'Nenhum post encontrado',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Icons.feed_outlined, size: 48),
                      const SizedBox(height: 12),
                      const Text('Ainda não há posts para exibir.'),
                    ],
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.refreshFeed(),
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount:
                  provider.feed.length + (provider.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= provider.feed.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Semantics(
                      label: 'Carregando mais posts',
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                final post = provider.feed[index];
                final mediaUrl =
                    post.mediaUrls.isNotEmpty ? post.mediaUrls.first : null;

                return Semantics(
                  container: true,
                  label:
                      'Post de ${post.authorId} em ${_formatRelativeTime(post.createdAt)}. Texto: ${post.text}',
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                child: Text(
                                  post.authorId.isNotEmpty
                                      ? post.authorId
                                          .substring(0, 1)
                                          .toUpperCase()
                                      : '?',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      post.authorId,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _formatRelativeTime(post.createdAt),
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SelectableText(post.text),
                          if (mediaUrl != null) ...<Widget>[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Semantics(
                                image: true,
                                label: 'Mídia do post',
                                child: Image.network(
                                  mediaUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 220,
                                  semanticLabel: 'Mídia do post',
                                  errorBuilder: (_, __, ___) => const SizedBox(
                                    height: 120,
                                    child: Center(
                                      child: Icon(Icons.broken_image_outlined),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              const Icon(Icons.chat_bubble_outline, size: 16),
                              const SizedBox(width: 6),
                              Text('${post.commentCount}'),
                              const SizedBox(width: 16),
                              const Icon(Icons.favorite_border, size: 16),
                              const SizedBox(width: 6),
                              Text('${post.reactionCount}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatRelativeTime(DateTime time) {
    final now = DateTime.now().toUtc();
    final delta = now.difference(time);
    if (delta.inMinutes < 1) {
      return 'agora';
    }
    if (delta.inHours < 1) {
      return '${delta.inMinutes}m';
    }
    if (delta.inDays < 1) {
      return '${delta.inHours}h';
    }
    if (delta.inDays < 7) {
      return '${delta.inDays}d';
    }
    return '${time.day}/${time.month}/${time.year}';
  }
}
