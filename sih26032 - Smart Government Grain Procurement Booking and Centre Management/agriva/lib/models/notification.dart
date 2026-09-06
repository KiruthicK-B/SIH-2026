import 'enums.dart';

class NotificationItem {
  final String id;
  final String userId; // farmerId, or 'centreOperator'/'districtAdmin'/'all'
  final String title;
  final String message;
  final DateTime timestamp;
  final bool read;
  final NotificationType type;
  final NotificationChannel channel;
  final String language;
  final NotificationDeliveryStatus deliveryStatus;
  final int retryCount;

  const NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.timestamp,
    this.read = false,
    this.type = NotificationType.general,
    this.channel = NotificationChannel.app,
    this.language = 'en',
    this.deliveryStatus = NotificationDeliveryStatus.sent,
    this.retryCount = 0,
  });

  bool get deliveryFailed =>
      deliveryStatus == NotificationDeliveryStatus.failed;

  NotificationItem copyWith({
    bool? read,
    NotificationDeliveryStatus? deliveryStatus,
    int? retryCount,
  }) => NotificationItem(
    id: id,
    userId: userId,
    title: title,
    message: message,
    timestamp: timestamp,
    read: read ?? this.read,
    type: type,
    channel: channel,
    language: language,
    deliveryStatus: deliveryStatus ?? this.deliveryStatus,
    retryCount: retryCount ?? this.retryCount,
  );

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        id: json['id'] as String,
        userId: json['userId'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        read: json['read'] as bool? ?? false,
        type: NotificationType.values.byName(
          json['type'] as String? ?? json['kind'] as String? ?? 'general',
        ),
        channel: NotificationChannel.values.byName(
          json['channel'] as String? ?? 'app',
        ),
        language: json['language'] as String? ?? 'en',
        deliveryStatus: NotificationDeliveryStatus.values.byName(
          json['deliveryStatus'] as String? ??
              (json['deliveryFailed'] == true ? 'failed' : 'sent'),
        ),
        retryCount: json['retryCount'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'read': read,
    'type': type.name,
    'channel': channel.name,
    'language': language,
    'deliveryStatus': deliveryStatus.name,
    'retryCount': retryCount,
  };
}
