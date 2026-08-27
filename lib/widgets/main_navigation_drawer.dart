import 'package:flutter/material.dart';

class MainNavigationDrawer extends StatelessWidget {
  const MainNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF102A72)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Icon(Icons.celebration, color: Colors.white, size: 38),
                  SizedBox(height: 8),
                  Text(
                    'Navegação La Bomba',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            _NavigationItem(
              icon: Icons.photo_library_outlined,
              label: 'Memórias',
              route: '/memories',
            ),
            _NavigationItem(
              icon: Icons.chat_bubble_outline,
              label: 'Chat híbrido',
              route: '/chat',
            ),
            _NavigationItem(
              icon: Icons.groups_outlined,
              label: 'Diretório de foliões',
              route: '/foliaos',
            ),
            _NavigationItem(
              icon: Icons.settings_outlined,
              label: 'Configurações',
              route: '/settings',
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;

  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }
}
