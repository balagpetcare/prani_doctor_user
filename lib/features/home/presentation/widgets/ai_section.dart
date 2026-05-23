import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../routing/app_routes.dart';
import '../../../ai/presentation/ai_providers.dart';
import '../theme/home_tokens.dart';
import 'home_card.dart';
import 'home_layout.dart';

class HomeAiSection extends ConsumerWidget {
  const HomeAiSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final chatAsync = ref.watch(aiChatProvider);

    return SliverToBoxAdapter(
      child: HomeSectionScope(
        label: l10n.dashboardAskAi,
        child: Padding(
          padding: const EdgeInsets.only(top: HomeTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeSectionHeader(title: l10n.dashboardAskAi),
              Padding(
                padding: HomeTokens.pageHorizontal(context),
                child: HomeSurfaceCard(
                  onTap: () => context.push(AppRoutes.ai),
                  semanticLabel: l10n.dashboardAskAi,
                  child: chatAsync.when(
                    loading: () => Row(
                      children: [
                        Icon(
                          Icons.psychology_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 36,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(l10n.aiHomeTitle)),
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ),
                    error: (_, _) => Row(
                      children: [
                        Icon(
                          Icons.psychology_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 36,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(l10n.aiHomeTitle)),
                        TextButton(
                          onPressed: () =>
                              ref.read(aiChatProvider.notifier).reload(),
                          child: Text(l10n.dashboardRetry),
                        ),
                      ],
                    ),
                    data: (state) => Row(
                      children: [
                        Icon(
                          Icons.psychology_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 36,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.aiAskTitle,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                state.messages.isEmpty
                                    ? l10n.aiEmptyState
                                    : l10n.aiHomeActiveSession,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
