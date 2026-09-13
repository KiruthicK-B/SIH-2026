import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../state/booking_controller.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_states.dart';
import '../../widgets/max_width_body.dart';

class CheckinScreen extends ConsumerWidget {
  final String bookingId;
  const CheckinScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingByIdProvider(bookingId));

    return Scaffold(
      appBar: const AgrivaAppBar(title: 'Farmer Check-in'),
      body: MaxWidthBody(
        child: bookingAsync.when(
          loading: () => const LoadingState(),
          error: (e, st) => const ErrorState(),
          data: (booking) {
            if (booking == null) return const ErrorState(message: 'Booking not found.');
            final farmerAsync = ref.watch(farmerByIdProvider(booking.farmerId));
            final farmer = farmerAsync.value;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AgrivaColors.surfaceFor(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AgrivaColors.borderFor(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Row('Booking ID', booking.id),
                        _Row('Farmer', farmer?.name ?? '—'),
                        _Row('Token', booking.token),
                        _Row('Expected Quantity', '${booking.expectedQuantityQ.toStringAsFixed(0)} Q'),
                      ],
                    ),
                  ),
                  const Spacer(),
                  PrimaryButton(
                    label: 'Confirm Arrival',
                    onPressed: () async {
                      final result = await ref.read(bookingControllerProvider).checkInFarmer(bookingId);
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
          Text(label, style: TextStyle(fontSize: 13, color: AgrivaColors.textSecondaryFor(context))),
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
