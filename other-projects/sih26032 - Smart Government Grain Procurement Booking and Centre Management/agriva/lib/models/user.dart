import 'enums.dart';

class AppUser {
  final String id;
  final String name;
  final UserRole role;
  final String? centreId; // operator's home centre
  final String? district; // manager's district

  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    this.centreId,
    this.district,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    name: json['name'] as String,
    role: UserRole.values.byName(json['role'] as String),
    centreId: json['centreId'] as String?,
    district: json['district'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role.name,
    'centreId': centreId,
    'district': district,
  };
}
