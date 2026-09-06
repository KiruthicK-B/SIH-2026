import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../widgets/app_states.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/max_width_body.dart';
import '../../state/state_admin_controller.dart';

class StateAdminBroadcastsScreen extends ConsumerWidget {
  const StateAdminBroadcastsScreen({super.key});

  Future<void> _compose(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('New Broadcast'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(label: 'Title', controller: titleController),
            const SizedBox(height: 10),
            AppTextField(label: 'Message', controller: messageController),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (result == true && context.mounted) {
      await ref
          .read(stateAdminControllerProvider)
          .createBroadcast(
            title: titleController.text.trim(),
            message: messageController.text.trim(),
            createdBy: 'admin-state',
          );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Broadcast sent.')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final broadcasts = ref.watch(broadcastsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Broadcasts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _compose(context, ref),
          ),
        ],
      ),
      body: MaxWidthBody(
        child: broadcasts.when(
          loading: () => const LoadingState(),
          error: (e, st) => const ErrorState(),
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(
                title: 'No broadcasts yet',
                message: 'Announcements you send appear here.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final b = list[i];
                return Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.campaign_outlined,
                      color: AgrivaColors.gold,
                    ),
                    title: Text(b.title),
                    subtitle: Text(b.message),
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
