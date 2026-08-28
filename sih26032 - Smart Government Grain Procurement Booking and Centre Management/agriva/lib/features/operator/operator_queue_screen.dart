import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/utils/list_extensions.dart';
import '../../models/enums.dart';
import '../../models/queue_entry.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/app_states.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/max_width_body.dart';

class OperatorQueueScreen extends ConsumerStatefulWidget {
  const OperatorQueueScreen({super.key});

  @override
  ConsumerState<OperatorQueueScreen> createState() =>
      _OperatorQueueScreenState();
}

class _OperatorQueueScreenState extends ConsumerState<OperatorQueueScreen> {
  bool _held = false;

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final centreId = appState.currentUser!.centreId!;

    final centreBookingIds = appState.bookings
        .where((b) => b.centreId == centreId)
        .map((b) => b.id)
        .toSet();
    final activeEntries =
        appState.queueEntries
            .where(
              (q) =>
                  centreBookingIds.contains(q.bookingId) &&
                  q.stage != QueueStage.completed &&
                  q.stage != QueueStage.exception,
            )
            .toList()
          ..sort((a, b) => a.enteredAt.compareTo(b.enteredAt));

    final waiting = appState.bookings
        .where(
          (b) => b.centreId == centreId && b.status == BookingStatus.confirmed,
        )
        .toList();

    return Scaffold(
      appBar: const AgrivaAppBar(title: 'Queue Management'),
      body: MaxWidthBody(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _Stat(
                      label: 'Total in Queue',
                      value: '${activeEntries.length}',
                    ),
                  ),
                  Container(width: 1, height: 40, color: AgrivaColors.border),
                  Expanded(
                    child: _Stat(
                      label: 'Est. Time for Next',
                      value:
                          '${notifier.estimatedWaitFor(activeEntries.firstOrNull?.bookingId ?? '')} min',
                    ),
                  ),
                ],
              ),
            ),
            if (_held)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AgrivaColors.warningBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Queue is on hold. New farmers will not be called forward.',
                    style: TextStyle(fontSize: 12, color: AgrivaColors.warning),
                  ),
                ),
              ),
            Expanded(
              child: activeEntries.isEmpty
                  ? const EmptyState(
                      icon: Icons.groups_outlined,
                      title: 'Queue is empty',
                      message: 'Checked-in farmers will appear here.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: activeEntries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _QueueRowTile(
                        entry: activeEntries[i],
                        position: i + 1,
                      ),
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: waiting.isEmpty
                            ? null
                            : () {
                                waiting.sort((a, b) {
                                  final sa = appState.slots
                                      .firstWhere((s) => s.id == a.slotId)
                                      .start;
                                  final sb = appState.slots
                                      .firstWhere((s) => s.id == b.slotId)
                                      .start;
                                  return sa.compareTo(sb);
                                });
                                final result = notifier.checkInFarmer(
                                  waiting.first.id,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(result.message)),
                                );
                              },
                        child: const Text('Call Next'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _held = !_held),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _held ? AgrivaColors.warning : null,
                        ),
                        child: Text(_held ? 'Resume Queue' : 'Hold Queue'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AgrivaColors.primaryDark,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AgrivaColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _QueueRowTile extends ConsumerWidget {
  final QueueEntry entry;
  final int position;
  const _QueueRowTile({required this.entry, required this.position});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final booking = appState.bookings.firstWhere(
      (b) => b.id == entry.bookingId,
    );
    final farmer = appState.farmers.firstWhere((f) => f.id == booking.farmerId);

    String actionLabel;
    VoidCallback onAction;
    switch (entry.stage) {
      case QueueStage.arrived:
        actionLabel = 'Start Quality';
        onAction = () => context.push('/operator/quality/${booking.id}');
      case QueueStage.qualityCheck:
        actionLabel = 'View';
        onAction = () => context.push('/operator/quality/${booking.id}');
      case QueueStage.weighment:
        actionLabel = 'Start Weighment';
        onAction = () => context.push('/operator/weighment/${booking.id}');
      default:
        actionLabel = 'View';
        onAction = () {};
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AgrivaColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '$position',
              style: const TextStyle(
                fontSize: 11,
                color: AgrivaColors.textMuted,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${booking.token} · ${farmer.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${booking.expectedQuantityQ.toStringAsFixed(0)} Q',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AgrivaColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(label: entry.stage.label, tone: StatusTone.warning),
          const SizedBox(width: 8),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
