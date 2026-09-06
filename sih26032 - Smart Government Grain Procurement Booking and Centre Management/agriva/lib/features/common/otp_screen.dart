import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../repositories/repository_providers.dart';
import '../../state/auth_controller.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/max_width_body.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  String? _error;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final l10n = AppLocalizations.of(context);
    final result = ref
        .read(farmerOtpControllerProvider.notifier)
        .verifyOtp(_otpController.text.trim());
    switch (result) {
      case OtpVerifyResult.success:
        setState(() => _error = null);
        final otpState = ref.read(farmerOtpControllerProvider);
        if (otpState.isNewFarmer) {
          if (mounted) context.go('/register?phone=${Uri.encodeComponent(otpState.phone)}');
          return;
        }
        final farmer = await ref
            .read(farmerRepositoryProvider)
            .findByPhone(otpState.phone);
        if (farmer != null) {
          await ref.read(authControllerProvider.notifier).loginAsFarmer(farmer);
        }
      case OtpVerifyResult.wrong:
        setState(() => _error = l10n.otpIncorrect);
      case OtpVerifyResult.expired:
        setState(() => _error = l10n.otpExpired);
      case OtpVerifyResult.locked:
        setState(() => _error = l10n.otpTooManyAttempts(2));
    }
  }

  Future<void> _resend() async {
    final phone = ref.read(farmerOtpControllerProvider).phone;
    await ref.read(farmerOtpControllerProvider.notifier).sendOtp(phone);
    setState(() => _error = null);
    _otpController.clear();
  }

  void _autoFillOtp(String? code) {
    if (code != null) {
      setState(() {
        _otpController.text = code;
        _error = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final otpState = ref.watch(farmerOtpControllerProvider);
    final cooldown = otpState.resendCooldownSecondsRemaining;

    return Scaffold(
      backgroundColor: AgrivaColors.background,
      appBar: AppBar(
        title: const Text('Verify Mobile OTP'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: MaxWidthBody(
          maxWidth: 480,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),

                // Lock & SMS verification icon
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AgrivaColors.primaryLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: AgrivaColors.primaryMedium.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.mark_email_read_outlined, size: 30, color: AgrivaColors.primary),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  l10n.enterOtp,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AgrivaColors.textPrimary),
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Sent to ', style: TextStyle(color: AgrivaColors.textSecondary, fontSize: 13.5)),
                    Text(
                      '+91 ${otpState.phone}',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AgrivaColors.primary, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Sandbox OTP banner — Phase 1 has no live SMS gateway, so
                // the generated code is shown here with a 1-tap auto-fill.
                if (otpState.sentOtp != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AgrivaColors.primaryLight50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AgrivaColors.primaryMedium.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 18, color: AgrivaColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your Verification Code',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AgrivaColors.primaryDark),
                              ),
                              Text(
                                'Generated code: ${otpState.sentOtp}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AgrivaColors.primary),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => _autoFillOtp(otpState.sentOtp),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AgrivaColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Auto-Fill',
                              style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // OTP Input Field
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AgrivaColors.border, width: 1.5),
                  ),
                  child: TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 28,
                      letterSpacing: 14,
                      fontWeight: FontWeight.w800,
                      color: AgrivaColors.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      counterText: '',
                      hintText: '••••••',
                      hintStyle: TextStyle(color: AgrivaColors.inactive, letterSpacing: 14),
                    ),
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AgrivaColors.error, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],

                const SizedBox(height: 16),

                // Resend timer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (cooldown > 0)
                      Text(
                        l10n.resendOtpIn(cooldown),
                        style: const TextStyle(fontSize: 13, color: AgrivaColors.textMuted, fontWeight: FontWeight.w500),
                      )
                    else
                      TextButton.icon(
                        onPressed: _resend,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text(l10n.resendOtp),
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                PrimaryButton(
                  label: l10n.verifyAndContinue,
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: _verify,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
