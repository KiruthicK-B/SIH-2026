/// All shared enums for AGRIVA. Kept together so status-transition rules
/// (README §4, §6) can be reasoned about in one place.
///
/// Where the README's own enumeration is a floor rather than a ceiling
/// (it says as much explicitly for languages, and the same spirit applies
/// to internal operational detail), a few extra values are kept alongside
/// the spec's values when the existing queue/disruption logic genuinely
/// needs the finer granularity — each is called out below.
library;

enum UserRole { farmer, centreOperator, districtAdmin, stateAdmin }

/// README §4 booking lifecycle, exactly:
/// Booked → Checked-In → In-Queue → Under Quality Check →
/// Accepted / Partially-Accepted / Rejected → Payment Pending →
/// Payment Initiated → Payment Completed / Payment Failed
/// plus the alternate terminal paths: Cancelled, No-Show, Waitlisted.
/// `rescheduleRequired` is an extra transient state (not in the spec list)
/// needed by the existing disruption-driven rebooking flow — a booking
/// sits here between "centre can no longer honour the original slot" and
/// "farmer accepted/declined a replacement".
enum BookingStatus {
  booked,
  checkedIn,
  inQueue,
  underQualityCheck,
  accepted,
  partiallyAccepted,
  rejected,
  paymentPending,
  paymentInitiated,
  paymentCompleted,
  paymentFailed,
  cancelled,
  noShow,
  waitlisted,
  rescheduleRequired,
}

/// README §4 ProcurementCentre.status is a 3-state (open/closed/
/// temporarily_disrupted) summary; the underlying disruption record still
/// carries the specific type/expected-resolution detail operators need.
enum CentreStatus { open, temporarilyDisrupted, closed }

/// Fine-grained internal stage feeding a booking's coarser
/// `underQualityCheck` status — operator-facing detail, not itself part of
/// the farmer-facing lifecycle.
enum QueueStage {
  arrived,
  qualityCheck,
  weighment,
  procurement,
  completed,
  exception,
}

/// README §4 Payment.status, plus `processing` — kept distinct from
/// `initiated` because README §5.1 explicitly requires the UI to
/// distinguish "agency hasn't released funds" from "processing" from
/// "credited" as different problems with different resolutions.
enum PaymentStatus { notInitiated, initiated, processing, completed, failed }

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

/// README §4 Grievance.category
enum GrievanceCategory {
  qualityDispute,
  paymentDelay,
  slotIssue,
  impersonation,
  other,
}

/// README §4 Grievance.status
enum GrievanceStatus { open, inReview, escalated, resolved, rejected }

/// README §4 Grievance.escalationLevel
enum EscalationLevel { centre, district, state }

/// README §4 Notification.channel
enum NotificationChannel { sms, app, both }

/// README §4 Notification.deliveryStatus
enum NotificationDeliveryStatus { sent, failed, pending, retrying }

/// README §4 Notification.type, plus a few operational extras the existing
/// queue/reschedule engine relies on (rescheduleRequired, newSlotOffered,
/// qualityResult, procurementComplete) that are more specific than the
/// spec's own `queue_update`/`general` buckets.
enum NotificationType {
  slotConfirmation,
  reminder,
  queueUpdate,
  delay,
  paymentUpdate,
  rejection,
  grievanceUpdate,
  broadcast,
  general,
  rescheduleRequired,
  newSlotOffered,
  qualityResult,
  procurementComplete,
}

/// README §4 LandRecord.ownershipType
enum LandOwnershipType { owner, tenant, sharecropper }

/// README §4 Crop.season
enum CropSeason { rabi, kharif, zaid }

extension UserRoleLabel on UserRole {
  String get label => switch (this) {
    UserRole.farmer => 'Farmer',
    UserRole.centreOperator => 'Centre Operator',
    UserRole.districtAdmin => 'District Admin',
    UserRole.stateAdmin => 'State Admin',
  };
}

extension BookingStatusLabel on BookingStatus {
  String get label => switch (this) {
    BookingStatus.booked => 'Booked',
    BookingStatus.checkedIn => 'Checked-In',
    BookingStatus.inQueue => 'In Queue',
    BookingStatus.underQualityCheck => 'Under Quality Check',
    BookingStatus.accepted => 'Accepted',
    BookingStatus.partiallyAccepted => 'Partially Accepted',
    BookingStatus.rejected => 'Rejected',
    BookingStatus.paymentPending => 'Payment Pending',
    BookingStatus.paymentInitiated => 'Payment Initiated',
    BookingStatus.paymentCompleted => 'Payment Completed',
    BookingStatus.paymentFailed => 'Payment Failed',
    BookingStatus.cancelled => 'Cancelled',
    BookingStatus.noShow => 'No-show',
    BookingStatus.waitlisted => 'Waitlisted',
    BookingStatus.rescheduleRequired => 'Reschedule Required',
  };
}

extension CentreStatusLabel on CentreStatus {
  String get label => switch (this) {
    CentreStatus.open => 'Open',
    CentreStatus.temporarilyDisrupted => 'Temporarily Disrupted',
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

extension PaymentStatusLabel on PaymentStatus {
  String get label => switch (this) {
    PaymentStatus.notInitiated => 'Not Initiated',
    PaymentStatus.initiated => 'Initiated',
    PaymentStatus.processing => 'Processing',
    PaymentStatus.completed => 'Completed',
    PaymentStatus.failed => 'Failed',
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

extension GrievanceCategoryLabel on GrievanceCategory {
  String get label => switch (this) {
    GrievanceCategory.qualityDispute => 'Quality Dispute',
    GrievanceCategory.paymentDelay => 'Payment Delay',
    GrievanceCategory.slotIssue => 'Slot Issue',
    GrievanceCategory.impersonation => 'Impersonation',
    GrievanceCategory.other => 'Other',
  };
}

extension GrievanceStatusLabel on GrievanceStatus {
  String get label => switch (this) {
    GrievanceStatus.open => 'Open',
    GrievanceStatus.inReview => 'In Review',
    GrievanceStatus.escalated => 'Escalated',
    GrievanceStatus.resolved => 'Resolved',
    GrievanceStatus.rejected => 'Rejected',
  };
}

extension EscalationLevelLabel on EscalationLevel {
  String get label => switch (this) {
    EscalationLevel.centre => 'Centre',
    EscalationLevel.district => 'District',
    EscalationLevel.state => 'State',
  };
}

extension CropSeasonLabel on CropSeason {
  String get label => switch (this) {
    CropSeason.rabi => 'Rabi',
    CropSeason.kharif => 'Kharif',
    CropSeason.zaid => 'Zaid',
  };
}

extension LandOwnershipTypeLabel on LandOwnershipType {
  String get label => switch (this) {
    LandOwnershipType.owner => 'Owner',
    LandOwnershipType.tenant => 'Tenant',
    LandOwnershipType.sharecropper => 'Sharecropper',
  };
}

enum FarmerVerificationStatus {
  pendingApproval,
  approved,
  rejected,
  escalatedToDistrict,
}

extension FarmerVerificationStatusLabel on FarmerVerificationStatus {
  String get label => switch (this) {
    FarmerVerificationStatus.pendingApproval => 'Pending Approval',
    FarmerVerificationStatus.approved => 'Verified & Approved',
    FarmerVerificationStatus.rejected => 'Verification Rejected',
    FarmerVerificationStatus.escalatedToDistrict => 'Escalated to District Admin',
  };
}

