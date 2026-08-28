import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/max_width_body.dart';

class WeighmentScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const WeighmentScreen({super.key, required this.bookingId});

  @override
  ConsumerState<WeighmentScreen> createState() => _WeighmentScreenState();
}

class _WeighmentScreenState extends ConsumerState<WeighmentScreen> {
  late final TextEditingController _actualController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final booking = ref
        .read(appStateProvider)
        .bookings
        .firstWhere((b) => b.id == widget.bookingId);
    _actualController = TextEditingController(
      text: booking.expectedQuantityQ.toStringAsFixed(1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final booking = appState.bookings.firstWhere(
      (b) => b.id == widget.bookingId,
    );
    final farmer = appState.farmers.firstWhere((f) => f.id == booking.farmerId);
    final actual = double.tryParse(_actualController.text);
    final diff = actual == null ? null : actual - booking.expectedQuantityQ;
    final exceeds = diff != null && diff > 0.01;

    return Scaffold(
      appBar: const AgrivaAppBar(title: 'Weighment'),
      body: MaxWidthBody(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AgrivaColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${booking.token} · ${farmer.name}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Expected: ${booking.expectedQuantityQ.toStringAsFixed(1)} Q',
                      style: const TextStyle(color: AgrivaColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              AppTextField(
                label: 'Actual Quantity (Q)',
                controller: _actualController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (diff != null && diff.abs() > 0.01) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: exceeds
                        ? AgrivaColors.warningBg
                        : AgrivaColors.infoBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    exceeds
                        ? 'Difference: +${diff.toStringAsFixed(1)} Q. Quantity exceeds declared amount — authorized review required.'
                        : 'Difference: ${diff.toStringAsFixed(1)} Q. Quantity variance detected.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: exceeds ? AgrivaColors.warning : AgrivaColors.info,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              PrimaryButton(
                label: 'Confirm Weighment',
                loading: _submitting,
                onPressed: actual == null || actual <= 0
                    ? null
                    : () async {
                        setState(() => _submitting = true);
                        final result = ref
                            .read(appStateProvider.notifier)
                            .submitWeighment(
                              bookingId: widget.bookingId,
                              actualQuantityQ: actual,
                            );
                        setState(() => _submitting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result.message)),
                          );
                          if (!exceeds) context.pop();
                        }
                      },
              ),
              if (exceeds) ...[
                const SizedBox(height: 10),
                SecondaryButton(
                  label: 'Approve Excess & Complete',
                  onPressed: () {
                    final result = ref
                        .read(appStateProvider.notifier)
                        .confirmExcessWeighment(widget.bookingId);
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(result.message)));
                    if (result.success) context.pop();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
