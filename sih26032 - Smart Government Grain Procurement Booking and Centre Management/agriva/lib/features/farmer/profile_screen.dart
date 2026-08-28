import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/max_width_body.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final farmer = appState.farmers.firstWhere(
      (f) => f.id == appState.currentUser!.id,
    );

    return Scaffold(
      appBar: const AgrivaAppBar(title: 'Profile'),
      body: MaxWidthBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AgrivaColors.border),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: AgrivaColors.primaryLight,
                    child: Icon(
                      Icons.person,
                      size: 32,
                      color: AgrivaColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    farmer.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    farmer.farmerCode,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AgrivaColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _InfoTile(
              icon: Icons.location_on_outlined,
              label: 'Village',
              value: farmer.village,
            ),
            _InfoTile(
              icon: Icons.social_distance_outlined,
              label: 'Distance to Centre',
              value: '${farmer.distanceKm.toStringAsFixed(0)} km',
            ),
            _InfoTile(
              icon: Icons.access_time_outlined,
              label: 'Estimated Travel Time',
              value: '${farmer.estimatedTravelMinutes} min',
            ),
            _InfoTile(
              icon: Icons.call_outlined,
              label: 'Phone',
              value: farmer.phone,
            ),
            const SizedBox(height: 24),
            SecondaryButton(
              label: 'Sign Out',
              icon: Icons.logout,
              onPressed: () {
                ref.read(appStateProvider.notifier).logout();
                context.go('/role-select');
              },
            ),
            const SizedBox(height: 10),
            DestructiveButton(
              label: 'Reset Demo',
              onPressed: () async {
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

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AgrivaColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AgrivaColors.textSecondary),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AgrivaColors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
