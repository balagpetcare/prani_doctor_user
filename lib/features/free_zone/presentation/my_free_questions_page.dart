import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/free_zone_repository.dart';

/// The customer's own free questions: status, doctor, and a rating prompt once completed.
class MyFreeQuestionsPage extends ConsumerStatefulWidget {
  const MyFreeQuestionsPage({super.key});

  @override
  ConsumerState<MyFreeQuestionsPage> createState() => _MyFreeQuestionsPageState();
}

class _MyFreeQuestionsPageState extends ConsumerState<MyFreeQuestionsPage> {
  List<MyQuestion>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final r = await ref.read(freeZoneRepositoryProvider).myQuestions();
      if (mounted) setState(() => _items = r);
    } catch (e) {
      if (mounted) setState(() => _error = _text(e));
    }
  }

  String _text(Object e) {
    try {
      final m = (e as dynamic).message;
      if (m is String && m.isNotEmpty) return m;
    } catch (_) {}
    return 'আবার চেষ্টা করুন।';
  }

  Future<void> _rate(MyQuestion q) async {
    var stars = 5;
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('ডাক্তারকে রেটিং দিন'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  onPressed: () => set(() => stars = i),
                  icon: Icon(i <= stars ? Icons.star : Icons.star_border, color: Colors.amber),
                ),
            ]),
            TextField(controller: c, maxLines: 3, maxLength: 1000, decoration: const InputDecoration(hintText: 'মন্তব্য (ঐচ্ছিক)')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('বাতিল')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('জমা দিন')),
          ],
        ),
      ),
    );
    final comment = c.text;
    c.dispose();
    if (ok != true) return;
    try {
      await ref.read(freeZoneRepositoryProvider).rate(q.id, stars, comment: comment);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ধন্যবাদ, রেটিং জমা হয়েছে')));
      }
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_text(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_error != null && _items == null) {
      body = Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!),
          FilledButton(onPressed: _load, child: const Text('আবার চেষ্টা করুন')),
        ]),
      );
    } else if (_items == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_items!.isEmpty) {
      body = const Center(child: Text('আপনি এখনো কোনো ফ্রি প্রশ্ন করেননি।'));
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.all(12), children: [
          for (final q in _items!)
            Card(
              child: ListTile(
                title: Text('${q.animalName} · ${q.statusBn}'),
                subtitle: Text([
                  q.symptoms,
                  if (q.doctorName != null) 'ডাক্তার: ${q.doctorName}',
                  if (q.myRating != null) 'আপনার রেটিং: ${q.myRating}★',
                ].join('\n')),
                isThreeLine: true,
                trailing: q.canRate ? TextButton(onPressed: () => _rate(q), child: const Text('রেটিং দিন')) : null,
              ),
            ),
        ]),
      );
    }
    return Scaffold(appBar: AppBar(title: const Text('আমার ফ্রি প্রশ্ন')), body: body);
  }
}
