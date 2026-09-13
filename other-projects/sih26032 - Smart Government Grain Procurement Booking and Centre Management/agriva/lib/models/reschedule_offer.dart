enum RescheduleOfferStatus { pending, accepted, declined, expired }

class RescheduleOffer {
  final String id;
  final String bookingId;
  final String originalSlotId;
  final String offeredSlotId;
  final String reason;
  final RescheduleOfferStatus status;
  final DateTime createdAt;

  const RescheduleOffer({
    required this.id,
    required this.bookingId,
    required this.originalSlotId,
    required this.offeredSlotId,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  RescheduleOffer copyWith({RescheduleOfferStatus? status}) => RescheduleOffer(
    id: id,
    bookingId: bookingId,
    originalSlotId: originalSlotId,
    offeredSlotId: offeredSlotId,
    reason: reason,
    status: status ?? this.status,
    createdAt: createdAt,
  );

  factory RescheduleOffer.fromJson(Map<String, dynamic> json) =>
      RescheduleOffer(
        id: json['id'] as String,
        bookingId: json['bookingId'] as String,
        originalSlotId: json['originalSlotId'] as String,
        offeredSlotId: json['offeredSlotId'] as String,
        reason: json['reason'] as String,
        status: RescheduleOfferStatus.values.byName(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookingId': bookingId,
    'originalSlotId': originalSlotId,
    'offeredSlotId': offeredSlotId,
    'reason': reason,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
  };
}
