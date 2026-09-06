import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../state/auth_controller.dart';
import '../../state/demo_reset_controller.dart';
import '../../state/locale_controller.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/max_width_body.dart';

class StateAdminAccountScreen extends ConsumerWidget {
  const StateAdminAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    if (user == null) return const SizedBox.shrink();
    final locale = ref.watch(localeControllerProvider);

    return Scaffold(
      backgroundColor: AgrivaColors.background,
      appBar: const AgrivaAppBar(title: 'Account'),
      body: MaxWidthBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Centered Official Profile Card (Matching Farmer Profile Theme)
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
                    backgroundColor: Color(0xFFFFF3E0),
                    child: Icon(Icons.admin_panel_settings_rounded, size: 32, color: Color(0xFFE65100)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'State Food Secretary • Directorate of Civil Supplies',
                    style: TextStyle(fontSize: 13, color: AgrivaColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFB74D)),
                    ),
                    child: const Text(
                      'STATE HEAD',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFFE65100)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Information Tiles (Follows Farmer Profile InfoTile Theme)
            const _InfoTile(
              icon: Icons.map_outlined,
              label: 'State Jurisdiction',
              value: 'Tamil Nadu (5 Focus Districts)',
            ),
            const _InfoTile(
              icon: Icons.storefront_outlined,
              label: 'DPC Infrastructure',
              value: '13 Direct Purchase Centres',
            ),
            const _InfoTile(
              icon: Icons.account_balance_outlined,
              label: 'DBT Settlement',
              value: 'PFMS / Aadhaar Bridge (APB)',
            ),
            const _InfoTile(
              icon: Icons.verified_user_outlined,
              label: 'Access Authority',
              value: 'Statewide Policy & Quotas',
            ),
            const _InfoTile(
              icon: Icons.badge_outlined,
              label: 'Officer ID',
              value: 'ST-Admin',
            ),

            const SizedBox(height: 16),
            const Text('Language', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: supportedAgrivaLocales.map((l) {
                final selected = locale?.languageCode == l.languageCode;
                return ChoiceChip(
                  label: Text(localeDisplayNames[l.languageCode] ?? l.languageCode),
                  selected: selected,
                  onSelected: (_) =>
                      ref.read(localeControllerProvider.notifier).setLocale(l),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dark mode', style: TextStyle(fontSize: 13.5)),
              value: ref.watch(themeModeControllerProvider) == ThemeMode.dark,
              onChanged: (v) => ref
                  .read(themeModeControllerProvider.notifier)
                  .setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AgrivaColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Sign Out to Login Portal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              onPressed: () => showAgrivaSignOutDialog(context, ref),
            ),
            const SizedBox(height: 10),
            DestructiveButton(
              label: 'Reset Demo Data',
              onPressed: () async {
                final confirmed = await showConfirmDialog(
                  context,
                  title: 'Reset Demo?',
                  message: 'This restores all bookings, queues and disruptions to the original demo state.',
                  confirmLabel: 'Reset',
                  destructive: true,
                );
                if (confirmed) {
                  await ref.read(demoResetControllerProvider).resetDemo();
                  if (context.mounted) context.go('/login');
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
  const _InfoTile({required this.icon, required this.label, required this.value});

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
            Text(label, style: const TextStyle(fontSize: 13, color: AgrivaColors.textSecondary)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
