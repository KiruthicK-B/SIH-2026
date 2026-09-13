import '../../models/enums.dart';
import '../../widgets/status_badge.dart';

StatusTone toneForBookingStatus(BookingStatus s) => switch (s) {
  BookingStatus.accepted ||
  BookingStatus.paymentCompleted ||
  BookingStatus.checkedIn => StatusTone.success,
  BookingStatus.booked ||
  BookingStatus.inQueue ||
  BookingStatus.underQualityCheck ||
  BookingStatus.partiallyAccepted ||
  BookingStatus.paymentPending ||
  BookingStatus.paymentInitiated ||
  BookingStatus.waitlisted ||
  BookingStatus.rescheduleRequired => StatusTone.warning,
  BookingStatus.rejected ||
  BookingStatus.paymentFailed ||
  BookingStatus.cancelled ||
  BookingStatus.noShow => StatusTone.error,
};

StatusTone toneForCentreStatus(CentreStatus s) => switch (s) {
  CentreStatus.open => StatusTone.success,
  CentreStatus.temporarilyDisrupted => StatusTone.warning,
  CentreStatus.closed => StatusTone.error,
};

StatusTone toneForPaymentStatus(PaymentStatus s) => switch (s) {
  PaymentStatus.completed => StatusTone.success,
  PaymentStatus.processing || PaymentStatus.initiated => StatusTone.warning,
  PaymentStatus.failed => StatusTone.error,
  PaymentStatus.notInitiated => StatusTone.inactive,
};

StatusTone toneForGrievanceStatus(GrievanceStatus s) => switch (s) {
  GrievanceStatus.resolved => StatusTone.success,
  GrievanceStatus.open || GrievanceStatus.inReview => StatusTone.warning,
  GrievanceStatus.escalated => StatusTone.info,
  GrievanceStatus.rejected => StatusTone.error,
};
