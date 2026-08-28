import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/ticket.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/shop_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/admin_sidebar.dart';
import 'package:labomba_app/widgets/user_appbar_actions.dart';
import '../../widgets/admin/metric_card.dart';
import 'client_base_page.dart';
import 'content_dashboard_page.dart';
import '../../features/notifications/services/official_horn_service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  final List<String> _sectionTitles = [
    'Operação & Vendas',
    'Base de Clientes',
    'Gestão de Conteúdo (CMS)',
  ];

  @override
  Widget build(BuildContext context) {
    if (!context.watch<AdminAuthProvider>().isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/admin/login');
        }
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 850;
        
        final sidebar = AdminSidebar(
          selectedIndex: _selectedIndex,
          forceExpanded: !isDesktop,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
            if (!isDesktop && Scaffold.of(context).isDrawerOpen) {
              Navigator.pop(context);
            }
          },
          onLogout: () async {
            await context.read<AdminAuthProvider>().logout();
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(context, '/admin/login', (_) => false);
            }
          },
        );

        return Scaffold(
          appBar: AppBar(
            title: Text('LaBomba Admin • ${_sectionTitles[_selectedIndex]}'),
            actions: [
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'AO VIVO',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (!isDesktop)
                IconButton(
                  tooltip: 'Sair',
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await context.read<AdminAuthProvider>().logout();
                    if (!mounted) return;
                    Navigator.pushNamedAndRemoveUntil(context, '/admin/login', (_) => false);
                  },
                ),
              UserAppBarActions(),
            ],
          ),
          drawer: isDesktop ? null : Drawer(child: sidebar),
          body: Row(
            children: [
              if (isDesktop) sidebar,
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: const [
                    _DashboardOverviewTab(),
                    ClientBasePage(embedded: true),
                    ContentDashboardPage(embedded: true),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}

class _DashboardOverviewTab extends StatelessWidget {
  const _DashboardOverviewTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(compact ? 16 : 32, 12, compact ? 16 : 32, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Consumer<ShopProvider>(
                  builder: (context, shop, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SEXTA, 05 FEV 2027  •  PEÇANHA, MG',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(color: Colors.white54, letterSpacing: 1.2)),
                      const SizedBox(height: 8),
                      Text('Bom dia, equipe.',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      const Text(
                          'Acompanhe a operação e registre vendas em poucos toques.',
                          style: TextStyle(color: Colors.white60)),
                      const SizedBox(height: 24),
                      _DashboardGrid(compact: compact, shop: shop),
                      const SizedBox(height: 16),
                      _QuickSalePanel(shop: shop),
                      const SizedBox(height: 16),
                      const _OfficialAnnouncementPanel(),
                      const SizedBox(height: 28),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Desempenho por lote',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                            Text('${shop.totalCapacity} abadás no total',
                                style:
                                    const TextStyle(color: Colors.white54)),
                          ]),
                      const SizedBox(height: 14),
                      _LotGrid(shop: shop),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OfficialAnnouncementPanel extends StatefulWidget {
    const _OfficialAnnouncementPanel();

    @override
    State<_OfficialAnnouncementPanel> createState() => _OfficialAnnouncementPanelState();
}

  class _OfficialAnnouncementPanelState extends State<_OfficialAnnouncementPanel> {
    final _titleController = TextEditingController(text: 'Aviso da direção');
    final _messageController = TextEditingController();
    final _service = OfficialHornService();
    bool _publishing = false;

    @override
    void dispose() {
      _titleController.dispose();
      _messageController.dispose();
      super.dispose();
    }

    Future<void> _publish() async {
      final message = _messageController.text.trim();
      if (message.isEmpty || _publishing) return;
      setState(() => _publishing = true);
      try {
        await _service.publish(
          title: _titleController.text.trim().isEmpty
              ? 'Aviso da direção'
              : _titleController.text,
          message: message,
        );
        _messageController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aviso enviado aos foliões ativos.')),
          );
        }
      } finally {
        if (mounted) setState(() => _publishing = false);
      }
    }

    @override
    Widget build(BuildContext context) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Buzina oficial', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Envie um aviso rápido para quem está no bloco.'),
              const SizedBox(height: 12),
              TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Título')),
              const SizedBox(height: 8),
              TextField(
                controller: _messageController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Comunicado'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _publishing ? null : _publish,
                icon: const Icon(Icons.campaign_outlined),
                label: Text(_publishing ? 'Enviando...' : 'Disparar aviso'),
              ),
            ],
          ),
        ),
      );
    }
  }
