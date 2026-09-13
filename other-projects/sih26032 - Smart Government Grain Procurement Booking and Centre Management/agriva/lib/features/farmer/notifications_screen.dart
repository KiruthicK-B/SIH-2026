import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/auth_controller.dart';
import '../../state/notification_controller.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/app_states.dart';
import '../../widgets/notification_tile.dart';
import '../../widgets/max_width_body.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    if (user == null) return const SizedBox.shrink();
    final itemsAsync = ref.watch(notificationsForUserProvider(user.id));

    return Scaffold(
      appBar: AgrivaAppBar(
        title: 'Notifications',
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(notificationControllerProvider).markAllRead(user.id),
            child: const Text('Mark all as read', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: MaxWidthBody(
        child: itemsAsync.when(
          loading: () => const LoadingState(),
          error: (e, st) => const ErrorState(),
          data: (rawItems) {
            final items = [...rawItems]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
            if (items.isEmpty) {
              return const EmptyState(
                icon: Icons.notifications_none_outlined,
                title: 'No notifications yet',
                message: 'Updates about your bookings will appear here.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              itemBuilder: (context, i) => NotificationTile(
                item: items[i],
                onTap: () => ref.read(notificationControllerProvider).markRead(items[i].id),
                onRetry: () => ref.read(notificationControllerProvider).retryDelivery(items[i].id),
              ),
            );
          },
        ),
      ),
    );
  }
}
