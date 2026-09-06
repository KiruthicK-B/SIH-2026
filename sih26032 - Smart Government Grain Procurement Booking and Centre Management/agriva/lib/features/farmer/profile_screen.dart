import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../models/farmer.dart';
import '../../state/auth_controller.dart';
import '../../state/booking_controller.dart';
import '../../state/demo_reset_controller.dart';
import '../../state/locale_controller.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_states.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/max_width_body.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    if (user == null) return const SizedBox.shrink();
    final farmerAsync = ref.watch(farmerByIdProvider(user.id));
    final locale = ref.watch(localeControllerProvider);

    return Scaffold(
      appBar: const AgrivaAppBar(title: 'Profile'),
      body: MaxWidthBody(
        child: farmerAsync.when(
          loading: () => const LoadingState(),
          error: (e, st) => const ErrorState(),
          data: (farmer) {
            if (farmer == null) return const ErrorState();
            return ListView(
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
                        child: Icon(Icons.person, size: 32, color: AgrivaColors.primary),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        farmer.name,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        farmer.farmerCode,
                        style: const TextStyle(fontSize: 13, color: AgrivaColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _InfoTile(icon: Icons.location_on_outlined, label: 'Village', value: farmer.village),
                _InfoTile(icon: Icons.call_outlined, label: 'Phone', value: farmer.phone),
                _InfoTile(
                  icon: Icons.badge_outlined,
                  label: 'Aadhaar',
                  value: Farmer.maskAadhaar(farmer.aadhaarNumber),
                ),
                _InfoTile(
                  icon: Icons.account_balance_outlined,
                  label: 'Bank Account',
                  value: Farmer.maskAccount(farmer.bankAccountNumber),
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
                      await ref.read(demoResetControllerProvider).resetDemo();
                      if (context.mounted) context.go('/login');
                    }
                  },
                ),
              ],
            );
          },
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
