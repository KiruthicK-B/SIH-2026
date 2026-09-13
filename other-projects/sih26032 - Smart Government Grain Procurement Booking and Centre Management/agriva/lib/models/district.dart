/// README §4 District.
class District {
  final String id;
  final String name;
  final String stateCode;

  const District({
    required this.id,
    required this.name,
    this.stateCode = 'DEMO',
  });

  factory District.fromJson(Map<String, dynamic> json) => District(
    id: json['id'] as String,
    name: json['name'] as String,
    stateCode: json['stateCode'] as String? ?? 'DEMO',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'stateCode': stateCode,
  };
}
