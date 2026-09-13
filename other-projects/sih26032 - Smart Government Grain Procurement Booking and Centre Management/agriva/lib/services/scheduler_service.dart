import '../models/booking.dart';
import '../models/centre.dart';
import '../models/disruption.dart';
import '../models/enums.dart';
import '../models/farmer.dart';
import '../models/slot.dart';
import 'capacity_service.dart';

class SlotRecommendation {
  final Slot slot;
  final bool feasible;
  final double score;
  final String reason;
  final SlotInvalidReason? invalidReason;
  final bool isRecommended;
  final int remainingFarmerSlots;
  final double remainingQuantityQ;

  const SlotRecommendation({
    required this.slot,
    required this.feasible,
    required this.score,
    required this.reason,
    this.invalidReason,
    this.isRecommended = false,
    required this.remainingFarmerSlots,
    required this.remainingQuantityQ,
  });

  SlotRecommendation copyWith({bool? isRecommended}) => SlotRecommendation(
    slot: slot,
    feasible: feasible,
    score: score,
    reason: reason,
    invalidReason: invalidReason,
    isRecommended: isRecommended ?? this.isRecommended,
    remainingFarmerSlots: remainingFarmerSlots,
    remainingQuantityQ: remainingQuantityQ,
  );
}

/// Deterministic, capacity-aware, travel-aware slot recommendation engine.
/// No machine learning — every decision is explainable (README §22-25).
class SchedulerService {
  const SchedulerService();

  static const _capacity = CapacityService();
  static const int _serviceMinutesPerFarmer = 15;

  List<SlotRecommendation> getRecommendedSlots({
    required Farmer farmer,
    required ProcurementCentre centre,
    required DateTime date,
    required double expectedQuantityQ,
    required List<Slot> slots,
    required List<Booking> bookings,
    required List<Disruption> disruptions,
    required DateTime now,
  }) {
    final candidateSlots =
        slots.where((s) => s.centreId == centre.id && s.date == date).toList()
          ..sort((a, b) => a.start.compareTo(b.start));

    final activeDisruptionSlotIds = disruptions
        .where(
          (d) => d.centreId == centre.id && d.status == DisruptionStatus.active,
        )
        .expand((d) => d.affectedSlotIds)
        .toSet();

    // If testing late in the evening or night for 'today', all operating slots
    // may have elapsed. In that demo scenario, do not hide all slots.
    final allInPast = candidateSlots.isNotEmpty &&
        candidateSlots.every((s) => s.start.isBefore(now));

    final results = <SlotRecommendation>[];

    for (final slot in candidateSlots) {
      final remainingFarmers = _capacity.remainingSlotFarmerCapacity(
        slot,
        bookings,
      );
      final remainingQuantity = _capacity.remainingSlotQuantityCapacity(
        slot,
        bookings,
      );
      final remainingDaily = _capacity.getRemainingDailyCapacity(
        centre,
        date,
        slots,
        bookings,
      );
      final projectedStorage = _capacity.getProjectedStorage(
        centre,
        expectedQuantityQ,
      );

      SlotInvalidReason? invalidReason;

      if (!allInPast && slot.start.isBefore(now)) {
        continue; // past slot — never offered when active future slots exist
      }
      if (centre.status == CentreStatus.closed) {
        invalidReason = SlotInvalidReason.centreClosed;
      } else if (centre.status == CentreStatus.temporarilyDisrupted) {
        invalidReason = SlotInvalidReason.centrePaused;
      } else if (activeDisruptionSlotIds.contains(slot.id)) {
        invalidReason = SlotInvalidReason.disruptionActive;
      } else if (slot.start.hour < centre.operatingStartHour ||
          slot.end.hour > centre.operatingEndHour) {
        invalidReason = SlotInvalidReason.outsideOperatingHours;
      } else {
        final requiredArrival = now.add(
          Duration(minutes: farmer.estimatedTravelMinutes),
        );
        if (!allInPast && slot.start.isBefore(requiredArrival)) {
          invalidReason = SlotInvalidReason.insufficientTravelTime;
        } else if (remainingFarmers <= 0) {
          invalidReason = SlotInvalidReason.capacityReserved;
        } else if (remainingQuantity < expectedQuantityQ ||
            remainingDaily < expectedQuantityQ) {
          invalidReason = SlotInvalidReason.insufficientQuantityCapacity;
        } else if (projectedStorage > centre.storageCapacityQ) {
          invalidReason = SlotInvalidReason.insufficientStorage;
        }
      }

      final feasible = invalidReason == null;

      double score = 0;
      String reason;

      if (feasible) {
        final quantityMargin = slot.maxQuantityQ == 0
            ? 0.0
            : remainingQuantity / slot.maxQuantityQ;
        final farmerMargin = slot.maxFarmers == 0
            ? 0.0
            : remainingFarmers / slot.maxFarmers;
        final bufferMinutes = allInPast
            ? 60
            : (slot.start.difference(now).inMinutes -
                farmer.estimatedTravelMinutes);
        final bufferScore = bufferMinutes.clamp(0, 180) / 180;
        // Earlier slots score slightly higher so the recommendation favours
        // the soonest genuinely feasible option, not just the emptiest one.
        final earlinessScore =
            1 - (candidateSlots.indexOf(slot) / candidateSlots.length);

        score =
            quantityMargin * 45 +
            farmerMargin * 25 +
            bufferScore * 15 +
            earlinessScore * 15;

        final reasons = <String>[];
        if (quantityMargin > 0.3) reasons.add('enough capacity');
        if (bufferMinutes >= 30) {
          reasons.add('sufficient travel time for your location');
        }
        if (reasons.isEmpty) reasons.add('meets all booking requirements');
        reason = reasons.join(' and ');
      } else {
        reason = invalidReason.label;
      }

      results.add(
        SlotRecommendation(
          slot: slot,
          feasible: feasible,
          score: score,
          reason: reason,
          invalidReason: invalidReason,
          remainingFarmerSlots: remainingFarmers < 0 ? 0 : remainingFarmers,
          remainingQuantityQ: remainingQuantity < 0 ? 0 : remainingQuantity,
        ),
      );
    }

    // Mark the single highest-scoring feasible slot as recommended.
    final feasibleOnes = results.where((r) => r.feasible).toList();
    if (feasibleOnes.isEmpty) return results;
    feasibleOnes.sort((a, b) => b.score.compareTo(a.score));
    final topId = feasibleOnes.first.slot.id;

    return results
        .map((r) => r.slot.id == topId ? r.copyWith(isRecommended: true) : r)
        .toList();
  }

  /// Estimated wait for a farmer at [queuePosition] given how many
  /// processing lanes are actively serving farmers right now.
  int estimateWaitMinutes({
    required int queuePosition,
    required int activeLanes,
  }) {
    final lanes = activeLanes <= 0 ? 1 : activeLanes;
    return ((queuePosition * _serviceMinutesPerFarmer) / lanes).ceil();
  }
}
