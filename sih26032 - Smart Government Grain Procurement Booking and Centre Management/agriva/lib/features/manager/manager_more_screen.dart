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

class ManagerMoreScreen extends ConsumerWidget {
  const ManagerMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    if (user == null) return const SizedBox.shrink();
    final locale = ref.watch(localeControllerProvider);

    final districtName = (user.district ?? 'district-erode')
        .replaceAll('district-', '')
        .replaceAll('dt-', '');
    final formattedDistrict = districtName.isEmpty
        ? 'Erode District'
        : '${districtName[0].toUpperCase()}${districtName.substring(1)} District';

    return Scaffold(
      backgroundColor: AgrivaColors.backgroundFor(context),
      appBar: const AgrivaAppBar(title: 'Account'),
      body: MaxWidthBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Centered Official Profile Card (Matching Farmer Profile Theme)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AgrivaColors.surfaceFor(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AgrivaColors.borderFor(context)),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: AgrivaColors.primaryLight,
                    child: Icon(Icons.shield_rounded, size: 32, color: AgrivaColors.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'District Collector & Magistrate • $formattedDistrict',
                    style: TextStyle(fontSize: 13, color: AgrivaColors.textSecondaryFor(context)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AgrivaColors.primaryLight50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AgrivaColors.primaryMedium),
                    ),
                    child: const Text(
                      'DISTRICT ADMIN',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AgrivaColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Information Tiles (Follows Farmer Profile InfoTile Theme)
            _InfoTile(
              icon: Icons.location_city_outlined,
              label: 'District Jurisdiction',
              value: formattedDistrict,
            ),
            const _InfoTile(
              icon: Icons.storefront_outlined,
              label: 'DPC Infrastructure',
              value: 'Active Direct Purchase Centres',
            ),
            const _InfoTile(
              icon: Icons.agriculture_outlined,
              label: 'Supported MSP Crops',
              value: 'Paddy, Maize, Ragi, Cotton',
            ),
            const _InfoTile(
              icon: Icons.account_balance_outlined,
              label: 'State Authority',
              value: 'TN Civil Supplies Corp (TNCSC)',
            ),
            _InfoTile(
              icon: Icons.badge_outlined,
              label: 'Officer ID',
              value: 'DT-${districtName.isEmpty ? 'Erode' : "${districtName[0].toUpperCase()}${districtName.substring(1)}"}',
            ),

            const SizedBox(height: 14),

            // District Shortcuts
            Container(
              decoration: BoxDecoration(
                color: AgrivaColors.surfaceFor(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AgrivaColors.borderFor(context)),
              ),
              child: ListTile(
                leading: const Icon(Icons.verified_user_outlined, color: AgrivaColors.primary),
                title: const Text('Farmer Document Verifications', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                subtitle: Text('Review Aadhaar & land records for approval', style: TextStyle(fontSize: 11, color: AgrivaColors.textMutedFor(context))),
                trailing: Icon(Icons.chevron_right, size: 18, color: AgrivaColors.textMutedFor(context)),
                onTap: () => context.push('/district-admin/verifications'),
              ),
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
                  title: 'Reset Demo Data?',
                  message: 'This restores all bookings, queues and disruptions to default demo state.',
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
          color: AgrivaColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AgrivaColors.borderFor(context)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AgrivaColors.textSecondaryFor(context)),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontSize: 13, color: AgrivaColors.textSecondaryFor(context))),
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
