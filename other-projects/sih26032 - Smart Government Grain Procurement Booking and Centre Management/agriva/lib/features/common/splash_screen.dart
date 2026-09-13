import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../models/enums.dart';
import '../../state/auth_controller.dart';
import '../../widgets/max_width_body.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      final user = ref.read(authControllerProvider);
      if (user != null) {
        final target = switch (user.role) {
          UserRole.farmer => '/farmer',
          UserRole.centreOperator => '/operator',
          UserRole.districtAdmin => '/district-admin',
          UserRole.stateAdmin => '/state-admin',
        };
        context.go(target);
      } else {
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AgrivaColors.backgroundFor(context),
      body: SafeArea(
        child: MaxWidthBody(
          maxWidth: 480,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Official Government Header Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AgrivaColors.primaryLight50,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AgrivaColors.borderFor(context)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('🇮🇳', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 8),
                      Text(
                        'GOVERNMENT OF INDIA • DoCA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AgrivaColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Brand Mark (Official Emblem Logo)
                Image.asset(
                  'assets/images/app_icon.png',
                  height: 120,
                  fit: BoxFit.contain,
                ),

                const Spacer(flex: 2),

                // Animated Loader & Secure digital infra note
                Column(
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AgrivaColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 14, color: AgrivaColors.textMutedFor(context)),
                        const SizedBox(width: 6),
                        Text(
                          'Secured by NIC Digital Infrastructure',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11.5, color: AgrivaColors.textMutedFor(context)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Govt. of Tamil Nadu • TNSCSC Smart APMC',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AgrivaColors.textMutedFor(context), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
