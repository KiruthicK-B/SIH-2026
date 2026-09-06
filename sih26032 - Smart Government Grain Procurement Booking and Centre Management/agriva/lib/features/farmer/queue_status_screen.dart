import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/utils/list_extensions.dart';
import '../../models/booking.dart';
import '../../models/disruption.dart';
import '../../models/enums.dart';
import '../../models/payment.dart';
import '../../models/procurement_record.dart';
import '../../models/queue_entry.dart';
import '../../state/auth_controller.dart';
import '../../state/booking_controller.dart';
import '../../state/centre_admin_controller.dart';
import '../../state/procurement_controller.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/app_states.dart';
import '../../widgets/max_width_body.dart';
import '../../widgets/queue_position_card.dart';
import '../../widgets/status_badge.dart';

class QueueStatusScreen extends ConsumerWidget {
  const QueueStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    if (user == null) return const SizedBox.shrink();

    final bookingsAsync = ref.watch(bookingsForFarmerProvider(user.id));

    return Scaffold(
      appBar: const AgrivaAppBar(title: 'Live Queue & Stage Tracking'),
      body: MaxWidthBody(
        child: bookingsAsync.when(
          loading: () => const LoadingState(),
          error: (e, st) => const ErrorState(),
          data: (bookings) {
            // Find active or most recent booking for this farmer
            final activeBookings = bookings
                .where((b) => b.isActive && b.status != BookingStatus.cancelled && b.status != BookingStatus.noShow)
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            final currentBooking = activeBookings.firstOrNull ?? bookings.firstOrNull;

            if (currentBooking == null) {
              return EmptyState(
                icon: Icons.access_time_rounded,
                title: 'No Active Procurement Slot',
                message:
                    'You do not currently have a booking in the procurement pipeline. Book a slot at your assigned regional procurement centre to track live queue status.',
                actionLabel: 'Book a Procurement Slot',
                onAction: () => context.push('/book'),
              );
            }

            return _QueueBody(booking: currentBooking);
          },
        ),
      ),
    );
  }
}

class _QueueBody extends ConsumerWidget {
  final Booking booking;

  const _QueueBody({required this.booking});

