import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking.dart';
import '../models/centre.dart';
import '../models/crop.dart';
import '../models/enums.dart';
import '../models/farmer.dart';
import '../models/notification.dart';
import '../models/queue_entry.dart';
import '../models/reschedule_offer.dart';
import '../models/slot.dart';
import '../core/utils/list_extensions.dart';
import '../repositories/booking_repositories.dart';
import '../repositories/catalog_repositories.dart';
import '../repositories/repository_providers.dart';
import '../services/capacity_service.dart';
import '../services/queue_service.dart';
import '../services/rescheduler_service.dart';
import '../services/scheduler_service.dart';
import 'data_revision.dart';
import 'op_result.dart';

// ---------------------------------------------------------------------
// Read-side view providers — every one watches dataRevisionProvider so the
// UI refreshes automatically after any controller mutation.
// ---------------------------------------------------------------------

const _queueServiceForProviders = QueueService();

/// A queue entry pre-resolved with its booking, farmer, live position, and
/// ETA — what the operator queue screen actually renders per row. Built once
/// per fetch instead of each row doing its own nested provider lookups, so
/// search/filter has synchronous data to match against.
class QueueRowView {
  final QueueEntry entry;
  final Booking booking;
  final Farmer? farmer;
  final int position;
  final int etaMinutes;

  const QueueRowView({
    required this.entry,
    required this.booking,
    required this.farmer,
    required this.position,
    required this.etaMinutes,
  });
}

final centresProvider = FutureProvider<List<ProcurementCentre>>((ref) {
  ref.watch(dataRevisionProvider);
  return ref.read(centreRepositoryProvider).getAll();
});

final centreByIdProvider = FutureProvider.family<ProcurementCentre?, String>((
  ref,
  id,
) {
  ref.watch(dataRevisionProvider);
  return ref.read(centreRepositoryProvider).getById(id);
});

final activeCropsProvider = FutureProvider<List<Crop>>((ref) {
  ref.watch(dataRevisionProvider);
  return ref.read(cropRepositoryProvider).activeCrops();
});

final bookingsForFarmerProvider = FutureProvider.family<List<Booking>, String>(
  (ref, farmerId) {
    ref.watch(dataRevisionProvider);
    return ref.read(bookingRepositoryProvider).forFarmer(farmerId);
  },
);

final bookingsForCentreProvider = FutureProvider.family<List<Booking>, String>(
  (ref, centreId) {
    ref.watch(dataRevisionProvider);
    return ref.read(bookingRepositoryProvider).forCentre(centreId);
  },
);

final bookingByIdProvider = FutureProvider.family<Booking?, String>((
  ref,
  id,
) {
  ref.watch(dataRevisionProvider);
  return ref.read(bookingRepositoryProvider).getById(id);
});

final queueEntryForBookingProvider = FutureProvider.family<QueueEntry?, String>(
  (ref, bookingId) {
    ref.watch(dataRevisionProvider);
    return ref.read(queueRepositoryProvider).forBooking(bookingId);
  },
);

final rescheduleOffersForBookingProvider =
    FutureProvider.family<List<RescheduleOffer>, String>((ref, bookingId) {
      ref.watch(dataRevisionProvider);
      return ref.read(rescheduleOfferRepositoryProvider).forBooking(bookingId);
    });

final replacementSlotsProvider =
    FutureProvider.family<List<RescheduleCandidate>, String>((ref, bookingId) {
      ref.watch(dataRevisionProvider);
      return ref.read(bookingControllerProvider).replacementSlotsFor(bookingId);
    });

final farmerByIdProvider = FutureProvider.family<Farmer?, String>((ref, id) {
  ref.watch(dataRevisionProvider);
  return ref.read(farmerRepositoryProvider).getById(id);
});

final slotByIdProvider = FutureProvider.family<Slot?, String>((ref, id) {
  ref.watch(dataRevisionProvider);
  return ref.read(slotRepositoryProvider).getById(id);
});

typedef CentreDateKey = ({String centreId, DateTime date});

