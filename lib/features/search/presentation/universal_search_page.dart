import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_guard.dart';
import '../../../features/ai/data/speech_service.dart';
import 'universal_search_provider.dart';

class UniversalSearchPage extends ConsumerStatefulWidget {
  const UniversalSearchPage({super.key, this.startVoice = false});

  final bool startVoice;

  @override
  ConsumerState<UniversalSearchPage> createState() =>
      _UniversalSearchPageState();
}

class _UniversalSearchPageState extends ConsumerState<UniversalSearchPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(universalSearchQueryProvider),
    );
    if (widget.startVoice) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startVoice());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startVoice() async {
    final speech = PlatformSpeechService();
    if (!await speech.initialize() || !mounted) return;
    if (!await speech.startListening() || !mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.homeSearchListening),
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.homeSearchStop,
            onPressed: () async {
              final text = await speech.stopListening();
              speech.dispose();
              if (text != null && mounted) {
                _controller.text = text;
                ref.read(universalSearchQueryProvider.notifier).state = text;
              }
            },
          ),
        ),
      );
  }

  void _submit(String value) {
    ref.read(universalSearchQueryProvider.notifier).state = value;
    ref.read(universalSearchRecentProvider.notifier).add(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final resultsAsync = ref.watch(universalSearchResultsProvider);
    final recent = ref.watch(universalSearchRecentProvider);

    return Scaffold(
      appBar: safeAppBar(
        context,
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.homeSearchPlaceholder,
            border: InputBorder.none,
          ),
          onChanged: (value) =>
              ref.read(universalSearchQueryProvider.notifier).state = value,
          onSubmitted: _submit,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic_outlined),
            onPressed: _startVoice,
            tooltip: l10n.homeSearchVoice,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_controller.text.trim().isEmpty) ...[
            Text(
              l10n.homeSearchRecentTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (recent.isEmpty)
              Text(l10n.homeSearchRecentEmpty)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: recent
                    .map(
                      (q) => ActionChip(
                        label: Text(
                          q,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () {
                          _controller.text = q;
                          _submit(q);
                        },
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 16),
            Text(
              l10n.homeSearchSourcesTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ..._sourceChips(l10n),
          ] else
            resultsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Text(l10n.dashboardSectionError),
              data: (results) {
                if (results.isEmpty) {
                  return Text(l10n.homeSearchNoResults);
                }
                return Column(
                  children: results
                      .map(
                        (result) => ListTile(
                          title: Text(
                            result.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${result.category} · ${result.subtitle}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            _submit(_controller.text);
                            context.push(result.route);
                          },
                        ),
                      )
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  List<Widget> _sourceChips(AppLocalizations l10n) {
    final sources = [
      l10n.homeSearchSourceDoctors,
      l10n.homeSearchSourceAi,
      l10n.homeSearchSourceServices,
      l10n.homeSearchSourceAnimals,
      l10n.homeSearchSourceMarketplace,
      l10n.homeSearchSourceReports,
      l10n.homeSearchSourceCommunity,
      l10n.homeSearchSourceEmergency,
    ];
    return sources
        .map(
          (label) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Chip(label: Text(label)),
            ),
          ),
        )
        .toList();
  }
}
