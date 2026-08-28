import 'enums.dart';

class Payment {
  final String id;
  final String bookingId;
  final double amount;
  final PaymentStatus status;
  final DateTime lastUpdated;
  final String? failureReason;

  const Payment({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.status,
    required this.lastUpdated,
    this.failureReason,
  });

  Payment copyWith({
    PaymentStatus? status,
    DateTime? lastUpdated,
    String? failureReason,
  }) => Payment(
    id: id,
    bookingId: bookingId,
    amount: amount,
    status: status ?? this.status,
    lastUpdated: lastUpdated ?? this.lastUpdated,
    failureReason: failureReason ?? this.failureReason,
  );

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
    id: json['id'] as String,
    bookingId: json['bookingId'] as String,
    amount: (json['amount'] as num).toDouble(),
    status: PaymentStatus.values.byName(json['status'] as String),
    lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    failureReason: json['failureReason'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookingId': bookingId,
    'amount': amount,
    'status': status.name,
    'lastUpdated': lastUpdated.toIso8601String(),
    'failureReason': failureReason,
  };
}