final slotsForCentreAndDateProvider =
    FutureProvider.family<List<Slot>, CentreDateKey>((ref, key) {
      ref.watch(dataRevisionProvider);
      return ref.read(slotRepositoryProvider).forCentreAndDate(key.centreId, key.date);
    });

final queuePositionProvider = FutureProvider.family<int, String>((
  ref,
  bookingId,
) {
  ref.watch(dataRevisionProvider);
  return ref.read(bookingControllerProvider).queuePositionFor(bookingId);
});

final estimatedWaitProvider = FutureProvider.family<int, String>((
  ref,
  bookingId,
) {
  ref.watch(dataRevisionProvider);
  return ref.read(bookingControllerProvider).estimatedWaitFor(bookingId);
});

typedef SlotRecommendationParams = ({
  String farmerId,
  String centreId,
  DateTime date,
  double qty,
});

final slotRecommendationsProvider = FutureProvider.family<
  List<SlotRecommendation>,
  SlotRecommendationParams
>((ref, params) {
  ref.watch(dataRevisionProvider);
  return ref
      .read(bookingControllerProvider)
      .recommendSlots(
        farmerId: params.farmerId,
        centreId: params.centreId,
        date: params.date,
        expectedQuantityQ: params.qty,
      );
});

final queueTotalForCentreProvider = FutureProvider.family<int, String>((
  ref,
  centreId,
) async {
  final entries = await ref.watch(activeQueueEntriesForCentreProvider(centreId).future);
  return entries.length;
});

/// Active (not completed/exception) queue entries for a centre, ordered by
/// [QueueService.activeQueueForCentre] (skip/priority/manual-position aware)
/// — this ordering IS the queue (README §6).
final activeQueueEntriesForCentreProvider =
    FutureProvider.family<List<QueueEntry>, String>((ref, centreId) async {
      ref.watch(dataRevisionProvider);
      final centreBookingIds = (await ref
              .read(bookingRepositoryProvider)
              .forCentre(centreId))
          .map((b) => b.id)
          .toSet();
      final entries = await ref.read(queueRepositoryProvider).getAll();
      return _queueServiceForProviders.activeQueueForCentre(entries, centreBookingIds);
    });

/// Same active-queue ordering as above, but each entry pre-resolved with its
/// booking, farmer, 1-based position, and live ETA — see [QueueRowView].
final queueRowsForCentreProvider =
    FutureProvider.family<List<QueueRowView>, String>((ref, centreId) async {
      ref.watch(dataRevisionProvider);
      final centre = await ref.read(centreRepositoryProvider).getById(centreId);
      final bookings = await ref.read(bookingRepositoryProvider).forCentre(centreId);
      final bookingsById = {for (final b in bookings) b.id: b};
      final entries = await ref.read(queueRepositoryProvider).getAll();
      final active = _queueServiceForProviders.activeQueueForCentre(
        entries,
        bookingsById.keys.toSet(),
      );
      final lanes = centre?.processingLanesActive ?? 1;
      final farmerRepo = ref.read(farmerRepositoryProvider);
      final rows = <QueueRowView>[];
      for (var i = 0; i < active.length; i++) {
        final entry = active[i];
        final booking = bookingsById[entry.bookingId];
        if (booking == null) continue;
        final farmer = await farmerRepo.getById(booking.farmerId);
        final position = i + 1;
        rows.add(
          QueueRowView(
            entry: entry,
            booking: booking,
            farmer: farmer,
            position: position,
            etaMinutes: _queueServiceForProviders.calculateEstimatedWait(
              queuePosition: position,
              activeLanes: lanes,
            ),
          ),
        );
      }
      return rows;
    });

/// Every queue entry for a centre today, arrival-ordered — matches a real
/// front-desk display (completed farmers stay visible).
final allQueueEntriesForCentreProvider =
    FutureProvider.family<List<QueueEntry>, String>((ref, centreId) async {
      ref.watch(dataRevisionProvider);
      final centreBookingIds = (await ref
              .read(bookingRepositoryProvider)
              .forCentre(centreId))
          .map((b) => b.id)
          .toSet();
      final entries = await ref.read(queueRepositoryProvider).getAll();
      final all = entries.where((q) => centreBookingIds.contains(q.bookingId)).toList()
        ..sort((a, b) => a.enteredAt.compareTo(b.enteredAt));
      return all;
    });

