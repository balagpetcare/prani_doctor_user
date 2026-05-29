import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../data/fattening_repository.dart';
import '../data/fattening_roi_dto.dart';
import 'fattening_providers.dart';
import 'widgets/fattening_feedback.dart';

class FatteningBatchRoiPage extends ConsumerWidget {
  const FatteningBatchRoiPage({
    super.key,
    required this.farmId,
    required this.batchId,
  });

  final String farmId;
  final String batchId;

  String _money(double v) => '৳${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final roiAsync = ref.watch(fatteningBatchRoiProvider(batchId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.fatteningRoiTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.fatteningEditRoi,
            onPressed: () => _showEditDialog(context, ref, roiAsync.valueOrNull),
          ),
        ],
      ),
      body: roiAsync.when(
        loading: FatteningFeedback.loading,
        error: (e, _) => FatteningFeedback.error(
          context,
          error: e,
          onRetry: () => ref.invalidate(fatteningBatchRoiProvider(batchId)),
        ),
        data: (roi) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(fatteningBatchRoiProvider(batchId));
              await ref.read(fatteningBatchRoiProvider(batchId).future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (roi.fromCache) FatteningFeedback.offlineHint(context),
                Text(
                  l10n.fatteningRoiCostSection,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _CostRow(
                  icon: Icons.shopping_cart_outlined,
                  label: l10n.fatteningRoiPurchase,
                  value: _money(roi.purchase.amountBdt),
                ),
                _CostRow(
                  icon: Icons.grass_outlined,
                  label: l10n.fatteningRoiFeed,
                  value: _money(roi.feed.amountBdt),
                  subtitle: roi.feed.recordCount > 0
                      ? l10n.fatteningRoiRecordCount(roi.feed.recordCount)
                      : null,
                ),
                _CostRow(
                  icon: Icons.medical_services_outlined,
                  label: l10n.fatteningRoiTreatment,
                  value: _money(roi.treatment.amountBdt),
                  subtitle: roi.treatment.recordCount > 0
                      ? l10n.fatteningRoiRecordCount(roi.treatment.recordCount)
                      : l10n.fatteningRoiTreatmentHint,
                ),
                const Divider(height: 32),
                _CostRow(
                  icon: Icons.receipt_long_outlined,
                  label: l10n.fatteningRoiTotalCost,
                  value: _money(roi.totalCostBdt),
                  emphasized: true,
                ),
                const SizedBox(height: 24),
                _CostRow(
                  icon: Icons.sell_outlined,
                  label: l10n.fatteningRoiProjectedSale,
                  value: _money(roi.projectedSaleBdt),
                ),
                const SizedBox(height: 12),
                Card(
                  color: roi.profitBdt >= 0
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          roi.profitBdt >= 0
                              ? Icons.trending_up
                              : Icons.trending_down,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.fatteningRoiProfit,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                _money(roi.profitBdt),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              if (roi.profitMarginPct != null)
                                Text(
                                  l10n.fatteningRoiMargin(roi.profitMarginPct!),
                                ),
                            ],
                          ),
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

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    FatteningBatchRoi? roi,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final settings = roi?.settings;
    final purchaseController = TextEditingController(
      text: settings?.purchaseCostBdt?.toStringAsFixed(0) ??
          roi?.purchase.manualAmountBdt?.toStringAsFixed(0) ??
          '',
    );
    final saleController = TextEditingController(
      text: settings?.projectedSaleBdt?.toStringAsFixed(0) ??
          roi?.projectedSaleBdt.toStringAsFixed(0) ??
          '',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.fatteningEditRoi),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: purchaseController,
                decoration: InputDecoration(
                  labelText: l10n.fatteningRoiPurchase,
                  prefixText: '৳ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: saleController,
                decoration: InputDecoration(
                  labelText: l10n.fatteningRoiProjectedSale,
                  prefixText: '৳ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.fatteningSaveRoi),
          ),
        ],
      ),
    );

    if (saved != true || !context.mounted) return;

    final purchase = double.tryParse(purchaseController.text.trim());
    final sale = double.tryParse(saleController.text.trim());
    final result = await ref.read(fatteningRepositoryProvider).upsertRoi(
          batchId,
          FatteningRoiSettings(
            purchaseCostBdt: purchase,
            projectedSaleBdt: sale,
          ),
        );
    if (!context.mounted) return;
    result.when(
      success: (_) {
        ref.invalidate(fatteningBatchRoiProvider(batchId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.fatteningRoiSaved)),
        );
      },
      failure: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      },
    );
  }
}

class _CostRow extends StatelessWidget {
  const _CostRow({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: style)),
          Text(
            value,
            style: style?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
