import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every mutating controller method bumps this after it writes through a
/// repository. Read-side `FutureProvider`s across `lib/state/` watch it so
/// the UI refreshes automatically after any write — a lightweight stand-in
/// for Hive box listenables, since repositories are storage-agnostic
/// (README §0) and shouldn't themselves be Riverpod-aware.
final dataRevisionProvider = NotifierProvider<DataRevisionController, int>(
  DataRevisionController.new,
);

class DataRevisionController extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}
