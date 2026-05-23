import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import '../data/support_dto.dart';
import 'support_providers.dart';
import 'widgets/support_feedback.dart';
import 'widgets/support_summary_section.dart';
import 'widgets/support_ticket_card.dart';

class SupportHomePage extends ConsumerWidget {
  const SupportHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final listAsync = ref.watch(supportTicketListProvider);
    final summaryAsync = ref.watch(supportSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.supportHomeTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(supportTicketListProvider.notifier).refresh();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            summaryAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const SizedBox.shrink(),
              data: (summary) => SupportSummarySection(summary: summary),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () =>
                        context.push(AppRoutes.supportTicketCreate),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.supportCreateTicket),
                  ),
                  OutlinedButton(
                    onPressed: () => context.push(AppRoutes.supportTickets),
                    child: Text(l10n.dashboardSupportTickets),
                  ),
                  OutlinedButton(
                    onPressed: () => context.push(AppRoutes.supportHelp),
                    child: Text(l10n.supportHelpTitle),
                  ),
                  OutlinedButton(
                    onPressed: () => context.push(AppRoutes.supportFaq),
                    child: Text(l10n.supportFaqTitle),
                  ),
                  OutlinedButton(
                    onPressed: () => context.push(AppRoutes.supportContact),
                    child: Text(l10n.supportContactTitle),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                l10n.supportRecentTicketsTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            listAsync.when(
              loading: SupportFeedback.loading,
              error: (e, _) => SupportFeedback.error(
                context,
                message: e.toString(),
                onRetry: () => ref
                    .read(supportTicketListProvider.notifier)
                    .reload(forceRefresh: true),
              ),
              data: (state) {
                if (state.fromCache) {
                  return Column(
                    children: [
                      SupportFeedback.offlineHint(context),
                      ..._recentTickets(context, state.tickets),
                    ],
                  );
                }
                return Column(children: _recentTickets(context, state.tickets));
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _recentTickets(
    BuildContext context,
    List<SupportTicketSummary> tickets,
  ) {
    if (tickets.isEmpty) {
      return [
        SupportFeedback.empty(
          context,
          onCreate: () => context.push(AppRoutes.supportTicketCreate),
        ),
      ];
    }
    final recent = tickets.take(5).toList();
    return recent
        .map(
          (ticket) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SupportTicketCard(
              ticket: ticket,
              onTap: () =>
                  context.push(AppRoutes.supportTicketDetail(ticket.id)),
            ),
          ),
        )
        .toList();
  }
}
