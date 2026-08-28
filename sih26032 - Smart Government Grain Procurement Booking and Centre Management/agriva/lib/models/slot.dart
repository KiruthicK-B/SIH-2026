class Slot {
  final String id;
  final String centreId;
  final DateTime start;
  final DateTime end;
  final int maxFarmers;
  final double maxQuantityQ;

  /// Aggregate occupancy baked into the demo seed, representing other
  /// centre activity not individually modeled as Booking records. Real
  /// bookings made in-app are tracked separately and added on top of this.
  final int baselineFarmers;
  final double baselineQuantityQ;

  const Slot({
    required this.id,
    required this.centreId,
    required this.start,
    required this.end,
    required this.maxFarmers,
    required this.maxQuantityQ,
    this.baselineFarmers = 0,
    this.baselineQuantityQ = 0,
  });

  DateTime get date => DateTime(start.year, start.month, start.day);

  factory Slot.fromJson(Map<String, dynamic> json) => Slot(
    id: json['id'] as String,
    centreId: json['centreId'] as String,
    start: DateTime.parse(json['start'] as String),
    end: DateTime.parse(json['end'] as String),
    maxFarmers: json['maxFarmers'] as int,
    maxQuantityQ: (json['maxQuantityQ'] as num).toDouble(),
    baselineFarmers: json['baselineFarmers'] as int? ?? 0,
    baselineQuantityQ: (json['baselineQuantityQ'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'centreId': centreId,
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'maxFarmers': maxFarmers,
    'maxQuantityQ': maxQuantityQ,
    'baselineFarmers': baselineFarmers,
    'baselineQuantityQ': baselineQuantityQ,
  };
}
