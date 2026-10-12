import 'package:flutter_test/flutter_test.dart';
import 'package:mony/features/transactions/domain/models/transaction.dart';
import 'package:mony/features/transactions/domain/models/transaction_filter.dart';

void main() {
  group('Transaction Time-Machine Rollback Tests', () {
    test('Rollback timestamp accurately separates older and newer transactions', () {
      final baseTime = DateTime(2026, 10, 10, 12, 0);

      final t1 = Transaction(
        id: 't1',
        accountId: 'acc1',
        amount: 100.0,
        currencyCode: 'INR',
        type: TransactionType.expense,
        name: 'Old Coffee',
        date: baseTime.subtract(const Duration(hours: 5)), // 07:00
        createdAt: baseTime.subtract(const Duration(hours: 5)),
        updatedAt: baseTime.subtract(const Duration(hours: 5)),
      );

      final t2 = Transaction(
        id: 't2',
        accountId: 'acc1',
        amount: 500.0,
        currencyCode: 'INR',
        type: TransactionType.expense,
        name: 'Exact Rollback Point',
        date: baseTime, // 12:00
        createdAt: baseTime,
        updatedAt: baseTime,
      );

      final t3 = Transaction(
        id: 't3',
        accountId: 'acc1',
        amount: 1500.0,
        currencyCode: 'INR',
        type: TransactionType.expense,
        name: 'New Dinner',
        date: baseTime.add(const Duration(hours: 2)), // 14:00
        createdAt: baseTime.add(const Duration(hours: 2)),
        updatedAt: baseTime.add(const Duration(hours: 2)),
      );

      final all = [t1, t2, t3];

      // Identify transactions strictly after baseTime
      final afterCutoff = all.where((t) => t.date.isAfter(baseTime)).toList();
      expect(afterCutoff.length, equals(1));
      expect(afterCutoff.first.id, equals('t3'));

      // Retained transactions (at or before baseTime)
      final retained = all.where((t) => !t.date.isAfter(baseTime)).toList();
      expect(retained.length, equals(2));
      expect(retained.map((t) => t.id), containsAll(['t1', 't2']));
    });
  });

  group('Reports Advanced Include/Exclude Filtering Tests', () {
    test('Include mode only retains transactions matching specified category or label', () {
      final now = DateTime.now();
      final list = [
        Transaction(
          id: '1',
          accountId: 'a',
          amount: 200,
          currencyCode: 'INR',
          type: TransactionType.expense,
          name: 'Burger',
          categoryId: 'cat-food',
          labels: ['#essential'],
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
        Transaction(
          id: '2',
          accountId: 'a',
          amount: 500,
          currencyCode: 'INR',
          type: TransactionType.expense,
          name: 'Movie',
          categoryId: 'cat-entertainment',
          labels: ['#discretionary'],
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      // Include only cat-food
      final included = list.where((t) => t.categoryId == 'cat-food').toList();
      expect(included.length, equals(1));
      expect(included.first.name, equals('Burger'));

      // Exclude cat-food
      final excluded = list.where((t) => t.categoryId != 'cat-food').toList();
      expect(excluded.length, equals(1));
      expect(excluded.first.name, equals('Movie'));
    });
  });

  group('Fast Search Logic Tests', () {
    test('Matches search query across name, description, and hashtags', () {
      final now = DateTime.now();
      final txn = Transaction(
        id: 't-search',
        accountId: 'a',
        amount: 350,
        currencyCode: 'INR',
        type: TransactionType.expense,
        name: 'Blue Tokai Cafe',
        description: 'Chai and croissant with team',
        labels: ['#work', '#routine'],
        date: now,
        createdAt: now,
        updatedAt: now,
      );

      bool matches(Transaction t, String query) {
        final q = query.toLowerCase();
        return t.name.toLowerCase().contains(q) ||
            (t.description?.toLowerCase().contains(q) ?? false) ||
            t.labels.any((l) => l.toLowerCase().contains(q));
      }

      expect(matches(txn, 'tokai'), isTrue);
      expect(matches(txn, 'croissant'), isTrue);
      expect(matches(txn, '#work'), isTrue);
      expect(matches(txn, 'random_nonexistent'), isFalse);
    });
  });
}
