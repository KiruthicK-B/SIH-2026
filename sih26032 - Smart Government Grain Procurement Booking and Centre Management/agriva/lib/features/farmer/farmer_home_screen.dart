import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/utils/list_extensions.dart';
import '../../models/enums.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/alert_banner.dart';
import '../../widgets/app_states.dart';
import '../../widgets/max_width_body.dart';
import '../../widgets/status_badge.dart';

class FarmerHomeScreen extends ConsumerWidget {
  final VoidCallback onGoToQueue;
  final VoidCallback onGoToBookings;
  const FarmerHomeScreen({
    super.key,
    required this.onGoToQueue,
    required this.onGoToBookings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final farmerId = appState.currentUser!.id;
    final farmer = appState.farmers.firstWhere((f) => f.id == farmerId);

    final myBookings = appState.bookings
        .where((b) => b.farmerId == farmerId)
        .toList();
    final upcoming =
        myBookings
            .where((b) => b.isActive && b.status != BookingStatus.waitlisted)
            .toList()
          ..sort((a, b) {
            final sa = appState.slots.firstWhere((s) => s.id == a.slotId).start;
            final sb = appState.slots.firstWhere((s) => s.id == b.slotId).start;
            return sa.compareTo(sb);
          });
    final upcomingBooking = upcoming.firstOrNull;

    final rescheduleNeeded = myBookings
        .where((b) => b.status == BookingStatus.rescheduleRequired)
        .firstOrNull;

    return Scaffold(
      backgroundColor: AgrivaColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              farmer.name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            Text(
              'Farmer ID: ${farmer.farmerCode}',
              style: const TextStyle(fontSize: 11.5, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () => context.push('/farmer/notifications'),
          ),
        ],
      ),
      body: MaxWidthBody(
        child: RefreshIndicator(
          onRefresh: () async {},
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (rescheduleNeeded != null) ...[
                AlertBanner(
                  title: 'Centre delay',
                  message:
                      'Your procurement centre is currently delayed. Review your replacement slot.',
                  tone: StatusTone.warning,
                  icon: Icons.warning_amber_outlined,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => context.push(
                      '/farmer/reschedule/${rescheduleNeeded.id}',
                    ),
                    child: const Text('Review replacement slot →'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              const Text(
                'Upcoming Booking',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              if (upcomingBooking == null)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AgrivaColors.border),
                  ),
                  child: EmptyState(
                    icon: Icons.calendar_today_outlined,
                    title: 'No upcoming bookings',
                    message: 'Book a slot to get started.',
                    actionLabel: 'Book Slot',
                    onAction: () => context.push('/farmer/book-slot'),
                  ),
                )
              else ...[
                _UpcomingSlotCard(bookingId: upcomingBooking.id),
                if (upcomingBooking.status == BookingStatus.inQueue ||
                    upcomingBooking.status == BookingStatus.processing) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Queue Status',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  _DashboardQueueStats(bookingId: upcomingBooking.id),
                ],
              ],
              const SizedBox(height: 24),
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _QuickAction(
                    icon: Icons.calendar_today_outlined,
                    label: 'Book New Slot',
                    onTap: () => context.push('/farmer/book-slot'),
                  ),
                  const SizedBox(height: 10),
                  _QuickAction(
                    icon: Icons.event_note_outlined,
                    label: 'My Bookings',
                    onTap: onGoToBookings,
                  ),
                  const SizedBox(height: 10),
                  _QuickAction(
                    icon: Icons.queue_outlined,
                    label: 'Queue Status',
                    onTap: onGoToQueue,
                  ),
                  const SizedBox(height: 10),
                  _QuickAction(
                    icon: Icons.notifications_none_outlined,
                    label: 'Notifications',
                    onTap: () => context.push('/farmer/notifications'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingSlotCard extends ConsumerWidget {
  final String bookingId;
  const _UpcomingSlotCard({required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final booking = appState.bookings.firstWhere((b) => b.id == bookingId);
    final slot = appState.slots.firstWhere((s) => s.id == booking.slotId);
    final centre = appState.centres.firstWhere((c) => c.id == booking.centreId);
    final wait = ref
        .read(appStateProvider.notifier)
        .estimatedWaitFor(bookingId);
    final inQueue =
        booking.status == BookingStatus.inQueue ||
        booking.status == BookingStatus.processing;

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
          Text(
            centre.name,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
          ),
          const SizedBox(height: 4),
          Text(
            '${DateFormat('d MMM yyyy').format(slot.start)}, ${DateFormat('h:mm a').format(slot.start)} – ${DateFormat('h:mm a').format(slot.end)}',
            style: const TextStyle(
              color: AgrivaColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(label: 'Token', value: booking.token),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Expected Quantity',
                  value: '${booking.expectedQuantityQ.toStringAsFixed(0)} Q',
                ),
              ),
              if (inQueue)
                Expanded(
                  child: _MiniStat(label: 'Estimated Wait', value: '$wait min'),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push('/farmer/booking/$bookingId'),
              child: const Text('View Details'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardQueueStats extends ConsumerWidget {
  final String bookingId;
  const _DashboardQueueStats({required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final position = notifier.queuePositionFor(bookingId);
    final wait = notifier.estimatedWaitFor(bookingId);

    final booking = appState.bookings.firstWhere((b) => b.id == bookingId);
    final centreBookingIds = appState.bookings
        .where((b) => b.centreId == booking.centreId)
        .map((b) => b.id)
        .toSet();
    final totalInQueue = appState.queueEntries
        .where(
          (q) =>
              centreBookingIds.contains(q.bookingId) &&
              q.stage != QueueStage.completed &&
              q.stage != QueueStage.exception,
        )
        .length;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AgrivaColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Queue Position',
                  style: TextStyle(fontSize: 11, color: AgrivaColors.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  position <= 0 ? '—' : '$position / $totalInQueue',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AgrivaColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estimated Waiting Time',
                  style: TextStyle(fontSize: 11, color: AgrivaColors.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  '$wait mins',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AgrivaColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AgrivaColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AgrivaColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AgrivaColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