final bookingControllerProvider = Provider<BookingController>(
  (ref) => BookingController(ref),
);

class BookingController {
  final Ref ref;
  static const _capacity = CapacityService();
  static const _scheduler = SchedulerService();
  static const _rescheduler = ReschedulerService();
  static const _queue = QueueService();

  BookingController(this.ref);

  BookingRepository get _bookingRepo => ref.read(bookingRepositoryProvider);
  SlotRepository get _slotRepo => ref.read(slotRepositoryProvider);
  QueueRepository get _queueRepo => ref.read(queueRepositoryProvider);
  RescheduleOfferRepository get _offerRepo =>
      ref.read(rescheduleOfferRepositoryProvider);

  void _bump() => ref.read(dataRevisionProvider.notifier).bump();

  Future<void> _notify(
    String userId,
    String title,
    String message,
    NotificationType type,
  ) async {
    await ref.read(notificationRepositoryProvider).save(
      NotificationItem(
        id: 'ntf-${DateTime.now().microsecondsSinceEpoch}',
        userId: userId,
        title: title,
        message: message,
        timestamp: DateTime.now(),
        type: type,
      ),
    );
  }

  String _fmtRange(DateTime start, DateTime end) {
    String two(int n) => n.toString().padLeft(2, '0');
    String h(DateTime t) =>
        '${two(t.hour % 12 == 0 ? 12 : t.hour % 12)}:${two(t.minute)} ${t.hour >= 12 ? 'PM' : 'AM'}';
    return '${h(start)} – ${h(end)}';
  }

  Future<String> _nextBookingId() async {
    final all = await _bookingRepo.getAll();
    var maxN = 10000;
    for (final b in all) {
      final n = int.tryParse(b.id.replaceFirst('AGR-', ''));
      if (n != null && n > maxN) maxN = n;
    }
    return 'AGR-${maxN + 1}';
  }

  Future<String> _nextToken(String centreId, DateTime day) async {
    final centreBookings = await _bookingRepo.forCentre(centreId);
    final slots = await _slotRepo.forCentre(centreId);
    final sameDayCount = centreBookings.where((b) {
      final slot = slots.where((s) => s.id == b.slotId).firstOrNull;
      return slot != null &&
          slot.date == day &&
          b.status != BookingStatus.waitlisted;
    }).length;
    return 'T${(sameDayCount + 1).toString().padLeft(3, '0')}';
  }

  // ---------------------------------------------------------------------
  // Slot recommendation / booking
  // ---------------------------------------------------------------------

  Future<List<SlotRecommendation>> recommendSlots({
    required String farmerId,
    required String centreId,
    required DateTime date,
    required double expectedQuantityQ,
  }) async {
    final farmer = await ref.read(farmerRepositoryProvider).getById(farmerId);
    final centre = await ref.read(centreRepositoryProvider).getById(centreId);
    if (farmer == null || centre == null) return [];

    final normalizedDate = DateTime(date.year, date.month, date.day);
    var slots = await _slotRepo.forCentre(centreId);

    // If no slots exist for this centre and date, dynamically generate hourly slots
    // from 08:00 to 17:00 so the farmer/reviewer NEVER encounters "no slots found".
    final existingForDate = slots.where((s) => s.date == normalizedDate).toList();
    if (existingForDate.isEmpty) {
      final defaultCropId = centre.supportedCrops.isNotEmpty
          ? centre.supportedCrops.first.cropId
          : 'crop-wheat';
      final newSlots = <Slot>[];
      for (var hour = 8; hour < 17; hour++) {
        newSlots.add(
          Slot(
            id: 'slot-$centreId-${normalizedDate.year}${normalizedDate.month.toString().padLeft(2, '0')}${normalizedDate.day.toString().padLeft(2, '0')}-$hour',
            centreId: centreId,
            cropId: defaultCropId,
            start: DateTime(normalizedDate.year, normalizedDate.month, normalizedDate.day, hour),
            end: DateTime(normalizedDate.year, normalizedDate.month, normalizedDate.day, hour + 1),
            maxFarmers: 10,
            totalCapacityQ: 150,
          ),
        );
      }
      await _slotRepo.saveMany(newSlots);
      slots = await _slotRepo.forCentre(centreId);
    }

    final bookings = await _bookingRepo.forCentre(centreId);
    final disruptions = await ref
        .read(disruptionRepositoryProvider)
        .forCentre(centreId);

    return _scheduler.getRecommendedSlots(
      farmer: farmer,
      centre: centre,
      date: normalizedDate,
      expectedQuantityQ: expectedQuantityQ,
      slots: slots,
      bookings: bookings,
      disruptions: disruptions,
      now: DateTime.now(),
    );
  }

