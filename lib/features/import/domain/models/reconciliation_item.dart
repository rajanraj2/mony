import '../../../transactions/domain/models/transaction.dart';

enum ReconciliationState {
  matched,   // Identical record already exists
  conflict,  // Probable match (same amount/date), but fields (merchant, notes) differ
  newRow,    // No match found — new record to add
}

class ImportedRow {
  final DateTime date;
  final double amount;
  final String name;
  final String? category;
  final String? notes;
  final TransactionType type;

  const ImportedRow({
    required this.date,
    required this.amount,
    required this.name,
    this.category,
    this.notes,
    this.type = TransactionType.expense,
  });
}

class ReconciliationItem {
  final String id;
  final ImportedRow importedRow;
  final Transaction? existingTransaction;
  final ReconciliationState state;
  final double matchScore; // 0.0 to 1.0

  const ReconciliationItem({
    required this.id,
    required this.importedRow,
    this.existingTransaction,
    required this.state,
    this.matchScore = 0.0,
  });

  ReconciliationItem copyWith({
    String? id,
    ImportedRow? importedRow,
    Transaction? existingTransaction,
    ReconciliationState? state,
    double? matchScore,
  }) {
    return ReconciliationItem(
      id: id ?? this.id,
      importedRow: importedRow ?? this.importedRow,
      existingTransaction: existingTransaction ?? this.existingTransaction,
      state: state ?? this.state,
      matchScore: matchScore ?? this.matchScore,
    );
  }
}

class ReconciliationResult {
  final List<ReconciliationItem> matched;
  final List<ReconciliationItem> conflicts;
  final List<ReconciliationItem> newRows;

  const ReconciliationResult({
    required this.matched,
    required this.conflicts,
    required this.newRows,
  });

  int get totalRows => matched.length + conflicts.length + newRows.length;
}
