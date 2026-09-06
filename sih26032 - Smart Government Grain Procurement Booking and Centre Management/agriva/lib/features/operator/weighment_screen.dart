import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../state/booking_controller.dart';
import '../../state/procurement_controller.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_states.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/max_width_body.dart';

const _reasons = [
  'Moisture out of range',
  'Foreign matter',
  'Damaged grain',
  'Discoloration',
  'Below quality standard',
];

class WeighmentScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const WeighmentScreen({super.key, required this.bookingId});

  @override
  ConsumerState<WeighmentScreen> createState() => _WeighmentScreenState();
}

class _WeighmentScreenState extends ConsumerState<WeighmentScreen> {
  final _weighedController = TextEditingController();
  final _acceptedController = TextEditingController();
  String? _reason;
  bool _submitting = false;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(bookingByIdProvider(widget.bookingId));

    return Scaffold(
      appBar: const AgrivaAppBar(title: 'Weighment'),
      body: MaxWidthBody(
        child: bookingAsync.when(
          loading: () => const LoadingState(),
          error: (e, st) => const ErrorState(),
          data: (booking) {
            if (booking == null) return const ErrorState(message: 'Booking not found.');
            final farmerAsync = ref.watch(farmerByIdProvider(booking.farmerId));
            final farmer = farmerAsync.value;

            if (!_initialized) {
              _weighedController.text = booking.expectedQuantityQ.toStringAsFixed(1);
              _acceptedController.text = booking.expectedQuantityQ.toStringAsFixed(1);
              _initialized = true;
            }

            final weighed = double.tryParse(_weighedController.text);
            final accepted = double.tryParse(_acceptedController.text);
            final rejected = (weighed != null && accepted != null) ? (weighed - accepted).clamp(0, double.infinity) : 0.0;
            final hasRejection = rejected > 0.01;

            return Padding(
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
                        Text('${booking.token} · ${farmer?.name ?? '—'}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(
                          'Expected: ${booking.expectedQuantityQ.toStringAsFixed(1)} Q',
                          style: const TextStyle(color: AgrivaColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppTextField(
                    label: 'Weighed Quantity (Q)',
                    controller: _weighedController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Accepted Quantity (Q)',
                    controller: _acceptedController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),
                  if (hasRejection) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AgrivaColors.warningBg, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        '${rejected.toStringAsFixed(1)} Q will be recorded as rejected.',
                        style: const TextStyle(fontSize: 12.5, color: AgrivaColors.warning),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('Rejection reason (required)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _reasons
                          .map((r) => ChoiceChip(
                                label: Text(r),
                                selected: _reason == r,
                                onSelected: (_) => setState(() => _reason = r),
                              ))
                          .toList(),
                    ),
                  ],
                  const Spacer(),
                  PrimaryButton(
                    label: 'Confirm Weighment',
                    loading: _submitting,
                    onPressed: (weighed == null || weighed <= 0 || accepted == null || accepted < 0 || (hasRejection && _reason == null))
                        ? null
                        : () async {
                            setState(() => _submitting = true);
                            final result = await ref.read(procurementControllerProvider).submitWeighment(
                                  bookingId: widget.bookingId,
                                  weighedQuantityQ: weighed,
                                  acceptedQuantityQ: accepted,
                                  rejectedQuantityQ: rejected.toDouble(),
                                  rejectionReason: hasRejection ? _reason : null,
                                  inspector: 'Suresh Babu',
                                );
                            setState(() => _submitting = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
                              if (result.success) context.pop();
                            }
                          },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
