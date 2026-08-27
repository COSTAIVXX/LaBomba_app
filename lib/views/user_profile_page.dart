import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/memories/models/memory.dart';
import '../features/memories/providers/memory_provider.dart';
import '../features/memories/views/memories_list_page.dart';
import '../providers/google_auth_provider.dart';
import '../widgets/user_appbar_actions.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MemoryProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<GoogleAuthProvider>().currentUserData;
    final memories = context.watch<MemoryProvider>().memories;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Meu perfil')),
        body: const Center(child: Text('Entre para acessar seu perfil.')),
      );
    }

    final ownMemories = memories
        .where((memory) => memory.ownerId == user.uid)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final displayName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!
        : 'Usuário';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu perfil'),
        actions: [UserAppBarActions()],
      ),
      body: RefreshIndicator(
        onRefresh: context.read<MemoryProvider>().load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundImage: user.photoUrl?.isNotEmpty == true
                          ? NetworkImage(user.photoUrl!)
                          : null,
                      child: user.photoUrl?.isNotEmpty == true
                          ? null
                          : Text(displayName[0].toUpperCase(),
                              style: const TextStyle(fontSize: 30)),
                    ),
                    const SizedBox(height: 12),
                    Text(displayName,
                        style: Theme.of(context).textTheme.headlineSmall),
                    if (user.email != null) ...[
                      const SizedBox(height: 4),
                      Text(user.email!, style: Theme.of(context).textTheme.bodySmall),
                    ],
                    const SizedBox(height: 16),
                    Text('${ownMemories.length} memórias publicadas'),
                  ],
                ),
              ),
            ),
            if (ownMemories.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('Você ainda não publicou memórias.')),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _MemoryTile(memory: ownMemories[index]),
                    childCount: ownMemories.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MemoryTile extends StatelessWidget {
  const _MemoryTile({required this.memory});

  final Memory memory;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MemoryDetailPage(memory: memory)),
      ),
      onLongPress: () => _showManagementMenu(context),
      child: Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: memory.imageUrls.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(memory.title,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                ),
              )
            : Image.network(memory.imageUrls.first, fit: BoxFit.cover),
      ),
    );
  }

  Future<void> _showManagementMenu(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('Visualizar'),
              onTap: () => Navigator.pop(context, 'view'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Excluir memória'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted) return;
    if (action == 'view') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MemoryDetailPage(memory: memory)),
      );
    } else if (action == 'delete') {
      await context.read<MemoryProvider>().remove(memory.id);
    }
  }
}
