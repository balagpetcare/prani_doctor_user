import 'package:flutter_test/flutter_test.dart';

import 'package:pranidoctor_user/features/finance/data/finance_dto.dart';
import 'package:pranidoctor_user/features/finance/data/finance_validation.dart';

void main() {
  group('FinanceRecord', () {
    test('parses expense json', () {
      final record = FinanceRecord.fromJson({
        'id': 'e1',
        'customerId': 'c1',
        'type': 'EXPENSE',
        'amountBdt': '500.00',
        'category': 'FEED',
        'recordedDate': '2026-05-22',
        'createdAt': '2026-05-22T08:00:00.000Z',
        'updatedAt': '2026-05-22T08:00:00.000Z',
      });
      expect(record.category, ExpenseCategory.feed);
      expect(record.amountBdt, 500);
      expect(record.isExpense, isTrue);
    });

    test('parses income json', () {
      final record = FinanceRecord.fromJson({
        'id': 'i1',
        'customerId': 'c1',
        'type': 'INCOME',
        'amountBdt': '1200.50',
        'source': 'MILK_SALES',
        'recordedDate': '2026-05-22',
        'createdAt': '2026-05-22T08:00:00.000Z',
        'updatedAt': '2026-05-22T08:00:00.000Z',
      });
      expect(record.source, IncomeSource.milkSales);
      expect(record.amountBdt, 1200.5);
    });
  });

  group('ExpenseInput', () {
    test('create json includes category', () {
      final input = ExpenseInput(
        category: ExpenseCategory.medicine,
        amountBdt: 250,
        recordedDate: DateTime.utc(2026, 5, 22),
        notes: 'Vaccine',
      );
      final json = input.toCreateJson();
      expect(json['category'], 'MEDICINE');
      expect(json['amountBdt'], 250);
      expect(json['notes'], 'Vaccine');
    });

    test('draft round trip', () {
      final input = ExpenseInput(
        farmRef: 'farm-1',
        category: ExpenseCategory.labor,
        amountBdt: 1000,
        recordedDate: DateTime.utc(2026, 5, 22),
      );
      final restored = ExpenseInput.fromDraftJson(input.toDraftJson());
      expect(restored.farmRef, 'farm-1');
      expect(restored.category, ExpenseCategory.labor);
    });
  });

  group('FinanceProfitData', () {
    test('parses profit payload', () {
      final profit = FinanceProfitData.fromJson({
        'from': '2026-05-01',
        'to': '2026-05-22',
        'totalIncomeBdt': 10000,
        'totalExpenseBdt': 4000,
        'profitBdt': 6000,
        'previousPeriod': {
          'from': '2026-04-01',
          'to': '2026-04-30',
          'totalIncomeBdt': 8000,
          'totalExpenseBdt': 5000,
          'profitBdt': 3000,
        },
        'profitChangePercent': 100,
      });
      expect(profit.profitBdt, 6000);
      expect(profit.previousPeriod.profitBdt, 3000);
      expect(profit.profitChangePercent, 100);
    });
  });

  group('FinanceChartsData', () {
    test('parses charts payload', () {
      final charts = FinanceChartsData.fromJson({
        'from': '2026-05-01',
        'to': '2026-05-22',
        'incomeTrend': [{'date': '2026-05-22', 'amountBdt': 500}],
        'expenseTrend': [{'date': '2026-05-22', 'amountBdt': 200}],
        'profitTrend': [{'date': '2026-05-22', 'amountBdt': 300}],
      });
      expect(charts.incomeTrend.single.amountBdt, 500);
      expect(charts.profitTrend.single.amountBdt, 300);
    });
  });

  group('FinanceValidation', () {
    test('validates amount and date', () {
      expect(FinanceValidation.validateAmount('', message: 'Required'), 'Required');
      expect(
        FinanceValidation.validateDate(DateTime.now().add(const Duration(days: 1)), message: 'Invalid'),
        'Invalid',
      );
    });
  });
}
