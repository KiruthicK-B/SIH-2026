import 'enums.dart';

/// README §4 LandRecord.
class LandRecord {
  final String id;
  final String farmerId;
  final String surveyNumber;
  final double areaInAcres;
  final String village;
  final String district;
  final LandOwnershipType ownershipType;
  final String? linkedOwnerFarmerId; // set when ownershipType != owner
  final String? consentDocPath; // tenant/sharecropper consent proof

  const LandRecord({
    required this.id,
    required this.farmerId,
    required this.surveyNumber,
    required this.areaInAcres,
    required this.village,
    required this.district,
    this.ownershipType = LandOwnershipType.owner,
    this.linkedOwnerFarmerId,
    this.consentDocPath,
  });

  bool get requiresConsent => ownershipType != LandOwnershipType.owner;
  bool get hasConsent => consentDocPath != null;

  factory LandRecord.fromJson(Map<String, dynamic> json) => LandRecord(
    id: json['id'] as String,
    farmerId: json['farmerId'] as String,
    surveyNumber: json['surveyNumber'] as String,
    areaInAcres: (json['areaInAcres'] as num).toDouble(),
    village: json['village'] as String,
    district: json['district'] as String,
    ownershipType: LandOwnershipType.values.byName(
      json['ownershipType'] as String? ?? 'owner',
    ),
    linkedOwnerFarmerId: json['linkedOwnerFarmerId'] as String?,
    consentDocPath: json['consentDocPath'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'farmerId': farmerId,
    'surveyNumber': surveyNumber,
    'areaInAcres': areaInAcres,
    'village': village,
    'district': district,
    'ownershipType': ownershipType.name,
    'linkedOwnerFarmerId': linkedOwnerFarmerId,
    'consentDocPath': consentDocPath,
  };
}
