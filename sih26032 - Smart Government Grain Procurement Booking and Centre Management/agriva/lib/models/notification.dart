enum NotificationKind {
  slotConfirmed,
  reminder,
  centreDelay,
  rescheduleRequired,
  newSlotOffered,
  qualityResult,
  procurementComplete,
  payment,
  general,
}

class NotificationItem {
  final String id;
  final String userId; // farmerId, or 'operator'/'manager'/'all'
  final String title;
  final String message;
  final DateTime timestamp;
  final bool read;
  final NotificationKind kind;
  final bool deliveryFailed;

  const NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.timestamp,
    this.read = false,
    this.kind = NotificationKind.general,
    this.deliveryFailed = false,
  });

  NotificationItem copyWith({bool? read, bool? deliveryFailed}) =>
      NotificationItem(
        id: id,
        userId: userId,
        title: title,
        message: message,
        timestamp: timestamp,
        read: read ?? this.read,
        kind: kind,
        deliveryFailed: deliveryFailed ?? this.deliveryFailed,
      );

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        id: json['id'] as String,
        userId: json['userId'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        read: json['read'] as bool? ?? false,
        kind: NotificationKind.values.byName(
          json['kind'] as String? ?? 'general',
        ),
        deliveryFailed: json['deliveryFailed'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'read': read,
    'kind': kind.name,
    'deliveryFailed': deliveryFailed,
  };
}
