import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../models/enums.dart';
import '../../state/auth_controller.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/app_states.dart';
import '../../widgets/max_width_body.dart';
import 'district_providers.dart';

class ManagerAnalyticsScreen extends ConsumerWidget {
  const ManagerAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final userDistrict = user?.district;
    final districtKey = (userDistrict != null && userDistrict.isNotEmpty)
        ? userDistrict
        : 'district-erode';
    final dataAsync = ref.watch(districtDataProvider(districtKey));

    return Scaffold(
      appBar: const AgrivaAppBar(title: 'Analytics'),
      body: MaxWidthBody(
        child: dataAsync.when(
          loading: () => const LoadingState(),
          error: (e, st) => const ErrorState(),
          data: (data) {
            final bookings = data.bookings;
            final total = bookings.isEmpty ? 1 : bookings.length;

            final noShowRate = bookings.where((b) => b.status == BookingStatus.noShow).length / total * 100;
            final cancellationRate = bookings.where((b) => b.status == BookingStatus.cancelled).length / total * 100;
            final rescheduleCount = data.rescheduleOffers.length;
            final disruptionImpact = data.disruptions.length;
            final rejectionCount = data.procurementRecords.where((p) => p.isFullyRejected).length;
            final paymentPendingCount = data.payments
                .where((p) => p.status == PaymentStatus.notInitiated || p.status == PaymentStatus.processing)
                .length;

            final totalActiveLanes = data.centres.fold<int>(0, (s, c) => s + c.processingLanesActive).clamp(1, 100);
            final activeInQueue = bookings.where((b) => b.status == BookingStatus.inQueue).length;
            final averageWaitingMinutes = ((activeInQueue * 18) / totalActiveLanes).round().clamp(0, 180);

            final totalDailyCapacity =
                data.centres.fold<double>(0, (sum, c) => sum + c.dailyProcessingCapacityQ);
            final totalBookedCapacity = data.centres.fold<double>(0, (sum, c) {
              final booked = data.bookings
                  .where((b) => b.centreId == c.id)
                  .fold<double>(0, (s, b) => s + b.expectedQuantityQ)
                  .clamp(0, c.dailyProcessingCapacityQ);
              return sum + booked;
            });
            final capacityUtilizationPercent = totalDailyCapacity == 0
                ? 0
                : (totalBookedCapacity / totalDailyCapacity * 100).round();

            final totalStorageCapacity =
                data.centres.fold<double>(0, (sum, c) => sum + c.storageCapacityQ);
            final totalCurrentStorage =
                data.centres.fold<double>(0, (sum, c) => sum + c.currentStorageQ);
            final storageUtilizationPercent = totalStorageCapacity == 0
                ? 0
                : (totalCurrentStorage / totalStorageCapacity * 100).round();

            final totalEstimatedSlots = data.centres.length * 36;
            final bookedTodayCount = data.bookings.where((b) => b.status == BookingStatus.booked || b.status == BookingStatus.checkedIn).length;
            final slotUtilizationPercent = totalEstimatedSlots == 0
                ? 0
                : ((bookedTodayCount / totalEstimatedSlots) * 100).round().clamp(0, 100);

            final items = [
              ('Average Waiting Time', '$averageWaitingMinutes min'),
              ('Slot Utilization (Today)', '$slotUtilizationPercent%'),
              ('Capacity Utilization', '$capacityUtilizationPercent%'),
              ('Storage Utilization', '$storageUtilizationPercent%'),
              ('No-show Rate', '${noShowRate.toStringAsFixed(1)}%'),
              ('Cancellation Rate', '${cancellationRate.toStringAsFixed(1)}%'),
              ('Rescheduling Count', '$rescheduleCount'),
              ('Disruption Impact', '$disruptionImpact recorded'),
              ('Rejection Count', '$rejectionCount'),
              ('Payment Pending Count', '$paymentPendingCount'),
            ];

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final (label, value) = items[i];
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final cardBg = isDark ? AgrivaColors.surfaceDark : Colors.white;
                final cardBorder = isDark ? AgrivaColors.borderDark : AgrivaColors.border;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: isDark ? AgrivaColors.textSecondaryDark : AgrivaColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
