import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:labomba_app/features/memories/providers/memory_provider.dart';
import 'package:labomba_app/features/memories/models/memory.dart';
import 'package:labomba_app/features/memories/views/memory_editor_page.dart';

class MemoriesListPage extends StatelessWidget {
  const MemoriesListPage({super.key});

  // Vibrant palette tuned for carnival
  static const Color _bgGradientStart = Color(0xFF7C1AFF); // magenta/purple
  static const Color _bgGradientEnd = Color(0xFFFF6A00); // orange
  static const Color _cardColor = Color(0xFF161616);
  static const double _cardRadius = 16.0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MemoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memórias'),
        backgroundColor: _bgGradientStart,
        elevation: 2,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bgGradientStart, _bgGradientEnd],
          ),
        ),
        child: Builder(builder: (context) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          if (provider.error != null) {
            return Center(child: Text('Erro: ${provider.error}', style: const TextStyle(color: Colors.white)));
          }

          // Sort memories chronologically (newest first)
          final List<Memory> items = List.from(provider.memories)
           ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          if (items.isEmpty) {
           return const Center(child: Text('Nenhuma memória encontrada', style: TextStyle(color: Colors.white70)));
          }

          return ListView.separated(
           padding: const EdgeInsets.all(16),
           itemCount: items.length + 1, // +1 for the stories carousel header
           separatorBuilder: (_, __) => const SizedBox(height: 12),
           itemBuilder: (context, index) {
             if (index == 0) {
               // Stories / Status carousel header
               final stories = items.where((m) => m.imageUrls.isNotEmpty).take(12).toList();
               return _StoriesCarousel(memories: stories, accentColor: _bgGradientStart);
             }

             final m = items[index - 1];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => MemoryDetailPage(memory: m),
                  ));
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(_cardRadius),
                    boxShadow: [
                                          BoxShadow(color: const Color.fromRGBO(0, 0, 0, 0.4), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      if (m.imageUrls.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(m.imageUrls.first, width: 84, height: 84, fit: BoxFit.cover),
                        )
                      else
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.photo, color: Colors.white30),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            if (m.description != null)
                              Text(
                                m.description!,
                                style: const TextStyle(color: Colors.white70),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 8),
                            Text(
                              '${m.createdAt.toLocal()}',
                              style: const TextStyle(color: Colors.white38, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _bgGradientEnd,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MemoryEditorPage()));
        },
      ),
    );
  }
}

class MemoryDetailPage extends StatelessWidget {
  final Memory memory;
  const MemoryDetailPage({super.key, required this.memory});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(memory.title), backgroundColor: const Color(0xFF7C1AFF)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.white10,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(memory.description ?? '', style: const TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 12),
                    Text('Data: ${memory.date.toLocal()}', style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (memory.imageUrls.isNotEmpty) ...[
              const Text('Imagens:', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, idx) => ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(memory.imageUrls[idx], width: 160, fit: BoxFit.cover)),
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: memory.imageUrls.length,
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}


// STORIES / STATUS CAROUSEL
class _StoriesCarousel extends StatelessWidget {
  final List<Memory> memories;
  final Color accentColor;
  const _StoriesCarousel({required this.memories, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    if (memories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
            child: Text('Status', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: memories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final m = memories[index];
                final thumb = m.imageUrls.first;
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => _FullScreenStoryViewer(memory: m, initialIndex: 0)));
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: accentColor, width: 3),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .4), blurRadius: 6, offset: const Offset(0,4))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(thumb, fit: BoxFit.cover, width: 72, height: 72),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 80,
                        child: Text(
                          m.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenStoryViewer extends StatefulWidget {
  final Memory memory;
  final int initialIndex;
  const _FullScreenStoryViewer({required this.memory, this.initialIndex = 0});

  @override
  State<_FullScreenStoryViewer> createState() => _FullScreenStoryViewerState();
}

class _FullScreenStoryViewerState extends State<_FullScreenStoryViewer> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.memory.imageUrls;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: Text(widget.memory.title)),
      body: PageView.builder(
        controller: _controller,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(images[index], fit: BoxFit.contain),
            ),
          );
        },
      ),
    );
  }
}