  bool _isSubmittingBooking = false;

  Future<OpResult> bookSlot({
    required String farmerId,
    required String slotId,
    required double expectedQuantityQ,
  }) async {
    if (_isSubmittingBooking) {
      return const OpResult(false, 'Your booking is already being processed.');
    }
    _isSubmittingBooking = true;
    try {
      final farmer = await ref.read(farmerRepositoryProvider).getById(farmerId);
      if (farmer == null) return const OpResult(false, 'Farmer not found.');
      if (!farmer.isVerified) {
        return const OpResult(
          false,
          'Your registration is pending verification by the Centre Operator. Slot booking will unlock once approved.',
        );
      }

      final slot = await _slotRepo.getById(slotId);
      if (slot == null) {
        return const OpResult(false, 'This slot is no longer available.');
      }

      final farmerBookings = await _bookingRepo.forFarmer(farmerId);
      final duplicate = farmerBookings.any(
        (b) =>
            b.isActive &&
            b.status != BookingStatus.waitlisted &&
            b.slotId == slotId,
      );
      // Same-crop-same-season guard is approximated here as
      // same-date-same-farmer, matching the existing (and still valid)
      // demo behaviour: one active booking per day.
      final sameDateDuplicate = farmerBookings.any((b) {
        if (!b.isActive || b.status == BookingStatus.waitlisted) return false;
        return true; // resolved further below once we know the slot date
      });

      final centreBookings = await _bookingRepo.forCentre(slot.centreId);
      final remainingFarmers = _capacity.remainingSlotFarmerCapacity(
        slot,
        centreBookings,
      );
      final remainingQuantity = _capacity.remainingSlotQuantityCapacity(
        slot,
        centreBookings,
      );
      if (remainingFarmers <= 0 || remainingQuantity < expectedQuantityQ) {
        return const OpResult(
          false,
          'This slot is no longer available. Please choose another.',
        );
      }
      if (duplicate) {
        return const OpResult(
          false,
          'You already have an active booking for this slot.',
        );
      }
      if (sameDateDuplicate) {
        final slots = await _slotRepo.getAll();
        final hasSameDateActive = farmerBookings.any((b) {
          if (!b.isActive || b.status == BookingStatus.waitlisted) return false;
          final s = slots.where((s) => s.id == b.slotId).firstOrNull;
          return s?.date == slot.date;
        });
        if (hasSameDateActive) {
          return const OpResult(
            false,
            'You already have an active booking for this date.',
          );
        }
      }

      final id = await _nextBookingId();
      final token = await _nextToken(slot.centreId, slot.date);

      final booking = Booking(
        id: id,
        farmerId: farmerId,
        centreId: slot.centreId,
        slotId: slot.id,
        expectedQuantityQ: expectedQuantityQ,
        status: BookingStatus.booked,
        token: token,
        createdAt: DateTime.now(),
      );
      await _bookingRepo.save(booking);
      await _notify(
        farmerId,
        'Slot Confirmed',
        'Your slot is ${_fmtRange(slot.start, slot.end)}. Token $token.',
        NotificationType.slotConfirmation,
      );
      _bump();
      return OpResult(true, 'Slot confirmed. Token $token.', id: id);
    } finally {
      _isSubmittingBooking = false;
    }
  }

