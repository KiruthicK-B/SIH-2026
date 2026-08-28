import 'enums.dart';

class ProcurementCentre {
  final String id;
  final String name;
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
  }) {
    return ProcurementCentre(
      id: id,
      name: name,
      status: status ?? this.status,
      dailyProcessingCapacityQ: dailyProcessingCapacityQ,
      storageCapacityQ: storageCapacityQ,
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
