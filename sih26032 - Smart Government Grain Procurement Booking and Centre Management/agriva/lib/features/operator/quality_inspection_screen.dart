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

class QualityInspectionScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const QualityInspectionScreen({super.key, required this.bookingId});

  @override
  ConsumerState<QualityInspectionScreen> createState() =>
      _QualityInspectionScreenState();
}

class _QualityInspectionScreenState
    extends ConsumerState<QualityInspectionScreen> {
  final _moistureController = TextEditingController(text: '17.5');
  bool _passed = true;
  String? _reason;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(bookingByIdProvider(widget.bookingId));

    return Scaffold(
      appBar: const AgrivaAppBar(title: 'Quality Inspection'),
      body: MaxWidthBody(
        child: bookingAsync.when(
          loading: () => const LoadingState(),
          error: (e, st) => const ErrorState(),
          data: (booking) {
            if (booking == null) {
              return const ErrorState(message: 'Booking not found.');
            }
            final farmerAsync = ref.watch(farmerByIdProvider(booking.farmerId));
            final farmer = farmerAsync.value;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Row('Booking', booking.id),
                _Row('Token', booking.token),
                _Row('Farmer', farmer?.name ?? '—'),
                _Row(
                  'Expected Quantity',
                  '${booking.expectedQuantityQ.toStringAsFixed(0)} Q',
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Moisture (%)',
                  controller: _moistureController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Result',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                RadioGroup<bool>(
                  groupValue: _passed,
                  onChanged: (v) => setState(() => _passed = v!),
                  child: Column(
                    children: [
                      RadioListTile<bool>(
                        value: true,
                        title: const Text('Passed'),
                        contentPadding: EdgeInsets.zero,
                        activeColor: AgrivaColors.primary,
                      ),
                      RadioListTile<bool>(
                        value: false,
                        title: const Text('Not Accepted'),
                        contentPadding: EdgeInsets.zero,
                        activeColor: AgrivaColors.primary,
                      ),
                    ],
                  ),
                ),
                if (!_passed) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Reason (required)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _reasons
                        .map(
                          (r) => ChoiceChip(
                            label: Text(r),
                            selected: _reason == r,
                            onSelected: (_) => setState(() => _reason = r),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Submit',
                  loading: _submitting,
                  onPressed: (!_passed && _reason == null)
                      ? null
                      : () async {
                          setState(() => _submitting = true);
                          final result = await ref
                              .read(procurementControllerProvider)
                              .submitQualityCheck(
                                bookingId: widget.bookingId,
                                moisturePercent:
                                    double.tryParse(_moistureController.text) ??
                                    0,
                                passed: _passed,
                                rejectionReason: _reason,
                                inspector: 'Suresh Babu',
                              );
                          setState(() => _submitting = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(result.message)),
                            );
                            if (result.success) {
                              if (_passed) {
                                context.pushReplacement(
                                  '/operator/weighment/${widget.bookingId}',
                                );
                              } else {
                                context.pop();
                              }
                            }
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

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AgrivaColors.textSecondaryFor(context),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
