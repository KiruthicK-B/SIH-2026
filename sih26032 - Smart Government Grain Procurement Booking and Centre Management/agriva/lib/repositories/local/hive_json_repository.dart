import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../repository.dart';

/// Shared Hive-backed implementation: one `Box<String>` per entity type,
/// storing each record as a JSON string keyed by its id (via the model's
/// own `toJson`/`fromJson`). This is genuinely Hive-backed local storage
/// without generated `TypeAdapter`s for every one of AGRIVA's 15+ models —
/// a deliberate simplification (see the rebuild plan) that keeps the
/// repository *interfaces* — the part Phase 2 actually swaps out — exactly
/// as the README specifies.
class HiveJsonRepository<T> implements Repository<T> {
  final Box<String> box;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T item) toJson;
  final String Function(T item) idOf;

  HiveJsonRepository(
    this.box, {
    required this.fromJson,
    required this.toJson,
    required this.idOf,
  });

  T _decode(String raw) => fromJson(jsonDecode(raw) as Map<String, dynamic>);
  String _encode(T item) => jsonEncode(toJson(item));

  @override
  Future<List<T>> getAll() async => box.values.map(_decode).toList();

  @override
  Future<T?> getById(String id) async {
    final raw = box.get(id);
    return raw == null ? null : _decode(raw);
  }

  @override
  Future<void> save(T item) async => box.put(idOf(item), _encode(item));

  @override
  Future<void> saveMany(List<T> items) async =>
      box.putAll({for (final item in items) idOf(item): _encode(item)});

  @override
  Future<void> delete(String id) async => box.delete(id);

  @override
  Future<void> clear() async => box.clear();
}

/// Opens every Hive box AGRIVA needs. Call once at startup before any
/// repository is used and before seed data is written.
class HiveBootstrap {
  HiveBootstrap._();

  static const boxNames = [
    'farmers',
    'landRecords',
    'crops',
    'centres',
    'slots',
    'districts',
    'bookings',
    'queueEntries',
    'procurementRecords',
    'payments',
    'rescheduleOffers',
    'disruptions',
    'adminUsers',
    'broadcasts',
    'grievances',
    'notifications',
    'auditLogs',
  ];

  static Future<void> init() async {
    await Hive.initFlutter();
    for (final name in boxNames) {
      await Hive.openBox<String>(name);
    }
  }

  static Box<String> box(String name) => Hive.box<String>(name);
}
