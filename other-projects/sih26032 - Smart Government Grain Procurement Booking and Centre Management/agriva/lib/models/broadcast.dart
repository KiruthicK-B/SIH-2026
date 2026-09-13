/// README §4 Broadcast — State Admin announcements.
class Broadcast {
  final String id;
  final String title;
  final String message;
  final String? targetDistrict; // null = all
  final String? targetCrop; // null = all
  final String createdBy;
  final DateTime createdAt;
  final Map<String, String> localizedMessage; // languageCode -> text

  const Broadcast({
    required this.id,
    required this.title,
    required this.message,
    this.targetDistrict,
    this.targetCrop,
    required this.createdBy,
    required this.createdAt,
    this.localizedMessage = const {},
  });

  String messageFor(String languageCode) =>
      localizedMessage[languageCode] ?? message;

  factory Broadcast.fromJson(Map<String, dynamic> json) => Broadcast(
    id: json['id'] as String,
    title: json['title'] as String,
    message: json['message'] as String,
    targetDistrict: json['targetDistrict'] as String?,
    targetCrop: json['targetCrop'] as String?,
    createdBy: json['createdBy'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    localizedMessage:
        (json['localizedMessage'] as Map?)?.cast<String, String>() ?? const {},
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'targetDistrict': targetDistrict,
    'targetCrop': targetCrop,
    'createdBy': createdBy,
    'createdAt': createdAt.toIso8601String(),
    'localizedMessage': localizedMessage,
  };
}
