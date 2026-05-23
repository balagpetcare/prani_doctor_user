import 'package:hive_flutter/hive_flutter.dart';

/// Typed facade over a Hive box for offline / session-adjacent cache.
class CacheStore {
  CacheStore(this._box);

  final Box<dynamic> _box;

  String get name => _box.name;

  T? read<T>(String key) {
    final value = _box.get(key);
    if (value is T) return value;
    return null;
  }

  Future<void> put(String key, dynamic value) => _box.put(key, value);

  Future<void> delete(String key) => _box.delete(key);

  Future<void> clear() => _box.clear();

  Iterable<dynamic> get values => _box.values;
}
