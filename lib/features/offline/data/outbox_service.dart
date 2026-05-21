import '../../../core/cache/cache_store.dart';

import 'outbox_item.dart';

class OutboxService {
  OutboxService(this._store);

  final CacheStore _store;
  static const _key = '_outbox_items';

  Future<List<OutboxItem>> listAll() async {
    final raw = _store.read<List<dynamic>>(_key) ?? [];
    return raw
        .whereType<Map>()
        .map((e) => OutboxItem.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.clientSequence.compareTo(b.clientSequence));
  }

  Future<List<OutboxItem>> listReady({int limit = 25}) async {
    final items = await listAll();
    return items.where((item) => item.isReady && !item.isDead).take(limit).toList();
  }

  Future<int> pendingCount() async {
    final items = await listAll();
    return items.where((item) => !item.isDead).length;
  }

  Future<void> enqueue(OutboxItem item) async {
    final items = await listAll();
    final filtered = items.where((i) => i.idempotencyKey != item.idempotencyKey).toList();
    filtered.add(item);
    await _save(filtered);
  }

  Future<void> remove(String idempotencyKey) async {
    final items = await listAll();
    await _save(items.where((i) => i.idempotencyKey != idempotencyKey).toList());
  }

  Future<void> update(OutboxItem item) async {
    final items = await listAll();
    final next = items
        .map((i) => i.idempotencyKey == item.idempotencyKey ? item : i)
        .toList();
    await _save(next);
  }

  Future<void> clear() => _store.delete(_key);

  Future<void> _save(List<OutboxItem> items) async {
    await _store.put(_key, items.map((e) => e.toJson()).toList());
  }
}
