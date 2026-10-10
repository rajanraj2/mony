import 'dart:math';
import '../../../../core/database/database.dart';
import '../../domain/models/asset.dart';
import '../../domain/repositories/portfolio_repository.dart';
import '../datasources/asset_dao.dart';
import '../../../accounts/data/datasources/account_dao.dart';

class PortfolioRepositoryImpl implements IPortfolioRepository {
  final AssetDao _assetDao;
  final AccountDao _accountDao;

  PortfolioRepositoryImpl(this._assetDao, this._accountDao);

  @override
  Stream<List<Asset>> watchAssets() => _assetDao.watchAssets();

  @override
  Future<List<Asset>> getAssets() => _assetDao.getAssets();

  @override
  Future<Asset?> getAssetById(String id) => _assetDao.getAssetById(id);

  @override
  Future<void> createAsset(Asset asset) => _assetDao.insertAsset(asset);

  @override
  Future<void> updateAsset(Asset asset) => _assetDao.updateAsset(asset);

  @override
  Future<void> deleteAsset(String id) => _assetDao.deleteAsset(id);

  @override
  Future<PortfolioSummary> getPortfolioSummary() async {
    final assets = await _assetDao.getAssets();

    double totalInvested = 0.0;
    double totalCurrent = 0.0;
    final allocation = <AssetType, double>{};

    for (final a in assets) {
      totalInvested += a.investedValue;
      totalCurrent += a.currentValue;
      allocation[a.type] = (allocation[a.type] ?? 0.0) + a.currentValue;
    }

    final totalGainLoss = totalCurrent - totalInvested;
    final gainLossPct = totalInvested > 0 ? (totalGainLoss / totalInvested) * 100 : 0.0;

    // Overall portfolio CAGR estimation
    double weightedCagr = 0.0;
    if (totalCurrent > 0) {
      for (final a in assets) {
        weightedCagr += a.cagr * (a.currentValue / totalCurrent);
      }
    }

    return PortfolioSummary(
      totalInvested: totalInvested,
      totalCurrentValue: totalCurrent,
      totalGainLoss: totalGainLoss,
      totalGainLossPercentage: gainLossPct,
      overallCagr: weightedCagr,
      allocationByType: allocation,
    );
  }

  @override
  Future<double> getAggregateNetWorth() async {
    final accounts = await _accountDao.getAllAccounts();
    final accountBalances = accounts.fold(0.0, (sum, a) => sum + a.currentBalance);

    final assets = await _assetDao.getAssets();
    final assetValues = assets.fold(0.0, (sum, a) => sum + a.currentValue);

    return accountBalances + assetValues;
  }
}
