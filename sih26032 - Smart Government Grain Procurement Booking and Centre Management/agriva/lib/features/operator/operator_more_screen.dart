import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../models/enums.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/max_width_body.dart';

class OperatorMoreScreen extends ConsumerWidget {
  const OperatorMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final user = appState.currentUser!;

    return Scaffold(
      appBar: const AgrivaAppBar(title: 'More'),
      body: MaxWidthBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AgrivaColors.border),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: AgrivaColors.primaryLight,
                    child: Icon(Icons.person, color: AgrivaColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        user.role.label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AgrivaColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _MenuTile(
              icon: Icons.warning_amber_outlined,
              label: 'Declare Disruption',
              onTap: () => context.push('/operator/disruption'),
            ),
            _MenuTile(
              icon: Icons.payments_outlined,
              label: 'Payments',
              onTap: () => context.push('/operator/payments'),
            ),
            _MenuTile(
              icon: Icons.tune_outlined,
              label: 'Demo Controls',
              onTap: () => context.push('/operator/demo-controls'),
            ),
            const Divider(height: 32),
            _MenuTile(
              icon: Icons.logout,
              label: 'Sign Out',
              onTap: () {
                ref.read(appStateProvider.notifier).logout();
                context.go('/role-select');
              },
            ),
            _MenuTile(
              icon: Icons.restart_alt,
              label: 'Reset Demo',
              destructive: true,
              onTap: () async {
                final confirmed = await showConfirmDialog(
                  context,
                  title: 'Reset Demo?',
                  message:
                      'This restores all bookings, queues and disruptions to the original demo state.',
                  confirmLabel: 'Reset',
                  destructive: true,
                );
                if (confirmed) {
                  await ref.read(appStateProvider.notifier).resetDemo();
                  if (context.mounted) context.go('/role-select');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.red.shade700 : AgrivaColors.textPrimary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: destructive ? Colors.red.shade400 : AgrivaColors.textSecondary,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        size: 18,
        color: AgrivaColors.textMuted,
      ),
      onTap: onTap,
    );
  }
}
