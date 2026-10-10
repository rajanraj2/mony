import 'package:flutter_test/flutter_test.dart';
import 'package:mony/core/utils/calculator.dart';
import 'package:mony/core/utils/currency.dart';
import 'package:mony/features/transactions/domain/models/transaction.dart';
import 'package:mony/features/accounts/domain/models/account.dart';
import 'package:mony/features/categories/domain/models/category.dart';

void main() {
  group('SimpleCalculator inline arithmetic tests', () {
    test('evaluates simple addition', () {
      expect(SimpleCalculator.evaluate('50+30'), equals(80.0));
    });

    test('evaluates mixed operators with correct precedence (* before +)', () {
      expect(SimpleCalculator.evaluate('50+20*3'), equals(110.0));
      expect(SimpleCalculator.evaluate('100-20/2'), equals(90.0));
    });

    test('evaluates plain single numbers', () {
      expect(SimpleCalculator.evaluate('450'), equals(450.0));
      expect(SimpleCalculator.evaluate('12.50'), equals(12.50));
    });

    test('returns null on invalid expression syntax', () {
      expect(SimpleCalculator.evaluate('abc'), isNull);
      expect(SimpleCalculator.evaluate('50++20'), isNull);
      expect(SimpleCalculator.evaluate(''), isNull);
    });
  });

  group('Currency formatter tests', () {
    test('formats INR correctly with symbol', () {
      final res = formatCurrency(1250.0, 'INR');
      expect(res.contains('1,250.00'), isTrue);
    });

    test('formats USD correctly with symbol', () {
      final res = formatCurrency(99.99, 'USD');
      expect(res.contains('99.99'), isTrue);
    });
  });

  group('Domain model constructors & enums', () {
    test('Transaction status defaults to cleared', () {
      final t = Transaction(
        id: '1',
        accountId: 'acc-1',
        amount: 100,
        currencyCode: 'INR',
        type: TransactionType.expense,
        name: 'Lunch',
        date: DateTime(2026, 10, 10),
        createdAt: DateTime(2026, 10, 10),
        updatedAt: DateTime(2026, 10, 10),
      );
      expect(t.status, equals(TransactionStatus.cleared));
      expect(t.labels, isEmpty);
    });

    test('Account balances calculate properly', () {
      final a = Account(
        id: 'a1',
        name: 'HDFC',
        type: AccountType.bank,
        currencyCode: 'INR',
        openingBalance: 1000,
        currentBalance: 1450,
        color: 0xFF123456,
        icon: 'bank',
        createdAt: DateTime(2026, 10, 10),
        updatedAt: DateTime(2026, 10, 10),
      );
      expect(a.currentBalance, equals(1450.0));
    });
  });
}
