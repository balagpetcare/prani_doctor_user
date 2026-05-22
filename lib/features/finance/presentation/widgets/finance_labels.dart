import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../data/finance_dto.dart';

String expenseCategoryLabel(AppLocalizations l10n, ExpenseCategory category) {
  return switch (category) {
    ExpenseCategory.feed => l10n.financeCategoryFeed,
    ExpenseCategory.medicine => l10n.financeCategoryMedicine,
    ExpenseCategory.labor => l10n.financeCategoryLabor,
    ExpenseCategory.equipment => l10n.financeCategoryEquipment,
    ExpenseCategory.transport => l10n.financeCategoryTransport,
    ExpenseCategory.other => l10n.financeCategoryOther,
  };
}

String incomeSourceLabel(AppLocalizations l10n, IncomeSource source) {
  return switch (source) {
    IncomeSource.milkSales => l10n.financeSourceMilkSales,
    IncomeSource.animalSales => l10n.financeSourceAnimalSales,
    IncomeSource.subsidy => l10n.financeSourceSubsidy,
    IncomeSource.service => l10n.financeSourceService,
    IncomeSource.other => l10n.financeSourceOther,
  };
}
