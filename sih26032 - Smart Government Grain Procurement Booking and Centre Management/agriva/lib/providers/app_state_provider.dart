import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_state.dart';
import '../core/storage/local_storage_service.dart';
import '../core/utils/list_extensions.dart';
import '../data/demo_data.dart';
import '../models/audit_log.dart';
import '../models/booking.dart';
import '../models/disruption.dart';
import '../models/enums.dart';
import '../models/inspection.dart';
import '../models/notification.dart';
import '../models/payment.dart';
import '../models/procurement.dart';
import '../models/queue_entry.dart';
import '../models/reschedule_offer.dart';
import '../models/weighment.dart';
import '../services/capacity_service.dart';
import '../services/queue_service.dart';
import '../services/rescheduler_service.dart';
import '../services/scheduler_service.dart';

class OpResult {
  final bool success;
  final String message;
  final String? id;
  const OpResult(this.success, this.message, {this.id});
}

final localStorageServiceProvider = Provider((ref) => LocalStorageService());

final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AgrivaAppState>(
      (ref) => AppStateNotifier(ref.read(localStorageServiceProvider)),
    );

final appReadyProvider = FutureProvider<void>(
  (ref) => ref.watch(appStateProvider.notifier).initialize(),
);

class AppStateNotifier extends StateNotifier<AgrivaAppState> {
  final LocalStorageService _storage;
  final _capacity = const CapacityService();
  final _scheduler = const SchedulerService();
  final _rescheduler = const ReschedulerService();
  final _queue = const QueueService();

  AppStateNotifier(this._storage) : super(const AgrivaAppState());

  Future<void> initialize() async {
    final loaded = await _storage.loadState();
    state = loaded ?? buildInitialDemoState(DateTime.now());
    if (loaded == null) await _persist();
  }

  Future<void> _persist() => _storage.saveState(state);

  // ---------------------------------------------------------------------
  // Auth / role
  // ---------------------------------------------------------------------

  void loginAs(UserRole role) {
    final user = state.users.firstWhere(
      (u) => u.role == role,
      orElse: () => state.users.first,
    );
    state = state.copyWith(currentUser: user);
    _persist();
  }

  void logout() {
    state = state.copyWith(clearCurrentUser: true);
    _persist();
  }

  Future<void> resetDemo() async {
    await _storage.clear();
    state = buildInitialDemoState(DateTime.now());
    await _persist();
  }

  // ---------------------------------------------------------------------
  // Small helpers
  // ---------------------------------------------------------------------

  void _audit(
    String actor,
    String action,
    String entity,
    String entityId, {
    String? oldState,
    String? newState,
  }) {
    state = state.copyWith(
      auditLogs: [
        ...state.auditLogs,
        AuditLog(
          id: 'audit-${DateTime.now().microsecondsSinceEpoch}',
          actor: actor,
          action: action,
          entity: entity,
          entityId: entityId,
          timestamp: DateTime.now(),
          oldState: oldState,
          newState: newState,
        ),
      ],
    );
  }

  void _notify(
    String userId,
    String title,
    String message,
    NotificationKind kind,
  ) {
    state = state.copyWith(
      notifications: [
        NotificationItem(
          id: 'ntf-${DateTime.now().microsecondsSinceEpoch}',
          userId: userId,
          title: title,
          message: message,
          timestamp: DateTime.now(),
          kind: kind,
        ),
        ...state.notifications,
      ],
    );
  }

  String _nextBookingId() {
    var maxN = 10000;
    for (final b in state.bookings) {
      final n = int.tryParse(b.id.replaceFirst('AGR-', ''));
      if (n != null && n > maxN) maxN = n;
    }
    return 'AGR-${maxN + 1}';
  }

