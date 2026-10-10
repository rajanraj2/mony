import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../shared/constants/app_constants.dart';

part 'database.g.dart';

// ── Tables ──────────────────────────────────────────────────────────────────

class AccountsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get type => text()(); // bank, cash, card, wallet
  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();
  RealColumn get openingBalance => real().withDefault(const Constant(0.0))();
  IntColumn get color => integer()();
  TextColumn get icon => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class CategoriesTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get type => text()(); // expense, income
  IntColumn get color => integer()();
  TextColumn get icon => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class TransactionsTable extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text().references(AccountsTable, #id)();
  TextColumn get transferAccountId => text().nullable().references(AccountsTable, #id)();
  TextColumn get categoryId => text().nullable().references(CategoriesTable, #id)();
  RealColumn get amount => real()();
  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();
  RealColumn get fxRate => real().nullable()();
  TextColumn get type => text()(); // income, expense, transfer
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  TextColumn get person => text().nullable()();
  TextColumn get place => text().nullable()();
  TextColumn get attachmentPath => text().nullable()();
  IntColumn get date => integer()(); // Unix ms
  TextColumn get status => text().withDefault(const Constant('cleared'))();
  TextColumn get recurrenceId => text().nullable()();
  TextColumn get labels => text().withDefault(const Constant(''))(); // comma-separated
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class BudgetsTable extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text().references(CategoriesTable, #id)();
  RealColumn get amount => real()();
  TextColumn get period => text()(); // weekly, monthly, custom
  IntColumn get periodStart => integer().nullable()();
  IntColumn get periodEnd => integer().nullable()();
  IntColumn get rollover => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class GoalsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get targetAmount => real()();
  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();
  TextColumn get linkedAccountId => text().nullable().references(AccountsTable, #id)();
  IntColumn get deadline => integer()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class AssetsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // stock, mf, etf, crypto, real_estate, gold, fd, ppf, nps, other
  TextColumn get ticker => text().nullable()();
  RealColumn get quantity => real()();
  RealColumn get purchasePrice => real()();
  TextColumn get purchaseCurrency => text().withLength(min: 3, max: 3)();
  IntColumn get purchaseDate => integer()();
  TextColumn get accountId => text().nullable().references(AccountsTable, #id)();
  TextColumn get icon => text()();
  IntColumn get color => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class SmsRulesTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get senderPattern => text()();
  TextColumn get messagePattern => text()();
  TextColumn get direction => text()(); // income, expense
  TextColumn get defaultCategoryId => text().nullable().references(CategoriesTable, #id)();
  TextColumn get accountHint => text().nullable()();
  IntColumn get enabled => integer().withDefault(const Constant(1))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class PendingSmsTransactionsTable extends Table {
  TextColumn get id => text()();
  TextColumn get rawSms => text()();
  TextColumn get parsedName => text().nullable()();
  RealColumn get parsedAmount => real().nullable()();
  TextColumn get parsedAccountHint => text().nullable()();
  TextColumn get direction => text()();
  IntColumn get smsDate => integer()();
  IntColumn get capturedAt => integer()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get duplicateFlag => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class ImportSessionsTable extends Table {
  TextColumn get id => text()();
  TextColumn get filename => text()();
  IntColumn get importedAt => integer()();
  IntColumn get totalRows => integer()();
  IntColumn get matched => integer()();
  IntColumn get conflicts => integer()();
  IntColumn get added => integer()();
  IntColumn get rejected => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Database Definition ─────────────────────────────────────────────────────

@DriftDatabase(tables: [
  AccountsTable,
  CategoriesTable,
  TransactionsTable,
  BudgetsTable,
  GoalsTable,
  AssetsTable,
  SmsRulesTable,
  PendingSmsTransactionsTable,
  ImportSessionsTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Seed default categories and sample account
          await _seedInitialData();
        },
      );

  Future<void> _seedInitialData() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    // Default categories
    final defaultCategories = [
      CategoriesTableCompanion.insert(id: 'cat-food', name: 'Food & Dining', type: 'expense', color: 0xFFEF5350, icon: 'restaurant', createdAt: now),
      CategoriesTableCompanion.insert(id: 'cat-transport', name: 'Transportation', type: 'expense', color: 0xFF42A5F5, icon: 'directions_car', createdAt: now),
      CategoriesTableCompanion.insert(id: 'cat-housing', name: 'Housing & Rent', type: 'expense', color: 0xFFAB47BC, icon: 'home', createdAt: now),
      CategoriesTableCompanion.insert(id: 'cat-health', name: 'Health & Medical', type: 'expense', color: 0xFF26A69A, icon: 'local_hospital', createdAt: now),
      CategoriesTableCompanion.insert(id: 'cat-entertainment', name: 'Entertainment', type: 'expense', color: 0xFFFFCA28, icon: 'movie', createdAt: now),
      CategoriesTableCompanion.insert(id: 'cat-shopping', name: 'Shopping', type: 'expense', color: 0xFFEC407A, icon: 'shopping_bag', createdAt: now),
      CategoriesTableCompanion.insert(id: 'cat-utilities', name: 'Utilities & Bills', type: 'expense', color: 0xFFFFA726, icon: 'receipt', createdAt: now),
      CategoriesTableCompanion.insert(id: 'cat-salary', name: 'Salary', type: 'income', color: 0xFF66BB6A, icon: 'account_balance_wallet', createdAt: now),
      CategoriesTableCompanion.insert(id: 'cat-investment', name: 'Investments', type: 'income', color: 0xFF29B6F6, icon: 'trending_up', createdAt: now),
      CategoriesTableCompanion.insert(id: 'cat-freelance', name: 'Freelance & Side', type: 'income', color: 0xFF9CCC65, icon: 'work', createdAt: now),
    ];
    for (final cat in defaultCategories) {
      await into(categoriesTable).insert(cat, mode: InsertMode.insertOrIgnore);
    }

    // Default primary cash and bank accounts
    await into(accountsTable).insert(
      AccountsTableCompanion.insert(
        id: 'acc-primary-bank',
        name: 'Primary Bank',
        type: 'bank',
        currencyCode: 'INR',
        openingBalance: const Value(0.0),
        color: 0xFF1B6B3A,
        icon: 'account_balance',
        sortOrder: const Value(0),
        createdAt: now,
        updatedAt: now,
      ),
      mode: InsertMode.insertOrIgnore,
    );
    await into(accountsTable).insert(
      AccountsTableCompanion.insert(
        id: 'acc-cash',
        name: 'Cash Wallet',
        type: 'cash',
        currencyCode: 'INR',
        openingBalance: const Value(0.0),
        color: 0xFF0288D1,
        icon: 'payments',
        sortOrder: const Value(1),
        createdAt: now,
        updatedAt: now,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, AppConstants.dbFileName));
    return NativeDatabase.createInBackground(file);
  });
}
