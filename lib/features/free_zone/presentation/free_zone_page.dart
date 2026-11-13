import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../animals/data/animal_dto.dart';
import '../../animals/data/animal_repository.dart';
import '../data/free_zone_repository.dart';
import '../../../routing/app_routes.dart';

/// Free consultation question. The server enforces the quota; this page only shows it.
class FreeZonePage extends ConsumerStatefulWidget {
  const FreeZonePage({super.key});

  @override
  ConsumerState<FreeZonePage> createState() => _FreeZonePageState();
}

class _FreeZonePageState extends ConsumerState<FreeZonePage> {
  final _symptoms = TextEditingController();
  final _desc = TextEditingController();
  List<AnimalProfile>? _animals;
  String? _animalId;
  FreeQuota? _quota;
  List<PublicSlot> _slots = const [];
  String? _error;
  bool _emergency = false;
  bool _busy = false;
  String? _sentId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _symptoms.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final q = await ref.read(freeZoneRepositoryProvider).quota();
      final slots = await ref.read(freeZoneRepositoryProvider).slots().catchError((_) => <PublicSlot>[]);
      final res = await ref.read(animalRepositoryProvider).listAnimals(pageSize: 50);
      final list = res.when(
        success: (d) => d.animals,
        failure: (e) => throw e,
      );
      if (!mounted) return;
      setState(() {
        _quota = q;
        _slots = slots;
        _animals = list;
        _animalId = list.isNotEmpty ? list.first.id : null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = _text(e));
    }
  }

  Future<void> _toggleBooking(PublicSlot s) async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(freeZoneRepositoryProvider);
      if (s.bookedByMe) {
        await repo.cancelBooking(s.id);
      } else {
        await repo.bookSlot(s.id);
      }
      final slots = await repo.slots().catchError((_) => <PublicSlot>[]);
      if (!mounted) return;
      setState(() => _slots = slots);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.bookedByMe ? 'বুকিং বাতিল হয়েছে।' : 'স্লট বুক হয়েছে।')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_text(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _text(Object e) {
    try {
      final m = (e as dynamic).message;
      if (m is String && m.isNotEmpty) return m;
    } catch (_) {}
    return 'আবার চেষ্টা করুন।';
  }

  Future<void> _submit() async {
    final id = _animalId;
    if (id == null || _symptoms.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('প্রাণী বেছে নিন এবং উপসর্গ লিখুন।')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final rid = await ref.read(freeZoneRepositoryProvider).submit(
            animalId: id,
            symptoms: _symptoms.text,
            description: _desc.text,
            isEmergency: _emergency,
          );
      if (mounted) setState(() => _sentId = rid);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_text(e))));
        _load();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _fmt(DateTime a, DateTime b) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(a.day)}/${two(a.month)} ${two(a.hour)}:${two(a.minute)}–${two(b.hour)}:${two(b.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_sentId != null) {
      body = const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'আপনার প্রশ্ন পাঠানো হয়েছে। একজন ডাক্তার গ্রহণ করলে আপনাকে জানানো হবে।',
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (_error != null) {
      body = Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!),
          const SizedBox(height: 8),
          FilledButton(onPressed: _load, child: const Text('আবার চেষ্টা করুন')),
        ]),
      );
    } else if (_quota == null || _animals == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_animals!.isEmpty) {
      body = const Center(child: Text('আগে একটি প্রাণী যোগ করুন।'));
    } else {
      final q = _quota!;
      final blocked = !q.canAsk && !_emergency;
      body = ListView(padding: const EdgeInsets.all(16), children: [
        if (!q.canAsk)
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(q.message ?? 'এখন ফ্রি পরামর্শ চাওয়া যাবে না।'),
            ),
          ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _animalId,
          decoration: const InputDecoration(labelText: 'প্রাণী'),
          items: [
            for (final a in _animals!) DropdownMenuItem(value: a.id, child: Text('${a.name} (${a.species})')),
          ],
          onChanged: (v) => setState(() => _animalId = v),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _symptoms,
          maxLines: 4,
          maxLength: 1000,
          decoration: const InputDecoration(labelText: 'উপসর্গ / সমস্যা'),
        ),
        TextField(
          controller: _desc,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'অতিরিক্ত তথ্য (ঐচ্ছিক)'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('জরুরি অবস্থা'),
          subtitle: const Text('জরুরি হলে ফ্রি সীমা প্রযোজ্য নয়। তবে প্রাণীর অবস্থা গুরুতর হলে সরাসরি নিকটস্থ ডাক্তারের কাছে যান।'),
          value: _emergency,
          onChanged: (v) => setState(() => _emergency = v),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: (_busy || blocked) ? null : _submit,
          child: Text(_busy ? 'পাঠানো হচ্ছে…' : 'ফ্রি প্রশ্ন পাঠান'),
        ),
        if (_slots.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('ডাক্তারদের আসন্ন ফ্রি সময়', style: Theme.of(context).textTheme.titleMedium),
          for (final s in _slots)
            Card(
              child: ListTile(
                title: Row(children: [
                  Flexible(child: Text(s.doctorName)),
                  if (s.verified)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Tooltip(message: 'যাচাইকৃত ডাক্তার', child: Icon(Icons.verified, size: 18, color: Colors.blue)),
                    ),
                ]),
                subtitle: Text([
                  _fmt(s.startsAt, s.endsAt),
                  if (s.degree != null) s.degree!,
                  if (s.ratingAvg != null) '★ ${s.ratingAvg} (${s.ratingCount})',
                  s.seatsLeft > 0 ? 'ফাঁকা ${s.seatsLeft}টি' : 'পূর্ণ',
                ].join(' · ')),
                trailing: s.bookedByMe
                    ? OutlinedButton(onPressed: _busy ? null : () => _toggleBooking(s), child: const Text('বাতিল'))
                    : FilledButton(
                        onPressed: (_busy || s.seatsLeft <= 0) ? null : () => _toggleBooking(s),
                        child: const Text('বুক করুন'),
                      ),
              ),
            ),
        ],
      ]);
    }
    return Scaffold(appBar: AppBar(
        title: const Text('ফ্রি পরামর্শ'),
        actions: [
          TextButton(onPressed: () => context.push(AppRoutes.freeFeed), child: const Text('সবার প্রশ্ন')),
          TextButton(onPressed: () => context.push(AppRoutes.myFreeQuestions), child: const Text('আমার প্রশ্ন')),
        ],
      ), body: body);
  }
}
