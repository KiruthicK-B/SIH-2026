import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/utils/status_mapper.dart';
import '../../models/enums.dart';
import '../../models/slot.dart';
import '../../providers/app_state_provider.dart';
import '../../services/capacity_service.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/max_width_body.dart';

const _capacity = CapacityService();

class OperatorDashboardScreen extends ConsumerWidget {
  const OperatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final centreId = appState.currentUser!.centreId!;
    final centre = appState.centres.firstWhere((c) => c.id == centreId);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final todaySlots =
        appState.slots
            .where((s) => s.centreId == centreId && s.date == todayDate)
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));

    final todayBookings = appState.bookings
        .where(
          (b) =>
              todaySlots.any((s) => s.id == b.slotId) &&
              b.status != BookingStatus.cancelled,
        )
        .toList();
    final totalBookingsToday = todayBookings.length;
    final completedToday = todayBookings
        .where((b) => b.status == BookingStatus.completed)
        .length;
    final inProgressToday = todayBookings
        .where(
          (b) =>
              b.status == BookingStatus.checkedIn ||
              b.status == BookingStatus.inQueue ||
              b.status == BookingStatus.processing,
        )
        .length;

    return Scaffold(
      appBar: AgrivaAppBar(title: centre.name, subtitle: 'Operator'),
      body: MaxWidthBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                StatusBadge(
                  label: centre.status.label,
                  tone: toneForCentreStatus(centre.status),
                ),
                const Spacer(),
                Text(
                  DateFormat('d MMM yyyy').format(today),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AgrivaColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Today Overview',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    icon: Icons.event_note_outlined,
                    label: 'Total Bookings',
                    value: '$totalBookingsToday',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricCard(
                    icon: Icons.check_circle_outline,
                    label: 'Completed',
                    value: '$completedToday',
                    accent: AgrivaColors.success,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricCard(
                    icon: Icons.hourglass_top_outlined,
                    label: 'In Progress',
                    value: '$inProgressToday',
                    accent: AgrivaColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Today's Schedule",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                TextButton(
                  onPressed: () => context.push('/operator/disruption'),
                  child: const Text('Declare Disruption'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AgrivaColors.border),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < todaySlots.length; i++)
                    _ScheduleRow(
                      slot: todaySlots[i],
                      isLast: i == todaySlots.length - 1,
                      now: today,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleRow extends ConsumerWidget {
  final Slot slot;
  final bool isLast;
  final DateTime now;
  const _ScheduleRow({
    required this.slot,
    required this.isLast,
    required this.now,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final booked = _capacity.bookedFarmersForSlot(slot, appState.bookings);
    final bookedQ = _capacity.bookedQuantityForSlot(slot, appState.bookings);

    final label = now.isAfter(slot.end)
        ? 'Completed'
        : now.isBefore(slot.start)
        ? 'Upcoming'
        : 'In Progress';
    final tone = label == 'Completed'
        ? StatusTone.success
        : label == 'In Progress'
        ? StatusTone.warning
        : StatusTone.inactive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AgrivaColors.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '${DateFormat('h a').format(slot.start)}–${DateFormat('h a').format(slot.end)}',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '$booked/${slot.maxFarmers}',
              style: const TextStyle(
                fontSize: 12.5,
                color: AgrivaColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${bookedQ.toStringAsFixed(0)} Q',
              style: const TextStyle(
                fontSize: 12.5,
                color: AgrivaColors.textSecondary,
              ),
            ),
          ),
          StatusBadge(label: label, tone: tone),
        ],
      ),
    );
  }
}