  int _currentStageIndex(BookingStatus status) {
    return switch (status) {
      BookingStatus.booked => 0,
      BookingStatus.checkedIn || BookingStatus.inQueue => 1,
      BookingStatus.underQualityCheck => 2,
      BookingStatus.accepted ||
      BookingStatus.partiallyAccepted ||
      BookingStatus.paymentPending => 3,
      BookingStatus.paymentInitiated || BookingStatus.paymentCompleted => 4,
      BookingStatus.paymentFailed => 4,
      _ => 0,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final centreAsync = ref.watch(centreByIdProvider(booking.centreId));
    final position = ref.watch(queuePositionProvider(booking.id)).value ?? -1;
    final wait = ref.watch(estimatedWaitProvider(booking.id)).value ?? 0;
    final activeEntries =
        ref.watch(activeQueueEntriesForCentreProvider(booking.centreId)).value ?? const [];
    final listEntriesAsync = ref.watch(allQueueEntriesForCentreProvider(booking.centreId));
    final disruptionsAsync = ref.watch(disruptionsForCentreProvider(booking.centreId));
    final procurementAsync = ref.watch(procurementForBookingProvider(booking.id));
    final paymentAsync = ref.watch(paymentForBookingProvider(booking.id));

    final centre = centreAsync.value;
    final disruptions = disruptionsAsync.value ?? const [];
    final activeDisruptions = disruptions.where((d) => d.status == DisruptionStatus.active).toList();
    final procurement = procurementAsync.value;
    final payment = paymentAsync.value;

    final currentStage = _currentStageIndex(booking.status);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Live Disruption Alert Banner (Dynamic Disruption Feed)
        if (activeDisruptions.isNotEmpty) ...[
          for (final d in activeDisruptions)
            _DisruptionAlertCard(disruption: d),
          const SizedBox(height: 14),
        ],

        // 2. Booking Header Card with Token
        _BookingHeaderCard(booking: booking, centreName: centre?.name ?? 'Procurement Centre'),
        const SizedBox(height: 14),

        // 3. Live Queue Position (Shown if checked in and waiting)
        if (booking.status == BookingStatus.inQueue ||
            booking.status == BookingStatus.underQualityCheck ||
            position > 0) ...[
          QueuePositionCard(
            position: position > 0 ? position : 1,
            totalInQueue: activeEntries.isNotEmpty ? activeEntries.length : 1,
            estimatedWaitMinutes: wait > 0 ? wait : 15,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AgrivaColors.success),
              ),
              const SizedBox(width: 6),
              Text(
                'Centre Status: ${centre?.status.label ?? 'Open'}',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              const Text(
                'Live IoT Sync: Active',
                style: TextStyle(fontSize: 11, color: AgrivaColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // 4. End-to-End Procurement Lifecycle Stepper
        _ProcurementLifecycleStepper(
          currentStage: currentStage,
          status: booking.status,
          procurement: procurement,
          payment: payment,
        ),
        const SizedBox(height: 16),

        // 5. Procurement Record & Payment Details (if available)
        if (procurement != null || payment != null) ...[
          _ProcurementDetailsCard(procurement: procurement, payment: payment),
          const SizedBox(height: 16),
        ],

        // 6. Fast-Forward Demo Simulator Controls for SIH Review
        _DemoStageAdvanceCard(booking: booking),
        const SizedBox(height: 20),

        // 7. Today's Live Yard Queue Table
        const Text(
          'Procurement Yard Queue (Live)',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        listEntriesAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, st) => const Text('Could not load queue list', style: TextStyle(color: Colors.red)),
          data: (listEntries) {
            if (listEntries.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AgrivaColors.border),
                ),
                child: const Center(
                  child: Text(
                    'No other farmers currently waiting in yard queue.',
                    style: TextStyle(fontSize: 12.5, color: AgrivaColors.textSecondary),
                  ),
                ),
              );
            }

            return Container(
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
                      isYou: listEntries[i].bookingId == booking.id,
                      isLast: i == listEntries.length - 1,
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Icon(Icons.info_outline, size: 14, color: AgrivaColors.textMuted),
            SizedBox(width: 4),
            Text(
              'Tokens advance automatically upon lane weighbridge completion.',
              style: TextStyle(fontSize: 11, color: AgrivaColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _BookingHeaderCard extends StatelessWidget {
  final Booking booking;
  final String centreName;

  const _BookingHeaderCard({required this.booking, required this.centreName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AgrivaColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AgrivaColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'TOKEN: ${booking.token.isNotEmpty ? booking.token : 'WAITING'}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AgrivaColors.primaryDark,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              StatusBadge(
                label: booking.status.name.toUpperCase(),
                tone: switch (booking.status) {
                  BookingStatus.paymentCompleted => StatusTone.success,
                  BookingStatus.underQualityCheck || BookingStatus.inQueue => StatusTone.warning,
                  BookingStatus.paymentFailed || BookingStatus.rejected => StatusTone.error,
                  _ => StatusTone.info,
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            centreName,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined, size: 14, color: AgrivaColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Booking Ref: ${booking.id}',
                style: const TextStyle(fontSize: 12, color: AgrivaColors.textSecondary),
              ),
              const Spacer(),
              const Icon(Icons.scale_outlined, size: 14, color: AgrivaColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Expected: ${booking.expectedQuantityQ.toStringAsFixed(0)} Quintals',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DisruptionAlertCard extends StatelessWidget {
  final Disruption disruption;

  const _DisruptionAlertCard({required this.disruption});

  String _disruptionTitle(DisruptionType type) => switch (type) {
    DisruptionType.weighingMachineFailure => 'Weighing machine calibration failure',
    DisruptionType.powerFailure => 'Power grid disruption at centre yard',
    DisruptionType.networkIssue => 'Network server synchronization issue',
    DisruptionType.labourShortage => 'Temporary yard labour shortage',
    DisruptionType.storageUnavailable => 'Storage godown capacity limit reached',
    DisruptionType.inspectionDelay => 'Equipment inspection & sensor recalibration delay',
    DisruptionType.centreClosure => 'Temporary centre closure',
    DisruptionType.generalOperationalDelay => 'General operational delay',
    DisruptionType.capacityReduction => 'Daily procurement throughput capacity reduced',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'CENTRE OPERATIONAL ALERT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF92400E),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Spacer(),
                    Text(
                      'SMS Sent',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _disruptionTitle(disruption.type),
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF78350F), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Expected Normalcy: ${DateFormat('hh:mm a').format(disruption.expectedResolution)}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcurementLifecycleStepper extends StatelessWidget {
  final int currentStage;
  final BookingStatus status;
  final ProcurementRecord? procurement;
  final Payment? payment;

  const _ProcurementLifecycleStepper({
    required this.currentStage,
    required this.status,
    this.procurement,
    this.payment,
  });

  @override
  Widget build(BuildContext context) {
    final stages = [
      ('Slot Booked', 'Scheduled date & assigned centre confirmed'),
      ('Gate Check-in', 'Token issued & waiting in yard queue'),
      ('Quality Lab Inspection', 'Moisture & foreign matter verification'),
      ('Weighment Complete', 'Net accepted quintals logged at weighbridge'),
      ('DBT Payment Payout', 'Direct Benefit Transfer credited to farmer bank'),
    ];

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
          const Text(
            'Procurement Pipeline Stages',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < stages.length; i++)
            _StageStepRow(
              index: i,
              title: stages[i].$1,
              subtitle: stages[i].$2,
              isCompleted: i < currentStage || (i == 4 && payment?.status == PaymentStatus.completed),
              isCurrent: i == currentStage && payment?.status != PaymentStatus.completed,
              isLast: i == stages.length - 1,
            ),
        ],
      ),
    );
  }
}

class _StageStepRow extends StatelessWidget {
  final int index;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLast;

  const _StageStepRow({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? AgrivaColors.success
                      : isCurrent
                          ? AgrivaColors.primary
                          : Colors.grey.shade200,
                  border: isCurrent ? Border.all(color: AgrivaColors.primaryDark, width: 2) : null,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isCurrent ? Colors.white : Colors.grey.shade600,
                          ),
                        ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isCompleted ? AgrivaColors.success : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                          color: isCurrent ? AgrivaColors.primaryDark : AgrivaColors.textPrimary,
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AgrivaColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'CURRENT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AgrivaColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11.5, color: AgrivaColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcurementDetailsCard extends StatelessWidget {
  final ProcurementRecord? procurement;
  final Payment? payment;

  const _ProcurementDetailsCard({this.procurement, this.payment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified, color: AgrivaColors.success, size: 20),
              SizedBox(width: 8),
              Text(
                'Quality & Direct Benefit Transfer Summary',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF166534)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (procurement != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _metric(
                  'Moisture Content',
                  procurement!.moisturePercent != null
                      ? '${procurement!.moisturePercent!.toStringAsFixed(1)}%'
                      : 'Verified (<14%)',
                ),
                _metric('Grade Assigned', procurement!.qualityGrade ?? 'Standard Grade A'),
                _metric(
                  'Net Accepted',
                  procurement!.acceptedQuantityQ != null
                      ? '${procurement!.acceptedQuantityQ!.toStringAsFixed(1)} Q'
                      : 'Pending Weigh',
                ),
              ],
            ),
            if (procurement!.inspectedBy.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Inspected by: ${procurement!.inspectedBy} • ${DateFormat('d MMM, hh:mm a').format(procurement!.inspectionTime)}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF166534)),
              ),
            ],
          ],
          if (payment != null) ...[
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DBT Reference', style: TextStyle(fontSize: 11, color: Color(0xFF166534))),
                      const SizedBox(height: 2),
                      Text(
                        payment!.transactionRef.isNotEmpty ? payment!.transactionRef : 'PROCESSING-REF',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Amount: ₹${NumberFormat('#,##,###').format(payment!.amount)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF14532D)),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: payment!.status == PaymentStatus.completed ? 'DBT CREDITED' : payment!.status.name.toUpperCase(),
                  tone: payment!.status == PaymentStatus.completed ? StatusTone.success : StatusTone.warning,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF166534))),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF14532D))),
      ],
    );
  }
}

