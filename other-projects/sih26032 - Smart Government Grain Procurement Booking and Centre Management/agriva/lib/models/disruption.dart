import 'enums.dart';

class Disruption {
  final String id;
  final String centreId;
  final DisruptionType type;
  final DateTime start;
  final DateTime expectedResolution;
  final DateTime? actualResolution;
  final DisruptionStatus status;
  final List<String> affectedSlotIds;
  final int affectedProcessingLanes;

  const Disruption({
    required this.id,
    required this.centreId,
    required this.type,
    required this.start,
    required this.expectedResolution,
    this.actualResolution,
    required this.status,
    required this.affectedSlotIds,
    this.affectedProcessingLanes = 0,
  });

  Disruption copyWith({DisruptionStatus? status, DateTime? actualResolution}) =>
      Disruption(
        id: id,
        centreId: centreId,
        type: type,
        start: start,
        expectedResolution: expectedResolution,
        actualResolution: actualResolution ?? this.actualResolution,
        status: status ?? this.status,
        affectedSlotIds: affectedSlotIds,
        affectedProcessingLanes: affectedProcessingLanes,
      );

  factory Disruption.fromJson(Map<String, dynamic> json) => Disruption(
    id: json['id'] as String,
    centreId: json['centreId'] as String,
    type: DisruptionType.values.byName(json['type'] as String),
    start: DateTime.parse(json['start'] as String),
    expectedResolution: DateTime.parse(json['expectedResolution'] as String),
    actualResolution: json['actualResolution'] != null
        ? DateTime.parse(json['actualResolution'] as String)
        : null,
    status: DisruptionStatus.values.byName(json['status'] as String),
    affectedSlotIds: (json['affectedSlotIds'] as List).cast<String>(),
    affectedProcessingLanes: json['affectedProcessingLanes'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'centreId': centreId,
    'type': type.name,
    'start': start.toIso8601String(),
    'expectedResolution': expectedResolution.toIso8601String(),
    'actualResolution': actualResolution?.toIso8601String(),
    'status': status.name,
    'affectedSlotIds': affectedSlotIds,
    'affectedProcessingLanes': affectedProcessingLanes,
  };
}
