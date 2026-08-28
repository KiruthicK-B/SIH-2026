import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../models/enums.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/max_width_body.dart';

class RoleSelectScreen extends ConsumerWidget {
  const RoleSelectScreen({super.key});

  void _showMoreRoles(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Continue as (Demo)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AgrivaColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              SecondaryButton(
                label: 'Centre Manager',
                icon: Icons.insights_outlined,
                onPressed: () => ref
                    .read(appStateProvider.notifier)
                    .loginAs(UserRole.manager),
              ),
              const SizedBox(height: 10),
              SecondaryButton(
                label: 'Admin / Demo Controls',
                icon: Icons.tune_outlined,
                onPressed: () =>
                    ref.read(appStateProvider.notifier).loginAs(UserRole.admin),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AgrivaColors.background,
      body: MaxWidthBody(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'AGRIVA',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AgrivaColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Smart Procurement Booking\n& Centre Management',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AgrivaColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/images/login_banner.png',
                    fit: BoxFit.cover,
                    height: 180,
                  ),
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'I am a Farmer',
                  onPressed: () => ref
                      .read(appStateProvider.notifier)
                      .loginAs(UserRole.farmer),
                ),
                const SizedBox(height: 10),
                SecondaryButton(
                  label: 'Centre / Operator Login',
                  onPressed: () => ref
                      .read(appStateProvider.notifier)
                      .loginAs(UserRole.operator),
                ),
                const SizedBox(height: 18),
                Center(
                  child: TextButton(
                    onPressed: () => _showMoreRoles(context, ref),
                    child: const Text('Continue as Guest (Demo)'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
