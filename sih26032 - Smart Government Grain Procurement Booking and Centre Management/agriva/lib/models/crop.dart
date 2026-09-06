import 'enums.dart';

class QualityParameter {
  final String name;
  final double minAcceptable;
  final double maxAcceptable;
  final String unit;

  const QualityParameter({
    required this.name,
    required this.minAcceptable,
    required this.maxAcceptable,
    this.unit = '%',
  });

  factory QualityParameter.fromJson(Map<String, dynamic> json) =>
      QualityParameter(
        name: json['name'] as String,
        minAcceptable: (json['minAcceptable'] as num).toDouble(),
        maxAcceptable: (json['maxAcceptable'] as num).toDouble(),
        unit: json['unit'] as String? ?? '%',
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    'minAcceptable': minAcceptable,
    'maxAcceptable': maxAcceptable,
    'unit': unit,
  };
}

/// README §4 Crop — master data owned by the State/Super Admin.
class Crop {
  final String id;
  final String name;
  final Map<String, String> localNames; // languageCode -> localized name
  final double msp; // minimum support price, per unit
  final String unit; // e.g. "quintal"
  final CropSeason season;
  final List<QualityParameter> qualityParameters;
  final bool isActive;

  const Crop({
    required this.id,
    required this.name,
    this.localNames = const {},
    required this.msp,
    this.unit = 'quintal',
    required this.season,
    this.qualityParameters = const [],
    this.isActive = true,
  });

  String localName(String languageCode) => localNames[languageCode] ?? name;

  Crop copyWith({double? msp, bool? isActive}) => Crop(
    id: id,
    name: name,
    localNames: localNames,
    msp: msp ?? this.msp,
    unit: unit,
    season: season,
    qualityParameters: qualityParameters,
    isActive: isActive ?? this.isActive,
  );

  factory Crop.fromJson(Map<String, dynamic> json) => Crop(
    id: json['id'] as String,
    name: json['name'] as String,
    localNames: (json['localNames'] as Map?)?.cast<String, String>() ?? const {},
    msp: (json['msp'] as num).toDouble(),
    unit: json['unit'] as String? ?? 'quintal',
    season: CropSeason.values.byName(json['season'] as String),
    qualityParameters: (json['qualityParameters'] as List? ?? [])
        .map((e) => QualityParameter.fromJson(e as Map<String, dynamic>))
        .toList(),
    isActive: json['isActive'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'localNames': localNames,
    'msp': msp,
    'unit': unit,
    'season': season.name,
    'qualityParameters': qualityParameters.map((e) => e.toJson()).toList(),
    'isActive': isActive,
  };
}