class _DemoStageAdvanceCard extends ConsumerWidget {
  final Booking booking;

  const _DemoStageAdvanceCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AgrivaColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AgrivaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt, size: 16, color: AgrivaColors.primary),
              SizedBox(width: 4),
              Text(
                'Live Demonstration Controls • Fast-Forward Lifecycle',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AgrivaColors.primaryDark),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (booking.status == BookingStatus.booked)
                ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(bookingControllerProvider).checkInFarmer(booking.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gate check-in completed. Token issued! SMS notification dispatched.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.login, size: 16),
                  label: const Text('Simulate Gate Check-in', style: TextStyle(fontSize: 12)),
                ),
              if (booking.status == BookingStatus.checkedIn || booking.status == BookingStatus.inQueue)
                ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(bookingControllerProvider).moveQueueStage(booking.id, QueueStage.qualityCheck);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Called to Quality Lab. Live SMS sent!')),
                      );
                    }
                  },
                  icon: const Icon(Icons.biotech, size: 16),
                  label: const Text('Call to Quality Lab', style: TextStyle(fontSize: 12)),
                ),
              if (booking.status == BookingStatus.underQualityCheck)
                ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(procurementControllerProvider).submitQualityCheck(
                          bookingId: booking.id,
                          moisturePercent: 12.8,
                          passed: true,
                          inspector: 'K. Shanmugam',
                        );
                    await ref.read(procurementControllerProvider).submitWeighment(
                          bookingId: booking.id,
                          weighedQuantityQ: booking.expectedQuantityQ,
                          acceptedQuantityQ: booking.expectedQuantityQ,
                          rejectedQuantityQ: 0,
                          inspector: 'K. Shanmugam',
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Quality passed (12.8% moisture) & Weighment completed!')),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Pass Quality & Weigh', style: TextStyle(fontSize: 12)),
                ),
              if (booking.status == BookingStatus.accepted ||
                  booking.status == BookingStatus.partiallyAccepted ||
                  booking.status == BookingStatus.paymentPending)
                ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(procurementControllerProvider).initiatePayment(booking.id);
                    await ref.read(procurementControllerProvider).updatePaymentStatus(
                          booking.id,
                          PaymentStatus.completed,
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('DBT MSP Payment disbursed directly to Bank Account!')),
                      );
                    }
                  },
                  icon: const Icon(Icons.account_balance, size: 16),
                  label: const Text('Disburse DBT Payment', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QueueRow extends ConsumerWidget {
  final int index;
  final QueueEntry entry;
  final bool isYou;
  final bool isLast;

  const _QueueRow({
    required this.index,
    required this.entry,
    required this.isYou,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingByIdProvider(entry.bookingId));
    final booking = bookingAsync.value;
    if (booking == null) return const SizedBox.shrink();
    final farmerAsync = ref.watch(farmerByIdProvider(booking.farmerId));
    final farmer = farmerAsync.value;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isYou ? AgrivaColors.primaryLight.withValues(alpha: 0.5) : null,
        border: isLast ? null : const Border(bottom: BorderSide(color: AgrivaColors.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text('$index', style: const TextStyle(fontSize: 12, color: AgrivaColors.textMuted)),
          ),
          Expanded(
            child: Text(
              isYou ? '${farmer?.name ?? '—'} (You • Token ${booking.token})' : (farmer?.name ?? '—'),
              style: TextStyle(fontSize: 13, fontWeight: isYou ? FontWeight.w700 : FontWeight.w500),
            ),
          ),
          Text(
            '${booking.expectedQuantityQ.toStringAsFixed(0)} Q',
            style: const TextStyle(fontSize: 12.5, color: AgrivaColors.textSecondary),
          ),
          const SizedBox(width: 10),
          StatusBadge(label: _displayStatus(entry.stage), tone: _displayTone(entry.stage)),
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
