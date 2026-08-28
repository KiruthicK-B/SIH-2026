class Weighment {
  final String id;
  final String bookingId;
  final double expectedQuantityQ;
  final double actualQuantityQ;
  final DateTime timestamp;

  const Weighment({
    required this.id,
    required this.bookingId,
    required this.expectedQuantityQ,
    required this.actualQuantityQ,
    required this.timestamp,
  });

  double get difference => actualQuantityQ - expectedQuantityQ;
  bool get hasVariance => difference.abs() > 0.01;
  bool get exceedsDeclared => actualQuantityQ > expectedQuantityQ;

  factory Weighment.fromJson(Map<String, dynamic> json) => Weighment(
    id: json['id'] as String,
    bookingId: json['bookingId'] as String,
    expectedQuantityQ: (json['expectedQuantityQ'] as num).toDouble(),
    actualQuantityQ: (json['actualQuantityQ'] as num).toDouble(),
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookingId': bookingId,
    'expectedQuantityQ': expectedQuantityQ,
    'actualQuantityQ': actualQuantityQ,
    'timestamp': timestamp.toIso8601String(),
  };
}