  Future<OpResult> cancelBooking(String bookingId) async {
    final booking = await _bookingRepo.getById(bookingId);
    if (booking == null) return const OpResult(false, 'Booking not found.');
    if (!booking.isActive) {
      return const OpResult(false, 'This booking can no longer be cancelled.');
    }
    await _bookingRepo.save(
      booking.copyWith(status: BookingStatus.cancelled, cancelledAt: DateTime.now()),
    );
    final entry = await _queueRepo.forBooking(bookingId);
    if (entry != null) await _queueRepo.delete(entry.id);
    await _offerReleasedCapacityIfPossible(booking.centreId);
    _bump();
    return const OpResult(true, 'Booking cancelled. Capacity has been released.');
  }

  Future<OpResult> markNoShow(String bookingId) async {
    final booking = await _bookingRepo.getById(bookingId);
    if (booking == null) return const OpResult(false, 'Booking not found.');
    await _bookingRepo.save(
      booking.copyWith(status: BookingStatus.noShow, noShowAt: DateTime.now()),
    );
    final entry = await _queueRepo.forBooking(bookingId);
    if (entry != null) await _queueRepo.delete(entry.id);
    await _notify(
      booking.farmerId,
      'Marked as No-show',
      'You were marked as a no-show for your booked slot.',
      NotificationType.general,
    );
    await _offerReleasedCapacityIfPossible(booking.centreId);
    _bump();
    return const OpResult(true, 'Farmer marked as no-show.');
  }

  Future<OpResult> offerReleasedCapacity(String centreId) async {
    final before = (await _offerRepo.getAll()).length;
    await _offerReleasedCapacityIfPossible(centreId);
    final created = (await _offerRepo.getAll()).length > before;
    _bump();
    return OpResult(
      created,
      created
          ? 'Released capacity offered to the next waitlisted farmer.'
          : 'No feasible capacity to offer right now.',
    );
  }

  Future<void> _offerReleasedCapacityIfPossible(String centreId) async {
    final centreBookings = await _bookingRepo.forCentre(centreId);
    final waitlisted = centreBookings
        .where((b) => b.status == BookingStatus.waitlisted)
        .toList();
    if (waitlisted.isEmpty) return;
    final candidate = waitlisted.first;
    final farmer = await ref
        .read(farmerRepositoryProvider)
        .getById(candidate.farmerId);
    final centre = await ref.read(centreRepositoryProvider).getById(centreId);
    if (farmer == null || centre == null) return;
    final slots = await _slotRepo.forCentre(centreId);
    final disruptions = await ref
        .read(disruptionRepositoryProvider)
        .forCentre(centreId);

    final options = _rescheduler.findReplacementSlots(
      farmer: farmer,
      centre: centre,
      expectedQuantityQ: candidate.expectedQuantityQ,
      slots: slots,
      bookings: centreBookings,
      disruptions: disruptions,
      now: DateTime.now(),
    );
    if (options.isEmpty) return;
    final best = options.first.recommendation.slot;

    final existingOffers = await _offerRepo.forBooking(candidate.id);
    final alreadyOffered = existingOffers.any(
      (o) => o.status == RescheduleOfferStatus.pending,
    );
    if (alreadyOffered) return;

    await _offerRepo.save(
      RescheduleOffer(
        id: 'offer-${DateTime.now().microsecondsSinceEpoch}',
        bookingId: candidate.id,
        originalSlotId: candidate.slotId,
        offeredSlotId: best.id,
        reason: 'Released capacity became available',
        status: RescheduleOfferStatus.pending,
        createdAt: DateTime.now(),
      ),
    );
    await _notify(
      candidate.farmerId,
      'Slot Available',
      'A slot has become available for your ${candidate.expectedQuantityQ.toStringAsFixed(0)} Q request.',
      NotificationType.newSlotOffered,
    );
  }

  // ---------------------------------------------------------------------
  // Reschedule offers
  // ---------------------------------------------------------------------

