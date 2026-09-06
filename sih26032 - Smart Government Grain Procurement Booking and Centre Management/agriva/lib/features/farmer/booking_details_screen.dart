import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/utils/status_mapper.dart';
import '../../models/booking.dart';
import '../../models/centre.dart';
import '../../models/enums.dart';
import '../../models/payment.dart';
import '../../models/procurement_record.dart';
import '../../models/queue_entry.dart';
import '../../models/slot.dart';
import '../../repositories/repository_providers.dart';
import '../../state/booking_controller.dart';
import '../../state/data_revision.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/alert_banner.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/max_width_body.dart';
import '../../widgets/timeline_widget.dart';

class _DetailsData {
  final Booking booking;
  final Slot slot;
  final ProcurementCentre centre;
  final QueueEntry? queueEntry;
  final ProcurementRecord? procurement;
  final Payment? payment;
  const _DetailsData({
    required this.booking,
    required this.slot,
    required this.centre,
    this.queueEntry,
    this.procurement,
    this.payment,
  });
}

final _detailsDataProvider = FutureProvider.family<_DetailsData?, String>((
  ref,
  bookingId,
) async {
  ref.watch(dataRevisionProvider);
  final booking = await ref.read(bookingRepositoryProvider).getById(bookingId);
  if (booking == null) return null;
  final slot = await ref.read(slotRepositoryProvider).getById(booking.slotId);
  final centre = await ref.read(centreRepositoryProvider).getById(booking.centreId);
  if (slot == null || centre == null) return null;
  final queueEntry = await ref.read(queueRepositoryProvider).forBooking(bookingId);
  final procurement = await ref.read(procurementRepositoryProvider).forBooking(bookingId);
  final payment = await ref.read(paymentRepositoryProvider).forBooking(bookingId);
  return _DetailsData(
    booking: booking,
    slot: slot,
    centre: centre,
    queueEntry: queueEntry,
    procurement: procurement,
    payment: payment,
  );
});

class BookingDetailsScreen extends ConsumerWidget {
  final String bookingId;
  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(_detailsDataProvider(bookingId));

