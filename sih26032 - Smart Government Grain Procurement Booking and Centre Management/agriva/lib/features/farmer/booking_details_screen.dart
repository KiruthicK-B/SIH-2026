import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/utils/list_extensions.dart';
import '../../models/enums.dart';
import '../../models/procurement.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/alert_banner.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/max_width_body.dart';
import '../../widgets/timeline_widget.dart';

class BookingDetailsScreen extends ConsumerWidget {
  final String bookingId;
  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final booking = appState.bookings
        .where((b) => b.id == bookingId)
        .firstOrNull;

    if (booking == null) {
      return const Scaffold(body: Center(child: Text('Booking not found.')));
    }

    final slot = appState.slots.firstWhere((s) => s.id == booking.slotId);
    final centre = appState.centres.firstWhere((c) => c.id == booking.centreId);
    final queueEntry = appState.queueEntries
        .where((q) => q.bookingId == bookingId)
        .firstOrNull;
    final inspection = appState.inspections
        .where((i) => i.bookingId == bookingId)
        .lastOrNull;
    final weighment = appState.weighments
        .where((w) => w.bookingId == bookingId)
        .lastOrNull;
    final procurement = appState.procurements
        .where((p) => p.bookingId == bookingId)
        .lastOrNull;
    final payment = appState.payments
        .where((p) => p.bookingId == bookingId)
        .lastOrNull;

    final canCancel =
        booking.isActive &&
        booking.checkedInAt == null &&
        booking.status != BookingStatus.rescheduleRequired &&
        booking.status != BookingStatus.waitlisted;

    return Scaffold(
      appBar: const AgrivaAppBar(title: 'Booking Details'),
      body: MaxWidthBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  centre.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                StatusBadge(
                  label: booking.status.label,
                  tone: _toneFor(booking.status),
                ),
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
              AlertBanner(
                title: 'Your original slot was affected',
                message:
                    'Review your recommended replacement slot to continue.',
                tone: StatusTone.warning,
                icon: Icons.event_repeat_outlined,
              ),
            if (booking.status == BookingStatus.rescheduleRequired) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Review Replacement Slot',
                  onPressed: () =>
                      context.push('/farmer/reschedule/$bookingId'),
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
                  const Text(
                    'Status Timeline',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  TimelineWidget(
                    steps: [
                      const TimelineStepData(
                        title: 'Booked',
                        state: TimelineStepState.done,
                      ),
                      TimelineStepData(
                        title: 'Arrived at Centre',
                        subtitle: booking.checkedInAt != null
                            ? DateFormat(
                                'd MMM, h:mm a',
                              ).format(booking.checkedInAt!)
                            : null,
                        state: booking.checkedInAt != null
                            ? TimelineStepState.done
                            : TimelineStepState.pending,
                      ),
                      TimelineStepData(
                        title: 'Quality Check',
                        subtitle: inspection == null
                            ? null
                            : inspection.result == InspectionStatus.notAccepted
                            ? 'Your produce was not accepted based on the recorded inspection result.'
                            : inspection.result ==
                                  InspectionStatus.furtherInspection
                            ? 'Further inspection required.'
                            : 'Passed · ${inspection.moisturePercent}% moisture',
                        state: switch (inspection?.result) {
                          InspectionStatus.passed => TimelineStepState.done,
                          InspectionStatus.notAccepted =>
                            TimelineStepState.blocked,
                          InspectionStatus.furtherInspection =>
                            TimelineStepState.blocked,
                          _ =>
                            queueEntry?.stage == QueueStage.qualityCheck
                                ? TimelineStepState.active
                                : TimelineStepState.pending,
                        },
                      ),
                      TimelineStepData(
                        title: 'Weighment',
                        subtitle: weighment != null
                            ? '${weighment.actualQuantityQ.toStringAsFixed(1)} Q recorded'
                            : null,
                        state: weighment != null
                            ? TimelineStepState.done
                            : queueEntry?.stage == QueueStage.weighment
                            ? TimelineStepState.active
                            : TimelineStepState.pending,
                      ),
                      TimelineStepData(
                        title: 'Payment',
                        subtitle: payment != null
                            ? payment.status.label
                            : weighment != null &&
                                  weighment.exceedsDeclared &&
                                  procurement == null
                            ? 'Quantity exceeds declared amount — authorized review required.'
                            : null,
                        state: switch (payment?.status) {
                          PaymentStatus.paid => TimelineStepState.done,
                          PaymentStatus.processing ||
                          PaymentStatus.initiated ||
                          PaymentStatus.pending => TimelineStepState.active,
                          PaymentStatus.failed ||
                          PaymentStatus.exception => TimelineStepState.blocked,
                          _ =>
                            (procurement?.status ==
                                        ProcurementStatus.notAccepted ||
                                    (weighment != null &&
                                        weighment.exceedsDeclared))
                                ? TimelineStepState.blocked
                                : TimelineStepState.pending,
                        },
                      ),
                      TimelineStepData(
                        title: 'Completed',
                        subtitle:
                            procurement?.status == ProcurementStatus.completed
                            ? '${procurement!.acceptedQuantityQ?.toStringAsFixed(1)} Q accepted'
                            : procurement?.status ==
                                  ProcurementStatus.notAccepted
                            ? 'Not accepted'
                            : null,
                        state: switch (procurement?.status) {
                          ProcurementStatus.notAccepted =>
                            TimelineStepState.blocked,
                          ProcurementStatus.completed =>
                            payment?.status == PaymentStatus.paid
                                ? TimelineStepState.done
                                : TimelineStepState.active,
                          _ => TimelineStepState.pending,
                        },
                      ),
                    ],
                  ),
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
                  const Text(
                    'Booking Info',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  _Row('Token', booking.token),
                  _Row(
                    'Expected Quantity',
                    '${booking.expectedQuantityQ.toStringAsFixed(0)} Q',
                  ),
                  _Row('Booking ID', booking.id),
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
                    final result = ref
                        .read(appStateProvider.notifier)
                        .cancelBooking(bookingId);
                    if (context.mounted)
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(result.message)));
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  StatusTone _toneFor(BookingStatus s) => switch (s) {
    BookingStatus.confirmed ||
    BookingStatus.checkedIn ||
    BookingStatus.completed => StatusTone.success,
    BookingStatus.inQueue ||
    BookingStatus.processing ||
    BookingStatus.rescheduleRequired ||
    BookingStatus.waitlisted => StatusTone.warning,
    BookingStatus.notAccepted ||
    BookingStatus.cancelled ||
    BookingStatus.noShow => StatusTone.error,
    _ => StatusTone.inactive,
  };
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
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AgrivaColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
