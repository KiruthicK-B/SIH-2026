import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/manager_kpis.dart';
import '../../models/enums.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/max_width_body.dart';

class ManagerAnalyticsScreen extends ConsumerWidget {
  const ManagerAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final bookings = appState.bookings;
    final total = bookings.isEmpty ? 1 : bookings.length;

    final noShowRate =
        bookings.where((b) => b.status == BookingStatus.noShow).length /
        total *
        100;
    final cancellationRate =
        bookings.where((b) => b.status == BookingStatus.cancelled).length /
        total *
        100;
    final rescheduleCount = appState.rescheduleOffers.length;
    final disruptionImpact = appState.disruptions.length;
    final nonAcceptanceCount = appState.procurements
        .where((p) => p.status.name == 'notAccepted')
        .length;
    final paymentPendingCount = appState.payments
        .where(
          (p) =>
              p.status == PaymentStatus.pending ||
              p.status == PaymentStatus.processing,
        )
        .length;

    final items = [
      ('Average Waiting Time', '${ManagerKpis.averageWaitingMinutes} min'),
      ('Average Processing Time', '18 min'),
      ('Slot Utilization', '76%'),
      ('Capacity Utilization', '${ManagerKpis.capacityUtilizationPercent}%'),
      ('Storage Utilization', '${ManagerKpis.storageUtilizationPercent}%'),
      ('No-show Rate', '${noShowRate.toStringAsFixed(1)}%'),
      ('Cancellation Rate', '${cancellationRate.toStringAsFixed(1)}%'),
      ('Rescheduling Count', '$rescheduleCount'),
      ('Disruption Impact', '$disruptionImpact recorded'),
      ('Non-acceptance Count', '$nonAcceptanceCount'),
      ('Payment Pending Count', '$paymentPendingCount'),
    ];

    return Scaffold(
      appBar: const AgrivaAppBar(title: 'Analytics'),
      body: MaxWidthBody(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final (label, value) = items[i];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AgrivaColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AgrivaColors.textSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
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
