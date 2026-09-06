import '../models/booking.dart';
import '../models/disruption.dart';
import '../models/payment.dart';
import '../models/procurement_record.dart';
import '../models/queue_entry.dart';
import '../models/reschedule_offer.dart';
import 'repository.dart';

abstract class BookingRepository extends Repository<Booking> {
  Future<List<Booking>> forFarmer(String farmerId);
  Future<List<Booking>> forCentre(String centreId);
}

abstract class QueueRepository extends Repository<QueueEntry> {
  Future<QueueEntry?> forBooking(String bookingId);
}

abstract class ProcurementRepository extends Repository<ProcurementRecord> {
  Future<ProcurementRecord?> forBooking(String bookingId);
}

abstract class PaymentRepository extends Repository<Payment> {
  Future<Payment?> forBooking(String bookingId);
  Future<List<Payment>> forFarmer(String farmerId);
}

abstract class RescheduleOfferRepository extends Repository<RescheduleOffer> {
  Future<List<RescheduleOffer>> forBooking(String bookingId);
}

abstract class DisruptionRepository extends Repository<Disruption> {
  Future<List<Disruption>> forCentre(String centreId);
  Future<List<Disruption>> activeForCentre(String centreId);
}
