import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/utils/status_mapper.dart';
import '../../models/enums.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/app_states.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/max_width_body.dart';

class OperatorScheduleScreen extends ConsumerWidget {
  const OperatorScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final centreId = appState.currentUser!.centreId!;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final bookings =
        appState.bookings.where((b) {
          if (b.centreId != centreId) return false;
          final slot = appState.slots.firstWhere((s) => s.id == b.slotId);
          return slot.date == todayDate;
        }).toList()..sort((a, b) {
          final sa = appState.slots.firstWhere((s) => s.id == a.slotId).start;
          final sb = appState.slots.firstWhere((s) => s.id == b.slotId).start;
          return sa.compareTo(sb);
        });

    return Scaffold(
      appBar: const AgrivaAppBar(title: "Today's Bookings"),
      body: MaxWidthBody(
        child: bookings.isEmpty
            ? const EmptyState(
                icon: Icons.event_busy_outlined,
                title: 'No bookings today',
                message: 'Bookings for today will appear here.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: bookings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final b = bookings[i];
                  final slot = appState.slots.firstWhere(
                    (s) => s.id == b.slotId,
                  );
                  final farmer = appState.farmers.firstWhere(
                    (f) => f.id == b.farmerId,
                  );
                  final canCheckIn = b.status == BookingStatus.confirmed;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AgrivaColors.border),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 56,
                          child: Text(
                            DateFormat('h:mm a').format(slot.start),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                farmer.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                ),
                              ),
                              Text(
                                '${b.token} · ${b.expectedQuantityQ.toStringAsFixed(0)} Q',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AgrivaColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (canCheckIn)
                          TextButton(
                            onPressed: () =>
                                context.push('/operator/checkin/${b.id}'),
                            child: const Text('Check In'),
                          )
                        else
                          StatusBadge(
                            label: b.status.label,
                            tone: toneForBookingStatus(b.status),
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
