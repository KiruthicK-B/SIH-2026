import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/utils/status_mapper.dart';
import '../../models/centre.dart';
import '../../models/enums.dart';
import '../../services/scheduler_service.dart';
import '../../state/auth_controller.dart';
import '../../state/booking_controller.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/app_states.dart';
import '../../widgets/progress_stat_bar.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/max_width_body.dart';
import 'district_providers.dart';

class ManagerCentresScreen extends ConsumerWidget {
  const ManagerCentresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final userDistrict = user?.district;
    final districtKey = (userDistrict != null && userDistrict.isNotEmpty)
        ? userDistrict
        : 'district-erode';
    final dataAsync = ref.watch(districtDataProvider(districtKey));

    return Scaffold(
      appBar: const AgrivaAppBar(title: 'Centres'),
      body: MaxWidthBody(
        child: dataAsync.when(
          loading: () => const LoadingState(),
          error: (e, st) => const ErrorState(),
          data: (data) => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: data.centres.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final centre = data.centres[i];
              final centreBookings = data.bookings.where((b) => b.centreId == centre.id).toList();

              // Slot-level capacity math needs the centre's slots; the
              // district roll-up only carries bookings, so approximate
              // today's booked quantity directly from today's bookings.
              final bookedCapacity = centreBookings
                  .fold<double>(0, (sum, b) => sum + b.expectedQuantityQ)
                  .clamp(0, centre.dailyProcessingCapacityQ);

              final isDark = Theme.of(context).brightness == Brightness.dark;
              final cardBg = isDark ? AgrivaColors.surfaceDark : Colors.white;
              final cardBorder = isDark ? AgrivaColors.borderDark : AgrivaColors.border;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(centre.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                        ),
                        StatusBadge(label: centre.status.label, tone: toneForCentreStatus(centre.status)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ProgressStatBar(
                      label: 'Processing Capacity',
                      current: bookedCapacity.toDouble(),
                      max: centre.dailyProcessingCapacityQ,
                    ),
                    const SizedBox(height: 10),
                    ProgressStatBar(label: 'Storage', current: centre.currentStorageQ, max: centre.storageCapacityQ),
                    const SizedBox(height: 12),
                    _CentreQueueStats(centre: centre),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Live queue length + estimated wait for one centre, computed from real
/// queue entries (the same scheduler logic the farmer's own queue screen
/// uses) instead of a fixed per-centre lookup table.
class _CentreQueueStats extends ConsumerWidget {
  final ProcurementCentre centre;
  const _CentreQueueStats({required this.centre});

  static const _scheduler = SchedulerService();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeQueue = ref.watch(queueTotalForCentreProvider(centre.id)).value ?? 0;
    final avgWait = activeQueue == 0
        ? 0
        : _scheduler.estimateWaitMinutes(
            queuePosition: (activeQueue / 2).ceil(),
            activeLanes: centre.processingLanesActive,
          );
    return Row(
      children: [
        Expanded(child: _Mini(label: 'Queue', value: '$activeQueue')),
        Expanded(child: _Mini(label: 'Avg Wait', value: '$avgWait min')),
        Expanded(
          child: _Mini(
            label: 'Lanes',
            value: '${centre.processingLanesActive}/${centre.processingLanesTotal}',
          ),
        ),
      ],
    );
  }
}

class _Mini extends StatelessWidget {
  final String label;
  final String value;
  const _Mini({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AgrivaColors.textMuted)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
