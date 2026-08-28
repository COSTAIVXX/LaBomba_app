import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../../../services/auth_service.dart';
import '../../../services/outbox_service.dart';

/// Master Developer Dashboard (God-Mode)
/// - Access restricted to a whitelisted email plus a PIN stored in secure storage.
/// - Provides: user search + ban/delete, interactions audit (posts + comments), and Outbox/Dead-letter inspection + export.

class MasterDeveloperDashboardPage extends StatefulWidget {
  const MasterDeveloperDashboardPage({super.key});

  @override
  State<MasterDeveloperDashboardPage> createState() => _MasterDeveloperDashboardPageState();
}

class _MasterDeveloperDashboardPageState extends State<MasterDeveloperDashboardPage> {
  static const String _whitelistedEmail = 'costaivxxxxx@gmail.com'; // provided by user
  static const String _pinStorageKey = 'godmode_pin';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _allowedByEmail = false;
  bool _authorized = false;
  bool _loading = true;

  String _search = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkEmailPermission();
  }

  Future<void> _checkEmailPermission() async {
    setState(() => _loading = true);
    try {
      final current = AuthService().currentUser;
      final email = current?.email?.toLowerCase();
      _allowedByEmail = email != null && email == _whitelistedEmail.toLowerCase();
    } catch (_) {
      _allowedByEmail = false;
    }
    setState(() => _loading = false);

    if (_allowedByEmail) {
      // prompt for PIN
      WidgetsBinding.instance.addPostFrameCallback((_) => _showPinDialogIfNeeded());
    }
  }

  Future<void> _showPinDialogIfNeeded() async {
    if (_authorized) return;

    final stored = await _secureStorage.read(key: _pinStorageKey);

    // If PIN not set yet, allow the whitelisted user to create one
    if (stored == null) {
      final set = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Configurar PIN God‑Mode'),
          content: const Text('Nenhum PIN foi configurado. Deseja criar um PIN agora?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Não')),
            ElevatedButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Sim')),
          ],
        ),
      );

      if (set == true) {
        await _setPinFlow();
      }
      return;
    }

    // Ask for PIN
    final ok = await _askForPinAndValidate(stored);
    if (ok) setState(() => _authorized = true);
  }

  Future<void> _setPinFlow() async {
    final controller = TextEditingController();
    final confirm = TextEditingController();
    final set = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Criar PIN God‑Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: controller, decoration: const InputDecoration(labelText: 'PIN'), obscureText: true),
            TextField(controller: confirm, decoration: const InputDecoration(labelText: 'Confirmar PIN'), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Salvar')),
        ],
      ),
    );

    if (set == true) {
      final pin = controller.text.trim();
      final conf = confirm.text.trim();
      if (pin.isEmpty || pin != conf) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN inválido ou não confere')));
        return;
      }
      await _secureStorage.write(key: _pinStorageKey, value: pin);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN salvo com sucesso')));
      setState(() => _authorized = true);
    }
  }

  Future<bool> _askForPinAndValidate(String stored) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: const Text('PIN God‑Mode'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'PIN'), obscureText: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Entrar')),
        ],
      ),
    );

    if (ok != true) return false;
    final entered = controller.text.trim();
    if (entered == stored) return true;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN incorreto')));
    return false;
  }

  // User management actions
  Future<void> _banUser(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirmar banimento'),
        content: const Text('Deseja marcar este usuário como banido?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Não')),
          ElevatedButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Sim')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _firestore.collection('users').doc(userId).update({'banned': true});
      await _logAdminAction(action: 'ban_user', targetId: userId, details: {'collection': 'users'});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuário banido')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falha ao banir usuário')));
    }
  }

  Future<void> _deleteUser(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Excluir este usuário removerá seus dados do Firestore. Confirma?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Não')),
          ElevatedButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Sim')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _firestore.collection('users').doc(userId).delete();
      await _logAdminAction(action: 'delete_user', targetId: userId, details: {'collection': 'users'});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuário excluído')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falha ao excluir usuário')));
    }
  }

  Future<void> _exportDeadLetter() async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/outbox_deadletter.json';
    await OutboxService.instance.exportDeadLetterToFile(path);
    await _logAdminAction(action: 'export_deadletter', targetId: path, details: {'exportPath': path});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dead-letter exportado: $path')));
  }

  Future<void> _logAdminAction({required String action, required String targetId, Map<String, dynamic>? details}) async {
    try {
      final admin = AuthService().currentUser;
      final entry = <String, dynamic>{
        'action': action,
        'targetId': targetId,
        'details': details ?? {},
        'adminUid': admin?.uid,
        'adminEmail': admin?.email,
        'timestamp': FieldValue.serverTimestamp(),
      };
      await _firestore.collection('admin_audit').add(entry);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!_allowedByEmail) return const Scaffold(body: Center(child: Text('Acesso negado')));

    return Scaffold(
      appBar: AppBar(title: const Text('Master Developer Dashboard')),
      body: _authorized ? _buildDashboard() : Center(child: ElevatedButton(onPressed: _showPinDialogIfNeeded, child: const Text('Autenticar (PIN)'))),
    );
  }

  Widget _buildDashboard() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.primary,
            child: TabBar(
              tabs: const [Tab(text: 'Usuários'), Tab(text: 'Interações'), Tab(text: 'Outbox')],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildUsersTab(),
                _buildInteractionsTab(),
                _buildOutboxTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Buscar por nome ou email'),
            onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('users').snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final docs = snap.data?.docs ?? [];
              final filtered = docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final name = (data['name'] as String?)?.toLowerCase() ?? '';
                final email = (data['email'] as String?)?.toLowerCase() ?? '';
                if (_search.isEmpty) return true;
                return name.contains(_search) || email.contains(_search) || d.id.contains(_search);
              }).toList();
              if (filtered.isEmpty) return const Center(child: Text('Nenhum usuário encontrado'));
              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final d = filtered[i];
                  final data = d.data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(data['name'] as String? ?? d.id),
                    subtitle: Text(data['email'] as String? ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.block, color: Colors.orange), onPressed: () => _banUser(d.id)),
                        IconButton(icon: const Icon(Icons.delete_forever, color: Colors.red), onPressed: () => _deleteUser(d.id)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInteractionsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('posts').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('Nenhuma postagem'));
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i];
            final data = d.data() as Map<String, dynamic>;
            final created = data['createdAt'];
            return ExpansionTile(
              title: Text('Post ${d.id} — ${data['authorId'] ?? 'unknown'}'),
              subtitle: Text('${data['content'] ?? ''}'),
              children: [
                ListTile(title: Text('Criado em: ${created is Timestamp ? created.toDate() : created ?? 'n/a'}')),
                FutureBuilder<QuerySnapshot>(
                  future: _firestore.collection('posts').doc(d.id).collection('comments').get(),
                  builder: (c, cs) {
                    final comments = cs.data?.docs ?? [];
                    return Column(
                      children: comments.map((cm) {
                        final cd = cm.data() as Map<String, dynamic>;
                        final cAt = cd['createdAt'];
                        return ListTile(
                          title: Text(cd['text'] as String? ?? ''),
                          subtitle: Text('por ${cd['authorId'] ?? 'unknown'} — ${cAt is Timestamp ? cAt.toDate() : cAt ?? ''}'),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildOutboxTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: OutboxService.instance.readDeadLetter(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final items = snap.data ?? [];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  ElevatedButton.icon(onPressed: _exportDeadLetter, icon: const Icon(Icons.download), label: const Text('Exportar dead-letter')),
                  const SizedBox(width: 12),
                  Text('Itens: ${items.length}'),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final it = items[i];
                  return ListTile(
                    title: Text(it['type'] as String? ?? 'unknown'),
                    subtitle: Text('id: ${it['id'] ?? 'n/a'} — reason: ${it['deadReason'] ?? ''}'),
                    isThreeLine: true,
                    trailing: Text(it['deadLetterAt'] ?? ''),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
