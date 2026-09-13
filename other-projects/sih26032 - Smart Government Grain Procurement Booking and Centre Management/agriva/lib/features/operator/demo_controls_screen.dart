import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/utils/list_extensions.dart';
import '../../data/seed_data_service.dart';
import '../../models/booking.dart';
import '../../models/enums.dart';
import '../../repositories/repository_providers.dart';
import '../../state/auth_controller.dart';
import '../../state/booking_controller.dart';
import '../../state/centre_admin_controller.dart';
import '../../state/demo_reset_controller.dart';
import '../../state/procurement_controller.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/alert_banner.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/max_width_body.dart';

class _Action {
  final String label;
  final Future<dynamic> Function() run;
  const _Action(this.label, this.run);
}

/// Internal control panel used only to drive a reliable, scripted demo.
/// Not part of the real farmer/operator experience.
class DemoControlsScreen extends ConsumerWidget {
  const DemoControlsScreen({super.key});

  Future<Booking?> _targetBooking(WidgetRef ref) async {
    final all = await ref
        .read(bookingRepositoryProvider)
        .forFarmer(palanisamyFarmerId);
    final active =
        all
            .where((b) => b.isActive && b.status != BookingStatus.waitlisted)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return active.firstOrNull ?? all.firstOrNull;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);

    return FutureBuilder<Booking?>(
      future: _targetBooking(ref),
      builder: (context, snapshot) {
        final targetBooking = snapshot.data;
        Future<String> noBooking() async => 'No active booking found for target farmer.';

        return FutureBuilder(
          future: ref.read(centreRepositoryProvider).getAll(),
          builder: (context, centresSnapshot) {
            final centres = centresSnapshot.data ?? const [];
            if (centres.isEmpty) return const SizedBox.shrink();
            final centreId = user?.centreId ?? centres.first.id;

            void run(Future<dynamic> Function() action) async {
              final result = await action();
              final message = result is String
                  ? result
                  : (result?.message ?? 'Done.');
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(message)));
              }
            }

            Widget section(String title, List<_Action> actions) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AgrivaColors.textSecondaryFor(context),
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
                    if (targetBooking != null)
                      Text(
                        'Target booking: ${targetBooking.id} (M. Palanisamy, Token ${targetBooking.token})',
                        style: TextStyle(
                          fontSize: 12,
                          color: AgrivaColors.textSecondaryFor(context),
                        ),
                      ),
                    const SizedBox(height: 12),

                    section('Disruption', [
                      _Action(
                        'Trigger Machine Failure',
                        () => ref
                            .read(centreAdminControllerProvider)
                            .declareDisruption(
                              centreId: centreId,
                              type: DisruptionType.weighingMachineFailure,
                              expectedResolution: DateTime.now().add(
                                const Duration(minutes: 75),
                              ),
                              affectedSlotIds: targetBooking == null
                                  ? []
                                  : [targetBooking.slotId],
                            ),
                      ),
                      _Action('Resolve Disruption', () async {
                        final active = await ref
                            .read(disruptionRepositoryProvider)
                            .activeForCentre(centreId);
                        if (active.isEmpty) {
                          return 'No active disruption to resolve.';
                        }
                        return ref
                            .read(centreAdminControllerProvider)
                            .resolveDisruption(active.first.id);
                      }),
                    ]),

                    section('Booking & Capacity', [
                      _Action(
                        'Cancel Target Slot',
                        () => targetBooking == null
                            ? noBooking()
                            : ref
                                  .read(bookingControllerProvider)
                                  .cancelBooking(targetBooking.id),
                      ),
                      _Action(
                        'Create Released Capacity',
                        () => ref
                            .read(bookingControllerProvider)
                            .offerReleasedCapacity(centreId),
                      ),
                    ]),

                    section('Queue & Procurement Stages', [
                      _Action(
                        'Mark Arrived',
                        () => targetBooking == null
                            ? noBooking()
                            : ref
                                  .read(bookingControllerProvider)
                                  .checkInFarmer(targetBooking.id),
                      ),
                      _Action(
                        'Move to Quality Inspection',
                        () => targetBooking == null
                            ? noBooking()
                            : ref
                                  .read(bookingControllerProvider)
                                  .moveQueueStage(
                                    targetBooking.id,
                                    QueueStage.qualityCheck,
                                  ),
                      ),
                      _Action(
                        'Move to Weighment',
                        () => targetBooking == null
                            ? noBooking()
                            : ref
                                  .read(bookingControllerProvider)
                                  .moveQueueStage(
                                    targetBooking.id,
                                    QueueStage.weighment,
                                  ),
                      ),
                    ]),

                    section('Quality & Weighment', [
                      _Action(
                        'Pass Quality (17.8% Moisture)',
                        () => targetBooking == null
                            ? noBooking()
                            : ref
                                  .read(procurementControllerProvider)
                                  .submitQualityCheck(
                                    bookingId: targetBooking.id,
                                    moisturePercent: 17.8,
                                    passed: true,
                                    inspector: 'K. Shanmugam',
                                  ),
                      ),
                      _Action(
                        'Reject Quality (High Moisture)',
                        () => targetBooking == null
                            ? noBooking()
                            : ref
                                  .read(procurementControllerProvider)
                                  .submitQualityCheck(
                                    bookingId: targetBooking.id,
                                    moisturePercent: 22.4,
                                    passed: false,
                                    rejectionReason: 'Moisture content exceeds 19% threshold',
                                    inspector: 'K. Shanmugam',
                                  ),
                      ),
                      _Action(
                        'Complete Weighment (43.5 Q)',
                        () => targetBooking == null
                            ? noBooking()
                            : ref
                                  .read(procurementControllerProvider)
                                  .submitWeighment(
                                    bookingId: targetBooking.id,
                                    weighedQuantityQ:
                                        (targetBooking.expectedQuantityQ - 1.5).clamp(
                                          0,
                                          100000,
                                        ),
                                    acceptedQuantityQ:
                                        (targetBooking.expectedQuantityQ - 1.5).clamp(
                                          0,
                                          100000,
                                        ),
                                    rejectedQuantityQ: 0,
                                    inspector: 'K. Shanmugam',
                                  ),
                      ),
                    ]),

                    section('DBT Payment Payout', [
                      _Action(
                        'Initiate DBT Payment',
                        () => targetBooking == null
                            ? noBooking()
                            : ref
                                  .read(procurementControllerProvider)
                                  .initiatePayment(targetBooking.id),
                      ),
                      _Action(
                        'Set Payment Completed (Disbursed)',
                        () => targetBooking == null
                            ? noBooking()
                            : ref
                                  .read(procurementControllerProvider)
                                  .updatePaymentStatus(
                                    targetBooking.id,
                                    PaymentStatus.completed,
                                  ),
                      ),
                      _Action(
                        'Set Payment Failed',
                        () => targetBooking == null
                            ? noBooking()
                            : ref
                                  .read(procurementControllerProvider)
                                  .updatePaymentStatus(
                                    targetBooking.id,
                                    PaymentStatus.failed,
                                    failureReason:
                                        'Bank server timeout during DBT clearing.',
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
                          await ref
                              .read(demoResetControllerProvider)
                              .resetDemo();
                          if (context.mounted) context.go('/login');
                        }
                      },
                      child: const Text('Reset Demo'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
