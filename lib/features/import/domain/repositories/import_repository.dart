import 'dart:typed_data';
import '../models/reconciliation_item.dart';

abstract class IImportRepository {
  Future<List<List<String>>> parseRawCsv(String csvContent);

  Future<ReconciliationResult> reconcileRows({
    required List<ImportedRow> rows,
    required String accountId,
  });

  Future<void> commitReconciliation({
    required List<ImportedRow> approvedRows,
    required String accountId,
    required String filename,
    required int matchedCount,
    required int conflictsCount,
  });
}