  String _nextToken(String centreId, DateTime day) {
    final count = state.bookings
        .where(
          (b) =>
              b.centreId == centreId &&
              DateTime(b.createdAt.year, b.createdAt.month, b.createdAt.day) ==
                  day &&
              b.status != BookingStatus.waitlisted,
        )
        .length;
    final sameDayBookings = state.bookings.where((b) {
      final slot = state.slots.where((s) => s.id == b.slotId).firstOrNull;
      return slot != null &&
          slot.centreId == centreId &&
          slot.date == day &&
          b.status != BookingStatus.waitlisted;
    }).length;
    final n = (sameDayBookings > count ? sameDayBookings : count) + 1;
    return 'T${n.toString().padLeft(3, '0')}';
  }

  // ---------------------------------------------------------------------
  // Booking
  // ---------------------------------------------------------------------

  List<SlotRecommendation> recommendSlots({
    required String farmerId,
    required String centreId,
    required DateTime date,
    required double expectedQuantityQ,
  }) {
    final farmer = state.farmers.firstWhere((f) => f.id == farmerId);
    final centre = state.centres.firstWhere((c) => c.id == centreId);
    return _scheduler.getRecommendedSlots(
      farmer: farmer,
      centre: centre,
      date: DateTime(date.year, date.month, date.day),
      expectedQuantityQ: expectedQuantityQ,
      slots: state.slots,
      bookings: state.bookings,
      disruptions: state.disruptions,
      now: DateTime.now(),
    );
  }

  bool _isSubmittingBooking = false;

