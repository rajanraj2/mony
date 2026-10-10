import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database.dart';
import '../../../transactions/domain/models/transaction.dart';
import '../../domain/models/reconciliation_item.dart';
import '../../domain/repositories/import_repository.dart';

class ImportRepositoryImpl implements IImportRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  ImportRepositoryImpl(this._db);

  @override
  Future<List<List<String>>> parseRawCsv(String csvContent) async {
    final lines = const LineSplitter().convert(csvContent);
    final rows = <List<String>>[];

    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      // Handle standard comma split while preserving quoted commas
      final cells = <String>[];
      var insideQuotes = false;
      var currentCell = StringBuffer();

      for (var i = 0; i < line.length; i++) {
        final char = line[i];
        if (char == '"') {
          insideQuotes = !insideQuotes;
        } else if (char == ',' && !insideQuotes) {
          cells.add(currentCell.toString().trim().replaceAll('"', ''));
          currentCell = StringBuffer();
        } else {
          currentCell.write(char);
        }
      }
      cells.add(currentCell.toString().trim().replaceAll('"', ''));
      rows.add(cells);
    }
    return rows;
  }

  @override
  Future<ReconciliationResult> reconcileRows({
    required List<ImportedRow> rows,
    required String accountId,
  }) async {
    final matched = <ReconciliationItem>[];
    final conflicts = <ReconciliationItem>[];
    final newRows = <ReconciliationItem>[];

    // Fetch existing account transactions
    final existingTxns = await (_db.select(_db.transactionsTable)
          ..where((t) => t.accountId.equals(accountId)))
        .get();

    for (final row in rows) {
      final itemId = _uuid.v4();
      Transaction? bestMatch;
      double bestScore = 0.0;

      for (final existing in existingTxns) {
        final existingDate = DateTime.fromMillisecondsSinceEpoch(existing.date);
        final dateDiffDays = (existingDate.difference(row.date).inDays).abs();

        // Must be within +/- 1 day tolerance
        if (dateDiffDays > 1) continue;

        // Amount comparison (+/- 0.01 tolerance)
        final amountDiff = (existing.amount - row.amount).abs();
        final isExactAmount = amountDiff < 0.01;

        if (!isExactAmount) continue;

        // Fuzzy Name Similarity Score
        final nameSim = _calculateSimilarity(row.name.toLowerCase(), existing.name.toLowerCase());
        final totalScore = (nameSim * 0.7) + (dateDiffDays == 0 ? 0.3 : 0.15);

        if (totalScore > bestScore) {
          bestScore = totalScore;
          bestMatch = Transaction(
            id: existing.id,
            accountId: existing.accountId,
            amount: existing.amount,
            currencyCode: existing.currencyCode,
            type: TransactionType.fromString(existing.type),
            name: existing.name,
            description: existing.description,
            date: existingDate,
            createdAt: DateTime.fromMillisecondsSinceEpoch(existing.createdAt),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(existing.updatedAt),
          );
        }
      }

      if (bestMatch != null && bestScore >= 0.85) {
        matched.add(ReconciliationItem(
          id: itemId,
          importedRow: row,
          existingTransaction: bestMatch,
          state: ReconciliationState.matched,
          matchScore: bestScore,
        ));
      } else if (bestMatch != null && bestScore >= 0.5) {
        conflicts.add(ReconciliationItem(
          id: itemId,
          importedRow: row,
          existingTransaction: bestMatch,
          state: ReconciliationState.conflict,
          matchScore: bestScore,
        ));
      } else {
        newRows.add(ReconciliationItem(
          id: itemId,
          importedRow: row,
          state: ReconciliationState.newRow,
          matchScore: 0.0,
        ));
      }
    }

    return ReconciliationResult(
      matched: matched,
      conflicts: conflicts,
      newRows: newRows,
    );
  }

  @override
  Future<void> commitReconciliation({
    required List<ImportedRow> approvedRows,
    required String accountId,
    required String filename,
    required int matchedCount,
    required int conflictsCount,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Batch insert approved transactions
    for (final row in approvedRows) {
      await _db.into(_db.transactionsTable).insert(
        TransactionsTableCompanion(
          id: Value(_uuid.v4()),
          accountId: Value(accountId),
          amount: Value(row.amount),
          currencyCode: const Value('INR'),
          type: Value(row.type.name),
          name: Value(row.name),
          description: Value(row.notes),
          date: Value(row.date.millisecondsSinceEpoch),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    }

    // Record audit session
    await _db.into(_db.importSessionsTable).insert(
      ImportSessionsTableCompanion(
        id: Value(_uuid.v4()),
        filename: Value(filename),
        importedAt: Value(now),
        totalRows: Value(approvedRows.length + matchedCount + conflictsCount),
        matched: Value(matchedCount),
        conflicts: Value(conflictsCount),
        added: Value(approvedRows.length),
        rejected: const Value(0),
      ),
    );
  }

  /// Levenshtein distance string similarity normalized to 0.0..1.0
  double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final d = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );

    for (var i = 0; i <= s1.length; i++) {
      d[i][0] = i;
    }
    for (var j = 0; j <= s2.length; j++) {
      d[0][j] = j;
    }

    for (var i = 1; i <= s1.length; i++) {
      for (var j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        d[i][j] = [
          d[i - 1][j] + 1,
          d[i][j - 1] + 1,
          d[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    final maxLength = [s1.length, s2.length].reduce((a, b) => a > b ? a : b);
    return 1.0 - (d[s1.length][s2.length] / maxLength);
  }
}
