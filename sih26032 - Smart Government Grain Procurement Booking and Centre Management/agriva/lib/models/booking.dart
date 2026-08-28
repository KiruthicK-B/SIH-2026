import 'enums.dart';

class Booking {
  final String id;
  final String farmerId;
  final String centreId;
  final String slotId;
  final double expectedQuantityQ;
  final BookingStatus status;
  final String token;
  final DateTime createdAt;
  final DateTime? checkedInAt;
  final DateTime? cancelledAt;
  final DateTime? noShowAt;

  const Booking({
    required this.id,
    required this.farmerId,
    required this.centreId,
    required this.slotId,
    required this.expectedQuantityQ,
    required this.status,
    required this.token,
    required this.createdAt,
    this.checkedInAt,
    this.cancelledAt,
    this.noShowAt,
  });

  Booking copyWith({
    BookingStatus? status,
    DateTime? checkedInAt,
    DateTime? cancelledAt,
    DateTime? noShowAt,
    String? slotId,
  }) {
    return Booking(
      id: id,
      farmerId: farmerId,
      centreId: centreId,
      slotId: slotId ?? this.slotId,
      expectedQuantityQ: expectedQuantityQ,
      status: status ?? this.status,
      token: token,
      createdAt: createdAt,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      noShowAt: noShowAt ?? this.noShowAt,
    );
  }

  bool get isActive => ![
    BookingStatus.cancelled,
    BookingStatus.noShow,
    BookingStatus.expired,
  ].contains(status);

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
    id: json['id'] as String,
    farmerId: json['farmerId'] as String,
    centreId: json['centreId'] as String,
    slotId: json['slotId'] as String,
    expectedQuantityQ: (json['expectedQuantityQ'] as num).toDouble(),
    status: BookingStatus.values.byName(json['status'] as String),
    token: json['token'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    checkedInAt: json['checkedInAt'] != null
        ? DateTime.parse(json['checkedInAt'] as String)
        : null,
    cancelledAt: json['cancelledAt'] != null
        ? DateTime.parse(json['cancelledAt'] as String)
        : null,
    noShowAt: json['noShowAt'] != null
        ? DateTime.parse(json['noShowAt'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'farmerId': farmerId,
    'centreId': centreId,
    'slotId': slotId,
    'expectedQuantityQ': expectedQuantityQ,
    'status': status.name,
    'token': token,
    'createdAt': createdAt.toIso8601String(),
    'checkedInAt': checkedInAt?.toIso8601String(),
    'cancelledAt': cancelledAt?.toIso8601String(),
    'noShowAt': noShowAt?.toIso8601String(),
  };
}
