import 'enums.dart';

/// README §4 AdminUser — Centre Operator / District Admin / State Admin.
/// `passwordHash` is a mock plaintext-equality check in Phase 1 (no real
/// crypto backend yet); Phase 2 swaps this repository's implementation for
/// a real auth service without touching the UI (README §0).
class AdminUser {
  final String id;
  final String name;
  final UserRole role; // centreOperator | districtAdmin | stateAdmin
  final String employeeId;
  final String passwordHash;
  final String? district; // districtAdmin's district; centreOperator's too
  final String? centreId; // centreOperator's home centre
  final int loginAttempts;
  final DateTime? lockedUntil;

  const AdminUser({
    required this.id,
    required this.name,
    required this.role,
    required this.employeeId,
    required this.passwordHash,
    this.district,
    this.centreId,
    this.loginAttempts = 0,
    this.lockedUntil,
  });

  bool get isLocked =>
      lockedUntil != null && lockedUntil!.isAfter(DateTime.now());

  AdminUser copyWith({
    String? passwordHash,
    int? loginAttempts,
    DateTime? lockedUntil,
    bool clearLock = false,
  }) => AdminUser(
    id: id,
    name: name,
    role: role,
    employeeId: employeeId,
    passwordHash: passwordHash ?? this.passwordHash,
    district: district,
    centreId: centreId,
    loginAttempts: loginAttempts ?? this.loginAttempts,
    lockedUntil: clearLock ? null : (lockedUntil ?? this.lockedUntil),
  );

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
    id: json['id'] as String,
    name: json['name'] as String,
    role: UserRole.values.byName(json['role'] as String),
    employeeId: json['employeeId'] as String,
    passwordHash: json['passwordHash'] as String,
    district: json['district'] as String?,
    centreId: json['centreId'] as String?,
    loginAttempts: json['loginAttempts'] as int? ?? 0,
    lockedUntil: json['lockedUntil'] != null
        ? DateTime.parse(json['lockedUntil'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role.name,
    'employeeId': employeeId,
    'passwordHash': passwordHash,
    'district': district,
    'centreId': centreId,
    'loginAttempts': loginAttempts,
    'lockedUntil': lockedUntil?.toIso8601String(),
  };
}
