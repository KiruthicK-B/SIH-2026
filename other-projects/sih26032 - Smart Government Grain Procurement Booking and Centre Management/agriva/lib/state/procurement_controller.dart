import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/notification.dart';
import '../models/payment.dart';
import '../models/procurement_record.dart';
import '../repositories/booking_repositories.dart';
import '../repositories/repository_providers.dart';
import 'data_revision.dart';
import 'op_result.dart';

final procurementForBookingProvider =
    FutureProvider.family<ProcurementRecord?, String>((ref, bookingId) {
      ref.watch(dataRevisionProvider);
      return ref.read(procurementRepositoryProvider).forBooking(bookingId);
    });

final paymentForBookingProvider = FutureProvider.family<Payment?, String>((
  ref,
  bookingId,
) {
  ref.watch(dataRevisionProvider);
  return ref.read(paymentRepositoryProvider).forBooking(bookingId);
});

final paymentsForFarmerProvider = FutureProvider.family<List<Payment>, String>(
  (ref, farmerId) {
    ref.watch(dataRevisionProvider);
    return ref.read(paymentRepositoryProvider).forFarmer(farmerId);
  },
);

final paymentsForCentreProvider = FutureProvider.family<List<Payment>, String>((
  ref,
  centreId,
) async {
  ref.watch(dataRevisionProvider);
  final centreBookingIds = (await ref.read(bookingRepositoryProvider).forCentre(centreId))
      .map((b) => b.id)
      .toSet();
  final all = await ref.read(paymentRepositoryProvider).getAll();
  return all.where((p) => centreBookingIds.contains(p.bookingId)).toList()
    ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
});

final procurementControllerProvider = Provider<ProcurementController>(
  (ref) => ProcurementController(ref),
);

/// Operator quality-check + weighment flow (README §5.2), writing into one
/// unified [ProcurementRecord] and driving the booking through
/// underQualityCheck → accepted/partiallyAccepted/rejected →
/// paymentPending → paymentInitiated → paymentCompleted/paymentFailed.
class ProcurementController {
  final Ref ref;
  const ProcurementController(this.ref);

  BookingRepository get _bookingRepo => ref.read(bookingRepositoryProvider);
  QueueRepository get _queueRepo => ref.read(queueRepositoryProvider);
  ProcurementRepository get _procurementRepo =>
      ref.read(procurementRepositoryProvider);
  PaymentRepository get _paymentRepo => ref.read(paymentRepositoryProvider);

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

  /// Quality check happens before weighment. A mandatory [rejectionReason]
  /// is required when [passed] is false (README §5.2).
  Future<OpResult> submitQualityCheck({
    required String bookingId,
    required double moisturePercent,
    required bool passed,
    String? rejectionReason,
    required String inspector,
  }) async {
    final booking = await _bookingRepo.getById(bookingId);
    if (booking == null) return const OpResult(false, 'Booking not found.');
    if (!passed && (rejectionReason == null || rejectionReason.trim().isEmpty)) {
      return const OpResult(false, 'A rejection reason is required.');
    }

    final existing = await _procurementRepo.forBooking(bookingId);
    final record = ProcurementRecord(
      id: existing?.id ?? 'proc-${DateTime.now().microsecondsSinceEpoch}',
      bookingId: bookingId,
      moisturePercent: moisturePercent,
      rejectionReason: passed ? null : rejectionReason,
      acceptedQuantityQ: passed ? existing?.acceptedQuantityQ : 0,
      rejectedQuantityQ: passed ? existing?.rejectedQuantityQ : booking.expectedQuantityQ,
      inspectedBy: inspector,
      inspectionTime: DateTime.now(),
    );
    await _procurementRepo.save(record);

    if (!passed) {
      await _bookingRepo.save(booking.copyWith(status: BookingStatus.rejected));
      final entry = await _queueRepo.forBooking(bookingId);
      if (entry != null) {
        await _queueRepo.save(entry.copyWith(stage: QueueStage.exception));
      }
      await _notify(
        booking.farmerId,
        'Quality Result',
        'Your produce was not accepted: $rejectionReason',
        NotificationType.rejection,
      );
      _bump();
      return const OpResult(true, 'Rejection recorded.');
    }

    final entry = await _queueRepo.forBooking(bookingId);
    if (entry != null) {
      await _queueRepo.save(entry.copyWith(stage: QueueStage.weighment));
    }
    await _notify(
      booking.farmerId,
      'Quality Check Passed',
      'Proceeding to weighment.',
      NotificationType.qualityResult,
    );
    _bump();
    return const OpResult(true, 'Quality check passed. Proceed to weighment.');
  }