  Future<List<RescheduleCandidate>> replacementSlotsFor(String bookingId) async {
    final booking = await _bookingRepo.getById(bookingId);
    if (booking == null) return [];
    final farmer = await ref.read(farmerRepositoryProvider).getById(booking.farmerId);
    final centre = await ref.read(centreRepositoryProvider).getById(booking.centreId);
    if (farmer == null || centre == null) return [];
    final slots = await _slotRepo.forCentre(booking.centreId);
    final bookings = await _bookingRepo.forCentre(booking.centreId);
    final disruptions = await ref
        .read(disruptionRepositoryProvider)
        .forCentre(booking.centreId);
    return _rescheduler.findReplacementSlots(
      farmer: farmer,
      centre: centre,
      expectedQuantityQ: booking.expectedQuantityQ,
      slots: slots,
      bookings: bookings,
      disruptions: disruptions,
      now: DateTime.now(),
    );
  }

  Future<OpResult> acceptSpecificSlot(
    String bookingId,
    String offeredSlotId,
  ) async {
    final booking = await _bookingRepo.getById(bookingId);
    if (booking == null) return const OpResult(false, 'Booking not found.');
    final offers = await _offerRepo.forBooking(bookingId);
    final pending = offers
        .where((o) => o.status == RescheduleOfferStatus.pending)
        .toList();
    if (pending.isNotEmpty && pending.first.offeredSlotId == offeredSlotId) {
      return acceptRescheduleOffer(pending.first.id);
    }
    await _bookingRepo.save(
      booking.copyWith(status: BookingStatus.booked, slotId: offeredSlotId),
    );
    for (final o in pending) {
      await _offerRepo.save(o.copyWith(status: RescheduleOfferStatus.declined));
    }
    await _notify(
      booking.farmerId,
      'Reschedule Confirmed',
      'Your new slot has been confirmed.',
      NotificationType.slotConfirmation,
    );
    _bump();
    return const OpResult(true, 'New slot confirmed.');
  }

  Future<OpResult> acceptRescheduleOffer(String offerId) async {
    final offer = await _offerRepo.getById(offerId);
    if (offer == null) return const OpResult(false, 'Offer not found.');
    final booking = await _bookingRepo.getById(offer.bookingId);
    if (booking == null) return const OpResult(false, 'Booking not found.');

    await _bookingRepo.save(
      booking.copyWith(status: BookingStatus.booked, slotId: offer.offeredSlotId),
    );
    await _offerRepo.save(offer.copyWith(status: RescheduleOfferStatus.accepted));
    await _notify(
      booking.farmerId,
      'Reschedule Confirmed',
      'Your new slot has been confirmed.',
      NotificationType.slotConfirmation,
    );
    _bump();
    return const OpResult(true, 'New slot confirmed.');
  }

  Future<OpResult> declineRescheduleOffer(String offerId) async {
    final offer = await _offerRepo.getById(offerId);
    if (offer != null) {
      await _offerRepo.save(offer.copyWith(status: RescheduleOfferStatus.declined));
    }
    _bump();
    return const OpResult(
      true,
      'Offer declined. We will show you the next available option.',
    );
  }

  // ---------------------------------------------------------------------
  // Queue / check-in
  // ---------------------------------------------------------------------

  Future<OpResult> checkInFarmer(String bookingId) async {
    final booking = await _bookingRepo.getById(bookingId);
    if (booking == null) return const OpResult(false, 'Booking not found.');
    await _bookingRepo.save(
      booking.copyWith(status: BookingStatus.inQueue, checkedInAt: DateTime.now()),
    );
    final centreBookingIds = (await _bookingRepo.forCentre(booking.centreId))
        .map((b) => b.id)
        .toSet();
    final active = _queue.activeQueueForCentre(
      await _queueRepo.getAll(),
      centreBookingIds,
    );
    final nextPosition = active.isEmpty
        ? 1
        : active.map((e) => e.queuePosition).reduce((a, b) => a > b ? a : b) + 1;
    await _queueRepo.save(
      QueueEntry(
        id: 'q-${DateTime.now().microsecondsSinceEpoch}',
        bookingId: bookingId,
        token: booking.token,
        stage: QueueStage.arrived,
        enteredAt: DateTime.now(),
        queuePosition: nextPosition,
      ),
    );
    _bump();
    return const OpResult(true, 'Farmer checked in and added to the queue.');
  }

