import 'enums.dart';

class QueueEntry {
  final String id;
  final String bookingId;
  final String token;
  final QueueStage stage;
  final DateTime enteredAt;

  const QueueEntry({
    required this.id,
    required this.bookingId,
    required this.token,
    required this.stage,
    required this.enteredAt,
  });

  QueueEntry copyWith({QueueStage? stage}) => QueueEntry(
    id: id,
    bookingId: bookingId,
    token: token,
    stage: stage ?? this.stage,
    enteredAt: enteredAt,
  );

  factory QueueEntry.fromJson(Map<String, dynamic> json) => QueueEntry(
    id: json['id'] as String,
    bookingId: json['bookingId'] as String,
    token: json['token'] as String,
    stage: QueueStage.values.byName(json['stage'] as String),
    enteredAt: DateTime.parse(json['enteredAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookingId': bookingId,
    'token': token,
    'stage': stage.name,
    'enteredAt': enteredAt.toIso8601String(),
  };
}
