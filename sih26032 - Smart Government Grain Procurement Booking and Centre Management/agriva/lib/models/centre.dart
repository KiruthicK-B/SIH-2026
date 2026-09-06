import 'enums.dart';

class CentreCropSupport {
  final String cropId;
  final CropSeason season;
  final bool isActive;

  const CentreCropSupport({
    required this.cropId,
    required this.season,
    this.isActive = true,
  });

  factory CentreCropSupport.fromJson(Map<String, dynamic> json) =>
      CentreCropSupport(
        cropId: json['cropId'] as String,
        season: CropSeason.values.byName(json['season'] as String),
        isActive: json['isActive'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
    'cropId': cropId,
    'season': season.name,
    'isActive': isActive,
  };
}

/// README §4 ProcurementCentre. `status` is the 3-state public summary;
/// `activeDisruptionIds` plus the operational fields below (processing
/// lanes, staffing, storage) carry the detail the existing queue engine and
/// operator screens need to keep working exactly as before.
class ProcurementCentre {
  final String id;
  final String name;
  final String code;
  final String district;
  final String taluk;
  final double? latitude;
  final double? longitude;
  final String contactNumber;
  final List<CentreCropSupport> supportedCrops;
  final Map<String, double> dailyCapacityQ; // cropId -> quantity
  final List<DateTime> holidays;
  final CentreStatus status;

  final double dailyProcessingCapacityQ;
  final double storageCapacityQ;
  final double currentStorageQ;
  final int processingLanesTotal;
  final int processingLanesActive;
  final int staffNormal;
  final int staffAvailable;
  final int operatingStartHour; // 24h
  final int operatingEndHour; // 24h

  const ProcurementCentre({
    required this.id,
    required this.name,
    this.code = '',
    this.district = '',
    this.taluk = '',
    this.latitude,
    this.longitude,
    this.contactNumber = '',
    this.supportedCrops = const [],
    this.dailyCapacityQ = const {},
    this.holidays = const [],
    required this.status,
    required this.dailyProcessingCapacityQ,
    required this.storageCapacityQ,
    required this.currentStorageQ,
    required this.processingLanesTotal,
    required this.processingLanesActive,
    required this.staffNormal,
    required this.staffAvailable,
    this.operatingStartHour = 8,
    this.operatingEndHour = 17,
  });

  double get storageAvailableQ => storageCapacityQ - currentStorageQ;
  double get storageOccupiedPercent =>
      (currentStorageQ / storageCapacityQ) * 100;

  StorageLevel get storageLevel {
    if (storageOccupiedPercent >= 100) return StorageLevel.full;
    if (storageOccupiedPercent >= 85) return StorageLevel.nearFull;
    return StorageLevel.normal;
  }

  bool supportsCrop(String cropId, CropSeason season) => supportedCrops.any(
    (s) => s.cropId == cropId && s.season == season && s.isActive,
  );

  /// Effective per-lane processing rate reduced by labour shortage.
  double get effectiveProcessingRate {
    final staffFactor = staffNormal == 0
        ? 1.0
        : (staffAvailable / staffNormal).clamp(0.4, 1.0);
    final laneFactor = processingLanesTotal == 0
        ? 0.0
        : processingLanesActive / processingLanesTotal;
    return dailyProcessingCapacityQ * laneFactor * staffFactor;
  }

  ProcurementCentre copyWith({
    CentreStatus? status,
    double? currentStorageQ,
    int? processingLanesActive,
    int? staffAvailable,
    List<CentreCropSupport>? supportedCrops,
    Map<String, double>? dailyCapacityQ,
    double? dailyProcessingCapacityQ,
    double? storageCapacityQ,
  }) {
    return ProcurementCentre(
      id: id,
      name: name,
      code: code,
      district: district,
      taluk: taluk,
      latitude: latitude,
      longitude: longitude,
      contactNumber: contactNumber,
      supportedCrops: supportedCrops ?? this.supportedCrops,
      dailyCapacityQ: dailyCapacityQ ?? this.dailyCapacityQ,
      holidays: holidays,
      status: status ?? this.status,
      dailyProcessingCapacityQ:
          dailyProcessingCapacityQ ?? this.dailyProcessingCapacityQ,
      storageCapacityQ: storageCapacityQ ?? this.storageCapacityQ,
      currentStorageQ: currentStorageQ ?? this.currentStorageQ,
      processingLanesTotal: processingLanesTotal,
      processingLanesActive:
          processingLanesActive ?? this.processingLanesActive,
      staffNormal: staffNormal,
      staffAvailable: staffAvailable ?? this.staffAvailable,
      operatingStartHour: operatingStartHour,
      operatingEndHour: operatingEndHour,
    );
  }

  factory ProcurementCentre.fromJson(Map<String, dynamic> json) =>
      ProcurementCentre(
        id: json['id'] as String,
        name: json['name'] as String,
        code: json['code'] as String? ?? '',
        district: json['district'] as String? ?? '',
        taluk: json['taluk'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        contactNumber: json['contactNumber'] as String? ?? '',
        supportedCrops: (json['supportedCrops'] as List? ?? [])
            .map((e) => CentreCropSupport.fromJson(e as Map<String, dynamic>))
            .toList(),
        dailyCapacityQ: (json['dailyCapacityQ'] as Map?)?.map(
              (k, v) => MapEntry(k as String, (v as num).toDouble()),
            ) ??
            const {},
        holidays: (json['holidays'] as List? ?? [])
            .map((e) => DateTime.parse(e as String))
            .toList(),
        status: CentreStatus.values.byName(json['status'] as String),
        dailyProcessingCapacityQ: (json['dailyProcessingCapacityQ'] as num)
            .toDouble(),
        storageCapacityQ: (json['storageCapacityQ'] as num).toDouble(),
        currentStorageQ: (json['currentStorageQ'] as num).toDouble(),
        processingLanesTotal: json['processingLanesTotal'] as int,
        processingLanesActive: json['processingLanesActive'] as int,
        staffNormal: json['staffNormal'] as int,
        staffAvailable: json['staffAvailable'] as int,
        operatingStartHour: json['operatingStartHour'] as int? ?? 8,
        operatingEndHour: json['operatingEndHour'] as int? ?? 17,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'district': district,
    'taluk': taluk,
    'latitude': latitude,
    'longitude': longitude,
    'contactNumber': contactNumber,
    'supportedCrops': supportedCrops.map((e) => e.toJson()).toList(),
    'dailyCapacityQ': dailyCapacityQ,
    'holidays': holidays.map((e) => e.toIso8601String()).toList(),
    'status': status.name,
    'dailyProcessingCapacityQ': dailyProcessingCapacityQ,
    'storageCapacityQ': storageCapacityQ,
    'currentStorageQ': currentStorageQ,
    'processingLanesTotal': processingLanesTotal,
    'processingLanesActive': processingLanesActive,
    'staffNormal': staffNormal,
    'staffAvailable': staffAvailable,
    'operatingStartHour': operatingStartHour,
    'operatingEndHour': operatingEndHour,
  };
}
