import '../models/booking.dart';
import '../models/centre.dart';
import '../models/enums.dart';
import '../models/slot.dart';

class CapacityService {
  const CapacityService();

  bool _isActiveForCapacity(Booking b) => [
    BookingStatus.requested,
    BookingStatus.held,
    BookingStatus.confirmed,
    BookingStatus.checkedIn,
    BookingStatus.inQueue,
    BookingStatus.processing,
    BookingStatus.completed,
  ].contains(b.status);

  int bookedFarmersForSlot(Slot slot, List<Booking> bookings) {
    final real = bookings
        .where((b) => b.slotId == slot.id && _isActiveForCapacity(b))
        .length;
    return slot.baselineFarmers + real;
  }

  double bookedQuantityForSlot(Slot slot, List<Booking> bookings) {
    final real = bookings
        .where((b) => b.slotId == slot.id && _isActiveForCapacity(b))
        .fold<double>(0, (sum, b) => sum + b.expectedQuantityQ);
    return slot.baselineQuantityQ + real;
  }

  int remainingSlotFarmerCapacity(Slot slot, List<Booking> bookings) {
    return slot.maxFarmers - bookedFarmersForSlot(slot, bookings);
  }

  double remainingSlotQuantityCapacity(Slot slot, List<Booking> bookings) {
    return slot.maxQuantityQ - bookedQuantityForSlot(slot, bookings);
  }

  /// Remaining daily processing capacity across every slot at [centre] on
  /// the given [day].
  double getRemainingDailyCapacity(
    ProcurementCentre centre,
    DateTime day,
    List<Slot> slots,
    List<Booking> bookings,
  ) {
    final daySlots = slots.where(
      (s) => s.centreId == centre.id && s.date == day,
    );
    final bookedToday = daySlots.fold<double>(
      0,
      (sum, s) => sum + bookedQuantityForSlot(s, bookings),
    );
    return centre.dailyProcessingCapacityQ - bookedToday;
  }

  double getStorageAvailable(ProcurementCentre centre) =>
      centre.storageAvailableQ;

  double getProjectedStorage(ProcurementCentre centre, double additionalQ) =>
      centre.currentStorageQ + additionalQ;

  double getEffectiveProcessingRate(ProcurementCentre centre) =>
      centre.effectiveProcessingRate;

  bool getCentreOperationalCapacity(ProcurementCentre centre) =>
      centre.status == CentreStatus.open;
}