class _DashboardGrid extends StatelessWidget {
  const _DashboardGrid({required this.compact, required this.shop});
  final bool compact;
  final ShopProvider shop;

  @override
  Widget build(BuildContext context) {
    final cards = [
      MetricCard(
          label: 'Abadás vendidos',
          value: '${shop.totalSold}',
          detail: 'de ${shop.totalCapacity}',
          icon: Icons.confirmation_number_outlined,
          color: AppTheme.primaryLight),
      MetricCard(
          label: 'Disponibilidade',
          value: '${shop.totalCapacity - shop.totalSold}',
          detail: 'restantes',
          icon: Icons.inventory_2_outlined,
          color: Colors.greenAccent),
      MetricCard(
          label: 'Ticket médio',
          value: shop.totalSold == 0
              ? 'R\$ 0'
              : 'R\$ ${(shop.estimatedRevenue / shop.totalSold).toStringAsFixed(0)}',
          detail: 'por abadá',
          icon: Icons.sell_outlined,
          color: AppTheme.pink),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _PanelTitle(
          title: 'Indicadores-chave', icon: Icons.insights_outlined),
      const SizedBox(height: 10),
      Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map((card) =>
                  SizedBox(width: compact ? double.infinity : 250, child: card))
              .toList()),
    ]);
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 18, color: AppTheme.primaryLight),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800))
      ]);
}

class _QuickSalePanel extends StatefulWidget {
  const _QuickSalePanel({required this.shop});
  final ShopProvider shop;

  @override
  State<_QuickSalePanel> createState() => _QuickSalePanelState();
}

class _QuickSalePanelState extends State<_QuickSalePanel> {
  String? _lotId;

  @override
  Widget build(BuildContext context) {
    final lots = widget.shop.lots;
    _lotId ??= lots.first.id;
    final selected = lots.firstWhere((lot) => lot.id == _lotId);
    return Card(
        color: AppTheme.primary.withValues(alpha: 0.16),
        child: Padding(
            padding: const EdgeInsets.all(18),
            child: LayoutBuilder(builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              final controls = Row(children: [
                Expanded(
                    child: DropdownButtonFormField<String>(
                        initialValue: _lotId,
                        decoration: const InputDecoration(
                            labelText: 'Lote',
                            prefixIcon: Icon(Icons.sell_outlined)),
                        items: lots
                            .map((lot) => DropdownMenuItem(
                                value: lot.id, child: Text(lot.name)))
                            .toList(),
                        onChanged: (value) => setState(() => _lotId = value))),
                const SizedBox(width: 12),
                Text('${selected.remaining} livres',
                    style: const TextStyle(color: Colors.white60))
              ]);
              final actions = Wrap(spacing: 8, runSpacing: 8, children: [
                for (final amount in [1, 5, 10])
                  FilledButton(
                      onPressed: selected.remaining >= amount && selected.active
                          ? () => _register(amount)
                          : null,
                      child: Text('+$amount')),
                OutlinedButton.icon(
                    onPressed: () => _showEditDialog(context, selected),
                    icon: const Icon(Icons.tune),
                    label: const Text('Ajustar lote'))
              ]);
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _PanelTitle(
                        title: 'Registro rápido', icon: Icons.bolt),
                    const SizedBox(height: 12),
                    if (compact) ...[
                      controls,
                      const SizedBox(height: 12),
                      actions
                    ] else
                      Row(children: [
                        Expanded(child: controls),
                        const SizedBox(width: 18),
                        actions
                      ])
                  ]);
            })));
  }

  Future<void> _register(int amount) async {
    final success = await widget.shop.registerSale(_lotId!, quantity: amount);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
            ? '$amount venda(s) registrada(s).'
            : 'Não há disponibilidade suficiente.')));
  }

  Future<void> _showEditDialog(BuildContext context, TicketLot lot) async {
    await showDialog<void>(
        context: context,
        builder: (context) => _EditLotDialog(shop: widget.shop, lot: lot));
  }
}

