import '../models/asset.dart';

abstract class IPortfolioRepository {
  Stream<List<Asset>> watchAssets();
  Future<List<Asset>> getAssets();
  Future<Asset?> getAssetById(String id);
  Future<void> createAsset(Asset asset);
  Future<void> updateAsset(Asset asset);
  Future<void> deleteAsset(String id);
  Future<PortfolioSummary> getPortfolioSummary();
  Future<double> getAggregateNetWorth();
}
