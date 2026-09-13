import '../models/booking.dart';
import '../models/centre.dart';
import '../models/disruption.dart';
import '../models/enums.dart';
import '../models/farmer.dart';
import '../models/slot.dart';
import 'scheduler_service.dart';

class RescheduleCandidate {
  final SlotRecommendation recommendation;
  final bool isSameDay;

  const RescheduleCandidate({
    required this.recommendation,
    required this.isSameDay,
  });
}

/// Finds affected bookings when a disruption is declared, and generates
/// travel-aware, capacity-aware replacement offers (README §48-51).
class ReschedulerService {
  const ReschedulerService();

  static const _scheduler = SchedulerService();

  List<Booking> findAffectedBookings(
    Disruption disruption,
    List<Booking> bookings,
  ) {
    const activeStatuses = [
      BookingStatus.booked,
      BookingStatus.checkedIn,
      BookingStatus.inQueue,
    ];
    return bookings
        .where(
          (b) =>
              disruption.affectedSlotIds.contains(b.slotId) &&
              activeStatuses.contains(b.status),
        )
        .toList();
  }

  /// Ranked replacement slots across today (remaining hours) and tomorrow
  /// at the same centre, respecting the same feasibility rules as a fresh
  /// booking — including travel time from the farmer's location.
  List<RescheduleCandidate> findReplacementSlots({
    required Farmer farmer,
    required ProcurementCentre centre,
    required double expectedQuantityQ,
    required List<Slot> slots,
    required List<Booking> bookings,
    required List<Disruption> disruptions,
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final candidates = <RescheduleCandidate>[];

    for (final day in [today, tomorrow]) {
      final recs = _scheduler.getRecommendedSlots(
        farmer: farmer,
        centre: centre,
        date: day,
        expectedQuantityQ: expectedQuantityQ,
        slots: slots,
        bookings: bookings,
        disruptions: disruptions,
        now: now,
      );
      for (final r in recs.where((r) => r.feasible)) {
        candidates.add(
          RescheduleCandidate(recommendation: r, isSameDay: day == today),
        );
      }
    }

    candidates.sort(
      (a, b) => b.recommendation.score.compareTo(a.recommendation.score),
    );
    return candidates;
  }
}
