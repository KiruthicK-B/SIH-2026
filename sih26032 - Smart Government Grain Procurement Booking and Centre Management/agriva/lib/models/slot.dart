enum SlotStatus { open, full, closed, cancelled }

/// README §4 Slot. `totalCapacity`/`bookedCapacity` are expressed in
/// quantity (Q) — farmer-count capacity is tracked alongside via
/// `maxFarmers`/`baselineFarmers` since the existing scheduler needs both
/// dimensions (a slot can be quantity-available but farmer-slot-full).
class Slot {
  final String id;
  final String centreId;
  final String cropId;
  final DateTime start;
  final DateTime end;
  final int maxFarmers;
  final double totalCapacityQ;

  /// Aggregate occupancy baked into the demo seed, representing other
  /// centre activity not individually modeled as Booking records. Real
  /// bookings made in-app are tracked separately and added on top of this.
  final int baselineFarmers;
  final double baselineQuantityQ;

  const Slot({
    required this.id,
    required this.centreId,
    this.cropId = '',
    required this.start,
    required this.end,
    required this.maxFarmers,
    required this.totalCapacityQ,
    this.baselineFarmers = 0,
    this.baselineQuantityQ = 0,
  });

  DateTime get date => DateTime(start.year, start.month, start.day);

  // Backward-compatible alias used throughout the existing scheduler code.
  double get maxQuantityQ => totalCapacityQ;

  factory Slot.fromJson(Map<String, dynamic> json) => Slot(
    id: json['id'] as String,
    centreId: json['centreId'] as String,
    cropId: json['cropId'] as String? ?? '',
    start: DateTime.parse(json['start'] as String),
    end: DateTime.parse(json['end'] as String),
    maxFarmers: json['maxFarmers'] as int,
    totalCapacityQ: (json['totalCapacityQ'] as num).toDouble(),
    baselineFarmers: json['baselineFarmers'] as int? ?? 0,
    baselineQuantityQ: (json['baselineQuantityQ'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'centreId': centreId,
    'cropId': cropId,
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'maxFarmers': maxFarmers,
    'totalCapacityQ': totalCapacityQ,
    'baselineFarmers': baselineFarmers,
    'baselineQuantityQ': baselineQuantityQ,
  };
}
