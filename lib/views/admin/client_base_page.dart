import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/client.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/client_provider.dart';
import '../../theme/app_theme.dart';
import 'admin_login_page.dart';

class ClientBasePage extends StatelessWidget {
  const ClientBasePage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!context.watch<AdminAuthProvider>().isAuthenticated) {
      return const AdminLoginPage();
    }
    return const _ClientBaseContent();
  }
}

class _ClientBaseContent extends StatefulWidget {
  const _ClientBaseContent();

  @override
  State<_ClientBaseContent> createState() => _ClientBaseContentState();
}

class _ClientBaseContentState extends State<_ClientBaseContent> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Base de Clientes'),
        leading: IconButton(
          tooltip: 'Voltar para operação',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/admin'),
        ),
      ),
      body: SafeArea(
        child: Consumer<ClientProvider>(
          builder: (context, provider, _) {
            final clients = provider.clients
                .where((c) => c.fullName.toLowerCase().contains(_query.toLowerCase()))
                .toList();
            return LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 680;
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Padding(
                      padding: EdgeInsets.all(compact ? 16 : 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Compradores cadastrados',
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 6),
                          Text('${provider.clients.length} cliente(s) na base',
                              style: const TextStyle(color: Colors.white60)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Buscar por nome',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (v) => setState(() => _query = v),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: clients.isEmpty
                                ? const _EmptyClients()
                                : ListView.separated(
                                    itemCount: clients.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (context, index) => _ClientRowSimple(client: clients[index]),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _EmptyClients extends StatelessWidget {
  const _EmptyClients();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: const [
          Icon(Icons.people_outline, size: 52, color: Colors.white38),
          SizedBox(height: 12),
          Text('Nenhum cliente cadastrado ainda',
              style: TextStyle(color: Colors.white60)),
        ]),
      );
}

class _ClientRowSimple extends StatelessWidget {
  const _ClientRowSimple({required this.client});
  final Client client;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.primaryLight.withOpacity(.2),
            child: Text(client.fullName.substring(0, 1).toUpperCase()),
          ),
          title: Text(client.fullName, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(client.purchaseHistory.isEmpty
              ? client.phone
              : '${client.phone} • ${client.purchaseHistory.map((p) => p.description).join(', ')}'),
          trailing: SizedBox(
            width: 140,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${client.age} anos', style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(client.purchaseHistory.isEmpty ? 'Pendente' : client.purchaseHistory.last.paymentStatus,
                        style: TextStyle(color: client.purchaseHistory.isEmpty ? Colors.orangeAccent : (client.purchaseHistory.last.paymentStatus == 'Confirmado' ? Colors.greenAccent : Colors.orangeAccent), fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    IconButton(
                        tooltip: 'Editar',
                        onPressed: () async {
                          await showDialog<void>(
                              context: context,
                              builder: (context) => _EditClientDialog(client: client));
                        },
                        icon: const Icon(Icons.edit)),
                    IconButton(
                        tooltip: 'Excluir',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                    title: const Text('Confirmar exclusão'),
                                    content: const Text('Deseja realmente excluir este cliente?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                                      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
                                    ],
                                  ));
                          if (confirm == true) {
                            if (!context.mounted) return;
                            await context.read<ClientProvider>().deleteClient(client.id);
                          }
                        },
                        icon: const Icon(Icons.delete)),
                  ],
                )
              ],
            ),
          ),
          onTap: () => showDialog<void>(context: context, builder: (context) => _ClientDetailsDialog(client: client)),
        ),
            );
}

class _ClientDetailsDialog extends StatelessWidget {
  const _ClientDetailsDialog({required this.client});
  final Client client;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(client.fullName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailLine(label: 'Idade', value: '${client.age} anos'),
              _DetailLine(
                  label: 'Data de nascimento', value: _date(client.birthDate)),
              _DetailLine(label: 'CPF', value: client.cpf),
              _DetailLine(label: 'Telefone', value: client.phone),
              const SizedBox(height: 14),
              const Text('Informações de Pagamento',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (client.purchaseHistory.isEmpty)
                const Text('Nenhuma informação de pagamento registrada.',
                    style: TextStyle(color: Colors.white60))
              else
                for (final purchase in client.purchaseHistory)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(purchase.description),
                    subtitle: Text(
                        '${purchase.quantity} unidade(s) • ${_date(purchase.purchasedAt)}\nMétodo: ${purchase.paymentMethod}'),
                    trailing: Text(purchase.paymentStatus,
                        style: TextStyle(
                            color: purchase.paymentStatus == 'Confirmado'
                                ? Colors.greenAccent
                                : Colors.orangeAccent)),
                  ),
            ],
          ),
        ),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar')),
        ],
      );
}

class _EditClientDialog extends StatefulWidget {
  const _EditClientDialog({required this.client});
  final Client client;

  @override
  State<_EditClientDialog> createState() => _EditClientDialogState();
}

class _EditClientDialogState extends State<_EditClientDialog> {
  late final _name = TextEditingController(text: widget.client.fullName);
  late final _birth = TextEditingController(
      text:
          '${widget.client.birthDate.day.toString().padLeft(2, '0')}/${widget.client.birthDate.month.toString().padLeft(2, '0')}/${widget.client.birthDate.year}');
  late final _cpf = TextEditingController(text: widget.client.cpf);
  late final _phone = TextEditingController(text: widget.client.phone);
  late bool _accepted = widget.client.acceptedTerms;

  @override
  void dispose() {
    _name.dispose();
    _birth.dispose();
    _cpf.dispose();
    _phone.dispose();
    super.dispose();
  }

  DateTime? _parseBirth() {
    final parts = _birth.text.split('/');
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return null;
    return DateTime(y, m, d);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Editar cliente'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nome completo')),
          TextField(controller: _birth, decoration: const InputDecoration(labelText: 'Data de nascimento (DD/MM/AAAA)')),
          TextField(controller: _cpf, decoration: const InputDecoration(labelText: 'CPF')),
          TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Telefone')),
          SwitchListTile(value: _accepted, onChanged: (v) => setState(() => _accepted = v), title: const Text('Aceitou o termo')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () async {
            final birthDate = _parseBirth();
            if (birthDate == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data de nascimento inválida')));
              return;
            }
            await context.read<ClientProvider>().updateClient(
                  clientId: widget.client.id,
                  fullName: _name.text,
                  birthDate: birthDate,
                  cpf: _cpf.text,
                  phone: _phone.text,
                  acceptedTerms: _accepted,
                );
            if (context.mounted) Navigator.pop(context);
          }, child: const Text('Salvar')),
        ],
      );
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: RichText(
          text: TextSpan(style: DefaultTextStyle.of(context).style, children: [
            TextSpan(
                text: '$label: ',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            TextSpan(
                text: value, style: const TextStyle(color: Colors.white70)),
          ]),
        ),
      );
}

String _date(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
