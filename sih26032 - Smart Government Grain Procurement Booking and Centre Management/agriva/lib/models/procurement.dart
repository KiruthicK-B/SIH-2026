enum ProcurementStatus { pending, completed, notAccepted }

class Procurement {
  final String id;
  final String bookingId;
  final ProcurementStatus status;
  final double? acceptedQuantityQ;
  final DateTime timestamp;

  const Procurement({
    required this.id,
    required this.bookingId,
    required this.status,
    this.acceptedQuantityQ,
    required this.timestamp,
  });

  Procurement copyWith({
    ProcurementStatus? status,
    double? acceptedQuantityQ,
    DateTime? timestamp,
  }) => Procurement(
    id: id,
    bookingId: bookingId,
    status: status ?? this.status,
    acceptedQuantityQ: acceptedQuantityQ ?? this.acceptedQuantityQ,
    timestamp: timestamp ?? this.timestamp,
  );

  factory Procurement.fromJson(Map<String, dynamic> json) => Procurement(
    id: json['id'] as String,
    bookingId: json['bookingId'] as String,
    status: ProcurementStatus.values.byName(json['status'] as String),
    acceptedQuantityQ: (json['acceptedQuantityQ'] as num?)?.toDouble(),
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookingId': bookingId,
    'status': status.name,
    'acceptedQuantityQ': acceptedQuantityQ,
    'timestamp': timestamp.toIso8601String(),
  };
}
