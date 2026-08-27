import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../widgets/user_appbar_actions.dart';

class SettingsHubPage extends StatelessWidget {
  const SettingsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = [
      _SettingsSection(
        icon: Icons.person_outline,
        title: 'Perfil',
        subtitle: 'Nome, foto e crachá Folião Raiz',
        route: '/settings/profile',
      ),
      _SettingsSection(
        icon: Icons.palette_outlined,
        title: 'Tema',
        subtitle: 'Escolha entre tema claro e escuro',
        route: '/settings/theme',
      ),
      _SettingsSection(
        icon: Icons.notifications_outlined,
        title: 'Notificações',
        subtitle: 'Veja avisos e interações recentes',
        route: '/notifications',
      ),
      _SettingsSection(
        icon: Icons.privacy_tip_outlined,
        title: 'Privacidade',
        subtitle: 'Termos, aceite e preferências de dados',
        route: '/settings/privacy/data',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Central de configurações'),
        actions: [UserAppBarActions()],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final section = sections[index];
          return Card(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              leading: CircleAvatar(
                child: Icon(section.icon),
              ),
              title: Text(section.title),
              subtitle: Text(section.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, section.route),
            ),
          );
        },
      ),
    );
  }
}

class _SettingsSection {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });
}

class SettingsThemePage extends StatelessWidget {
  const SettingsThemePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Tema')),
      body: SwitchListTile(
        title: const Text('Tema escuro'),
        subtitle: Text(theme.isDark ? 'Ativado' : 'Desativado'),
        value: theme.isDark,
        onChanged: theme.toggleTheme,
      ),
    );
  }
}

class SettingsPrivacyPage extends StatelessWidget {
  const SettingsPrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacidade')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const ListTile(
            leading: Icon(Icons.description_outlined),
            title: Text('Termos de Uso'),
            subtitle: Text('Revise os termos aceitos para usar o aplicativo.'),
          ),
          const ListTile(
            leading: Icon(Icons.security_outlined),
            title: Text('Dados e privacidade'),
            subtitle: Text('Gerencie como suas informações são utilizadas.'),
          ),
          FilledButton(
            onPressed: () => Navigator.pushNamed(context, '/terms'),
            child: const Text('Ver termos completos'),
          ),
        ],
      ),
    );
  }
}
