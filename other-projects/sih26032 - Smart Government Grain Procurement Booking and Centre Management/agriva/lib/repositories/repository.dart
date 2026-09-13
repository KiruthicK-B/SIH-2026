/// Generic CRUD contract every AGRIVA repository interface builds on
/// (README §0: "every screen must talk to an abstract repository interface,
/// never directly to local storage"). Phase 1 implements these with Hive;
/// Phase 2 implements the same interfaces with HTTP calls — the state layer
/// and UI depend only on this contract, never on which one is active.
abstract class Repository<T> {
  Future<List<T>> getAll();
  Future<T?> getById(String id);
  Future<void> save(T item);
  Future<void> saveMany(List<T> items);
  Future<void> delete(String id);
  Future<void> clear();
}
