import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/utils/status_mapper.dart';
import '../../models/enums.dart';
import '../../state/auth_controller.dart';
import '../../state/booking_controller.dart';
import '../../state/procurement_controller.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/app_states.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/max_width_body.dart';

class PaymentsListScreen extends ConsumerWidget {
  const PaymentsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final centreId = user?.centreId;
    if (centreId == null || centreId.isEmpty) return const SizedBox.shrink();
    final paymentsAsync = ref.watch(paymentsForCentreProvider(centreId));

    return Scaffold(
      appBar: const AgrivaAppBar(title: 'Payments'),
      body: MaxWidthBody(
        child: paymentsAsync.when(
          loading: () => const LoadingState(),
          error: (e, st) => const ErrorState(),
          data: (payments) {
            if (payments.isEmpty) {
              return const EmptyState(
                icon: Icons.payments_outlined,
                title: 'No payments yet',
                message: 'Payments appear once procurement is completed.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: payments.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final p = payments[i];
                final bookingAsync = ref.watch(bookingByIdProvider(p.bookingId));
                final booking = bookingAsync.value;
                final farmerAsync = booking == null ? null : ref.watch(farmerByIdProvider(booking.farmerId));
                final farmer = farmerAsync?.value;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AgrivaColors.surfaceFor(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AgrivaColors.borderFor(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              '${p.bookingId} · ${farmer?.name ?? '—'}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(label: p.status.label, tone: toneForPaymentStatus(p.status)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${p.amount.toStringAsFixed(0)} · Updated ${DateFormat('d MMM, h:mm a').format(p.lastUpdated)}',
                        style: TextStyle(fontSize: 12, color: AgrivaColors.textSecondaryFor(context)),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _ActionChip(
                            label: 'Initiate',
                            onTap: () => ref.read(procurementControllerProvider).initiatePayment(p.bookingId),
                          ),
                          _ActionChip(
                            label: 'Processing',
                            onTap: () => ref
                                .read(procurementControllerProvider)
                                .updatePaymentStatus(p.bookingId, PaymentStatus.processing),
                          ),
                          _ActionChip(
                            label: 'Mark Completed',
                            onTap: () => ref
                                .read(procurementControllerProvider)
                                .updatePaymentStatus(p.bookingId, PaymentStatus.completed),
                          ),
                          _ActionChip(
                            label: 'Mark Failed',
                            onTap: () => ref.read(procurementControllerProvider).updatePaymentStatus(
                                  p.bookingId,
                                  PaymentStatus.failed,
                                  failureReason: 'Transaction could not be completed.',
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ActionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11.5)),
      onPressed: onTap,
      backgroundColor: AgrivaColors.inactiveBg,
      visualDensity: VisualDensity.compact,
    );
  }
}
