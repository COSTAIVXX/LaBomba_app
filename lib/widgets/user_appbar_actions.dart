import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/google_auth_provider.dart';
import '../services/auth_service.dart';

class UserAppBarActions extends StatelessWidget {
  const UserAppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    final google = context.watch<GoogleAuthProvider?>();
    final auth = Provider.of<AuthService?>(context, listen: false);
    final userData = google?.currentUserData;

    if (userData == null) {
      // show generic icon and a settings shortcut
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Entrar / Perfil',
            onPressed: () {
              // open settings or login
              if (auth?.currentUser != null) {
                Navigator.pushNamed(context, '/settings');
              } else {
                Navigator.pushNamed(context, '/admin/login');
              }
            },
          ),
        ],
      );
    }

    final display = userData.displayName ?? 'Usuário';
    final photo = userData.photoUrl;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              if (photo != null && photo.isNotEmpty)
                CircleAvatar(radius: 16, backgroundImage: NetworkImage(photo))
              else
                CircleAvatar(radius: 16, child: Text(display.isNotEmpty ? display[0].toUpperCase() : 'U')),
              const SizedBox(width: 8),
              Text(display, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'settings') {
              Navigator.pushNamed(context, '/settings');
            } else if (v == 'profile') {
              Navigator.pushNamed(context, '/profile');
            } else if (v == 'notifications') {
              Navigator.pushNamed(context, '/notifications');
            } else if (v == 'moderation') {
              Navigator.pushNamed(context, '/admin/moderation');
            } else if (v == 'badge') {
              Navigator.pushNamed(context, '/badge');
            } else if (v == 'foliaos') {
              Navigator.pushNamed(context, '/foliaos');
            } else if (v == 'signout') {
              try {
                if (google != null) {
                  await google.signOut();
                } else if (auth != null) {
                  await auth.signOut();
                }
                // After sign out, navigate to landing
                Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
              } catch (_) {}
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'settings', child: Text('Configurações')),
            const PopupMenuItem(value: 'profile', child: Text('Meu perfil')),
            const PopupMenuItem(value: 'notifications', child: Text('Notificações')),
            const PopupMenuItem(value: 'moderation', child: Text('Moderação')),
            const PopupMenuItem(value: 'badge', child: Text('Meu crachá Folião Raiz')),
            const PopupMenuItem(value: 'foliaos', child: Text('Diretório de foliões')),
            const PopupMenuItem(value: 'signout', child: Text('Sair')),
          ],
        ),
      ],
    );
  }
}
