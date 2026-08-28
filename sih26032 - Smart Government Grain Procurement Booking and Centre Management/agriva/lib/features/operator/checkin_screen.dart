import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/max_width_body.dart';

class CheckinScreen extends ConsumerWidget {
  final String bookingId;
  const CheckinScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final booking = appState.bookings.firstWhere((b) => b.id == bookingId);
    final farmer = appState.farmers.firstWhere((f) => f.id == booking.farmerId);

    return Scaffold(
      appBar: const AgrivaAppBar(title: 'Farmer Check-in'),
      body: MaxWidthBody(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AgrivaColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Row('Booking ID', booking.id),
                    _Row('Farmer', farmer.name),
                    _Row('Token', booking.token),
                    _Row(
                      'Expected Quantity',
                      '${booking.expectedQuantityQ.toStringAsFixed(0)} Q',
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Confirm Arrival',
                onPressed: () {
                  final result = ref
                      .read(appStateProvider.notifier)
                      .checkInFarmer(bookingId);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(result.message)));
                  if (result.success) context.pop();
                },
              ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
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
