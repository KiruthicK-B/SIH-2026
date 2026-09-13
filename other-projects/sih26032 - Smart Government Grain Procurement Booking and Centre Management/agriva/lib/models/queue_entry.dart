import 'enums.dart';

class QueueEntry {
  final String id;
  final String bookingId;
  final String token;
  final QueueStage stage;
  final DateTime enteredAt;
  final int queuePosition;
  final DateTime? estimatedCallTime;
  final DateTime? actualCallTime;
  final bool isPriority;
  final bool skipped;

  const QueueEntry({
    required this.id,
    required this.bookingId,
    required this.token,
    required this.stage,
    required this.enteredAt,
    this.queuePosition = 0,
    this.estimatedCallTime,
    this.actualCallTime,
    this.isPriority = false,
    this.skipped = false,
  });

  QueueEntry copyWith({
    QueueStage? stage,
    int? queuePosition,
    DateTime? estimatedCallTime,
    DateTime? actualCallTime,
    bool? isPriority,
    bool? skipped,
  }) => QueueEntry(
    id: id,
    bookingId: bookingId,
    token: token,
    stage: stage ?? this.stage,
    enteredAt: enteredAt,
    queuePosition: queuePosition ?? this.queuePosition,
    estimatedCallTime: estimatedCallTime ?? this.estimatedCallTime,
    actualCallTime: actualCallTime ?? this.actualCallTime,
    isPriority: isPriority ?? this.isPriority,
    skipped: skipped ?? this.skipped,
  );

  factory QueueEntry.fromJson(Map<String, dynamic> json) => QueueEntry(
    id: json['id'] as String,
    bookingId: json['bookingId'] as String,
    token: json['token'] as String,
    stage: QueueStage.values.byName(json['stage'] as String),
    enteredAt: DateTime.parse(json['enteredAt'] as String),
    queuePosition: json['queuePosition'] as int? ?? 0,
    estimatedCallTime: json['estimatedCallTime'] != null
        ? DateTime.parse(json['estimatedCallTime'] as String)
        : null,
    actualCallTime: json['actualCallTime'] != null
        ? DateTime.parse(json['actualCallTime'] as String)
        : null,
    isPriority: json['isPriority'] as bool? ?? false,
    skipped: json['skipped'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookingId': bookingId,
    'token': token,
    'stage': stage.name,
    'enteredAt': enteredAt.toIso8601String(),
    'queuePosition': queuePosition,
    'estimatedCallTime': estimatedCallTime?.toIso8601String(),
    'actualCallTime': actualCallTime?.toIso8601String(),
    'isPriority': isPriority,
    'skipped': skipped,
  };
}
