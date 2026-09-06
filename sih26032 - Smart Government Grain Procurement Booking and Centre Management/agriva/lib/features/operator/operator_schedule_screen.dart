import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/utils/status_mapper.dart';
import '../../models/booking.dart';
import '../../models/enums.dart';
import '../../models/farmer.dart';
import '../../models/slot.dart';
import '../../repositories/repository_providers.dart';
import '../../state/auth_controller.dart';
import '../../state/booking_controller.dart';
import '../../state/data_revision.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/app_states.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/max_width_body.dart';

class _ScheduleRow {
  final Booking booking;
  final Slot slot;
  final Farmer farmer;
  const _ScheduleRow({required this.booking, required this.slot, required this.farmer});
}

final _todayScheduleProvider = FutureProvider.family<List<_ScheduleRow>, String>((
  ref,
  centreId,
) async {
  ref.watch(dataRevisionProvider);
  final today = DateTime.now();
  final todaySlots = await ref.read(slotRepositoryProvider).forCentreAndDate(centreId, today);
  final todaySlotById = {for (final s in todaySlots) s.id: s};
  final bookings = await ref.read(bookingRepositoryProvider).forCentre(centreId);
  final rows = <_ScheduleRow>[];
  for (final b in bookings) {
    final slot = todaySlotById[b.slotId];
    if (slot == null) continue;
    final farmer = await ref.read(farmerRepositoryProvider).getById(b.farmerId);
    if (farmer == null) continue;
    rows.add(_ScheduleRow(booking: b, slot: slot, farmer: farmer));
  }
  rows.sort((a, b) => a.slot.start.compareTo(b.slot.start));
  return rows;
});

class OperatorScheduleScreen extends ConsumerWidget {
  const OperatorScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final allCentresAsync = ref.watch(centresProvider);
    final allCentres = allCentresAsync.value ?? const [];
    final userCentre = user?.centreId;
    final centreId = (userCentre != null && userCentre.isNotEmpty)
        ? userCentre
        : (allCentres.isNotEmpty ? allCentres.first.id : 'centre-erode-01');
    final rowsAsync = ref.watch(_todayScheduleProvider(centreId));

    return Scaffold(
      appBar: const AgrivaAppBar(title: "Today's Bookings"),
      body: MaxWidthBody(
        child: rowsAsync.when(
          loading: () => const LoadingState(),
          error: (e, st) => const ErrorState(),
          data: (rows) {
            if (rows.isEmpty) {
              return const EmptyState(
                icon: Icons.event_busy_outlined,
                title: 'No bookings today',
                message: 'Bookings for today will appear here.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final row = rows[i];
                final canCheckIn = row.booking.status == BookingStatus.booked;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                          DateFormat('h:mm a').format(row.slot.start),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(row.farmer.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                            Text(
                              '${row.booking.token} · ${row.booking.expectedQuantityQ.toStringAsFixed(0)} Q',
                              style: const TextStyle(fontSize: 12, color: AgrivaColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (canCheckIn)
                        TextButton(
                          onPressed: () => context.push('/operator/checkin/${row.booking.id}'),
                          child: const Text('Check In'),
                        )
                      else
                        StatusBadge(label: row.booking.status.label, tone: toneForBookingStatus(row.booking.status)),
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
