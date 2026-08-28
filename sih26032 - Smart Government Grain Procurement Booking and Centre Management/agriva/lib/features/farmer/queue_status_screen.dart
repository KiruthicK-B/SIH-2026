import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/app_state.dart';
import '../../core/utils/list_extensions.dart';
import '../../models/enums.dart';
import '../../models/queue_entry.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/app_states.dart';
import '../../widgets/queue_position_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/max_width_body.dart';

class QueueStatusScreen extends ConsumerWidget {
  const QueueStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final farmerId = appState.currentUser!.id;

    final myActiveBooking = appState.bookings
        .where(
          (b) =>
              b.farmerId == farmerId &&
              (b.status == BookingStatus.inQueue ||
                  b.status == BookingStatus.processing),
        )
        .firstOrNull;

    return Scaffold(
      appBar: const AgrivaAppBar(title: 'Queue Status'),
      body: MaxWidthBody(
        child: myActiveBooking == null
            ? const EmptyState(
                icon: Icons.queue_outlined,
                title: 'You are not in a live queue',
                message:
                    'Once you check in at a procurement centre, your live queue position appears here.',
              )
            : _QueueBody(
                bookingId: myActiveBooking.id,
                centreId: myActiveBooking.centreId,
                notifier: notifier,
                appState: appState,
              ),
      ),
    );
  }
}

class _QueueBody extends StatelessWidget {
  final String bookingId;
  final String centreId;
  final AppStateNotifier notifier;
  final AgrivaAppState appState;

  const _QueueBody({
    required this.bookingId,
    required this.centreId,
    required this.notifier,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    final centre = appState.centres.firstWhere((c) => c.id == centreId);
    final position = notifier.queuePositionFor(bookingId);
    final wait = notifier.estimatedWaitFor(bookingId);

    final centreBookingIds = appState.bookings
        .where((b) => b.centreId == centreId)
        .map((b) => b.id)
        .toSet();
    final activeEntries = appState.queueEntries
        .where(
          (q) =>
              centreBookingIds.contains(q.bookingId) &&
              q.stage != QueueStage.completed &&
              q.stage != QueueStage.exception,
        )
        .toList();
    // Today's full queue list — includes completed farmers too, matching a real front-desk display.
    final listEntries =
        appState.queueEntries
            .where((q) => centreBookingIds.contains(q.bookingId))
            .toList()
          ..sort((a, b) => a.enteredAt.compareTo(b.enteredAt));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        QueuePositionCard(
          position: position,
          totalInQueue: activeEntries.length,
          estimatedWaitMinutes: wait,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AgrivaColors.success,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Centre Status: ${centre.status.label}',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const Text(
              'Last Updated: Just now (simulated)',
              style: TextStyle(fontSize: 11, color: AgrivaColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Queue List (Today)',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AgrivaColors.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < listEntries.length; i++)
                _QueueRow(
                  index: i + 1,
                  entry: listEntries[i],
                  appState: appState,
                  isYou: listEntries[i].bookingId == bookingId,
                  isLast: i == listEntries.length - 1,
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Note: Queue updates every 2 minutes.',
          style: TextStyle(fontSize: 11, color: AgrivaColors.textMuted),
        ),
      ],
    );
  }
}

class _QueueRow extends StatelessWidget {
  final int index;
  final QueueEntry entry;
  final AgrivaAppState appState;
  final bool isYou;
  final bool isLast;

  const _QueueRow({
    required this.index,
    required this.entry,
    required this.appState,
    required this.isYou,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final booking = appState.bookings.firstWhere(
      (b) => b.id == entry.bookingId,
    );
    final farmer = appState.farmers.firstWhere((f) => f.id == booking.farmerId);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isYou ? AgrivaColors.primaryLight.withValues(alpha: 0.5) : null,
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AgrivaColors.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '$index',
              style: const TextStyle(
                fontSize: 12,
                color: AgrivaColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              isYou ? '${farmer.name} (You)' : farmer.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isYou ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${booking.expectedQuantityQ.toStringAsFixed(0)} Q',
            style: const TextStyle(
              fontSize: 12.5,
              color: AgrivaColors.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          StatusBadge(
            label: _displayStatus(entry.stage),
            tone: _displayTone(entry.stage),
          ),
        ],
      ),
    );
  }

  String _displayStatus(QueueStage stage) => switch (stage) {
    QueueStage.arrived => 'Waiting',
    QueueStage.completed => 'Completed',
    QueueStage.exception => 'Exception',
    _ => 'In Progress',
  };

  StatusTone _displayTone(QueueStage stage) => switch (stage) {
    QueueStage.arrived => StatusTone.inactive,
    QueueStage.completed => StatusTone.success,
    QueueStage.exception => StatusTone.error,
    _ => StatusTone.warning,
  };
}