class _EditLotDialog extends StatefulWidget {
  const _EditLotDialog({required this.shop, required this.lot});
  final ShopProvider shop;
  final TicketLot lot;

  @override
  State<_EditLotDialog> createState() => _EditLotDialogState();
}

class _EditLotDialogState extends State<_EditLotDialog> {
  late final total = TextEditingController(text: '${widget.lot.total}');
  late final price =
      TextEditingController(text: widget.lot.price.toStringAsFixed(2));
  late bool active = widget.lot.active;

  @override
  void dispose() {
    total.dispose();
    price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: Text('Editar ${widget.lot.name}'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: total,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Quantidade total')),
            TextField(
                controller: price,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Preço')),
            SwitchListTile(
                value: active,
                onChanged: (value) => setState(() => active = value),
                title: const Text('Lote ativo'))
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () async {
                  await widget.shop.updateLot(
                      lotId: widget.lot.id,
                      total: int.tryParse(total.text) ?? widget.lot.total,
                      price: double.tryParse(price.text.replaceAll(',', '.')) ??
                          widget.lot.price,
                      active: active);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('Salvar'))
          ]);
}

class _LotGrid extends StatelessWidget {
  const _LotGrid({required this.shop});
  final ShopProvider shop;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth > 900
            ? 3
            : constraints.maxWidth > 580
                ? 2
                : 1;
        final width = (constraints.maxWidth - (columns - 1) * 14) / columns;
        final items = shop.lots
            .map((lot) => SizedBox(width: width, child: _LotCard(lot: lot)))
            .toList();
        items.add(SizedBox(width: width, child: _AddLotCard(shop: shop)));
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 14, runSpacing: 14, children: items),
          const SizedBox(height: 18),
          _LotSummary(shop: shop)
        ]);
      });
}

class _LotCard extends StatelessWidget {
  const _LotCard({required this.lot});
  final TicketLot lot;

  @override
  Widget build(BuildContext context) => InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        await showDialog<void>(
            context: context,
            builder: (context) =>
                _EditLotDialog(shop: context.read<ShopProvider>(), lot: lot));
      },
      child: Card(
          child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text(lot.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 17))),
                      Icon(lot.active ? Icons.check_circle : Icons.pause_circle,
                          color: lot.active
                              ? Colors.greenAccent
                              : Colors.orangeAccent)
                    ]),
                    const SizedBox(height: 12),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${lot.sold} vendidos',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                Text('${lot.remaining} restantes',
                                    style:
                                        const TextStyle(color: AppTheme.accent))
                              ]),
                          Text('R\$ ${lot.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w800))
                        ]),
                    const SizedBox(height: 8),
                    ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                            value: lot.occupancy,
                            minHeight: 9,
                            backgroundColor: Colors.white12,
                            color: AppTheme.primaryLight)),
                    const SizedBox(height: 12),
                    Row(children: [
                      FilledButton(
                          onPressed: lot.remaining >= 1 && lot.active
                              ? () async {
                                  final success = await context
                                      .read<ShopProvider>()
                                      .registerSale(lot.id, quantity: 1);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(success
                                              ? 'Venda registrada.'
                                              : 'Sem disponibilidade.')));
                                }
                              : null,
                          child: const Text('+1')),
                      const SizedBox(width: 8),
                      OutlinedButton(
                          onPressed: lot.sold > 0
                              ? () async {
                                  await context
                                      .read<ShopProvider>()
                                      .revertSale(lot.id, quantity: 1);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Venda revertida.')));
                                }
                              : null,
                          child: const Text('-1')),
                      const SizedBox(width: 8),
                      IconButton(
                          tooltip: 'Ajustar lote',
                          onPressed: () async {
                            await showDialog<void>(
                                context: context,
                                builder: (context) => _EditLotDialog(
                                    shop: context.read<ShopProvider>(),
                                    lot: lot));
                          },
                          icon: const Icon(Icons.tune))
                    ])
                  ]))));
}