  /// [acceptedQuantityQ] + [rejectedQuantityQ] should sum to
  /// [weighedQuantityQ]; a mandatory reason is required whenever any
  /// quantity is rejected (README §5.2 "mandatory reason").
  Future<OpResult> submitWeighment({
    required String bookingId,
    required double weighedQuantityQ,
    required double acceptedQuantityQ,
    required double rejectedQuantityQ,
    String? rejectionReason,
    String? qualityGrade,
    required String inspector,
  }) async {
    final booking = await _bookingRepo.getById(bookingId);
    if (booking == null) return const OpResult(false, 'Booking not found.');
    if (rejectedQuantityQ > 0 &&
        (rejectionReason == null || rejectionReason.trim().isEmpty)) {
      return const OpResult(
        false,
        'A rejection reason is required for the rejected quantity.',
      );
    }

    final existing = await _procurementRepo.forBooking(bookingId);
    final record = (existing ??
            ProcurementRecord(
              id: 'proc-${DateTime.now().microsecondsSinceEpoch}',
              bookingId: bookingId,
              inspectedBy: inspector,
              inspectionTime: DateTime.now(),
            ))
        .copyWith(
      weighedQuantityQ: weighedQuantityQ,
      acceptedQuantityQ: acceptedQuantityQ,
      rejectedQuantityQ: rejectedQuantityQ,
      rejectionReason: rejectionReason,
      qualityGrade: qualityGrade,
    );
    await _procurementRepo.save(record);

    final newStatus = acceptedQuantityQ <= 0
        ? BookingStatus.rejected
        : (rejectedQuantityQ > 0
              ? BookingStatus.partiallyAccepted
              : BookingStatus.accepted);
    await _bookingRepo.save(booking.copyWith(status: newStatus));

    final entry = await _queueRepo.forBooking(bookingId);
    if (entry != null) {
      await _queueRepo.save(
        entry.copyWith(
          stage: newStatus == BookingStatus.rejected
              ? QueueStage.exception
              : QueueStage.completed,
        ),
      );
    }

    if (acceptedQuantityQ > 0) {
      // README uses a flat MSP-independent demo rate here; crop-specific
      // MSP lookups are applied at booking time in a real backend.
      await _paymentRepo.save(
        Payment(
          id: 'pay-${DateTime.now().microsecondsSinceEpoch}',
          bookingId: bookingId,
          farmerId: booking.farmerId,
          amount: acceptedQuantityQ * 2500,
          status: PaymentStatus.notInitiated,
          lastUpdated: DateTime.now(),
        ),
      );
    }

    final message = switch (newStatus) {
      BookingStatus.rejected => 'Your produce was not accepted: $rejectionReason',
      BookingStatus.partiallyAccepted =>
        '${acceptedQuantityQ.toStringAsFixed(1)} Q accepted, ${rejectedQuantityQ.toStringAsFixed(1)} Q rejected.',
      _ => '${acceptedQuantityQ.toStringAsFixed(1)} Q accepted in full.',
    };
    await _notify(
      booking.farmerId,
      'Procurement Result',
      message,
      newStatus == BookingStatus.rejected
          ? NotificationType.rejection
          : NotificationType.procurementComplete,
    );
    _bump();
    return OpResult(true, message);
  }

  Future<OpResult> flagDispute(String bookingId, String note) async {
    final record = await _procurementRepo.forBooking(bookingId);
    if (record == null) return const OpResult(false, 'No procurement record yet.');
    await _procurementRepo.save(
      record.copyWith(disputeRaised: true, disputeNote: note),
    );
    _bump();
    return const OpResult(true, 'Dispute flagged for review.');
  }

  // ---------------------------------------------------------------------
  // Payment
  // ---------------------------------------------------------------------

  Future<OpResult> initiatePayment(String bookingId) async {
    final booking = await _bookingRepo.getById(bookingId);
    final payment = await _paymentRepo.forBooking(bookingId);
    if (booking == null || payment == null) {
      return const OpResult(false, 'No payment record for this booking.');
    }
    await _paymentRepo.save(
      payment.copyWith(
        status: PaymentStatus.initiated,
        initiatedAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        transactionRef: 'AGV-PAY-${DateTime.now().millisecondsSinceEpoch}',
      ),
    );
    await _bookingRepo.save(booking.copyWith(status: BookingStatus.paymentInitiated));
    await _notify(
      booking.farmerId,
      'Payment Initiated',
      'Your payment of ₹${payment.amount.toStringAsFixed(0)} is being processed.',
      NotificationType.paymentUpdate,
    );
    _bump();
    return const OpResult(true, 'Payment initiated.');
  }

  Future<OpResult> updatePaymentStatus(
    String bookingId,
    PaymentStatus status, {
    String? failureReason,
  }) async {
    final booking = await _bookingRepo.getById(bookingId);
    final payment = await _paymentRepo.forBooking(bookingId);
    if (booking == null || payment == null) {
      return const OpResult(false, 'No payment record for this booking.');
    }
    await _paymentRepo.save(
      payment.copyWith(
        status: status,
        lastUpdated: DateTime.now(),
        failureReason: failureReason,
        completedAt: status == PaymentStatus.completed ? DateTime.now() : null,
        retryCount: status == PaymentStatus.failed
            ? payment.retryCount + 1
            : payment.retryCount,
      ),
    );
    final bookingStatus = switch (status) {
      PaymentStatus.completed => BookingStatus.paymentCompleted,
      PaymentStatus.failed => BookingStatus.paymentFailed,
      PaymentStatus.processing || PaymentStatus.initiated =>
        BookingStatus.paymentInitiated,
      PaymentStatus.notInitiated => BookingStatus.paymentPending,
    };
    await _bookingRepo.save(booking.copyWith(status: bookingStatus));

    final message = switch (status) {
      PaymentStatus.completed =>
        'Your payment of ₹${payment.amount.toStringAsFixed(0)} has been completed.',
      PaymentStatus.failed =>
        'Payment could not be completed${failureReason != null ? ': $failureReason' : '.'}',
      PaymentStatus.processing => 'Your payment is being processed.',
      _ => 'Payment status updated.',
    };
    await _notify(booking.farmerId, 'Payment', message, NotificationType.paymentUpdate);
    _bump();
    return const OpResult(true, 'Payment status updated.');
  }
}
