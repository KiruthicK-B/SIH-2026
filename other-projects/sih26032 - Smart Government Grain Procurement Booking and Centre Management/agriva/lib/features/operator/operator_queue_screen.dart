import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/utils/list_extensions.dart';
import '../../models/booking.dart';
import '../../models/enums.dart';
import '../../state/auth_controller.dart';
import '../../state/booking_controller.dart';
import '../../state/op_result.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/app_states.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/max_width_body.dart';

class OperatorQueueScreen extends ConsumerStatefulWidget {
  const OperatorQueueScreen({super.key});

  @override
  ConsumerState<OperatorQueueScreen> createState() => _OperatorQueueScreenState();
}

class _OperatorQueueScreenState extends ConsumerState<OperatorQueueScreen> {
  bool _held = false;
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final allCentresAsync = ref.watch(centresProvider);
    final allCentres = allCentresAsync.value ?? const [];
    final userCentre = user?.centreId;
    final centreId = (userCentre != null && userCentre.isNotEmpty)
        ? userCentre
        : (allCentres.isNotEmpty ? allCentres.first.id : 'centre-erode-01');
    final rowsAsync = ref.watch(queueRowsForCentreProvider(centreId));
    final bookingsAsync = ref.watch(bookingsForCentreProvider(centreId));

    return Scaffold(
      appBar: const AgrivaAppBar(title: 'Queue Management'),
      body: MaxWidthBody(
        child: rowsAsync.when(
          loading: () => const LoadingState(),
          error: (e, st) => const ErrorState(),
          data: (rows) {
            final waiting = (bookingsAsync.value ?? const [])
                .where((b) => b.centreId == centreId && b.status == BookingStatus.booked)
                .toList();
            final query = _search.trim().toLowerCase();
            final visibleRows = query.isEmpty
                ? rows
                : rows
                    .where(
                      (r) =>
                          r.booking.token.toLowerCase().contains(query) ||
                          (r.farmer?.name.toLowerCase().contains(query) ?? false),
                    )
                    .toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(child: _Stat(label: 'Total in Queue', value: '${rows.length}')),
                      Container(width: 1, height: 40, color: AgrivaColors.borderFor(context)),
                      Expanded(
                        child: _Stat(
                          label: 'Est. Time for Next',
                          value: '${rows.firstOrNull?.etaMinutes ?? 0} min',
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search by token or farmer name',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _search.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _search = '');
                              },
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (_held)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(color: AgrivaColors.warningBg, borderRadius: BorderRadius.circular(8)),
                      child: const Text(
                        'Queue is on hold. New farmers will not be called forward.',
                        style: TextStyle(fontSize: 12, color: AgrivaColors.warning),
                      ),
                    ),
                  ),
                Expanded(
                  child: visibleRows.isEmpty
                      ? EmptyState(
                          icon: Icons.groups_outlined,
                          title: rows.isEmpty ? 'Queue is empty' : 'No matches',
                          message: rows.isEmpty
                              ? 'Checked-in farmers will appear here.'
                              : 'No queue entries match "$_search".',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: visibleRows.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, i) =>
                              _QueueRowCard(row: visibleRows[i], centreId: centreId),
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
                                : () async {
                                    Booking earliest = waiting.first;
                                    DateTime? earliestStart;
                                    for (final b in waiting) {
                                      final slot = await ref.read(slotByIdProvider(b.slotId).future);
                                      if (slot == null) continue;
                                      if (earliestStart == null || slot.start.isBefore(earliestStart)) {
                                        earliestStart = slot.start;
                                        earliest = b;
                                      }
                                    }
                                    final result =
                                        await ref.read(bookingControllerProvider).checkInFarmer(earliest.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(content: Text(result.message)));
                                    }
                                  },
                            child: const Text('Call Next'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _held = !_held),
                            style: OutlinedButton.styleFrom(foregroundColor: _held ? AgrivaColors.warning : null),
                            child: Text(_held ? 'Resume Queue' : 'Hold Queue'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
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
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AgrivaColors.primaryDark)),
        Text(label, style: TextStyle(fontSize: 11, color: AgrivaColors.textSecondaryFor(context))),
      ],
    );
  }
}

