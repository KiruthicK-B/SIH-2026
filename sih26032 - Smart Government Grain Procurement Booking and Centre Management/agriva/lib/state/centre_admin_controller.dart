import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/disruption.dart';
import '../models/enums.dart';
import '../models/notification.dart';
import '../models/reschedule_offer.dart';
import '../repositories/booking_repositories.dart';
import '../repositories/catalog_repositories.dart';
import '../repositories/repository_providers.dart';
import '../services/rescheduler_service.dart';
import 'data_revision.dart';
import 'op_result.dart';

final disruptionsForCentreProvider =
    FutureProvider.family<List<Disruption>, String>((ref, centreId) {
      ref.watch(dataRevisionProvider);
      return ref.read(disruptionRepositoryProvider).forCentre(centreId);
    });

final centreAdminControllerProvider = Provider<CentreAdminController>(
  (ref) => CentreAdminController(ref),
);

/// Operator + District Admin centre-management actions: disruptions,
/// manual capacity adjustment, centre CRUD, bulk closure (README §5.2/§5.3).
class CentreAdminController {
  final Ref ref;
  static const _rescheduler = ReschedulerService();

  const CentreAdminController(this.ref);

  CentreRepository get _centreRepo => ref.read(centreRepositoryProvider);
  BookingRepository get _bookingRepo => ref.read(bookingRepositoryProvider);
  DisruptionRepository get _disruptionRepo =>
      ref.read(disruptionRepositoryProvider);
  RescheduleOfferRepository get _offerRepo =>
      ref.read(rescheduleOfferRepositoryProvider);

  void _bump() => ref.read(dataRevisionProvider.notifier).bump();

  Future<void> _notify(
    String userId,
    String title,
    String message,
    NotificationType type,
  ) => ref.read(notificationRepositoryProvider).save(
    NotificationItem(
      id: 'ntf-${DateTime.now().microsecondsSinceEpoch}',
      userId: userId,
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: type,
    ),
  );

  Future<OpResult> declareDisruption({
    required String centreId,
    required DisruptionType type,
    required DateTime expectedResolution,
    List<String> affectedSlotIds = const [],
  }) async {
    final centre = await _centreRepo.getById(centreId);
    if (centre == null) return const OpResult(false, 'Centre not found.');

    final disruption = Disruption(
      id: 'disr-${DateTime.now().microsecondsSinceEpoch}',
      centreId: centreId,
      type: type,
      start: DateTime.now(),
      expectedResolution: expectedResolution,
      status: DisruptionStatus.active,
      affectedSlotIds: affectedSlotIds,
      affectedProcessingLanes:
          type == DisruptionType.weighingMachineFailure ||
                  type == DisruptionType.powerFailure
              ? 1
              : 0,
    );
    await _disruptionRepo.save(disruption);

    final newStatus = type == DisruptionType.centreClosure
        ? CentreStatus.closed
        : CentreStatus.temporarilyDisrupted;
    final newLanes = (centre.processingLanesActive -
            disruption.affectedProcessingLanes)
        .clamp(0, centre.processingLanesTotal);
    final newStaff = type == DisruptionType.labourShortage
        ? (centre.staffAvailable * 0.6).round()
        : centre.staffAvailable;

    final updatedCentre = centre.copyWith(
      status: newStatus,
      processingLanesActive: newLanes,
      staffAvailable: newStaff,
    );
    await _centreRepo.save(updatedCentre);

    final centreBookings = await _bookingRepo.forCentre(centreId);
    const activeStatuses = [
      BookingStatus.booked,
      BookingStatus.checkedIn,
      BookingStatus.inQueue,
    ];
    final affected = centreBookings
        .where(
          (b) =>
              affectedSlotIds.contains(b.slotId) &&
              activeStatuses.contains(b.status),
        )
        .toList();

    for (final booking in affected) {
      await _bookingRepo.save(
        booking.copyWith(status: BookingStatus.rescheduleRequired),
      );
      await _notify(
        booking.farmerId,
        'Centre Delay',
        'Procurement at ${centre.name} is delayed due to ${type.label.toLowerCase()}.',
        NotificationType.delay,
      );

      final farmer = await ref
          .read(farmerRepositoryProvider)
          .getById(booking.farmerId);
      if (farmer == null) continue;
      final slots = await ref
          .read(slotRepositoryProvider)
          .forCentre(centreId);
      final disruptions = await _disruptionRepo.forCentre(centreId);
      final options = _rescheduler.findReplacementSlots(
        farmer: farmer,
        centre: updatedCentre,
        expectedQuantityQ: booking.expectedQuantityQ,
        slots: slots,
        bookings: centreBookings,
        disruptions: disruptions,
        now: DateTime.now(),
      );
      if (options.isNotEmpty) {
        final best = options.first.recommendation.slot;
        await _offerRepo.save(
          RescheduleOffer(
            id: 'offer-${DateTime.now().microsecondsSinceEpoch}-${booking.id}',
            bookingId: booking.id,
            originalSlotId: booking.slotId,
            offeredSlotId: best.id,
            reason: type.label,
            status: RescheduleOfferStatus.pending,
            createdAt: DateTime.now(),
          ),
        );
        await _notify(
          booking.farmerId,
          'Reschedule Required',
          'Your original slot is affected. We recommend a new slot — review and accept in Reschedule.',
          NotificationType.rescheduleRequired,
        );
      }
    }

    _bump();
    return OpResult(
      true,
      '${centre.name} is now ${newStatus.label}. ${affected.length} farmer(s) affected.',
    );
  }

