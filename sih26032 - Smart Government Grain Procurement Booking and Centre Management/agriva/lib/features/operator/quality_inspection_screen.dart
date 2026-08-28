import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../models/enums.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/app_buttons.dart';
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
  final _remarksController = TextEditingController();
  InspectionStatus _result = InspectionStatus.passed;
  String? _reason;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final booking = appState.bookings.firstWhere(
      (b) => b.id == widget.bookingId,
    );
    final farmer = appState.farmers.firstWhere((f) => f.id == booking.farmerId);

    return Scaffold(
      appBar: const AgrivaAppBar(title: 'Quality Inspection'),
      body: MaxWidthBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Row('Booking', booking.id),
            _Row('Token', booking.token),
            _Row('Farmer', farmer.name),
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
            RadioListTile<InspectionStatus>(
              value: InspectionStatus.passed,
              groupValue: _result,
              onChanged: (v) => setState(() => _result = v!),
              title: const Text('Passed'),
              contentPadding: EdgeInsets.zero,
              activeColor: AgrivaColors.primary,
            ),
            RadioListTile<InspectionStatus>(
              value: InspectionStatus.notAccepted,
              groupValue: _result,
              onChanged: (v) => setState(() => _result = v!),
              title: const Text('Not Accepted'),
              contentPadding: EdgeInsets.zero,
              activeColor: AgrivaColors.primary,
            ),
            RadioListTile<InspectionStatus>(
              value: InspectionStatus.furtherInspection,
              groupValue: _result,
              onChanged: (v) => setState(() => _result = v!),
              title: const Text('Further Inspection'),
              contentPadding: EdgeInsets.zero,
              activeColor: AgrivaColors.primary,
            ),
            if (_result == InspectionStatus.notAccepted) ...[
              const SizedBox(height: 8),
              const Text(
                'Reason',
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
            const SizedBox(height: 16),
            AppTextField(
              label: 'Remarks (Optional)',
              controller: _remarksController,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Submit',
              loading: _submitting,
              onPressed: () async {
                setState(() => _submitting = true);
                final result = ref
                    .read(appStateProvider.notifier)
                    .submitInspection(
                      bookingId: widget.bookingId,
                      moisturePercent:
                          double.tryParse(_moistureController.text) ?? 0,
                      result: _result,
                      reason: _reason,
                      remarks: _remarksController.text.isEmpty
                          ? null
                          : _remarksController.text,
                      inspector: 'Suresh Babu',
                    );
                setState(() => _submitting = false);
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(result.message)));
                  if (result.success) context.pop();
                }
              },
            ),
          ],
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
            style: const TextStyle(
              fontSize: 13,
              color: AgrivaColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
