import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/utils/status_mapper.dart';
import '../../data/manager_kpis.dart';
import '../../models/enums.dart';
import '../../providers/app_state_provider.dart';
import '../../services/capacity_service.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/progress_stat_bar.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/max_width_body.dart';

const _capacity = CapacityService();

class ManagerCentresScreen extends ConsumerWidget {
  const ManagerCentresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    return Scaffold(
      appBar: const AgrivaAppBar(title: 'Centres'),
      body: MaxWidthBody(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: appState.centres.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final centre = appState.centres[i];
            final remainingCapacity = _capacity.getRemainingDailyCapacity(
              centre,
              todayDate,
              appState.slots,
              appState.bookings,
            );
            final bookedCapacity =
                (centre.dailyProcessingCapacityQ - remainingCapacity).clamp(
                  0,
                  centre.dailyProcessingCapacityQ,
                );

            final centreBookingIds = appState.bookings
                .where((b) => b.centreId == centre.id)
                .map((b) => b.id)
                .toSet();
            final activeQueue = appState.queueEntries
                .where(
                  (q) =>
                      centreBookingIds.contains(q.bookingId) &&
                      q.stage != QueueStage.completed &&
                      q.stage != QueueStage.exception,
                )
                .length;
            final avgWait =
                ManagerKpis.avgWaitByCentre[centre.name.contains('ABC')
                    ? 'ABC Centre'
                    : 'XYZ Centre'] ??
                0;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AgrivaColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          centre.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                      StatusBadge(
                        label: centre.status.label,
                        tone: toneForCentreStatus(centre.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ProgressStatBar(
                    label: 'Processing Capacity',
                    current: bookedCapacity.toDouble(),
                    max: centre.dailyProcessingCapacityQ,
                  ),
                  const SizedBox(height: 10),
                  ProgressStatBar(
                    label: 'Storage',
                    current: centre.currentStorageQ,
                    max: centre.storageCapacityQ,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _Mini(label: 'Queue', value: '$activeQueue'),
                      ),
                      Expanded(
                        child: _Mini(label: 'Avg Wait', value: '$avgWait min'),
                      ),
                      Expanded(
                        child: _Mini(
                          label: 'Lanes',
                          value:
                              '${centre.processingLanesActive}/${centre.processingLanesTotal}',
                        ),
                      ),
                    ],
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

class _Mini extends StatelessWidget {
  final String label;
  final String value;
  const _Mini({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AgrivaColors.textMuted),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