  OpResult bookSlot({
    required String farmerId,
    required String slotId,
    required double expectedQuantityQ,
  }) {
    if (_isSubmittingBooking) {
      return const OpResult(false, 'Your booking is already being processed.');
    }
    _isSubmittingBooking = true;
    try {
      final slot = state.slots.where((s) => s.id == slotId).firstOrNull;
      if (slot == null)
        return const OpResult(false, 'This slot is no longer available.');

      final duplicate = state.bookings.any(
        (b) =>
            b.farmerId == farmerId &&
            b.isActive &&
            b.status != BookingStatus.waitlisted &&
            state.slots.where((s) => s.id == b.slotId).firstOrNull?.date ==
                slot.date,
      );
      if (duplicate) {
        return const OpResult(
          false,
          'You already have an active booking for this date.',
        );
      }

      // Re-check capacity right before confirming (concurrency-like guard).
      final remainingFarmers = _capacity.remainingSlotFarmerCapacity(
        slot,
        state.bookings,
      );
      final remainingQuantity = _capacity.remainingSlotQuantityCapacity(
        slot,
        state.bookings,
      );
      if (remainingFarmers <= 0 || remainingQuantity < expectedQuantityQ) {
        return const OpResult(
          false,
          'This slot is no longer available. Please choose another.',
        );
      }

      final farmer = state.farmers.firstWhere((f) => f.id == farmerId);
      final id = _nextBookingId();
      final token = _nextToken(slot.centreId, slot.date);

      final booking = Booking(
        id: id,
        farmerId: farmerId,
        centreId: slot.centreId,
        slotId: slot.id,
        expectedQuantityQ: expectedQuantityQ,
        status: BookingStatus.confirmed,
        token: token,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(bookings: [...state.bookings, booking]);
      _audit(
        farmer.name,
        'Booking Confirmed',
        'Booking',
        id,
        newState: 'confirmed',
      );
      _notify(
        farmerId,
        'Slot Confirmed',
        'Your slot is ${_fmtRange(slot.start, slot.end)}. Token $token.',
        NotificationKind.slotConfirmed,
      );
      _persist();
      return OpResult(true, 'Slot confirmed. Token $token.', id: id);
    } finally {
      _isSubmittingBooking = false;
    }
  }

  OpResult cancelBooking(String bookingId) {
    final booking = state.bookings.where((b) => b.id == bookingId).firstOrNull;
    if (booking == null) return const OpResult(false, 'Booking not found.');
    if (!booking.isActive)
      return const OpResult(false, 'This booking can no longer be cancelled.');

    state = state.copyWith(
      bookings: state.bookings
          .map(
            (b) => b.id == bookingId
                ? b.copyWith(
                    status: BookingStatus.cancelled,
                    cancelledAt: DateTime.now(),
                  )
                : b,
          )
          .toList(),
      queueEntries: state.queueEntries
          .where((q) => q.bookingId != bookingId)
          .toList(),
    );
    _audit(
      'Farmer',
      'Booking Cancelled',
      'Booking',
      bookingId,
      oldState: booking.status.name,
      newState: 'cancelled',
    );
    _offerReleasedCapacityIfPossible(booking.centreId);
    _persist();
    return const OpResult(
      true,
      'Booking cancelled. Capacity has been released.',
    );
  }

  OpResult markNoShow(String bookingId) {
    final booking = state.bookings.where((b) => b.id == bookingId).firstOrNull;
    if (booking == null) return const OpResult(false, 'Booking not found.');

    state = state.copyWith(
      bookings: state.bookings
          .map(
            (b) => b.id == bookingId
                ? b.copyWith(
                    status: BookingStatus.noShow,
                    noShowAt: DateTime.now(),
                  )
                : b,
          )
          .toList(),
      queueEntries: state.queueEntries
          .where((q) => q.bookingId != bookingId)
          .toList(),
    );
    _audit(
      'Operator',
      'No-show Recorded',
      'Booking',
      bookingId,
      newState: 'noShow',
    );
    _notify(
      booking.farmerId,
      'Marked as No-show',
      'You were marked as a no-show for your booked slot.',
      NotificationKind.general,
    );
    _offerReleasedCapacityIfPossible(booking.centreId);
    _persist();
    return const OpResult(true, 'Farmer marked as no-show.');
  }

  /// Demo Controller entry point — same effect as capacity freed by a
  /// cancellation, without requiring one to have just happened.
  OpResult offerReleasedCapacity(String centreId) {
    final before = state.rescheduleOffers.length;
    _offerReleasedCapacityIfPossible(centreId);
    final created = state.rescheduleOffers.length > before;
    _persist();
    return OpResult(
      created,
      created
          ? 'Released capacity offered to the next waitlisted farmer.'
          : 'No feasible capacity to offer right now.',
    );
  }

  /// After a cancellation/no-show frees capacity, offer it to the first
  /// waitlisted farmer whose desired quantity now fits somewhere today.
  void _offerReleasedCapacityIfPossible(String centreId) {
    final waitlisted = state.bookings
        .where(
          (b) => b.centreId == centreId && b.status == BookingStatus.waitlisted,
        )
        .toList();
    if (waitlisted.isEmpty) return;
    final candidate = waitlisted.first;
    final farmer = state.farmers.firstWhere((f) => f.id == candidate.farmerId);
    final centre = state.centres.firstWhere((c) => c.id == centreId);
    final today = DateTime.now();
    final options = _rescheduler.findReplacementSlots(
      farmer: farmer,
      centre: centre,
      expectedQuantityQ: candidate.expectedQuantityQ,
      slots: state.slots,
      bookings: state.bookings,
      disruptions: state.disruptions,
      now: today,
    );
    if (options.isEmpty) return;
    final best = options.first.recommendation.slot;

    final alreadyOffered = state.rescheduleOffers.any(
      (o) =>
          o.bookingId == candidate.id &&
          o.status == RescheduleOfferStatus.pending,
    );
    if (alreadyOffered) return;

    state = state.copyWith(
      rescheduleOffers: [
        ...state.rescheduleOffers,
        RescheduleOffer(
          id: 'offer-${DateTime.now().microsecondsSinceEpoch}',
          bookingId: candidate.id,
          originalSlotId: candidate.slotId,
          offeredSlotId: best.id,
          reason: 'Released capacity became available',
          status: RescheduleOfferStatus.pending,
          createdAt: DateTime.now(),
        ),
      ],
    );
    _notify(
      candidate.farmerId,
      'Slot Available',
      'A slot has become available for your ${candidate.expectedQuantityQ.toStringAsFixed(0)} Q request.',
      NotificationKind.newSlotOffered,
    );
  }

  // ---------------------------------------------------------------------
  // Reschedule offers
  // ---------------------------------------------------------------------

  List<RescheduleCandidate> replacementSlotsFor(String bookingId) {
    final booking = state.bookings.firstWhere((b) => b.id == bookingId);
    final farmer = state.farmers.firstWhere((f) => f.id == booking.farmerId);
    final centre = state.centres.firstWhere((c) => c.id == booking.centreId);
    return _rescheduler.findReplacementSlots(
      farmer: farmer,
      centre: centre,
      expectedQuantityQ: booking.expectedQuantityQ,
      slots: state.slots,
      bookings: state.bookings,
      disruptions: state.disruptions,
      now: DateTime.now(),
    );
  }

  OpResult acceptSpecificSlot(
    String bookingId,
    String offeredSlotId,
    String reason,
  ) {
    final existingOffer = state.rescheduleOffers
        .where(
          (o) =>
              o.bookingId == bookingId &&
              o.status == RescheduleOfferStatus.pending,
        )
        .firstOrNull;
    final booking = state.bookings.firstWhere((b) => b.id == bookingId);

    if (existingOffer != null && existingOffer.offeredSlotId == offeredSlotId) {
      return acceptRescheduleOffer(existingOffer.id);
    }

    state = state.copyWith(
      bookings: state.bookings
          .map(
            (b) => b.id == bookingId
                ? b.copyWith(
                    status: BookingStatus.confirmed,
                    slotId: offeredSlotId,
                  )
                : b,
          )
          .toList(),
      rescheduleOffers: existingOffer == null
          ? state.rescheduleOffers
          : state.rescheduleOffers
                .map(
                  (o) => o.id == existingOffer.id
                      ? o.copyWith(status: RescheduleOfferStatus.declined)
                      : o,
                )
                .toList(),
    );
    _audit(
      'Farmer',
      'Booking Rescheduled',
      'Booking',
      bookingId,
      newState: offeredSlotId,
    );
    _notify(
      booking.farmerId,
      'Reschedule Confirmed',
      'Your new slot has been confirmed.',
      NotificationKind.slotConfirmed,
    );
    _persist();
    return const OpResult(true, 'New slot confirmed.');
  }

  OpResult acceptRescheduleOffer(String offerId) {
    final offer = state.rescheduleOffers
        .where((o) => o.id == offerId)
        .firstOrNull;
    if (offer == null) return const OpResult(false, 'Offer not found.');

    state = state.copyWith(
      bookings: state.bookings.map((b) {
        if (b.id != offer.bookingId) return b;
        return b.copyWith(
          status: BookingStatus.confirmed,
          slotId: offer.offeredSlotId,
        );
      }).toList(),
      rescheduleOffers: state.rescheduleOffers
          .map(
            (o) => o.id == offerId
                ? o.copyWith(status: RescheduleOfferStatus.accepted)
                : o,
          )
          .toList(),
    );
    final booking = state.bookings.firstWhere((b) => b.id == offer.bookingId);
    _audit(
      'Farmer',
      'Booking Rescheduled',
      'Booking',
      booking.id,
      newState: offer.offeredSlotId,
    );
    _notify(
      booking.farmerId,
      'Reschedule Confirmed',
      'Your new slot has been confirmed.',
      NotificationKind.slotConfirmed,
    );
    _persist();
    return const OpResult(true, 'New slot confirmed.');
  }

  OpResult declineRescheduleOffer(String offerId) {
    state = state.copyWith(
      rescheduleOffers: state.rescheduleOffers
          .map(
            (o) => o.id == offerId
                ? o.copyWith(status: RescheduleOfferStatus.declined)
                : o,
          )
          .toList(),
    );
    _persist();
    return const OpResult(
      true,
      'Offer declined. We will show you the next available option.',
    );
  }

  // ---------------------------------------------------------------------
  // Disruptions
  // ---------------------------------------------------------------------

  OpResult declareDisruption({
    required String centreId,
    required DisruptionType type,
    required DateTime expectedResolution,
    required List<String> affectedSlotIds,
  }) {
    final centre = state.centres.firstWhere((c) => c.id == centreId);
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

    final newStatus = type == DisruptionType.centreClosure
        ? CentreStatus.closed
        : CentreStatus.delayed;
    final newLanes =
        (centre.processingLanesActive - disruption.affectedProcessingLanes)
            .clamp(0, centre.processingLanesTotal);
    final newStaff = type == DisruptionType.labourShortage
        ? (centre.staffAvailable * 0.6).round()
        : centre.staffAvailable;

    state = state.copyWith(
      disruptions: [...state.disruptions, disruption],
      centres: state.centres
          .map(
            (c) => c.id == centreId
                ? c.copyWith(
                    status: newStatus,
                    processingLanesActive: newLanes,
                    staffAvailable: newStaff,
                  )
                : c,
          )
          .toList(),
    );

    _audit(
      'Operator',
      'Disruption Declared',
      'Disruption',
      disruption.id,
      newState: type.name,
    );

    final affected = _rescheduler.findAffectedBookings(
      disruption,
      state.bookings,
    );
    for (final booking in affected) {
      state = state.copyWith(
        bookings: state.bookings
            .map(
              (b) => b.id == booking.id
                  ? b.copyWith(status: BookingStatus.rescheduleRequired)
                  : b,
            )
            .toList(),
      );
      _notify(
        booking.farmerId,
        'Centre Delay',
        'Procurement at ${centre.name} is delayed due to ${type.label.toLowerCase()}.',
        NotificationKind.centreDelay,
      );

      final farmer = state.farmers.firstWhere((f) => f.id == booking.farmerId);
      final options = _rescheduler.findReplacementSlots(
        farmer: farmer,
        centre: centre.copyWith(
          status: newStatus,
          processingLanesActive: newLanes,
          staffAvailable: newStaff,
        ),
        expectedQuantityQ: booking.expectedQuantityQ,
        slots: state.slots,
        bookings: state.bookings,
        disruptions: state.disruptions,
        now: DateTime.now(),
      );
      if (options.isNotEmpty) {
        final best = options.first.recommendation.slot;
        state = state.copyWith(
          rescheduleOffers: [
            ...state.rescheduleOffers,
            RescheduleOffer(
              id: 'offer-${DateTime.now().microsecondsSinceEpoch}-${booking.id}',
              bookingId: booking.id,
              originalSlotId: booking.slotId,
              offeredSlotId: best.id,
              reason: type.label,
              status: RescheduleOfferStatus.pending,
              createdAt: DateTime.now(),
            ),
          ],
        );
        _notify(
          booking.farmerId,
          'Reschedule Required',
          'Your original slot is affected. We recommend a new slot — review and accept in Reschedule.',
          NotificationKind.rescheduleRequired,
        );
      }
    }

    _persist();
    return OpResult(
      true,
      '${centre.name} is now ${newStatus.label}. ${affected.length} farmer(s) affected.',
    );
  }

  OpResult resolveDisruption(String disruptionId) {
    final disruption = state.disruptions
        .where((d) => d.id == disruptionId)
        .firstOrNull;
    if (disruption == null)
      return const OpResult(false, 'Disruption not found.');

    state = state.copyWith(
      disruptions: state.disruptions
          .map(
            (d) => d.id == disruptionId
                ? d.copyWith(
                    status: DisruptionStatus.resolved,
                    actualResolution: DateTime.now(),
                  )
                : d,
          )
          .toList(),
    );

    final stillActive = state.disruptions.any(
      (d) =>
          d.centreId == disruption.centreId &&
          d.status == DisruptionStatus.active,
    );
    if (!stillActive) {
      state = state.copyWith(
        centres: state.centres.map((c) {
          if (c.id != disruption.centreId) return c;
          return c.copyWith(
            status: CentreStatus.open,
            processingLanesActive: c.processingLanesTotal,
            staffAvailable: c.staffNormal,
          );
        }).toList(),
      );
    }

    _audit(
      'Operator',
      'Disruption Resolved',
      'Disruption',
      disruptionId,
      oldState: 'active',
      newState: 'resolved',
    );
    _persist();
    return const OpResult(true, 'Disruption resolved. Centre status updated.');
  }

  // ---------------------------------------------------------------------
  // Queue / check-in
  // ---------------------------------------------------------------------

  OpResult checkInFarmer(String bookingId) {
    final booking = state.bookings.where((b) => b.id == bookingId).firstOrNull;
    if (booking == null) return const OpResult(false, 'Booking not found.');

    state = state.copyWith(
      bookings: state.bookings
          .map(
            (b) => b.id == bookingId
                ? b.copyWith(
                    status: BookingStatus.inQueue,
                    checkedInAt: DateTime.now(),
                  )
                : b,
          )
          .toList(),
      queueEntries: [
        ...state.queueEntries,
        QueueEntry(
          id: 'q-${DateTime.now().microsecondsSinceEpoch}',
          bookingId: bookingId,
          token: booking.token,
          stage: QueueStage.arrived,
          enteredAt: DateTime.now(),
        ),
      ],
    );
    _audit(
      'Operator',
      'Farmer Checked In',
      'Booking',
      bookingId,
      newState: 'inQueue',
    );
    _persist();
    return const OpResult(true, 'Farmer checked in and added to the queue.');
  }

  OpResult moveQueueStage(String bookingId, QueueStage newStage) {
    final entry = state.queueEntries
        .where((q) => q.bookingId == bookingId)
        .firstOrNull;
    if (entry == null) return const OpResult(false, 'Queue entry not found.');

    state = state.copyWith(
      queueEntries: state.queueEntries
          .map(
            (q) => q.bookingId == bookingId ? q.copyWith(stage: newStage) : q,
          )
          .toList(),
      bookings: state.bookings
          .map(
            (b) => b.id == bookingId
                ? b.copyWith(status: BookingStatus.processing)
                : b,
          )
          .toList(),
    );
    _audit(
      'Operator',
      'Queue Stage Updated',
      'QueueEntry',
      entry.id,
      newState: newStage.name,
    );
    _persist();
    return OpResult(true, 'Moved to ${newStage.label}.');
  }

  int queuePositionFor(String bookingId) {
    final booking = state.bookings.where((b) => b.id == bookingId).firstOrNull;
    if (booking == null) return -1;
    final centreBookingIds = state.bookings
        .where((b) => b.centreId == booking.centreId)
        .map((b) => b.id)
        .toSet();
    final activeQueue = _queue.activeQueueForCentre(
      state.queueEntries,
      centreBookingIds,
    );
    return _queue.calculateQueuePosition(bookingId, activeQueue);
  }

  int estimatedWaitFor(String bookingId) {
    final booking = state.bookings.where((b) => b.id == bookingId).firstOrNull;
    if (booking == null) return 0;
    final centre = state.centres.firstWhere((c) => c.id == booking.centreId);
    final position = queuePositionFor(bookingId);
    return _queue.calculateEstimatedWait(
      queuePosition: position,
      activeLanes: centre.processingLanesActive,
    );
  }

  // ---------------------------------------------------------------------
  // Quality inspection
  // ---------------------------------------------------------------------

  OpResult submitInspection({
    required String bookingId,
    required double moisturePercent,
    required InspectionStatus result,
    String? reason,
    String? remarks,
    required String inspector,
  }) {
    final booking = state.bookings.where((b) => b.id == bookingId).firstOrNull;
    if (booking == null) return const OpResult(false, 'Booking not found.');

    final inspection = Inspection(
      id: 'insp-${DateTime.now().microsecondsSinceEpoch}',
      bookingId: bookingId,
      moisturePercent: moisturePercent,
      result: result,
      reason: reason,
      remarks: remarks,
      inspector: inspector,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(inspections: [...state.inspections, inspection]);
    _audit(
      inspector,
      'Quality Updated',
      'Inspection',
      inspection.id,
      newState: result.name,
    );

    switch (result) {
      case InspectionStatus.passed:
        state = state.copyWith(
          queueEntries: state.queueEntries
              .map(
                (q) => q.bookingId == bookingId
                    ? q.copyWith(stage: QueueStage.weighment)
                    : q,
              )
              .toList(),
        );
        _notify(
          booking.farmerId,
          'Quality Inspection',
          'PASSED. Proceeding to weighment.',
          NotificationKind.qualityResult,
        );
      case InspectionStatus.notAccepted:
        state = state.copyWith(
          bookings: state.bookings
              .map(
                (b) => b.id == bookingId
                    ? b.copyWith(status: BookingStatus.notAccepted)
                    : b,
              )
              .toList(),
          queueEntries: state.queueEntries
              .map(
                (q) => q.bookingId == bookingId
                    ? q.copyWith(stage: QueueStage.exception)
                    : q,
              )
              .toList(),
          procurements: [
            ...state.procurements,
            Procurement(
              id: 'proc-${DateTime.now().microsecondsSinceEpoch}',
              bookingId: bookingId,
              status: ProcurementStatus.notAccepted,
              timestamp: DateTime.now(),
            ),
          ],
        );
        _notify(
          booking.farmerId,
          'Quality Result',
          'Your produce was not accepted based on the recorded inspection result.',
          NotificationKind.qualityResult,
        );
      case InspectionStatus.furtherInspection:
        _notify(
          booking.farmerId,
          'Further Inspection Required',
          'Procurement is temporarily pending. You will be notified when the inspection is updated.',
          NotificationKind.qualityResult,
        );
      case InspectionStatus.pending:
        break;
    }

    _persist();
    return OpResult(true, 'Inspection result recorded: ${result.label}.');
  }

  // ---------------------------------------------------------------------
  // Weighment / procurement
  // ---------------------------------------------------------------------

  OpResult submitWeighment({
    required String bookingId,
    required double actualQuantityQ,
  }) {
    final booking = state.bookings.where((b) => b.id == bookingId).firstOrNull;
    if (booking == null) return const OpResult(false, 'Booking not found.');

    final weighment = Weighment(
      id: 'weigh-${DateTime.now().microsecondsSinceEpoch}',
      bookingId: bookingId,
      expectedQuantityQ: booking.expectedQuantityQ,
      actualQuantityQ: actualQuantityQ,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(weighments: [...state.weighments, weighment]);
    _audit(
      'Operator',
      'Weighment Updated',
      'Weighment',
      weighment.id,
      newState: actualQuantityQ.toString(),
    );

    if (weighment.exceedsDeclared) {
      _persist();
      return const OpResult(
        true,
        'Quantity exceeds declared amount. Authorized review required before completion.',
      );
    }

    _completeProcurement(booking, actualQuantityQ);
    _persist();
    return const OpResult(
      true,
      'Weighment recorded and procurement completed.',
    );
  }

  OpResult confirmExcessWeighment(String bookingId) {
    final booking = state.bookings.where((b) => b.id == bookingId).firstOrNull;
    if (booking == null) return const OpResult(false, 'Booking not found.');
    final weighment = state.weighments
        .where((w) => w.bookingId == bookingId)
        .lastOrNull;
    if (weighment == null)
      return const OpResult(false, 'No weighment recorded.');

    _completeProcurement(booking, weighment.actualQuantityQ);
    _persist();
    return const OpResult(
      true,
      'Excess quantity approved. Procurement completed.',
    );
  }

  void _completeProcurement(Booking booking, double acceptedQuantityQ) {
    state = state.copyWith(
      bookings: state.bookings
          .map(
            (b) => b.id == booking.id
                ? b.copyWith(status: BookingStatus.completed)
                : b,
          )
          .toList(),
      queueEntries: state.queueEntries
          .map(
            (q) => q.bookingId == booking.id
                ? q.copyWith(stage: QueueStage.completed)
                : q,
          )
          .toList(),
      procurements: [
        ...state.procurements,
        Procurement(
          id: 'proc-${DateTime.now().microsecondsSinceEpoch}',
          bookingId: booking.id,
          status: ProcurementStatus.completed,
          acceptedQuantityQ: acceptedQuantityQ,
          timestamp: DateTime.now(),
        ),
      ],
      payments: [
        ...state.payments,
        Payment(
          id: 'pay-${DateTime.now().microsecondsSinceEpoch}',
          bookingId: booking.id,
          amount: acceptedQuantityQ * 2500,
          status: PaymentStatus.processing,
          lastUpdated: DateTime.now(),
        ),
      ],
      centres: state.centres
          .map(
            (c) => c.id == booking.centreId
                ? c.copyWith(
                    currentStorageQ: c.currentStorageQ + acceptedQuantityQ,
                  )
                : c,
          )
          .toList(),
    );
    _audit(
      'Operator',
      'Procurement Completed',
      'Procurement',
      booking.id,
      newState: 'completed',
    );
    _notify(
      booking.farmerId,
      'Procurement Complete',
      '${acceptedQuantityQ.toStringAsFixed(1)} Q accepted.',
      NotificationKind.procurementComplete,
    );
    _notify(
      booking.farmerId,
      'Payment',
      'Payment is being processed.',
      NotificationKind.payment,
    );
  }

  // ---------------------------------------------------------------------
  // Payment
  // ---------------------------------------------------------------------

  OpResult updatePaymentStatus(
    String bookingId,
    PaymentStatus status, {
    String? failureReason,
  }) {
    final payment = state.payments
        .where((p) => p.bookingId == bookingId)
        .lastOrNull;
    if (payment == null)
      return const OpResult(false, 'No payment record for this booking.');

    state = state.copyWith(
      payments: state.payments
          .map(
            (p) => p.id == payment.id
                ? p.copyWith(
                    status: status,
                    lastUpdated: DateTime.now(),
                    failureReason: failureReason,
                  )
                : p,
          )
          .toList(),
    );
    _audit(
      'Operator',
      'Payment Updated',
      'Payment',
      payment.id,
      newState: status.name,
    );

    final booking = state.bookings.firstWhere((b) => b.id == bookingId);
    final message = switch (status) {
      PaymentStatus.paid =>
        'Your payment of ₹${payment.amount.toStringAsFixed(0)} has been completed.',
      PaymentStatus.pending => 'Your payment is pending.',
      PaymentStatus.failed =>
        'Payment could not be completed. Procurement remains completed.',
      _ => 'Payment status updated.',
    };
    _notify(booking.farmerId, 'Payment', message, NotificationKind.payment);
    _persist();
    return const OpResult(true, 'Payment status updated.');
  }

  // ---------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------

  void markNotificationRead(String id) {
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.id == id ? n.copyWith(read: true) : n)
          .toList(),
    );
    _persist();
  }

  void markAllNotificationsRead(String userId) {
    state = state.copyWith(
      notifications: state.notifications
          .map(
            (n) => n.userId == userId || n.userId == 'all'
                ? n.copyWith(read: true)
                : n,
          )
          .toList(),
    );
    _persist();
  }

  String _fmtRange(DateTime start, DateTime end) {
    String two(int n) => n.toString().padLeft(2, '0');
    String h(DateTime t) =>
        '${two(t.hour % 12 == 0 ? 12 : t.hour % 12)}:${two(t.minute)} ${t.hour >= 12 ? 'PM' : 'AM'}';
    return '${h(start)} – ${h(end)}';
  }
}