enum _QueueRowMenuAction { priorityOn, priorityOff, moveUp, moveDown, skip, recall, noShow }

class _QueueRowCard extends ConsumerWidget {
  final QueueRowView row;
  final String centreId;
  const _QueueRowCard({required this.row, required this.centreId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = row.entry;
    final booking = row.booking;
    final farmer = row.farmer;

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

    Future<void> runAction(Future<OpResult> Function() action) async {
      final result = await action();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
      }
    }

    final controller = ref.read(bookingControllerProvider);

    return Opacity(
      opacity: entry.skipped ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AgrivaColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AgrivaColors.borderFor(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 22,
                  child: Text(
                    '${row.position}',
                    style: TextStyle(fontSize: 11, color: AgrivaColors.textMutedFor(context)),
                  ),
                ),
                if (entry.isPriority) ...[
                  const Icon(Icons.star_rounded, size: 16, color: AgrivaColors.gold),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    '${booking.token} · ${farmer?.name ?? '—'}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AgrivaColors.textPrimaryFor(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  entry.skipped ? 'Skipped' : '~${row.etaMinutes} min',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: entry.skipped ? AgrivaColors.warning : AgrivaColors.textMutedFor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const SizedBox(width: 22),
                Text(
                  '${booking.expectedQuantityQ.toStringAsFixed(0)} Q',
                  style: TextStyle(fontSize: 11.5, color: AgrivaColors.textSecondaryFor(context)),
                ),
                const Spacer(),
                StatusBadge(label: entry.stage.label, tone: StatusTone.warning),
                const SizedBox(width: 4),
                TextButton(onPressed: onAction, child: Text(actionLabel)),
                PopupMenuButton<_QueueRowMenuAction>(
                  icon: Icon(Icons.more_vert, size: 20, color: AgrivaColors.textMutedFor(context)),
                  onSelected: (action) {
                    switch (action) {
                      case _QueueRowMenuAction.priorityOn:
                        runAction(() => controller.setQueuePriority(booking.id, true));
                      case _QueueRowMenuAction.priorityOff:
                        runAction(() => controller.setQueuePriority(booking.id, false));
                      case _QueueRowMenuAction.moveUp:
                        runAction(() => controller.reorderQueueEntry(centreId, booking.id, moveUp: true));
                      case _QueueRowMenuAction.moveDown:
                        runAction(() => controller.reorderQueueEntry(centreId, booking.id, moveUp: false));
                      case _QueueRowMenuAction.skip:
                        runAction(() => controller.setQueueSkipped(booking.id, true));
                      case _QueueRowMenuAction.recall:
                        runAction(() => controller.setQueueSkipped(booking.id, false));
                      case _QueueRowMenuAction.noShow:
                        runAction(() => controller.markNoShow(booking.id));
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: entry.isPriority
                          ? _QueueRowMenuAction.priorityOff
                          : _QueueRowMenuAction.priorityOn,
                      child: Text(entry.isPriority ? 'Remove priority' : 'Mark priority'),
                    ),
                    const PopupMenuItem(value: _QueueRowMenuAction.moveUp, child: Text('Move up')),
                    const PopupMenuItem(value: _QueueRowMenuAction.moveDown, child: Text('Move down')),
                    PopupMenuItem(
                      value: entry.skipped ? _QueueRowMenuAction.recall : _QueueRowMenuAction.skip,
                      child: Text(entry.skipped ? 'Recall to queue' : 'Skip'),
                    ),
                    const PopupMenuItem(value: _QueueRowMenuAction.noShow, child: Text('Mark no-show')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
