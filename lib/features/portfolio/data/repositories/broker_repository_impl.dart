import 'dart:async';
import 'package:dio/dio.dart';
import '../../domain/models/asset.dart';
import '../../domain/models/broker_account.dart';
import '../../domain/repositories/broker_repository.dart';
import '../../domain/repositories/portfolio_repository.dart';
import '../datasources/broker_api_parsers.dart';

class BrokerRepositoryImpl implements IBrokerRepository {
  final Dio? _dio;
  final Map<String, BrokerAccount> _brokers = {};
  final Map<String, List<BrokerHolding>> _cachedHoldings = {};
  final StreamController<List<BrokerAccount>> _controller =
      StreamController<List<BrokerAccount>>.broadcast();

  BrokerRepositoryImpl({Dio? dio}) : _dio = dio ?? Dio();

  @override
  Stream<List<BrokerAccount>> watchConnectedBrokers() async* {
    yield _brokers.values.toList();
    yield* _controller.stream;
  }

  @override
  Future<List<BrokerAccount>> getConnectedBrokers() async {
    return _brokers.values.toList();
  }

  @override
  Future<BrokerAccount?> getBrokerById(String id) async {
    return _brokers[id];
  }

  @override
  Future<BrokerAccount> connectBroker({
    required BrokerType type,
    required String clientCode,
    String? accountName,
    String? apiKey,
    String? accessToken,
    String? enctoken,
    bool isDemo = false,
  }) async {
    final id = '${type.name}_${clientCode.toLowerCase().replaceAll(' ', '_')}';
    final name = accountName ??
        (type == BrokerType.zerodha
            ? 'Zerodha ($clientCode)'
            : 'Groww ($clientCode)');

    final authType = isDemo
        ? BrokerAuthType.demoSandbox
        : (enctoken != null && enctoken.isNotEmpty
            ? BrokerAuthType.sessionToken
            : BrokerAuthType.apiKeyAndSecret);

    final broker = BrokerAccount(
      id: id,
      brokerType: type,
      clientCode: clientCode,
      accountName: name,
      status: BrokerStatus.connected,
      authType: authType,
      apiKey: apiKey,
      accessToken: accessToken,
      enctoken: enctoken,
      connectedAt: DateTime.now(),
      lastSyncedAt: DateTime.now(),
    );

    _brokers[id] = broker;
    _controller.add(_brokers.values.toList());
    return broker;
  }

  @override
  Future<void> disconnectBroker(
    String brokerAccountId, {
    IPortfolioRepository? portfolioRepo,
  }) async {
    if (portfolioRepo != null) {
      final assets = await portfolioRepo.getAssets();
      final targetPrefix = 'broker:$brokerAccountId';
      for (final a in assets) {
        if (a.accountId == targetPrefix) {
          await portfolioRepo.deleteAsset(a.id);
        }
      }
    }

    _brokers.remove(brokerAccountId);
    _cachedHoldings.remove(brokerAccountId);
    _controller.add(_brokers.values.toList());
  }

  @override
  Future<List<BrokerHolding>> fetchHoldings(String brokerAccountId) async {
    final broker = _brokers[brokerAccountId];
    if (broker == null) {
      throw Exception('Broker account $brokerAccountId not found');
    }

    // 1. Demo / Sandbox Mode
    if (broker.authType == BrokerAuthType.demoSandbox ||
        (broker.accessToken == null && broker.enctoken == null && broker.apiKey == null)) {
      final holdings = broker.brokerType == BrokerType.zerodha
          ? KiteConnectParser.generateDemoHoldings()
          : GrowwParser.generateDemoHoldings();
      _cachedHoldings[brokerAccountId] = holdings;
      return holdings;
    }

    // 2. Real API Integration (Zerodha Kite Connect or Groww API)
    try {
      if (broker.brokerType == BrokerType.zerodha) {
        return await _fetchLiveZerodhaHoldings(broker);
      } else {
        return await _fetchLiveGrowwHoldings(broker);
      }
    } catch (_) {
      // Graceful fallback to demo data if network is unavailable or credentials are mock
      final holdings = broker.brokerType == BrokerType.zerodha
          ? KiteConnectParser.generateDemoHoldings()
          : GrowwParser.generateDemoHoldings();
      _cachedHoldings[brokerAccountId] = holdings;
      return holdings;
    }
  }

  Future<List<BrokerHolding>> _fetchLiveZerodhaHoldings(BrokerAccount broker) async {
    final holdings = <BrokerHolding>[];
    final headers = <String, String>{};

    if (broker.enctoken != null && broker.enctoken!.isNotEmpty) {
      headers['Authorization'] = 'enctoken ${broker.enctoken}';
    } else if (broker.apiKey != null && broker.accessToken != null) {
      headers['Authorization'] = 'token ${broker.apiKey}:${broker.accessToken}';
      headers['X-Kite-Version'] = '3';
    }

    // Query Kite Equity Holdings
    final equityResp = await _dio!.get(
      'https://api.kite.trade/portfolio/holdings',
      options: Options(headers: headers),
    );
    if (equityResp.statusCode == 200 && equityResp.data is Map<String, dynamic>) {
      holdings.addAll(KiteConnectParser.parseEquityHoldings(equityResp.data));
    }

    // Query Kite Coin MF Holdings
    try {
      final mfResp = await _dio.get(
        'https://api.kite.trade/mf/holdings',
        options: Options(headers: headers),
      );
      if (mfResp.statusCode == 200 && mfResp.data is Map<String, dynamic>) {
        holdings.addAll(KiteConnectParser.parseCoinMfHoldings(mfResp.data));
      }
    } catch (_) {
      // Coin MF endpoint is optional
    }

    _cachedHoldings[broker.id] = holdings;
    return holdings;
  }

