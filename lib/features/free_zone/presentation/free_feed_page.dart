import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/free_zone_repository.dart';
import 'free_question_thread_page.dart';

/// Public Q&A feed: every free question (asker anonymous). Tap to read and join the comment thread.
class FreeFeedPage extends ConsumerStatefulWidget {
  const FreeFeedPage({super.key});

  @override
  ConsumerState<FreeFeedPage> createState() => _FreeFeedPageState();
}

class _FreeFeedPageState extends ConsumerState<FreeFeedPage> {
  List<FeedItem>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final r = await ref.read(freeZoneRepositoryProvider).feed();
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

  String _date(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_error != null) {
      body = Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!),
          const SizedBox(height: 8),
          FilledButton(onPressed: _load, child: const Text('আবার চেষ্টা করুন')),
        ]),
      );
    } else if (_items == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_items!.isEmpty) {
      body = const Center(child: Text('এখনও কোনো প্রশ্ন নেই।'));
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _items!.length,
          itemBuilder: (context, i) {
            final q = _items![i];
            return Card(
              child: ListTile(
                title: Text(q.symptoms, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text([
                  if (q.isEmergency) 'জরুরি',
                  if (q.species.isNotEmpty) q.species,
                  _date(q.submittedAt),
                  if (q.isMine) 'আমার প্রশ্ন',
                ].join(' · ')),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.chat_bubble_outline, size: 18),
                  const SizedBox(width: 4),
                  Text('${q.commentCount}'),
                ]),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => FreeQuestionThreadPage(question: q)),
                  );
                  if (mounted) _load();
                },
              ),
            );
          },
        ),
      );
    }
    return Scaffold(appBar: AppBar(title: const Text('সবার ফ্রি প্রশ্ন')), body: body);
  }
}
