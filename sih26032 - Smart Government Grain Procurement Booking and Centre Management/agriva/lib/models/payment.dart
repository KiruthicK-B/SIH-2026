import 'enums.dart';

class Payment {
  final String id;
  final String bookingId;
  final String farmerId;
  final double amount;
  final PaymentStatus status;
  final DateTime? initiatedAt;
  final DateTime? completedAt;
  final DateTime lastUpdated;
  final String? failureReason;
  final String transactionRef;
  final int retryCount;

  const Payment({
    required this.id,
    required this.bookingId,
    this.farmerId = '',
    required this.amount,
    required this.status,
    this.initiatedAt,
    this.completedAt,
    required this.lastUpdated,
    this.failureReason,
    this.transactionRef = '',
    this.retryCount = 0,
  });

  Payment copyWith({
    PaymentStatus? status,
    DateTime? lastUpdated,
    String? failureReason,
    DateTime? initiatedAt,
    DateTime? completedAt,
    String? transactionRef,
    int? retryCount,
  }) => Payment(
    id: id,
    bookingId: bookingId,
    farmerId: farmerId,
    amount: amount,
    status: status ?? this.status,
    initiatedAt: initiatedAt ?? this.initiatedAt,
    completedAt: completedAt ?? this.completedAt,
    lastUpdated: lastUpdated ?? this.lastUpdated,
    failureReason: failureReason ?? this.failureReason,
    transactionRef: transactionRef ?? this.transactionRef,
    retryCount: retryCount ?? this.retryCount,
  );

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
    id: json['id'] as String,
    bookingId: json['bookingId'] as String,
    farmerId: json['farmerId'] as String? ?? '',
    amount: (json['amount'] as num).toDouble(),
    status: PaymentStatus.values.byName(json['status'] as String),
    initiatedAt: json['initiatedAt'] != null
        ? DateTime.parse(json['initiatedAt'] as String)
        : null,
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'] as String)
        : null,
    lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    failureReason: json['failureReason'] as String?,
    transactionRef: json['transactionRef'] as String? ?? '',
    retryCount: json['retryCount'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookingId': bookingId,
    'farmerId': farmerId,
    'amount': amount,
    'status': status.name,
    'initiatedAt': initiatedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'lastUpdated': lastUpdated.toIso8601String(),
    'failureReason': failureReason,
    'transactionRef': transactionRef,
    'retryCount': retryCount,
  };
}