    return dataAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => const Scaffold(body: Center(child: Text('Something went wrong.'))),
      data: (data) {
        if (data == null) {
          return const Scaffold(body: Center(child: Text('Booking not found.')));
        }
        final booking = data.booking;
        final slot = data.slot;
        final centre = data.centre;
        final queueEntry = data.queueEntry;
        final procurement = data.procurement;
        final payment = data.payment;

        final canCancel = booking.isActive &&
            booking.checkedInAt == null &&
            booking.status != BookingStatus.rescheduleRequired &&
            booking.status != BookingStatus.waitlisted;
        final canRaiseGrievance =
            booking.status == BookingStatus.rejected ||
            (procurement?.isPartial ?? false);

        return Scaffold(
          appBar: const AgrivaAppBar(title: 'Booking Details'),
          body: MaxWidthBody(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(centre.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    StatusBadge(label: booking.status.label, tone: toneForBookingStatus(booking.status)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('d MMM yyyy').format(slot.start)}, ${DateFormat('h:mm a').format(slot.start)} – ${DateFormat('h:mm a').format(slot.end)}',
                  style: const TextStyle(color: AgrivaColors.textSecondary),
                ),
                const SizedBox(height: 16),

                if (booking.status == BookingStatus.cancelled)
                  const AlertBanner(
                    title: 'Booking Cancelled',
                    message: 'Your capacity for this slot has been released.',
                    tone: StatusTone.error,
                  )
                else if (booking.status == BookingStatus.noShow)
                  const AlertBanner(
                    title: 'Marked as No-show',
                    message: 'You were marked as a no-show for this slot.',
                    tone: StatusTone.error,
                  )
                else if (booking.status == BookingStatus.rescheduleRequired)
                  const AlertBanner(
                    title: 'Your original slot was affected',
                    message: 'Review your recommended replacement slot to continue.',
                    tone: StatusTone.warning,
                    icon: Icons.event_repeat_outlined,
                  )
                else if (booking.status == BookingStatus.rejected)
                  AlertBanner(
                    title: 'Produce Not Accepted',
                    message: procurement?.rejectionReason ?? 'Your produce did not pass quality checks.',
                    tone: StatusTone.error,
                  )
                else if (procurement?.isPartial ?? false)
                  AlertBanner(
                    title: 'Partially Accepted',
                    message:
                        '${procurement!.acceptedQuantityQ!.toStringAsFixed(1)} Q accepted, ${procurement.rejectedQuantityQ!.toStringAsFixed(1)} Q rejected: ${procurement.rejectionReason ?? ''}',
                    tone: StatusTone.warning,
                  ),
                if (booking.status == BookingStatus.rescheduleRequired) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: 'Review Replacement Slot',
                      onPressed: () => context.push('/farmer/reschedule/$bookingId'),
                    ),
                  ),
                ],
                if (canRaiseGrievance) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: SecondaryButton(
                      label: 'Raise a Grievance',
                      icon: Icons.support_agent_outlined,
                      onPressed: () => context.push('/farmer/grievances/new?bookingId=$bookingId'),
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AgrivaColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Status Timeline', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      TimelineWidget(steps: _buildSteps(booking, queueEntry, procurement, payment)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AgrivaColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Booking Info', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      _Row('Token', booking.token),
                      _Row('Expected Quantity', '${booking.expectedQuantityQ.toStringAsFixed(0)} Q'),
                      _Row('Booking ID', booking.id),
                      if (payment != null) _Row('Transaction Ref', payment.transactionRef.isEmpty ? '—' : payment.transactionRef),
                    ],
                  ),
                ),

                if (canCancel) ...[
                  const SizedBox(height: 20),
                  DestructiveButton(
                    label: 'Cancel Booking',
                    onPressed: () async {
                      final confirmed = await showConfirmDialog(
                        context,
                        title: 'Cancel Booking?',
                        message: 'Your capacity will be released.',
                        confirmLabel: 'Cancel Slot',
                        cancelLabel: 'Keep Booking',
                        destructive: true,
                      );
                      if (confirmed) {
                        final result =
                            await ref.read(bookingControllerProvider).cancelBooking(bookingId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(result.message)));
                        }
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  List<TimelineStepData> _buildSteps(
    Booking booking,
    QueueEntry? queueEntry,
    ProcurementRecord? procurement,
    Payment? payment,
  ) {
    final qualityState = booking.status == BookingStatus.rejected
        ? TimelineStepState.blocked
        : procurement?.acceptedQuantityQ != null || procurement?.rejectionReason != null
            ? TimelineStepState.done
            : queueEntry?.stage == QueueStage.qualityCheck
                ? TimelineStepState.active
                : TimelineStepState.pending;

    final weighmentState = procurement?.weighedQuantityQ != null
        ? TimelineStepState.done
        : queueEntry?.stage == QueueStage.weighment
            ? TimelineStepState.active
            : TimelineStepState.pending;

    final paymentState = switch (payment?.status) {
      PaymentStatus.completed => TimelineStepState.done,
      PaymentStatus.processing || PaymentStatus.initiated => TimelineStepState.active,
      PaymentStatus.failed => TimelineStepState.blocked,
      _ => booking.status == BookingStatus.rejected
          ? TimelineStepState.pending
          : (payment != null ? TimelineStepState.active : TimelineStepState.pending),
    };

    final completedState = switch (booking.status) {
      BookingStatus.paymentCompleted => TimelineStepState.done,
      BookingStatus.accepted || BookingStatus.partiallyAccepted => TimelineStepState.active,
      BookingStatus.rejected => TimelineStepState.blocked,
      _ => TimelineStepState.pending,
    };

    return [
      const TimelineStepData(title: 'Booked', state: TimelineStepState.done),
      TimelineStepData(
        title: 'Checked-In',
        subtitle: booking.checkedInAt != null
            ? DateFormat('d MMM, h:mm a').format(booking.checkedInAt!)
            : null,
        state: booking.checkedInAt != null ? TimelineStepState.done : TimelineStepState.pending,
      ),
      TimelineStepData(
        title: 'Quality Check',
        subtitle: booking.status == BookingStatus.rejected
            ? procurement?.rejectionReason
            : procurement?.moisturePercent != null
                ? '${procurement!.moisturePercent}% moisture'
                : null,
        state: qualityState,
      ),
      TimelineStepData(
        title: 'Weighment',
        subtitle: procurement?.weighedQuantityQ != null
            ? '${procurement!.weighedQuantityQ!.toStringAsFixed(1)} Q recorded'
            : null,
        state: weighmentState,
      ),
      TimelineStepData(
        title: 'Payment',
        subtitle: payment?.status.label,
        state: paymentState,
      ),
      TimelineStepData(
        title: 'Completed',
        subtitle: booking.status == BookingStatus.paymentCompleted
            ? '${procurement?.acceptedQuantityQ?.toStringAsFixed(1) ?? '—'} Q accepted, payment credited'
            : booking.status == BookingStatus.rejected
                ? 'Not accepted'
                : null,
        state: completedState,
      ),
    ];
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AgrivaColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
