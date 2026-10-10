import 'package:flutter_test/flutter_test.dart';
import 'package:mony/features/import/domain/models/reconciliation_item.dart';
import 'package:mony/features/transactions/domain/models/transaction.dart';

void main() {
  group('CSV Reconciliation Model & Matching Tests', () {
    test('ReconciliationResult counts totals accurately', () {
      final item1 = ReconciliationItem(
        id: '1',
        importedRow: ImportedRow(date: DateTime.now(), amount: 500, name: 'Uber'),
        state: ReconciliationState.matched,
      );
      final item2 = ReconciliationItem(
        id: '2',
        importedRow: ImportedRow(date: DateTime.now(), amount: 750, name: 'Zomato'),
        state: ReconciliationState.conflict,
      );
      final item3 = ReconciliationItem(
        id: '3',
        importedRow: ImportedRow(date: DateTime.now(), amount: 1200, name: 'Groceries'),
        state: ReconciliationState.newRow,
      );

      final result = ReconciliationResult(
        matched: [item1],
        conflicts: [item2],
        newRows: [item3],
      );

      expect(result.totalRows, equals(3));
      expect(result.matched.length, equals(1));
      expect(result.conflicts.length, equals(1));
      expect(result.newRows.length, equals(1));
    });

    test('ImportedRow defaults to expense type', () {
      final row = ImportedRow(
        date: DateTime(2026, 10, 10),
        amount: 250,
        name: 'Coffee',
      );

      expect(row.type, equals(TransactionType.expense));
    });
  });
}
