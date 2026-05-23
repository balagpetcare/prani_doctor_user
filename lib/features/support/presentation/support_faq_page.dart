import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';


import '../../../routing/app_routes.dart';
import 'support_providers.dart';
import 'widgets/support_feedback.dart';

class SupportFaqPage extends ConsumerStatefulWidget {
  const SupportFaqPage({super.key});

  @override
  ConsumerState<SupportFaqPage> createState() => _SupportFaqPageState();
}

class _SupportFaqPageState extends ConsumerState<SupportFaqPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final helpAsync = ref.watch(supportHelpProvider);
    final query = ref.watch(supportFaqSearchProvider).trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.supportFaqTitle),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.supportContact),
            icon: const Icon(Icons.contact_support_outlined),
          ),
        ],
      ),
      body: helpAsync.when(
        loading: SupportFeedback.loading,
        error: (e, _) => SupportFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.invalidate(supportHelpProvider),
        ),
        data: (help) {
          final items = help.faq.where((item) {
            if (query.isEmpty) return true;
            return item.question.toLowerCase().contains(query) ||
                item.answer.toLowerCase().contains(query);
          }).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(supportHelpProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (help.fromCache) SupportFeedback.offlineHint(context),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.supportFaqSearchHint,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (v) =>
                      ref.read(supportFaqSearchProvider.notifier).state = v,
                ),
                const SizedBox(height: 16),
                if (items.isEmpty)
                  Center(child: Text(l10n.supportFaqEmpty))
                else
                  ...items.map(
                    (item) => Card(
                      child: ExpansionTile(
                        title: Text(item.question),
                        subtitle: Text(item.category),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(item.answer),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
