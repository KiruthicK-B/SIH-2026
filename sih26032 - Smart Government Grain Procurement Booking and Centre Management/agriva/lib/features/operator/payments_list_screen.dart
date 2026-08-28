import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/utils/status_mapper.dart';
import '../../models/enums.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/app_states.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/max_width_body.dart';

class PaymentsListScreen extends ConsumerWidget {
  const PaymentsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final centreId = appState.currentUser!.centreId!;
    final centreBookingIds = appState.bookings
        .where((b) => b.centreId == centreId)
        .map((b) => b.id)
        .toSet();

    final payments =
        appState.payments
            .where((p) => centreBookingIds.contains(p.bookingId))
            .toList()
          ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

    return Scaffold(
      appBar: const AgrivaAppBar(title: 'Payments'),
      body: MaxWidthBody(
        child: payments.isEmpty
            ? const EmptyState(
                icon: Icons.payments_outlined,
                title: 'No payments yet',
                message: 'Payments appear once procurement is completed.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: payments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final p = payments[i];
                  final booking = appState.bookings.firstWhere(
                    (b) => b.id == p.bookingId,
                  );
                  final farmer = appState.farmers.firstWhere(
                    (f) => f.id == booking.farmerId,
                  );

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AgrivaColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${booking.id} · ${farmer.name}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                            StatusBadge(
                              label: p.status.label,
                              tone: toneForPaymentStatus(p.status),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${p.amount.toStringAsFixed(0)} · Updated ${DateFormat('d MMM, h:mm a').format(p.lastUpdated)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AgrivaColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            _ActionChip(
                              label: 'Processing',
                              onTap: () => notifier.updatePaymentStatus(
                                p.bookingId,
                                PaymentStatus.processing,
                              ),
                            ),
                            _ActionChip(
                              label: 'Pending',
                              onTap: () => notifier.updatePaymentStatus(
                                p.bookingId,
                                PaymentStatus.pending,
                              ),
                            ),
                            _ActionChip(
                              label: 'Mark Paid',
                              onTap: () => notifier.updatePaymentStatus(
                                p.bookingId,
                                PaymentStatus.paid,
                              ),
                            ),
                            _ActionChip(
                              label: 'Mark Failed',
                              onTap: () => notifier.updatePaymentStatus(
                                p.bookingId,
                                PaymentStatus.failed,
                                failureReason:
                                    'Transaction could not be completed.',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
