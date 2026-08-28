import 'package:flutter/material.dart';

import '../features/notifications/services/notification_service.dart';
import '../widgets/labomba_explosion_overlay.dart';
import '../widgets/user_appbar_actions.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = NotificationService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [UserAppBarActions()],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: service.streamForCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Não foi possível carregar notificações.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifications = snapshot.data!;
          if (notifications.isEmpty) {
            return const Center(child: Text('Você não tem notificações novas.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Card(
                child: ListTile(
                  leading: Icon(
                    notification.read
                        ? Icons.notifications_none
                        : Icons.notifications_active,
                    color: notification.read
                        ? Colors.grey
                        : Theme.of(context).colorScheme.secondary,
                  ),
                  title: Text(notification.title),
                  subtitle: Text(notification.body),
                  onTap: () async {
                    if (!notification.read) {
                      await service.markAsRead(notification.id);
                    }
                    if (context.mounted) {
                      await LaBombaExplosionOverlay.show(context,
                          message: notification.title);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
