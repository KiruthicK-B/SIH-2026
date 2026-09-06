/// README §4 ProcurementRecord — replaces the previous separate
/// Inspection/Weighment/Procurement models with the one record the spec
/// describes, written by the operator's quality-check + weighment screens.
class ProcurementRecord {
  final String id;
  final String bookingId;
  final double? weighedQuantityQ;
  final double? acceptedQuantityQ;
  final double? rejectedQuantityQ;
  final String? rejectionReason;
  final String? qualityGrade;
  final double? moisturePercent;
  final Map<String, double> otherQualityReadings;
  final String inspectedBy;
  final DateTime inspectionTime;
  final bool disputeRaised;
  final String? disputeNote;

  const ProcurementRecord({
    required this.id,
    required this.bookingId,
    this.weighedQuantityQ,
    this.acceptedQuantityQ,
    this.rejectedQuantityQ,
    this.rejectionReason,
    this.qualityGrade,
    this.moisturePercent,
    this.otherQualityReadings = const {},
    required this.inspectedBy,
    required this.inspectionTime,
    this.disputeRaised = false,
    this.disputeNote,
  });

  bool get isFullyRejected =>
      acceptedQuantityQ == null || acceptedQuantityQ == 0;
  bool get isPartial =>
      acceptedQuantityQ != null &&
      rejectedQuantityQ != null &&
      acceptedQuantityQ! > 0 &&
      rejectedQuantityQ! > 0;

  ProcurementRecord copyWith({
    double? weighedQuantityQ,
    double? acceptedQuantityQ,
    double? rejectedQuantityQ,
    String? rejectionReason,
    String? qualityGrade,
    double? moisturePercent,
    bool? disputeRaised,
    String? disputeNote,
  }) => ProcurementRecord(
    id: id,
    bookingId: bookingId,
    weighedQuantityQ: weighedQuantityQ ?? this.weighedQuantityQ,
    acceptedQuantityQ: acceptedQuantityQ ?? this.acceptedQuantityQ,
    rejectedQuantityQ: rejectedQuantityQ ?? this.rejectedQuantityQ,
    rejectionReason: rejectionReason ?? this.rejectionReason,
    qualityGrade: qualityGrade ?? this.qualityGrade,
    moisturePercent: moisturePercent ?? this.moisturePercent,
    otherQualityReadings: otherQualityReadings,
    inspectedBy: inspectedBy,
    inspectionTime: inspectionTime,
    disputeRaised: disputeRaised ?? this.disputeRaised,
    disputeNote: disputeNote ?? this.disputeNote,
  );

  factory ProcurementRecord.fromJson(Map<String, dynamic> json) =>
      ProcurementRecord(
        id: json['id'] as String,
        bookingId: json['bookingId'] as String,
        weighedQuantityQ: (json['weighedQuantityQ'] as num?)?.toDouble(),
        acceptedQuantityQ: (json['acceptedQuantityQ'] as num?)?.toDouble(),
        rejectedQuantityQ: (json['rejectedQuantityQ'] as num?)?.toDouble(),
        rejectionReason: json['rejectionReason'] as String?,
        qualityGrade: json['qualityGrade'] as String?,
        moisturePercent: (json['moisturePercent'] as num?)?.toDouble(),
        otherQualityReadings: (json['otherQualityReadings'] as Map?)?.map(
              (k, v) => MapEntry(k as String, (v as num).toDouble()),
            ) ??
            const {},
        inspectedBy: json['inspectedBy'] as String,
        inspectionTime: DateTime.parse(json['inspectionTime'] as String),
        disputeRaised: json['disputeRaised'] as bool? ?? false,
        disputeNote: json['disputeNote'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookingId': bookingId,
    'weighedQuantityQ': weighedQuantityQ,
    'acceptedQuantityQ': acceptedQuantityQ,
    'rejectedQuantityQ': rejectedQuantityQ,
    'rejectionReason': rejectionReason,
    'qualityGrade': qualityGrade,
    'moisturePercent': moisturePercent,
    'otherQualityReadings': otherQualityReadings,
    'inspectedBy': inspectedBy,
    'inspectionTime': inspectionTime.toIso8601String(),
    'disputeRaised': disputeRaised,
    'disputeNote': disputeNote,
  };
}
