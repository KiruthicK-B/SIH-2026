import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/app_state.dart';
import '../../core/utils/list_extensions.dart';
import '../../data/demo_users.dart';
import '../../models/booking.dart';
import '../../models/enums.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/alert_banner.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/max_width_body.dart';

class _Action {
  final String label;
  final OpResult Function() run;
  const _Action(this.label, this.run);
}

/// Internal control panel used only to drive a reliable, scripted demo.
/// Not part of the real farmer/operator experience.
class DemoControlsScreen extends ConsumerWidget {
  const DemoControlsScreen({super.key});

  Booking? _raviBooking(AgrivaAppState state) {
    final active =
        state.bookings
            .where(
              (b) =>
                  b.farmerId == raviFarmerId &&
                  b.isActive &&
                  b.status != BookingStatus.waitlisted,
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return active.firstOrNull ??
        state.bookings.where((b) => b.farmerId == raviFarmerId).firstOrNull;
  }

  static const _noBooking = OpResult(false, 'No active booking for Ravi.');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final ravi = _raviBooking(appState);
    final centreId =
        appState.currentUser?.centreId ?? appState.centres.first.id;

    void run(OpResult Function() action) {
      final result = action();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    }

    Widget section(String title, List<_Action> actions) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AgrivaColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions
                  .map(
                    (a) => OutlinedButton(
                      onPressed: () => run(a.run),
                      child: Text(
                        a.label,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: const AgrivaAppBar(title: 'Demo Controls'),
      body: MaxWidthBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const AlertBanner(
              title: 'For demonstration only',
              message:
                  'These controls simulate real-world events for a reliable walkthrough. Not part of the live product.',
              tone: StatusTone.info,
            ),
            const SizedBox(height: 16),
            if (ravi != null)
              Text(
                'Target booking: ${ravi.id} (Ravi Kumar, Token ${ravi.token})',
                style: const TextStyle(
                  fontSize: 12,
                  color: AgrivaColors.textSecondary,
                ),
              ),
            const SizedBox(height: 12),

            section('Disruption', [
              _Action(
                'Trigger Machine Failure',
                () => notifier.declareDisruption(
                  centreId: centreId,
                  type: DisruptionType.weighingMachineFailure,
                  expectedResolution: DateTime.now().add(
                    const Duration(minutes: 75),
                  ),
                  affectedSlotIds: ravi == null ? [] : [ravi.slotId],
                ),
              ),
              _Action('Resolve Disruption', () {
                final active = appState.disruptions
                    .where(
                      (d) =>
                          d.centreId == centreId &&
                          d.status == DisruptionStatus.active,
                    )
                    .toList();
                if (active.isEmpty)
                  return const OpResult(
                    false,
                    'No active disruption to resolve.',
                  );
                return notifier.resolveDisruption(active.first.id);
              }),
            ]),

            section('Booking & Capacity', [
              _Action(
                'Cancel Ravi Slot',
                () =>
                    ravi == null ? _noBooking : notifier.cancelBooking(ravi.id),
              ),
              _Action(
                'Create Released Capacity',
                () => notifier.offerReleasedCapacity(centreId),
              ),
            ]),

            section('Queue', [
              _Action(
                'Mark Ravi Arrived',
                () =>
                    ravi == null ? _noBooking : notifier.checkInFarmer(ravi.id),
              ),
              _Action(
                'Move Ravi to Quality',
                () => ravi == null
                    ? _noBooking
                    : notifier.moveQueueStage(ravi.id, QueueStage.qualityCheck),
              ),
              _Action(
                'Advance Queue',
                () => ravi == null
                    ? _noBooking
                    : notifier.moveQueueStage(ravi.id, QueueStage.weighment),
              ),
            ]),

            section('Quality & Weighment', [
              _Action(
                'Pass Quality',
                () => ravi == null
                    ? _noBooking
                    : notifier.submitInspection(
                        bookingId: ravi.id,
                        moisturePercent: 17.8,
                        result: InspectionStatus.passed,
                        inspector: 'Suresh Babu',
                      ),
              ),
              _Action(
                'Reject Quality',
                () => ravi == null
                    ? _noBooking
                    : notifier.submitInspection(
                        bookingId: ravi.id,
                        moisturePercent: 22.4,
                        result: InspectionStatus.notAccepted,
                        reason: 'Below quality standard',
                        inspector: 'Suresh Babu',
                      ),
              ),
              _Action(
                'Set Actual Weight (48.5 Q)',
                () => ravi == null
                    ? _noBooking
                    : notifier.submitWeighment(
                        bookingId: ravi.id,
                        actualQuantityQ: (ravi.expectedQuantityQ - 1.5).clamp(
                          0,
                          100000,
                        ),
                      ),
              ),
              _Action(
                'Complete Procurement',
                () => ravi == null
                    ? _noBooking
                    : notifier.confirmExcessWeighment(ravi.id),
              ),
            ]),

            section('Payment', [
              _Action(
                'Set Payment Pending',
                () => ravi == null
                    ? _noBooking
                    : notifier.updatePaymentStatus(
                        ravi.id,
                        PaymentStatus.pending,
                      ),
              ),
              _Action(
                'Set Payment Paid',
                () => ravi == null
                    ? _noBooking
                    : notifier.updatePaymentStatus(ravi.id, PaymentStatus.paid),
              ),
              _Action(
                'Set Payment Failed',
                () => ravi == null
                    ? _noBooking
                    : notifier.updatePaymentStatus(
                        ravi.id,
                        PaymentStatus.failed,
                        failureReason: 'Transaction could not be completed.',
                      ),
              ),
            ]),

            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade300),
              ),
              onPressed: () async {
                final confirmed = await showConfirmDialog(
                  context,
                  title: 'Reset Demo?',
                  message: 'This restores the original demo state.',
                  confirmLabel: 'Reset',
                  destructive: true,
                );
                if (confirmed) {
                  await notifier.resetDemo();
                  if (context.mounted) context.go('/role-select');
                }
              },
              child: const Text('Reset Demo'),
            ),
          ],
        ),
      ),
    );
  }
}
