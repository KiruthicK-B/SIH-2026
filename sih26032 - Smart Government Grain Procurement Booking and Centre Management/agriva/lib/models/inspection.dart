import 'enums.dart';

class Inspection {
  final String id;
  final String bookingId;
  final double moisturePercent;
  final InspectionStatus result;
  final String? reason;
  final String? remarks;
  final String inspector;
  final DateTime timestamp;

  const Inspection({
    required this.id,
    required this.bookingId,
    required this.moisturePercent,
    required this.result,
    this.reason,
    this.remarks,
    required this.inspector,
    required this.timestamp,
  });

  factory Inspection.fromJson(Map<String, dynamic> json) => Inspection(
    id: json['id'] as String,
    bookingId: json['bookingId'] as String,
    moisturePercent: (json['moisturePercent'] as num).toDouble(),
    result: InspectionStatus.values.byName(json['result'] as String),
    reason: json['reason'] as String?,
    remarks: json['remarks'] as String?,
    inspector: json['inspector'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookingId': bookingId,
    'moisturePercent': moisturePercent,
    'result': result.name,
    'reason': reason,
    'remarks': remarks,
    'inspector': inspector,
    'timestamp': timestamp.toIso8601String(),
  };
}
