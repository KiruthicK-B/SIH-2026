import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_state_provider.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/app_states.dart';
import '../../widgets/notification_tile.dart';
import '../../widgets/max_width_body.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final userId = appState.currentUser!.id;
    final items =
        appState.notifications
            .where((n) => n.userId == userId || n.userId == 'all')
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      appBar: AgrivaAppBar(
        title: 'Notifications',
        actions: [
          TextButton(
            onPressed: items.isEmpty
                ? null
                : () => notifier.markAllNotificationsRead(userId),
            child: const Text(
              'Mark all as read',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: MaxWidthBody(
        child: items.isEmpty
            ? const EmptyState(
                icon: Icons.notifications_none_outlined,
                title: 'No notifications yet',
                message: 'Updates about your bookings will appear here.',
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                itemBuilder: (context, i) => NotificationTile(
                  item: items[i],
                  onTap: () => notifier.markNotificationRead(items[i].id),
                ),
              ),
      ),
    );
  }
}
