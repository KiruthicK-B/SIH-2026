import 'enums.dart';

/// README §4 Farmer.
class Farmer {
  final String id;
  final String name;
  final String farmerCode; // e.g. FRM-1001
  final String phone;
  final String preferredLanguage; // languageCode, e.g. "en"
  final String district;
  final String taluk; // Block / Tehsil
  final String village;
  final String doorNo; // Door / Flat / House No
  final String street; // Street / Locality
  final String pincode; // 6-digit PIN code
  final String assignedCentreId; // Pre-defined cluster mapping link to nearest centre
  final double distanceKm;
  final int estimatedTravelMinutes;
  final String? aadhaarNumber; // stored masked-ready; UI masks by default
  final String? bankAccountNumber;
  final String? bankIfsc;
  final List<String> landRecordIds;
  final List<String> registeredCropIds;
  final FarmerVerificationStatus verificationStatus;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final String? rejectionReason;
  final String? escalationNotes;
  final DateTime? escalatedAt;
  final List<String> deviceIds;
  final DateTime? createdAt;

  const Farmer({
    required this.id,
    required this.name,
    required this.farmerCode,
    required this.phone,
    this.preferredLanguage = 'en',
    this.district = '',
    this.taluk = '',
    required this.village,
    this.doorNo = '',
    this.street = '',
    this.pincode = '',
    this.assignedCentreId = '',
    this.distanceKm = 0,
    this.estimatedTravelMinutes = 0,
    this.aadhaarNumber,
    this.bankAccountNumber,
    this.bankIfsc,
    this.landRecordIds = const [],
    this.registeredCropIds = const [],
    FarmerVerificationStatus? verificationStatus,
    bool isVerified = false,
    this.verifiedAt,
    this.verifiedBy,
    this.rejectionReason,
    this.escalationNotes,
    this.escalatedAt,
    this.deviceIds = const [],
    this.createdAt,
  }) : verificationStatus = verificationStatus ??
            (isVerified
                ? FarmerVerificationStatus.approved
                : FarmerVerificationStatus.pendingApproval);

  /// Backwards-compatible getter used across the app
  bool get isVerified =>
      verificationStatus == FarmerVerificationStatus.approved;

  String get fullAddress {
    final parts = [
      if (doorNo.isNotEmpty) doorNo,
      if (street.isNotEmpty) street,
      if (village.isNotEmpty) village,
      if (taluk.isNotEmpty) '$taluk Taluk',
      if (district.isNotEmpty) '$district District',
      if (pincode.isNotEmpty) 'PIN: $pincode',
    ];
    return parts.isEmpty ? village : parts.join(', ');
  }

