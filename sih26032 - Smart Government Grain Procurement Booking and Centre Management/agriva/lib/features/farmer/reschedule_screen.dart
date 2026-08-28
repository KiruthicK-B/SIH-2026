import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/utils/list_extensions.dart';
import '../../models/enums.dart';
import '../../models/reschedule_offer.dart';
import '../../providers/app_state_provider.dart';
import '../../services/rescheduler_service.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_states.dart';
import '../../widgets/max_width_body.dart';

class RescheduleScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const RescheduleScreen({super.key, required this.bookingId});

  @override
  ConsumerState<RescheduleScreen> createState() => _RescheduleScreenState();
}

class _RescheduleScreenState extends ConsumerState<RescheduleScreen> {
  String? _selectedSlotId;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final booking = appState.bookings
        .where((b) => b.id == widget.bookingId)
        .firstOrNull;

    if (booking == null) {
      return const Scaffold(
        body: MaxWidthBody(child: Center(child: Text('Booking not found.'))),
      );
    }

    final originalSlot = appState.slots.firstWhere(
      (s) => s.id == booking.slotId,
    );
    final centre = appState.centres.firstWhere((c) => c.id == booking.centreId);
    final offer = appState.rescheduleOffers
        .where(
          (o) =>
              o.bookingId == widget.bookingId &&
              o.status == RescheduleOfferStatus.pending,
        )
        .firstOrNull;
    final candidates = ref
        .read(appStateProvider.notifier)
        .replacementSlotsFor(widget.bookingId);

    _selectedSlotId ??= candidates.firstOrNull?.recommendation.slot.id;

    return Scaffold(
      appBar: const AgrivaAppBar(title: 'Reschedule Slot'),
      body: booking.status != BookingStatus.rescheduleRequired
          ? const EmptyState(
              icon: Icons.event_available_outlined,
              title: 'No reschedule needed',
              message: 'This booking does not currently require rescheduling.',
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'Current Booking',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AgrivaColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AgrivaColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${DateFormat('d MMM yyyy').format(originalSlot.start)}, ${DateFormat('h:mm a').format(originalSlot.start)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              centre.name,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AgrivaColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${booking.expectedQuantityQ.toStringAsFixed(0)} Quintals',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AgrivaColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Reason: ${offer?.reason ?? 'Centre disruption'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AgrivaColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Select New Slot',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (candidates.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'No feasible replacement is currently available. You have been moved to Reschedule Required. We will show the next available option as soon as one opens up.',
                            style: TextStyle(color: AgrivaColors.textSecondary),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AgrivaColors.border),
                          ),
                          child: Column(
                            children: [
                              for (var i = 0; i < candidates.length; i++)
                                _CandidateRow(
                                  candidate: candidates[i],
                                  selected:
                                      _selectedSlotId ==
                                      candidates[i].recommendation.slot.id,
                                  isLast: i == candidates.length - 1,
                                  onTap: () => setState(
                                    () => _selectedSlotId =
                                        candidates[i].recommendation.slot.id,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (candidates.isNotEmpty)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: PrimaryButton(
                        label: 'Confirm Reschedule',
                        loading: _submitting,
                        onPressed: _selectedSlotId == null
                            ? null
                            : () async {
                                setState(() => _submitting = true);
                                final result = ref
                                    .read(appStateProvider.notifier)
                                    .acceptSpecificSlot(
                                      widget.bookingId,
                                      _selectedSlotId!,
                                      offer?.reason ?? 'Centre disruption',
                                    );
                                setState(() => _submitting = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(result.message)),
                                  );
                                  if (result.success) context.pop();
                                }
                              },
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _CandidateRow extends StatelessWidget {
  final RescheduleCandidate candidate;
  final bool selected;
  final bool isLast;
  final VoidCallback onTap;

  const _CandidateRow({
    required this.candidate,
    required this.selected,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rec = candidate.recommendation;
    final slot = rec.slot;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AgrivaColors.primaryLight.withValues(alpha: 0.5)
              : null,
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: AgrivaColors.border)),
        ),
        child: Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: selected ? true : null,
              onChanged: (_) => onTap(),
              activeColor: AgrivaColors.primary,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${candidate.isSameDay ? DateFormat('d MMM').format(slot.start) : 'Tomorrow'}, ${DateFormat('h:mm a').format(slot.start)} – ${DateFormat('h:mm a').format(slot.end)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${rec.remainingFarmerSlots}/${slot.maxFarmers} available',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AgrivaColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (rec.isRecommended)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AgrivaColors.successBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'RECOMMENDED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AgrivaColors.success,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
