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

class OperatorMoreScreen extends ConsumerWidget {
  const OperatorMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    if (user == null) return const SizedBox.shrink();
    final locale = ref.watch(localeControllerProvider);

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
                    backgroundColor: Color(0xFFE3F2FD),
                    child: Icon(Icons.badge_rounded, size: 32, color: Color(0xFF1565C0)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Centre In-Charge • ${user.centreId ?? "OP-Erode-01"}',
                    style: TextStyle(fontSize: 13, color: AgrivaColors.textSecondaryFor(context)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF90CAF9)),
                    ),
                    child: const Text(
                      'CENTRE OPERATOR',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF1565C0)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Information Tiles (Follows Farmer Profile InfoTile Theme)
            _InfoTile(
              icon: Icons.storefront_outlined,
              label: 'Procurement Centre',
              value: user.centreId ?? 'OP-Erode-01 Hub',
            ),
            _InfoTile(
              icon: Icons.location_on_outlined,
              label: 'District',
              value: user.district != null
                  ? '${user.district!.replaceAll("district-", "").toUpperCase()} District'
                  : 'Erode District',
            ),
            const _InfoTile(
              icon: Icons.check_circle_outline,
              label: 'Centre Status',
              value: 'Active • Operating',
            ),
            const _InfoTile(
              icon: Icons.linear_scale_outlined,
              label: 'Weighment Lanes',
              value: '3 Active Electronic Lanes',
            ),
            _InfoTile(
              icon: Icons.badge_outlined,
              label: 'Operator ID',
              value: user.centreId != null
                  ? 'OP-${user.centreId!.replaceAll("centre-", "")}'
                  : 'OP-Erode-01',
            ),

            const SizedBox(height: 14),

            // Operations & Shortcuts Card
            const Text(
              'Centre Operations & Tools',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AgrivaColors.surfaceFor(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AgrivaColors.borderFor(context)),
              ),
              child: Column(
                children: [
                  _MenuTile(
                    icon: Icons.verified_user_outlined,
                    label: 'Farmer Document Verifications',
                    onTap: () => context.push('/operator/verifications'),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _MenuTile(
                    icon: Icons.warning_amber_outlined,
                    label: 'Declare Disruption / Lane Hold',
                    onTap: () => context.push('/operator/disruption'),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _MenuTile(
                    icon: Icons.support_agent_outlined,
                    label: 'Farmer Grievance Desk',
                    onTap: () => context.push('/operator/grievances'),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _MenuTile(
                    icon: Icons.payments_outlined,
                    label: 'Payment Disbursement Records',
                    onTap: () => context.push('/operator/payments'),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _MenuTile(
                    icon: Icons.tune_outlined,
                    label: 'Demo Queue Controls',
                    onTap: () => context.push('/operator/demo-controls'),
                  ),
                ],
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
                  title: 'Reset Demo?',
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

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Icon(icon, color: AgrivaColors.textSecondaryFor(context)),
      title: Text(label, style: TextStyle(color: AgrivaColors.textPrimaryFor(context), fontWeight: FontWeight.w600, fontSize: 13.5)),
      trailing: Icon(Icons.chevron_right, size: 18, color: AgrivaColors.textMutedFor(context)),
      onTap: onTap,
    );
  }
}
