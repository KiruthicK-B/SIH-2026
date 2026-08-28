import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../providers/app_state_provider.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(appReadyProvider);

    ref.listen(appReadyProvider, (prev, next) {
      if (next.hasValue) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.go('/role-select');
        });
      }
    });

    return Scaffold(
      backgroundColor: AgrivaColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'AGRIVA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Smart Government Grain Procurement',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 32),
            ready.when(
              data: (_) => const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
              loading: () => const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
              error: (e, st) => Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(height: 8),
                  const Text(
                    'Unable to restore saved demo state.',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
