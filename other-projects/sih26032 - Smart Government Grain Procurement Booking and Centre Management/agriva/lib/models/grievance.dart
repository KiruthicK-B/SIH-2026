import 'enums.dart';

/// README §4 Grievance.
class Grievance {
  final String id;
  final String farmerId;
  final String? relatedBookingId;
  final GrievanceCategory category;
  final String description;
  final GrievanceStatus status;
  final DateTime raisedAt;
  final DateTime? resolvedAt;
  final String? resolutionNote;
  final EscalationLevel escalationLevel;
  final bool isEmergency;

  const Grievance({
    required this.id,
    required this.farmerId,
    this.relatedBookingId,
    required this.category,
    required this.description,
    this.status = GrievanceStatus.open,
    required this.raisedAt,
    this.resolvedAt,
    this.resolutionNote,
    this.escalationLevel = EscalationLevel.centre,
    this.isEmergency = false,
  });

  Grievance copyWith({
    GrievanceStatus? status,
    DateTime? resolvedAt,
    String? resolutionNote,
    EscalationLevel? escalationLevel,
  }) => Grievance(
    id: id,
    farmerId: farmerId,
    relatedBookingId: relatedBookingId,
    category: category,
    description: description,
    status: status ?? this.status,
    raisedAt: raisedAt,
    resolvedAt: resolvedAt ?? this.resolvedAt,
    resolutionNote: resolutionNote ?? this.resolutionNote,
    escalationLevel: escalationLevel ?? this.escalationLevel,
    isEmergency: isEmergency,
  );

  factory Grievance.fromJson(Map<String, dynamic> json) => Grievance(
    id: json['id'] as String,
    farmerId: json['farmerId'] as String,
    relatedBookingId: json['relatedBookingId'] as String?,
    category: GrievanceCategory.values.byName(json['category'] as String),
    description: json['description'] as String,
    status: GrievanceStatus.values.byName(
      json['status'] as String? ?? 'open',
    ),
    raisedAt: DateTime.parse(json['raisedAt'] as String),
    resolvedAt: json['resolvedAt'] != null
        ? DateTime.parse(json['resolvedAt'] as String)
        : null,
    resolutionNote: json['resolutionNote'] as String?,
    escalationLevel: EscalationLevel.values.byName(
      json['escalationLevel'] as String? ?? 'centre',
    ),
    isEmergency: json['isEmergency'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'farmerId': farmerId,
    'relatedBookingId': relatedBookingId,
    'category': category.name,
    'description': description,
    'status': status.name,
    'raisedAt': raisedAt.toIso8601String(),
    'resolvedAt': resolvedAt?.toIso8601String(),
    'resolutionNote': resolutionNote,
    'escalationLevel': escalationLevel.name,
    'isEmergency': isEmergency,
  };
}