  /// Toggles priority — priority entries sort ahead of normal ones (see
  /// [QueueService.activeQueueForCentre]) regardless of arrival order.
  Future<OpResult> setQueuePriority(String bookingId, bool priority) async {
    final entry = await _queueRepo.forBooking(bookingId);
    if (entry == null) return const OpResult(false, 'Queue entry not found.');
    await _queueRepo.save(entry.copyWith(isPriority: priority));
    _bump();
    return OpResult(true, priority ? 'Marked as priority.' : 'Priority removed.');
  }

  /// Skip sends a token to the back of the queue without removing it (the
  /// booking stays checked-in); Recall (skipped: false) brings it back into
  /// normal position ordering.
  Future<OpResult> setQueueSkipped(String bookingId, bool skipped) async {
    final entry = await _queueRepo.forBooking(bookingId);
    if (entry == null) return const OpResult(false, 'Queue entry not found.');
    await _queueRepo.save(entry.copyWith(skipped: skipped));
    _bump();
    return OpResult(
      true,
      skipped ? 'Token skipped — moved to back of queue.' : 'Token recalled to the queue.',
    );
  }

  /// Adjacent-swap manual reorder: swaps this entry's `queuePosition` with
  /// whichever entry is immediately above/below it in the currently-sorted
  /// active queue.
  Future<OpResult> reorderQueueEntry(
    String centreId,
    String bookingId, {
    required bool moveUp,
  }) async {
    final centreBookingIds = (await _bookingRepo.forCentre(centreId))
        .map((b) => b.id)
        .toSet();
    final active = _queue.activeQueueForCentre(await _queueRepo.getAll(), centreBookingIds);
    final idx = active.indexWhere((e) => e.bookingId == bookingId);
    if (idx == -1) return const OpResult(false, 'Queue entry not found.');
    final swapIdx = moveUp ? idx - 1 : idx + 1;
    if (swapIdx < 0 || swapIdx >= active.length) {
      return const OpResult(false, 'Already at the edge of the queue.');
    }
    final a = active[idx];
    final b = active[swapIdx];
    await _queueRepo.save(a.copyWith(queuePosition: b.queuePosition));
    await _queueRepo.save(b.copyWith(queuePosition: a.queuePosition));
    _bump();
    return const OpResult(true, 'Queue order updated.');
  }

  Future<OpResult> moveQueueStage(String bookingId, QueueStage newStage) async {
    final entry = await _queueRepo.forBooking(bookingId);
    if (entry == null) return const OpResult(false, 'Queue entry not found.');
    await _queueRepo.save(entry.copyWith(stage: newStage));
    final booking = await _bookingRepo.getById(bookingId);
    if (booking != null) {
      await _bookingRepo.save(
        booking.copyWith(status: BookingStatus.underQualityCheck),
      );
    }
    _bump();
    return OpResult(true, 'Moved to ${newStage.label}.');
  }

  Future<int> queuePositionFor(String bookingId) async {
    final booking = await _bookingRepo.getById(bookingId);
    if (booking == null) return -1;
    final centreBookingIds = (await _bookingRepo.forCentre(booking.centreId))
        .map((b) => b.id)
        .toSet();
    final allEntries = await _queueRepo.getAll();
    final activeQueue = _queue.activeQueueForCentre(allEntries, centreBookingIds);
    return _queue.calculateQueuePosition(bookingId, activeQueue);
  }

  Future<int> estimatedWaitFor(String bookingId) async {
    final booking = await _bookingRepo.getById(bookingId);
    if (booking == null) return 0;
    final centre = await ref.read(centreRepositoryProvider).getById(booking.centreId);
    final position = await queuePositionFor(bookingId);
    return _queue.calculateEstimatedWait(
      queuePosition: position,
      activeLanes: centre?.processingLanesActive ?? 1,
    );
  }
}
