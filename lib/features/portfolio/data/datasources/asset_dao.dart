import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../domain/models/asset.dart' as domain;

part 'asset_dao.g.dart';

@DriftAccessor(tables: [AssetsTable, AccountsTable, TransactionsTable])
class AssetDao extends DatabaseAccessor<AppDatabase> with _$AssetDaoMixin {
  AssetDao(super.db);

  Stream<List<domain.Asset>> watchAssets() {
    return select(assetsTable).watch().map((rows) => rows.map(_mapToDomain).toList());
  }

  Future<List<domain.Asset>> getAssets() {
    return select(assetsTable).get().then((rows) => rows.map(_mapToDomain).toList());
  }

  Future<domain.Asset?> getAssetById(String id) {
    return (select(assetsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull()
        .then((r) => r != null ? _mapToDomain(r) : null);
  }

  Future<void> insertAsset(domain.Asset a) {
    return into(assetsTable).insert(AssetsTableCompanion(
      id: Value(a.id),
      name: Value(a.name),
      type: Value(a.type.name),
      ticker: Value(a.ticker),
      quantity: Value(a.quantity),
      purchasePrice: Value(a.purchasePrice),
      purchaseCurrency: Value(a.purchaseCurrency),
      purchaseDate: Value(a.purchaseDate.millisecondsSinceEpoch),
      accountId: Value(a.accountId),
      icon: Value(a.icon),
      color: Value(a.color),
    ));
  }

  Future<void> updateAsset(domain.Asset a) {
    return update(assetsTable).replace(AssetsTableCompanion(
      id: Value(a.id),
      name: Value(a.name),
      type: Value(a.type.name),
      ticker: Value(a.ticker),
      quantity: Value(a.quantity),
      purchasePrice: Value(a.purchasePrice),
      purchaseCurrency: Value(a.purchaseCurrency),
      purchaseDate: Value(a.purchaseDate.millisecondsSinceEpoch),
      accountId: Value(a.accountId),
      icon: Value(a.icon),
      color: Value(a.color),
    ));
  }

  Future<void> deleteAsset(String id) {
    return (delete(assetsTable)..where((t) => t.id.equals(id))).go();
  }

  domain.Asset _mapToDomain(AssetsTableData r) {
    // Current price is stored in purchasePrice unless updated by live feed (mocked with 1.15x growth if recent)
    final daysHeld = (DateTime.now().millisecondsSinceEpoch - r.purchaseDate) / (1000 * 3600 * 24);
    final simulatedGrowth = daysHeld > 30 ? 1.18 : 1.05;
    final currentPrice = r.purchasePrice * simulatedGrowth;

    return domain.Asset(
      id: r.id,
      name: r.name,
      type: domain.AssetType.fromString(r.type),
      ticker: r.ticker,
      quantity: r.quantity,
      purchasePrice: r.purchasePrice,
      currentPrice: currentPrice,
      purchaseCurrency: r.purchaseCurrency,
      purchaseDate: DateTime.fromMillisecondsSinceEpoch(r.purchaseDate),
      accountId: r.accountId,
      icon: r.icon,
      color: r.color,
    );
  }
}
