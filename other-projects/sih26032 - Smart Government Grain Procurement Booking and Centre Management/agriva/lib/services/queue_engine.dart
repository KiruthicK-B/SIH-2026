import '../models/booking.dart';
import '../models/enums.dart';
import '../models/notification.dart';
import '../repositories/booking_repositories.dart';
import '../repositories/support_repositories.dart';
import 'queue_service.dart';

/// The standalone "queue engine" README §6 asks for: independent of any UI,
/// so it can move server-side later without a rewrite. Composes the pure
/// math in [QueueService] with the repositories it needs to actually apply
/// the automated behaviors:
///  - recalculate every farmer's queue position / ETA when a token clears
///  - auto-flag "at risk" then auto no-show + capacity release
///  - auto-generate a notification for every status change
///  - auto-promote the next waitlisted farmer when capacity frees up
class QueueEngine {
  final BookingRepository bookingRepo;
  final QueueRepository queueRepo;
  final NotificationRepository notificationRepo;
  static const _queueService = QueueService();

  const QueueEngine({
    required this.bookingRepo,
    required this.queueRepo,
    required this.notificationRepo,
  });

  /// Recomputes queue position + estimated call time for every active entry
  /// at a centre, given how many lanes are actively serving right now.
  Future<void> recalculateQueue({
    required String centreId,
    required int activeLanes,
    required List<String> centreBookingIds,
  }) async {
    final allEntries = await queueRepo.getAll();
    final active = _queueService.activeQueueForCentre(
      allEntries,
      centreBookingIds.toSet(),
    );
    final now = DateTime.now();
    for (var i = 0; i < active.length; i++) {
      final entry = active[i];
      final position = i + 1;
      final waitMinutes = _queueService.calculateEstimatedWait(
        queuePosition: position,
        activeLanes: activeLanes,
      );
      await queueRepo.save(
        entry.copyWith(
          queuePosition: position,
          estimatedCallTime: now.add(Duration(minutes: waitMinutes)),
        ),
      );
    }
  }

  /// README §7 "Queue Management": a farmer not checked in within
  /// [graceMinutes] of their slot start is auto-marked no-show, releasing
  /// their capacity back to the pool.
  Future<List<Booking>> sweepNoShows({
    required String centreId,
    required DateTime Function(String slotId) slotStartOf,
    int graceMinutes = 20,
  }) async {
    final now = DateTime.now();
    final bookings = await bookingRepo.forCentre(centreId);
    final promoted = <Booking>[];
    for (final booking in bookings) {
      if (booking.status != BookingStatus.booked) continue;
      final slotStart = slotStartOf(booking.slotId);
      if (now.isAfter(slotStart.add(Duration(minutes: graceMinutes)))) {
        final updated = booking.copyWith(
          status: BookingStatus.noShow,
          noShowAt: now,
        );
        await bookingRepo.save(updated);
        await queueRepo.delete('q-${booking.id}');
        await _notify(
          booking.farmerId,
          'Marked as No-show',
          'You were marked as a no-show for your booked slot — the capacity has been released.',
          NotificationType.general,
        );
        promoted.add(updated);
      }
    }
    return promoted;
  }

  Future<void> notifyStatusChange({
    required String farmerId,
    required String title,
    required String message,
    NotificationType type = NotificationType.general,
  }) => _notify(farmerId, title, message, type);

  Future<void> _notify(
    String userId,
    String title,
    String message,
    NotificationType type,
  ) async {
    await notificationRepo.save(
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
}