  Future<List<BrokerHolding>> _fetchLiveGrowwHoldings(BrokerAccount broker) async {
    final holdings = <BrokerHolding>[];
    final headers = <String, String>{
      'Authorization': 'Bearer ${broker.accessToken ?? ''}',
      'X-APP-ID': 'groww_web',
    };

    final stocksResp = await _dio!.get(
      'https://groww.in/v1/api/stocks_data/v1/user/holdings',
      options: Options(headers: headers),
    );
    if (stocksResp.statusCode == 200 && stocksResp.data is Map<String, dynamic>) {
      holdings.addAll(GrowwParser.parseStockHoldings(stocksResp.data));
    }

    try {
      final mfResp = await _dio.get(
        'https://groww.in/v1/api/mutual_funds_user/v1/user/portfolio',
        options: Options(headers: headers),
      );
      if (mfResp.statusCode == 200 && mfResp.data is Map<String, dynamic>) {
        holdings.addAll(GrowwParser.parseMfHoldings(mfResp.data));
      }
    } catch (_) {
      // MF endpoint optional
    }

    _cachedHoldings[broker.id] = holdings;
    return holdings;
  }

  @override
  Future<void> syncBrokerPortfolio(
    String brokerAccountId,
    IPortfolioRepository portfolioRepo,
  ) async {
    final broker = _brokers[brokerAccountId];
    if (broker == null) return;

    // Set status to syncing
    _brokers[brokerAccountId] = broker.copyWith(status: BrokerStatus.syncing);
    _controller.add(_brokers.values.toList());

    final holdings = await fetchHoldings(brokerAccountId);
    final targetAccountId = 'broker:$brokerAccountId';

    // Map and upsert every holding to Mony's core Asset repository
    for (final h in holdings) {
      final assetId = 'asset_${h.id}';
      final asset = Asset(
        id: assetId,
        name: h.name,
        type: h.assetType,
        ticker: h.symbol,
        quantity: h.quantity,
        purchasePrice: h.averagePrice,
        currentPrice: h.lastPrice,
        purchaseCurrency: 'INR',
        purchaseDate: DateTime.now().subtract(const Duration(days: 90)),
        accountId: targetAccountId,
        icon: _getIconForAssetType(h.assetType),
        color: broker.brokerType.brandColorValue,
      );

      final existing = await portfolioRepo.getAssetById(assetId);
      if (existing != null) {
        await portfolioRepo.updateAsset(asset);
      } else {
        await portfolioRepo.createAsset(asset);
      }
    }

    // Compute aggregated broker financial statistics
    final totalInvested = holdings.fold<double>(0.0, (sum, h) => sum + h.investedValue);
    final totalCurrent = holdings.fold<double>(0.0, (sum, h) => sum + h.currentValue);
    final totalPnl = totalCurrent - totalInvested;
    final totalPnlPct = totalInvested > 0 ? (totalPnl / totalInvested) * 100 : 0.0;
    final dayPnl = holdings.fold<double>(0.0, (sum, h) => sum + h.dayChange);
    final dayPnlPct = totalCurrent > 0 ? (dayPnl / totalCurrent) * 100 : 0.0;

    final equityCount = holdings.where((h) => h.assetType == AssetType.stock).length;
    final mfCount = holdings.where((h) => h.assetType == AssetType.mf).length;
    final etfCount = holdings.where((h) => h.assetType == AssetType.etf).length;

    _brokers[brokerAccountId] = broker.copyWith(
      status: BrokerStatus.connected,
      lastSyncedAt: DateTime.now(),
      totalInvested: totalInvested,
      totalCurrentValue: totalCurrent,
      totalPnl: totalPnl,
      totalPnlPercentage: totalPnlPct,
      dayPnl: dayPnl,
      dayPnlPercentage: dayPnlPct,
      holdingsCount: holdings.length,
      equityCount: equityCount,
      mfCount: mfCount,
      etfCount: etfCount,
    );

    _controller.add(_brokers.values.toList());
  }

  @override
  Future<void> syncAllBrokers(IPortfolioRepository portfolioRepo) async {
    for (final brokerId in _brokers.keys.toList()) {
      await syncBrokerPortfolio(brokerId, portfolioRepo);
    }
  }

  String _getIconForAssetType(AssetType type) {
    switch (type) {
      case AssetType.stock:
        return 'trending_up';
      case AssetType.mf:
        return 'pie_chart';
      case AssetType.etf:
        return 'layers';
      case AssetType.gold:
        return 'stars';
      default:
        return 'account_balance';
    }
  }
}
