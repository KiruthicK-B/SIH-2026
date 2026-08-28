import '../../models/enums.dart';
import '../../widgets/status_badge.dart';

StatusTone toneForBookingStatus(BookingStatus s) => switch (s) {
  BookingStatus.confirmed ||
  BookingStatus.checkedIn ||
  BookingStatus.completed => StatusTone.success,
  BookingStatus.inQueue ||
  BookingStatus.processing ||
  BookingStatus.waitlisted => StatusTone.warning,
  BookingStatus.notAccepted ||
  BookingStatus.cancelled ||
  BookingStatus.noShow => StatusTone.error,
  BookingStatus.rescheduleRequired => StatusTone.warning,
  _ => StatusTone.inactive,
};

StatusTone toneForCentreStatus(CentreStatus s) => switch (s) {
  CentreStatus.open => StatusTone.success,
  CentreStatus.delayed => StatusTone.warning,
  CentreStatus.paused || CentreStatus.closed => StatusTone.error,
};

StatusTone toneForPaymentStatus(PaymentStatus s) => switch (s) {
  PaymentStatus.paid => StatusTone.success,
  PaymentStatus.processing ||
  PaymentStatus.initiated ||
  PaymentStatus.pending => StatusTone.warning,
  PaymentStatus.failed || PaymentStatus.exception => StatusTone.error,
  PaymentStatus.notInitiated => StatusTone.inactive,
};

StatusTone toneForInspection(InspectionStatus s) => switch (s) {
  InspectionStatus.passed => StatusTone.success,
  InspectionStatus.furtherInspection => StatusTone.warning,
  InspectionStatus.notAccepted => StatusTone.error,
  InspectionStatus.pending => StatusTone.inactive,
};
