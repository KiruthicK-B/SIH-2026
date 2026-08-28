/// All shared enums for AGRIVA. Kept together so status-transition rules
/// (README §102-103) can be reasoned about in one place.
library;

enum UserRole { farmer, operator, manager, admin }

enum BookingStatus {
  requested,
  held,
  confirmed,
  checkedIn,
  inQueue,
  processing,
  completed,
  notAccepted,
  cancelled,
  noShow,
  rescheduleRequired,
  waitlisted,
  expired,
}

enum CentreStatus { open, delayed, paused, closed }

enum QueueStage {
  arrived,
  qualityCheck,
  weighment,
  procurement,
  completed,
  exception,
}

enum InspectionStatus { pending, passed, notAccepted, furtherInspection }

enum PaymentStatus {
  notInitiated,
  initiated,
  processing,
  paid,
  pending,
  failed,
  exception,
}

enum DisruptionStatus { active, resolved, cancelled }

enum DisruptionType {
  weighingMachineFailure,
  powerFailure,
  networkIssue,
  labourShortage,
  storageUnavailable,
  inspectionDelay,
  centreClosure,
  generalOperationalDelay,
  capacityReduction,
}

enum SlotInvalidReason {
  insufficientQuantityCapacity,
  insufficientStorage,
  insufficientTravelTime,
  centrePaused,
  centreClosed,
  outsideOperatingHours,
  capacityReserved,
  disruptionActive,
}

enum StorageLevel { normal, nearFull, full }

extension UserRoleLabel on UserRole {
  String get label => switch (this) {
    UserRole.farmer => 'Farmer',
    UserRole.operator => 'Centre Operator',
    UserRole.manager => 'Centre Manager',
    UserRole.admin => 'Admin',
  };
}

extension BookingStatusLabel on BookingStatus {
  String get label => switch (this) {
    BookingStatus.requested => 'Requested',
    BookingStatus.held => 'Held',
    BookingStatus.confirmed => 'Confirmed',
    BookingStatus.checkedIn => 'Checked In',
    BookingStatus.inQueue => 'In Queue',
    BookingStatus.processing => 'Processing',
    BookingStatus.completed => 'Completed',
    BookingStatus.notAccepted => 'Not Accepted',
    BookingStatus.cancelled => 'Cancelled',
    BookingStatus.noShow => 'No-show',
    BookingStatus.rescheduleRequired => 'Reschedule Required',
    BookingStatus.waitlisted => 'Waitlisted',
    BookingStatus.expired => 'Expired',
  };
}

extension CentreStatusLabel on CentreStatus {
  String get label => switch (this) {
    CentreStatus.open => 'Open',
    CentreStatus.delayed => 'Delayed',
    CentreStatus.paused => 'Paused',
    CentreStatus.closed => 'Closed',
  };
}

extension QueueStageLabel on QueueStage {
  String get label => switch (this) {
    QueueStage.arrived => 'Arrived',
    QueueStage.qualityCheck => 'Quality Check',
    QueueStage.weighment => 'Weighment',
    QueueStage.procurement => 'Procurement',
    QueueStage.completed => 'Completed',
    QueueStage.exception => 'Exception',
  };
}

extension InspectionStatusLabel on InspectionStatus {
  String get label => switch (this) {
    InspectionStatus.pending => 'Pending',
    InspectionStatus.passed => 'Passed',
    InspectionStatus.notAccepted => 'Not Accepted',
    InspectionStatus.furtherInspection => 'Further Inspection',
  };
}

extension PaymentStatusLabel on PaymentStatus {
  String get label => switch (this) {
    PaymentStatus.notInitiated => 'Not Initiated',
    PaymentStatus.initiated => 'Initiated',
    PaymentStatus.processing => 'Processing',
    PaymentStatus.paid => 'Paid',
    PaymentStatus.pending => 'Pending',
    PaymentStatus.failed => 'Failed',
    PaymentStatus.exception => 'Exception',
  };
}

extension DisruptionTypeLabel on DisruptionType {
  String get label => switch (this) {
    DisruptionType.weighingMachineFailure => 'Weighing Machine Issue',
    DisruptionType.powerFailure => 'Power Failure',
    DisruptionType.networkIssue => 'Network Issue',
    DisruptionType.labourShortage => 'Labour Shortage',
    DisruptionType.storageUnavailable => 'Storage Unavailable',
    DisruptionType.inspectionDelay => 'Inspection Delay',
    DisruptionType.centreClosure => 'Centre Closure',
    DisruptionType.generalOperationalDelay => 'General Operational Delay',
    DisruptionType.capacityReduction => 'Capacity Reduction',
  };
}

extension SlotInvalidReasonLabel on SlotInvalidReason {
  String get label => switch (this) {
    SlotInvalidReason.insufficientQuantityCapacity =>
      'Not enough quantity capacity remaining',
    SlotInvalidReason.insufficientStorage =>
      'Not enough storage capacity remaining',
    SlotInvalidReason.insufficientTravelTime =>
      'Not enough travel time from your location',
    SlotInvalidReason.centrePaused => 'Centre has temporarily paused intake',
    SlotInvalidReason.centreClosed => 'Centre is closed',
    SlotInvalidReason.outsideOperatingHours => 'Outside centre operating hours',
    SlotInvalidReason.capacityReserved =>
      'Capacity already reserved by other farmers',
    SlotInvalidReason.disruptionActive => 'Centre disruption is active',
  };
}
