import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/utils/status_mapper.dart';
import '../../models/booking.dart';
import '../../models/centre.dart';
import '../../models/enums.dart';
import '../../models/slot.dart';
import '../../repositories/repository_providers.dart';
import '../../services/capacity_service.dart';
import '../../state/auth_controller.dart';
import '../../state/booking_controller.dart';
import '../../state/data_revision.dart';
import 'manage_capacity_dialog.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/app_states.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/max_width_body.dart';

const _capacity = CapacityService();

class _DashboardData {
  final List<Slot> todaySlots;
  final List<Booking> todayBookings;
  const _DashboardData({required this.todaySlots, required this.todayBookings});
}

final _dashboardDataProvider = FutureProvider.family<_DashboardData, String>((
  ref,
  centreId,
) async {
  ref.watch(dataRevisionProvider);
  final today = DateTime.now();
  final allSlots = await ref.read(slotRepositoryProvider).forCentre(centreId);
  final todayDay = DateTime(today.year, today.month, today.day);
  var todaySlots = allSlots.where((s) => s.date == todayDay).toList()
    ..sort((a, b) => a.start.compareTo(b.start));
  if (todaySlots.isEmpty && allSlots.isNotEmpty) {
    todaySlots = allSlots.take(9).toList()..sort((a, b) => a.start.compareTo(b.start));
  }
  final todaySlotIds = todaySlots.map((s) => s.id).toSet();
  final centreBookings = await ref.read(bookingRepositoryProvider).forCentre(centreId);
  final todayBookings = centreBookings
      .where((b) => todaySlotIds.contains(b.slotId) && b.status != BookingStatus.cancelled)
      .toList();
  return _DashboardData(todaySlots: todaySlots, todayBookings: todayBookings);
});

class OperatorDashboardScreen extends ConsumerWidget {
  const OperatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final allCentresAsync = ref.watch(centresProvider);
    final allCentres = allCentresAsync.value ?? const [];
    final userCentre = user?.centreId;
    final centreId = (userCentre != null && userCentre.isNotEmpty)
        ? userCentre
        : (allCentres.isNotEmpty ? allCentres.first.id : 'centre-erode-01');

    final centreAsync = ref.watch(centreByIdProvider(centreId));
    final dataAsync = ref.watch(_dashboardDataProvider(centreId));
    final today = DateTime.now();

    final centre = centreAsync.value ??
        allCentres.where((c) => c.id == centreId).firstOrNull ??
        allCentres.firstOrNull ??
        ProcurementCentre(
          id: centreId,
          name: 'Erode Regulated Market Hub',
          code: 'OP-Erode-01',
          district: 'district-erode',
          taluk: 'Erode Rural',
          status: CentreStatus.open,
          dailyProcessingCapacityQ: 1500,
          storageCapacityQ: 2000,
          currentStorageQ: 750,
          processingLanesTotal: 3,
          processingLanesActive: 3,
          staffNormal: 14,
          staffAvailable: 14,
        );

    return Scaffold(
      appBar: AgrivaAppBar(
        title: centre.name,
        subtitle: 'Centre Operator (${user?.name ?? 'K. Shanmugam'})',
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () => showAgrivaSignOutDialog(context, ref),
          ),
        ],
      ),
      body: MaxWidthBody(
        child: dataAsync.when(
          loading: () => const LoadingState(message: 'Loading centre operations...'),
          error: (e, st) => const ErrorState(),
          data: (data) {
                final totalBookingsToday = data.todayBookings.length;
                final completedToday = data.todayBookings
                    .where((b) => b.status == BookingStatus.paymentCompleted || b.status == BookingStatus.accepted)
                    .length;
                final inProgressToday = data.todayBookings
                    .where(
                      (b) =>
                          b.status == BookingStatus.checkedIn ||
                          b.status == BookingStatus.inQueue ||
                          b.status == BookingStatus.underQualityCheck,
                    )
                    .length;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        StatusBadge(label: centre.status.label, tone: toneForCentreStatus(centre.status)),
                        const Spacer(),
                        Text(
                          DateFormat('d MMM yyyy').format(today),
                          style: const TextStyle(fontSize: 12, color: AgrivaColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Today Overview', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: MetricCard(icon: Icons.event_note_outlined, label: 'Total Bookings', value: '$totalBookingsToday'),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: MetricCard(
                            icon: Icons.check_circle_outline,
                            label: 'Completed',
                            value: '$completedToday',
                            accent: AgrivaColors.success,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: MetricCard(
                            icon: Icons.hourglass_top_outlined,
                            label: 'In Progress',
                            value: '$inProgressToday',
                            accent: AgrivaColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Quick Centre Management Actions
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => context.push('/operator/verifications'),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AgrivaColors.primaryLight50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AgrivaColors.border),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.verified_user_outlined, color: AgrivaColors.primary, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Farmer Approvals', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                        Text('Verify registered farmers', style: TextStyle(fontSize: 10.5, color: AgrivaColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AgrivaColors.primary),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => ManageCapacityDialog.show(context, centre),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8E1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AgrivaColors.gold.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.tune_rounded, color: AgrivaColors.gold, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Centre Capacity', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF8D6E63))),
                                        Text('Edit daily & slot quota', style: TextStyle(fontSize: 10.5, color: AgrivaColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.edit_rounded, size: 12, color: Color(0xFF8D6E63)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Today's Schedule", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        TextButton(
                          onPressed: () => context.push('/operator/disruption'),
                          child: const Text('Declare Disruption'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AgrivaColors.border),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < data.todaySlots.length; i++)
                            _ScheduleRow(
                              slot: data.todaySlots[i],
                              isLast: i == data.todaySlots.length - 1,
                              now: today,
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
  }
}

class _ScheduleRow extends ConsumerWidget {
  final Slot slot;
  final bool isLast;
  final DateTime now;
  const _ScheduleRow({required this.slot, required this.isLast, required this.now});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingsForCentreProvider(slot.centreId));
    final bookings = (bookingsAsync.value ?? const []).where((b) => b.slotId == slot.id).toList();
    final booked = _capacity.bookedFarmersForSlot(slot, bookings);
    final bookedQ = _capacity.bookedQuantityForSlot(slot, bookings);

    final label = now.isAfter(slot.end)
        ? 'Completed'
        : now.isBefore(slot.start)
            ? 'Upcoming'
            : 'In Progress';
    final tone = label == 'Completed'
        ? StatusTone.success
        : label == 'In Progress'
            ? StatusTone.warning
            : StatusTone.inactive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AgrivaColors.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '${DateFormat('h a').format(slot.start)}–${DateFormat('h a').format(slot.end)}',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text('$booked/${slot.maxFarmers}', style: const TextStyle(fontSize: 12.5, color: AgrivaColors.textSecondary)),
          ),
          Expanded(
            child: Text('${bookedQ.toStringAsFixed(0)} Q', style: const TextStyle(fontSize: 12.5, color: AgrivaColors.textSecondary)),
          ),
          StatusBadge(label: label, tone: tone),
        ],
      ),
    );
  }
}
