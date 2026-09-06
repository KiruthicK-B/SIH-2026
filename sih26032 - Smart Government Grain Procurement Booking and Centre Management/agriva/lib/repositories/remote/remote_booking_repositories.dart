import '../../models/booking.dart';
import '../../models/disruption.dart';
import '../../models/payment.dart';
import '../../models/procurement_record.dart';
import '../../models/queue_entry.dart';
import '../../models/reschedule_offer.dart';
import '../booking_repositories.dart';
import 'http_json_repository.dart';

class RemoteBookingRepository extends HttpJsonRepository<Booking>
    implements BookingRepository {
  RemoteBookingRepository()
    : super(
        'bookings',
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

class RemoteQueueRepository extends HttpJsonRepository<QueueEntry>
    implements QueueRepository {
  RemoteQueueRepository()
    : super(
        'queueEntries',
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

class RemoteProcurementRepository extends HttpJsonRepository<ProcurementRecord>
    implements ProcurementRepository {
  RemoteProcurementRepository()
    : super(
        'procurementRecords',
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

class RemotePaymentRepository extends HttpJsonRepository<Payment>
    implements PaymentRepository {
  RemotePaymentRepository()
    : super(
        'payments',
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

class RemoteRescheduleOfferRepository
    extends HttpJsonRepository<RescheduleOffer>
    implements RescheduleOfferRepository {
  RemoteRescheduleOfferRepository()
    : super(
        'rescheduleOffers',
        fromJson: RescheduleOffer.fromJson,
        toJson: (r) => r.toJson(),
        idOf: (r) => r.id,
      );

  @override
  Future<List<RescheduleOffer>> forBooking(String bookingId) async =>
      (await getAll()).where((r) => r.bookingId == bookingId).toList();
}

class RemoteDisruptionRepository extends HttpJsonRepository<Disruption>
    implements DisruptionRepository {
  RemoteDisruptionRepository()
    : super(
        'disruptions',
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