class _AddLotCard extends StatelessWidget {
  const _AddLotCard({required this.shop});
  final ShopProvider shop;

  @override
  Widget build(BuildContext context) => Card(
      color: AppTheme.primary.withValues(alpha: 0.06),
      child: Padding(
          padding: const EdgeInsets.all(18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.add, color: AppTheme.accent),
              SizedBox(width: 10),
              Text('Adicionar lote',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17))
            ]),
            const SizedBox(height: 12),
            const Text('Crie um novo lote para vender mais abadás',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            FilledButton.icon(
                onPressed: () async {
                  await showDialog<void>(
                      context: context,
                      builder: (context) => _CreateLotDialog(shop: shop));
                },
                icon: const Icon(Icons.add),
                label: const Text('Novo lote'))
          ])));
}

class _LotSummary extends StatelessWidget {
  const _LotSummary({required this.shop});
  final ShopProvider shop;

  @override
  Widget build(BuildContext context) {
    final lots = shop.lots;
    return Card(
        color: Colors.white.withValues(alpha: 0.03),
        child: Padding(
            padding: const EdgeInsets.all(12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Resumo por lote',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Lote')),
                    DataColumn(label: Text('Preço')),
                    DataColumn(label: Text('Vendidos')),
                    DataColumn(label: Text('Restantes')),
                    DataColumn(label: Text('Receita')),
                    DataColumn(label: Text('Ativo')),
                    DataColumn(label: Text(''))
                  ],
                  rows: lots.map((lot) {
                    return DataRow(cells: [
                      DataCell(Text(lot.name)),
                      DataCell(Text('R\$ ${lot.price.toStringAsFixed(2)}')),
                      DataCell(Text('${lot.sold}')),
                      DataCell(Text('${lot.remaining}')),
                      DataCell(Text(
                          'R\$ ${(lot.sold * lot.price).toStringAsFixed(2)}')),
                      DataCell(Icon(
                        lot.active ? Icons.check : Icons.close,
                        color: lot.active
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                      )),
                      DataCell(Row(children: [
                        IconButton(
                          tooltip: 'Editar',
                          onPressed: () async {
                            await showDialog<void>(
                              context: context,
                              builder: (context) => _EditLotDialog(
                                  shop: context.read<ShopProvider>(), lot: lot),
                            );
                          },
                          icon: const Icon(Icons.edit),
                        ),
                      ])),
                    ]);
                  }).toList(),
                ),
              )
            ])));
  }
}

class _CreateLotDialog extends StatefulWidget {
  const _CreateLotDialog({required this.shop});
  final ShopProvider shop;

  @override
  State<_CreateLotDialog> createState() => _CreateLotDialogState();
}

class _CreateLotDialogState extends State<_CreateLotDialog> {
  final name = TextEditingController();
  final total = TextEditingController(text: '100');
  final price = TextEditingController(text: '0.00');
  bool active = true;

  @override
  void dispose() {
    name.dispose();
    total.dispose();
    price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: const Text('Criar novo lote'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nome do lote')),
            TextField(
                controller: total,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Quantidade total')),
            TextField(
                controller: price,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Preço')),
            SwitchListTile(
                value: active,
                onChanged: (v) => setState(() => active = v),
                title: const Text('Lote ativo'))
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () async {
                  final parsedTotal = int.tryParse(total.text) ?? 0;
                  final parsedPrice =
                      double.tryParse(price.text.replaceAll(',', '.')) ?? 0.0;
                  if (name.text.trim().isEmpty || parsedTotal <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Nome e quantidade válidos são necessários.')));
                    return;
                  }
                  await widget.shop.addLot(
                      name: name.text.trim(),
                      total: parsedTotal,
                      price: parsedPrice,
                      active: active);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('Criar'))
          ]);
}