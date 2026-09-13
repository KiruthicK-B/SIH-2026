import '../../models/booking.dart';
import '../../models/disruption.dart';
import '../../models/payment.dart';
import '../../models/procurement_record.dart';
import '../../models/queue_entry.dart';
import '../../models/reschedule_offer.dart';
import '../booking_repositories.dart';
import 'hive_json_repository.dart';

class LocalBookingRepository extends HiveJsonRepository<Booking>
    implements BookingRepository {
  LocalBookingRepository()
    : super(
        HiveBootstrap.box('bookings'),
        fromJson: Booking.fromJson,
        toJson: (b) => b.toJson(),
        idOf: (b) => b.id,
      );

  @override
  Future<List<Booking>> forFarmer(String farmerId) async =>
      (await getAll()).where((b) => b.farmerId == farmerId).toList();

  @override
  Future<List<Booking>> forCentre(String centreId) async =>
      (await getAll()).where((b) => b.centreId == centreId).toList();
}

class LocalQueueRepository extends HiveJsonRepository<QueueEntry>
    implements QueueRepository {
  LocalQueueRepository()
    : super(
        HiveBootstrap.box('queueEntries'),
        fromJson: QueueEntry.fromJson,
        toJson: (q) => q.toJson(),
        idOf: (q) => q.id,
      );

  @override
  Future<QueueEntry?> forBooking(String bookingId) async {
    final all = await getAll();
    for (final q in all) {
      if (q.bookingId == bookingId) return q;
    }
    return null;
  }
}

class LocalProcurementRepository extends HiveJsonRepository<ProcurementRecord>
    implements ProcurementRepository {
  LocalProcurementRepository()
    : super(
        HiveBootstrap.box('procurementRecords'),
        fromJson: ProcurementRecord.fromJson,
        toJson: (p) => p.toJson(),
        idOf: (p) => p.id,
      );

  @override
  Future<ProcurementRecord?> forBooking(String bookingId) async {
    final all = await getAll();
    for (final p in all) {
      if (p.bookingId == bookingId) return p;
    }
    return null;
  }
}

class LocalPaymentRepository extends HiveJsonRepository<Payment>
    implements PaymentRepository {
  LocalPaymentRepository()
    : super(
        HiveBootstrap.box('payments'),
        fromJson: Payment.fromJson,
        toJson: (p) => p.toJson(),
        idOf: (p) => p.id,
      );

  @override
  Future<Payment?> forBooking(String bookingId) async {
    final all = await getAll();
    for (final p in all) {
      if (p.bookingId == bookingId) return p;
    }
    return null;
  }

  @override
  Future<List<Payment>> forFarmer(String farmerId) async =>
      (await getAll()).where((p) => p.farmerId == farmerId).toList();
}

class LocalRescheduleOfferRepository
    extends HiveJsonRepository<RescheduleOffer>
    implements RescheduleOfferRepository {
  LocalRescheduleOfferRepository()
    : super(
        HiveBootstrap.box('rescheduleOffers'),
        fromJson: RescheduleOffer.fromJson,
        toJson: (r) => r.toJson(),
        idOf: (r) => r.id,
      );

  @override
  Future<List<RescheduleOffer>> forBooking(String bookingId) async =>
      (await getAll()).where((r) => r.bookingId == bookingId).toList();
}

class LocalDisruptionRepository extends HiveJsonRepository<Disruption>
    implements DisruptionRepository {
  LocalDisruptionRepository()
    : super(
        HiveBootstrap.box('disruptions'),
        fromJson: Disruption.fromJson,
        toJson: (d) => d.toJson(),
        idOf: (d) => d.id,
      );

  @override
  Future<List<Disruption>> forCentre(String centreId) async =>
      (await getAll()).where((d) => d.centreId == centreId).toList();

  @override
  Future<List<Disruption>> activeForCentre(String centreId) async =>
      (await getAll())
          .where(
            (d) =>
                d.centreId == centreId &&
                d.status.name == 'active',
          )
          .toList();
}
