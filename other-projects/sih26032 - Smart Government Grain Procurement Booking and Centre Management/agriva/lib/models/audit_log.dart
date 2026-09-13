class AuditLog {
  final String id;
  final String actor;
  final String action;
  final String entity;
  final String entityId;
  final DateTime timestamp;
  final String? oldState;
  final String? newState;

  const AuditLog({
    required this.id,
    required this.actor,
    required this.action,
    required this.entity,
    required this.entityId,
    required this.timestamp,
    this.oldState,
    this.newState,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) => AuditLog(
    id: json['id'] as String,
    actor: json['actor'] as String,
    action: json['action'] as String,
    entity: json['entity'] as String,
    entityId: json['entityId'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    oldState: json['oldState'] as String?,
    newState: json['newState'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'actor': actor,
    'action': action,
    'entity': entity,
    'entityId': entityId,
    'timestamp': timestamp.toIso8601String(),
    'oldState': oldState,
    'newState': newState,
  };
}
