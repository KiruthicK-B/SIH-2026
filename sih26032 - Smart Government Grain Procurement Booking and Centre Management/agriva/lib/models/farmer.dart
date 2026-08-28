class Farmer {
  final String id;
  final String name;
  final String farmerCode; // e.g. FRM-1001
  final String village;
  final double distanceKm;
  final int estimatedTravelMinutes;
  final String phone;

  const Farmer({
    required this.id,
    required this.name,
    required this.farmerCode,
    required this.village,
    required this.distanceKm,
    required this.estimatedTravelMinutes,
    required this.phone,
  });

  factory Farmer.fromJson(Map<String, dynamic> json) => Farmer(
    id: json['id'] as String,
    name: json['name'] as String,
    farmerCode: json['farmerCode'] as String,
    village: json['village'] as String,
    distanceKm: (json['distanceKm'] as num).toDouble(),
    estimatedTravelMinutes: json['estimatedTravelMinutes'] as int,
    phone: json['phone'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'farmerCode': farmerCode,
    'village': village,
    'distanceKm': distanceKm,
    'estimatedTravelMinutes': estimatedTravelMinutes,
    'phone': phone,
  };
}
