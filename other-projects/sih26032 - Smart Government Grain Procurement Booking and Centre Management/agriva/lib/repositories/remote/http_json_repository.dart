import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../repository.dart';

/// HTTP-backed counterpart to `HiveJsonRepository<T>` (see
/// repositories/local/hive_json_repository.dart) — same constructor shape
/// (fromJson/toJson/idOf), same `Repository<T>` contract, but each method
/// hits the backend's generic `/api/v1/<entityPath>` routes instead of a Hive
/// box. `entityPath` must match one of the ENTITY_TABLES whitelisted in
/// backend/src/entities.js.
class HttpJsonRepository<T> implements Repository<T> {
  final String entityPath;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T item) toJson;
  final String Function(T item) idOf;

  HttpJsonRepository(
    this.entityPath, {
    required this.fromJson,
    required this.toJson,
    required this.idOf,
  });

  Uri _uri([String suffix = '']) => Uri.parse('$kApiBaseUrl/$entityPath$suffix');

  // Skips the ngrok free-tier browser-warning interstitial page, which would
  // otherwise return HTML instead of JSON when kApiBaseUrl is a *.ngrok-free
  // tunnel.
  static const _headers = {'ngrok-skip-browser-warning': 'true'};
  static const _jsonHeaders = {
    ..._headers,
    'content-type': 'application/json',
  };

  void _checkOk(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('AGRIVA backend ${res.request?.method} ${res.request?.url} '
          'failed: ${res.statusCode} ${res.body}');
    }
  }

  @override
  Future<List<T>> getAll() async {
    final res = await http.get(_uri(), headers: _headers);
    _checkOk(res);
    final list = jsonDecode(res.body) as List;
    return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<T?> getById(String id) async {
    final res = await http.get(_uri('/$id'), headers: _headers);
    if (res.statusCode == 404) return null;
    _checkOk(res);
    return fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  @override
  Future<void> save(T item) async {
    final res = await http.post(
      _uri(),
      headers: _jsonHeaders,
      body: jsonEncode(toJson(item)),
    );
    _checkOk(res);
  }

  @override
  Future<void> saveMany(List<T> items) async {
    final res = await http.post(
      _uri('/batch'),
      headers: _jsonHeaders,
      body: jsonEncode(items.map(toJson).toList()),
    );
    _checkOk(res);
  }

  @override
  Future<void> delete(String id) async {
    final res = await http.delete(_uri('/$id'), headers: _headers);
    _checkOk(res);
  }

  @override
  Future<void> clear() async {
    final res = await http.delete(_uri(), headers: _headers);
    _checkOk(res);
  }
}
