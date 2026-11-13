import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/free_zone_repository.dart';

/// Comment thread of one free question. Verified doctors and other customers can comment; the asker can hide
/// comments on their question; everyone else can report a comment.
class FreeQuestionThreadPage extends ConsumerStatefulWidget {
  const FreeQuestionThreadPage({super.key, required this.question});
  final FeedItem question;

  @override
  ConsumerState<FreeQuestionThreadPage> createState() => _FreeQuestionThreadPageState();
}

class _FreeQuestionThreadPageState extends ConsumerState<FreeQuestionThreadPage> {
  final _input = TextEditingController();
  CommentThread? _thread;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  String _text(Object e) {
    try {
      final m = (e as dynamic).message;
      if (m is String && m.isNotEmpty) return m;
    } catch (_) {}
    return 'আবার চেষ্টা করুন।';
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final t = await ref.read(freeZoneRepositoryProvider).comments(widget.question.id);
      if (mounted) setState(() => _thread = t);
    } catch (e) {
      if (mounted) setState(() => _error = _text(e));
    }
  }

  Future<void> _send() async {
    final body = _input.text.trim();
    if (body.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(freeZoneRepositoryProvider).postComment(widget.question.id, body);
      _input.clear();
      await _load();
    } catch (e) {
      if (mounted) _snack(_text(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _hide(FreeComment c, bool hidden) async {
    try {
      await ref.read(freeZoneRepositoryProvider).setCommentHidden(c.id, hidden);
      await _load();
      if (mounted) _snack(hidden ? 'মন্তব্য লুকানো হয়েছে।' : 'মন্তব্য আবার দেখানো হচ্ছে।');
    } catch (e) {
      if (mounted) _snack(_text(e));
    }
  }

  Future<void> _report(FreeComment c) async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('মন্তব্যটি রিপোর্ট করুন'),
        content: TextField(
          controller: reason,
          maxLength: 300,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'কারণ (ঐচ্ছিক)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('বাতিল')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('রিপোর্ট করুন')),
        ],
      ),
    );
    final text = reason.text;
    reason.dispose();
    if (ok != true) return;
    try {
      await ref.read(freeZoneRepositoryProvider).reportComment(c.id, reason: text);
      await _load();
      if (mounted) _snack('রিপোর্ট পাঠানো হয়েছে। ধন্যবাদ।');
    } catch (e) {
      if (mounted) _snack(_text(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    Widget list;
    if (_error != null) {
      list = Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!),
          const SizedBox(height: 8),
          FilledButton(onPressed: _load, child: const Text('আবার চেষ্টা করুন')),
        ]),
      );
    } else if (_thread == null) {
      list = const Center(child: CircularProgressIndicator());
    } else if (_thread!.items.isEmpty) {
      list = const Center(child: Text('এখনও কোনো মন্তব্য নেই।'));
    } else {
      list = ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _thread!.items.length,
        itemBuilder: (context, i) {
          final c = _thread!.items[i];
          return Opacity(
            opacity: c.hidden ? 0.55 : 1,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Flexible(child: Text(c.authorName, style: const TextStyle(fontWeight: FontWeight.w600))),
                        if (c.verified)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Tooltip(message: 'যাচাইকৃত ডাক্তার', child: Icon(Icons.verified, size: 16, color: Colors.blue)),
                          ),
                        if (c.isMine) const Text('  (আপনি)'),
                      ]),
                      const SizedBox(height: 4),
                      Text(c.body),
                      if (c.hidden)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text('লুকানো — অন্যরা দেখছে না', style: TextStyle(fontStyle: FontStyle.italic)),
                        ),
                    ]),
                  ),
                  if (c.canHide || c.canUnhide || c.canReport)
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'hide') _hide(c, true);
                        if (v == 'unhide') _hide(c, false);
                        if (v == 'report') _report(c);
                      },
                      itemBuilder: (_) => [
                        if (c.canHide) const PopupMenuItem(value: 'hide', child: Text('লুকান')),
                        if (c.canUnhide) const PopupMenuItem(value: 'unhide', child: Text('আবার দেখান')),
                        if (c.canReport) const PopupMenuItem(value: 'report', child: Text('রিপোর্ট করুন')),
                      ],
                    ),
                ]),
              ),
            ),
          );
        },
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('প্রশ্ন ও মন্তব্য')),
      body: Column(children: [
        Container(
          width: double.infinity,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.all(12),
          child: Text(q.symptoms),
        ),
        Expanded(child: list),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  maxLength: 1000,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'মন্তব্য লিখুন (ফোন নম্বর দেওয়া নিষেধ)', counterText: ''),
                ),
              ),
              IconButton(onPressed: _busy ? null : _send, icon: const Icon(Icons.send)),
            ]),
          ),
        ),
      ]),
    );
  }
}