  /// Digits-only, last 10 — so "+91 90000 10001", "9000010001" and
  /// "090000 10001" all compare equal regardless of how a phone number was
  /// typed or how it's stored.
  static String normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
  }

  /// Last 4 digits visible, rest masked
  static String maskAadhaar(String? aadhaar) {
    if (aadhaar == null || aadhaar.length < 4) return '—';
    return '•••• •••• ${aadhaar.substring(aadhaar.length - 4)}';
  }

  static String maskAccount(String? account) {
    if (account == null || account.length < 4) return '—';
    return '•••• ${account.substring(account.length - 4)}';
  }

  Farmer copyWith({
    String? preferredLanguage,
    String? district,
    String? taluk,
    String? village,
    String? doorNo,
    String? street,
    String? pincode,
    String? assignedCentreId,
    List<String>? landRecordIds,
    List<String>? registeredCropIds,
    bool? isVerified,
    FarmerVerificationStatus? verificationStatus,
    DateTime? verifiedAt,
    String? verifiedBy,
    String? rejectionReason,
    String? escalationNotes,
    DateTime? escalatedAt,
    String? bankAccountNumber,
    String? bankIfsc,
    double? distanceKm,
    int? estimatedTravelMinutes,
  }) =>
      Farmer(
        id: id,
        name: name,
        farmerCode: farmerCode,
        phone: phone,
        preferredLanguage: preferredLanguage ?? this.preferredLanguage,
        district: district ?? this.district,
        taluk: taluk ?? this.taluk,
        village: village ?? this.village,
        doorNo: doorNo ?? this.doorNo,
        street: street ?? this.street,
        pincode: pincode ?? this.pincode,
        assignedCentreId: assignedCentreId ?? this.assignedCentreId,
        distanceKm: distanceKm ?? this.distanceKm,
        estimatedTravelMinutes:
            estimatedTravelMinutes ?? this.estimatedTravelMinutes,
        aadhaarNumber: aadhaarNumber,
        bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
        bankIfsc: bankIfsc ?? this.bankIfsc,
        landRecordIds: landRecordIds ?? this.landRecordIds,
        registeredCropIds: registeredCropIds ?? this.registeredCropIds,
        verificationStatus: verificationStatus ??
            (isVerified != null
                ? (isVerified
                    ? FarmerVerificationStatus.approved
                    : FarmerVerificationStatus.pendingApproval)
                : this.verificationStatus),
        verifiedAt: verifiedAt ?? this.verifiedAt,
        verifiedBy: verifiedBy ?? this.verifiedBy,
        rejectionReason: rejectionReason ?? this.rejectionReason,
        escalationNotes: escalationNotes ?? this.escalationNotes,
        escalatedAt: escalatedAt ?? this.escalatedAt,
        deviceIds: deviceIds,
        createdAt: createdAt,
      );

  factory Farmer.fromJson(Map<String, dynamic> json) {
    FarmerVerificationStatus vStatus;
    if (json['verificationStatus'] != null) {
      try {
        vStatus = FarmerVerificationStatus.values.byName(
          json['verificationStatus'] as String,
        );
      } catch (_) {
        vStatus = (json['isVerified'] as bool? ?? false)
            ? FarmerVerificationStatus.approved
            : FarmerVerificationStatus.pendingApproval;
      }
    } else {
      vStatus = (json['isVerified'] as bool? ?? false)
          ? FarmerVerificationStatus.approved
          : FarmerVerificationStatus.pendingApproval;
    }

    return Farmer(
      id: json['id'] as String,
      name: json['name'] as String,
      farmerCode: json['farmerCode'] as String,
      phone: json['phone'] as String,
      preferredLanguage: json['preferredLanguage'] as String? ?? 'en',
      district: json['district'] as String? ?? '',
      taluk: json['taluk'] as String? ?? '',
      village: json['village'] as String? ?? '',
      doorNo: json['doorNo'] as String? ?? '',
      street: json['street'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      assignedCentreId: json['assignedCentreId'] as String? ?? '',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      estimatedTravelMinutes: json['estimatedTravelMinutes'] as int? ?? 0,
      aadhaarNumber: json['aadhaarNumber'] as String?,
      bankAccountNumber: json['bankAccountNumber'] as String?,
      bankIfsc: json['bankIfsc'] as String?,
      landRecordIds:
          (json['landRecordIds'] as List?)?.cast<String>() ?? const [],
      registeredCropIds:
          (json['registeredCropIds'] as List?)?.cast<String>() ?? const [],
      verificationStatus: vStatus,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'] as String)
          : null,
      verifiedBy: json['verifiedBy'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      escalationNotes: json['escalationNotes'] as String?,
      escalatedAt: json['escalatedAt'] != null
          ? DateTime.parse(json['escalatedAt'] as String)
          : null,
      deviceIds: (json['deviceIds'] as List?)?.cast<String>() ?? const [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'farmerCode': farmerCode,
        'phone': phone,
        'preferredLanguage': preferredLanguage,
        'district': district,
        'taluk': taluk,
        'village': village,
        'doorNo': doorNo,
        'street': street,
        'pincode': pincode,
        'assignedCentreId': assignedCentreId,
        'distanceKm': distanceKm,
        'estimatedTravelMinutes': estimatedTravelMinutes,
        'aadhaarNumber': aadhaarNumber,
        'bankAccountNumber': bankAccountNumber,
        'bankIfsc': bankIfsc,
        'landRecordIds': landRecordIds,
        'registeredCropIds': registeredCropIds,
        'verificationStatus': verificationStatus.name,
        'isVerified': isVerified,
        'verifiedAt': verifiedAt?.toIso8601String(),
        'verifiedBy': verifiedBy,
        'rejectionReason': rejectionReason,
        'escalationNotes': escalationNotes,
        'escalatedAt': escalatedAt?.toIso8601String(),
        'deviceIds': deviceIds,
        'createdAt': createdAt?.toIso8601String(),
      };
}