  Future<OpResult> resolveDisruption(String disruptionId) async {
    final disruption = await _disruptionRepo.getById(disruptionId);
    if (disruption == null) {
      return const OpResult(false, 'Disruption not found.');
    }
    await _disruptionRepo.save(
      disruption.copyWith(
        status: DisruptionStatus.resolved,
        actualResolution: DateTime.now(),
      ),
    );
    final remaining = await _disruptionRepo.activeForCentre(disruption.centreId);
    if (remaining.isEmpty) {
      final centre = await _centreRepo.getById(disruption.centreId);
      if (centre != null) {
        await _centreRepo.save(
          centre.copyWith(
            status: CentreStatus.open,
            processingLanesActive: centre.processingLanesTotal,
            staffAvailable: centre.staffNormal,
          ),
        );
      }
    }
    _bump();
    return const OpResult(true, 'Disruption resolved. Centre status updated.');
  }

  /// README §5.2 "mark closed" — bulk cancel + bulk notify every farmer
  /// with an active booking today.
  Future<OpResult> markCentreClosedForDay(String centreId, String reason) async {
    final centre = await _centreRepo.getById(centreId);
    if (centre == null) return const OpResult(false, 'Centre not found.');
    await _centreRepo.save(centre.copyWith(status: CentreStatus.closed));

    final bookings = await _bookingRepo.forCentre(centreId);
    var affectedCount = 0;
    for (final booking in bookings) {
      if (!booking.isActive || booking.status == BookingStatus.waitlisted) {
        continue;
      }
      await _bookingRepo.save(
        booking.copyWith(status: BookingStatus.cancelled, cancelledAt: DateTime.now()),
      );
      await _notify(
        booking.farmerId,
        'Centre Closed Today',
        '${centre.name} is closed today: $reason. Your booking has been cancelled — please rebook.',
        NotificationType.delay,
      );
      affectedCount++;
    }
    _bump();
    return OpResult(true, '$affectedCount booking(s) cancelled and farmers notified.');
  }

  /// Manual capacity adjustment (storage full, truck delay). If the new
  /// capacity can no longer cover bookings already made against today's
  /// slots, every affected farmer gets a reschedule offer — never a silent
  /// booking failure (README §5.2, §7 "Sudden capacity drop").
  Future<OpResult> adjustDailyCapacity(
    String centreId,
    double newDailyProcessingCapacityQ,
  ) async {
    final centre = await _centreRepo.getById(centreId);
    if (centre == null) return const OpResult(false, 'Centre not found.');
    final reduced = newDailyProcessingCapacityQ < centre.dailyProcessingCapacityQ;
    await _centreRepo.save(
      centre.copyWith(dailyProcessingCapacityQ: newDailyProcessingCapacityQ),
    );

    if (!reduced) {
      _bump();
      return const OpResult(true, 'Capacity updated.');
    }

    final today = DateTime.now();
    final slots = await ref.read(slotRepositoryProvider).forCentreAndDate(
      centreId,
      today,
    );
    final todaySlotIds = slots.map((s) => s.id).toSet();
    final centreBookings = await _bookingRepo.forCentre(centreId);
    const activeStatuses = [
      BookingStatus.booked,
      BookingStatus.checkedIn,
      BookingStatus.inQueue,
    ];
    final atRisk = centreBookings.where(
      (b) => todaySlotIds.contains(b.slotId) && activeStatuses.contains(b.status),
    );

    var offeredCount = 0;
    for (final booking in atRisk) {
      final farmer = await ref
          .read(farmerRepositoryProvider)
          .getById(booking.farmerId);
      if (farmer == null) continue;
      final updatedCentre = centre.copyWith(
        dailyProcessingCapacityQ: newDailyProcessingCapacityQ,
      );
      final disruptions = await _disruptionRepo.forCentre(centreId);
      final options = _rescheduler.findReplacementSlots(
        farmer: farmer,
        centre: updatedCentre,
        expectedQuantityQ: booking.expectedQuantityQ,
        slots: slots,
        bookings: centreBookings,
        disruptions: disruptions,
        now: today,
      );
      if (options.isEmpty) continue;
      await _bookingRepo.save(
        booking.copyWith(status: BookingStatus.rescheduleRequired),
      );
      await _offerRepo.save(
        RescheduleOffer(
          id: 'offer-${DateTime.now().microsecondsSinceEpoch}-${booking.id}',
          bookingId: booking.id,
          originalSlotId: booking.slotId,
          offeredSlotId: options.first.recommendation.slot.id,
          reason: 'Centre capacity was reduced',
          status: RescheduleOfferStatus.pending,
          createdAt: DateTime.now(),
        ),
      );
      await _notify(
        booking.farmerId,
        'Reschedule Required',
        'Centre capacity was reduced — we found you a new slot. Please review and accept.',
        NotificationType.rescheduleRequired,
      );
      offeredCount++;
    }
    _bump();
    return OpResult(
      true,
      'Capacity updated. $offeredCount farmer(s) offered a replacement slot.',
    );
  }
}
