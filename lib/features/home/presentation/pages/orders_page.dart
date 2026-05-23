import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../core/navigation/navigation_guard.dart';
import '../../../../routing/app_routes.dart';
import '../../../service_requests/data/service_request_dto.dart';
import '../../../service_requests/presentation/service_request_status_chip.dart';
import '../models/home_section_models.dart';
import '../providers/home_orders_provider.dart';
import '../theme/home_tokens.dart';
import '../widgets/home_card.dart';

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summaryAsync = ref.watch(homeOrdersSummaryProvider);

    return Scaffold(
      appBar: safeAppBar(context, title: Text(l10n.homeDrawerOrders)),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: HomeErrorRetry(
            message: l10n.dashboardSectionError,
            onRetry: () => ref.invalidate(homeOrdersSummaryProvider),
          ),
        ),
        data: (summary) {
          if (summary.total == 0) {
            return HomeEmptyState(
              message: l10n.homeOrdersEmpty,
              icon: Icons.receipt_long_outlined,
              actionLabel: l10n.homeBookDoctor,
              onAction: () => context.go(AppRoutes.services),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(homeOrdersListProvider),
            child: ListView(
              padding: EdgeInsetsDirectional.fromSTEB(
                HomeTokens.space16,
                HomeTokens.space16,
                HomeTokens.space16,
                HomeTokens.bottomScrollPadding(context),
              ),
              children: [
                _OrdersSummaryRow(summary: summary, l10n: l10n),
                const SizedBox(height: HomeTokens.space16),
                Text(
                  l10n.homeOrdersRecentTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: HomeTokens.space8),
                ...summary.recent.map(
                  (request) => Padding(
                    padding: const EdgeInsets.only(bottom: HomeTokens.space8),
                    child: _OrderTile(request: request),
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

class _OrdersSummaryRow extends StatelessWidget {
  const _OrdersSummaryRow({required this.summary, required this.l10n});

  final HomeOrdersSummary summary;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryChip(
            label: l10n.homeOrdersPending,
            value: '${summary.pending}',
            icon: Icons.hourglass_top_outlined,
          ),
        ),
        const SizedBox(width: HomeTokens.space8),
        Expanded(
          child: _SummaryChip(
            label: l10n.homeOrdersCompleted,
            value: '${summary.completed}',
            icon: Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: HomeTokens.space8),
        Expanded(
          child: _SummaryChip(
            label: l10n.homeOrdersCancelled,
            value: '${summary.cancelled}',
            icon: Icons.cancel_outlined,
          ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return HomeSurfaceCard(
      padding: const EdgeInsets.all(HomeTokens.space12),
      semanticLabel: '$label $value',
      child: Column(
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: HomeTokens.space4),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.request});

  final ServiceRequestDto request;

  @override
  Widget build(BuildContext context) {
    return HomeSurfaceCard(
      onTap: () => context.push(AppRoutes.serviceRequestDetail(request.id)),
      semanticLabel: request.problemOrSymptom,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          request.serviceCategory?.name ?? request.problemOrSymptom,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          request.animal?.name ?? request.createdAt ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: ServiceRequestStatusChip(status: request.status),
      ),
    );
  }
}
