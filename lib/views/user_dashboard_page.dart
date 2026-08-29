import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('La Bomba - Dashboard'),
        centerTitle: true,
        actions: [
          // Dynamic admin shortcut in the app bar for regular admins (not the master)
          ValueListenableBuilder<AuthStatus>(
            valueListenable: authService.authStatus,
            builder: (context, status, _) {
              final isMaster = authService.isMasterUser;
              final isAdminCommon = status == AuthStatus.admin && !isMaster;
              if (!isAdminCommon) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/admin/clients'),
                icon: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white),
                label: const Text('Admin', style: TextStyle(color: Colors.white)),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Hero banner / title
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E1B4B), Color(0xFF3B2C8A)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Bem-vindo ao Hub',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  SizedBox(height: 6),
                  Text('Aqui você encontra avisos, feed e atalhos rápidos',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Left column: mural de avisos
                    Flexible(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          const Text('Mural de Avisos', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Card(
                              color: const Color(0xFF111827),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: ListView.separated(
                                  itemCount: 6,
                                  separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text('Aviso ${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                      subtitle: Text('Detalhes do aviso número ${index + 1}', style: const TextStyle(color: Colors.white70)),
                                      leading: CircleAvatar(backgroundColor: AppTheme.primary, child: const Icon(Icons.campaign, color: Colors.white)),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Right column: feed de interações
                    Flexible(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          const Text('Feed', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Card(
                              color: const Color(0xFF0B1220),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: ListView.builder(
                                  itemCount: 12,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF081018),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(radius: 22, backgroundColor: Colors.indigoAccent, child: Text('${index + 1}')),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Usuário ${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                                                const SizedBox(height: 6),
                                                Text('Comentário de exemplo no feed número ${index + 1}.', style: const TextStyle(color: Colors.white70)),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: const [
                                                    Icon(Icons.favorite_border, color: Colors.white54, size: 18),
                                                    SizedBox(width: 8),
                                                    Icon(Icons.chat_bubble_outline, color: Colors.white54, size: 18),
                                                    SizedBox(width: 8),
                                                    Icon(Icons.share, color: Colors.white54, size: 18),
                                                  ],
                                                )
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        backgroundColor: const Color(0xFF071029),
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Avisos'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
      floatingActionButton: ValueListenableBuilder<AuthStatus>(
        valueListenable: authService.authStatus,
        builder: (context, status, _) {
          // Only the explicit master user gets the God Mode FAB (dev-safe and requires MASTER_EMAIL match)
          final isMaster = authService.isMasterUser;
          if (!isMaster) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            backgroundColor: AppTheme.primary,
            icon: const Icon(Icons.admin_panel_settings_rounded),
            label: const Text('God Mode'),
            onPressed: () => Navigator.pushNamed(context, '/admin/dashboard'),
          );
        },
      ),
    );
  }
}
