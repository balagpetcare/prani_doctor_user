import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import 'ai_providers.dart';
import 'widgets/ai_disclaimer_banner.dart';

class AiHomePage extends ConsumerWidget {
  const AiHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final chatAsync = ref.watch(aiChatProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aiHomeTitle),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.aiSettings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AiDisclaimerBanner(),
          const SizedBox(height: 16),
          chatAsync.when(
            loading: () => const LinearProgressIndicator(minHeight: 2),
            error: (_, _) => const SizedBox.shrink(),
            data: (state) => Text(
              state.messages.isEmpty
                  ? l10n.aiEmptyState
                  : l10n.aiHomeActiveSession,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push(AppRoutes.aiChat),
            icon: const Icon(Icons.chat_outlined),
            label: Text(l10n.aiAskTitle),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.aiVoiceInput),
            icon: const Icon(Icons.mic_none),
            label: Text(l10n.aiVoiceTitle),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.aiHistory),
            icon: const Icon(Icons.history),
            label: Text(l10n.aiHistoryTitle),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.aiSymptomChecker),
            icon: const Icon(Icons.medical_information_outlined),
            label: const Text('লক্ষণ যাচাই'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.aiSmartRecommendations),
            icon: const Icon(Icons.lightbulb_outline),
            label: const Text('AI পরামর্শ'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.aiFarmHealth),
            icon: const Icon(Icons.health_and_safety_outlined),
            label: const Text('খামার স্বাস্থ্য'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.aiKnowledgeSearch),
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('জ্ঞান ভান্ডার'),
          ),
        ],
      ),
    );
  }
}
