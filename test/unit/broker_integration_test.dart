import 'package:flutter_test/flutter_test.dart';
import 'package:mony/features/portfolio/data/datasources/broker_api_parsers.dart';
import 'package:mony/features/portfolio/data/repositories/broker_repository_impl.dart';
import 'package:mony/features/portfolio/domain/models/asset.dart';
import 'package:mony/features/portfolio/domain/models/broker_account.dart';
import 'package:mony/features/portfolio/domain/repositories/portfolio_repository.dart';

// In-memory test implementation of IPortfolioRepository
class InMemoryPortfolioRepository implements IPortfolioRepository {
  final Map<String, Asset> _assets = {};

  @override
  Stream<List<Asset>> watchAssets() async* {
    yield _assets.values.toList();
  }

  @override
  Future<List<Asset>> getAssets() async => _assets.values.toList();

  @override
  Future<Asset?> getAssetById(String id) async => _assets[id];

  @override
  Future<void> createAsset(Asset asset) async {
    _assets[asset.id] = asset;
  }

  @override
  Future<void> updateAsset(Asset asset) async {
    _assets[asset.id] = asset;
  }

  @override
  Future<void> deleteAsset(String id) async {
    _assets.remove(id);
  }

  @override
  Future<PortfolioSummary> getPortfolioSummary() async {
    final list = _assets.values.toList();
    final invested = list.fold<double>(0.0, (s, a) => s + a.investedValue);
    final current = list.fold<double>(0.0, (s, a) => s + a.currentValue);
    final gain = current - invested;
    final gainPct = invested > 0 ? (gain / invested) * 100 : 0.0;
    return PortfolioSummary(
      totalInvested: invested,
      totalCurrentValue: current,
      totalGainLoss: gain,
      totalGainLossPercentage: gainPct,
      overallCagr: 15.0,
      allocationByType: {},
    );
  }

  @override
  Future<double> getAggregateNetWorth() async {
    return _assets.values.fold<double>(0.0, (s, a) => s + a.currentValue);
  }
}

void main() {
  group('Zerodha Kite Connect Parser Tests', () {
    test('Parses Kite equity holdings and detects Stocks vs ETFs accurately', () {
      final mockKiteJson = {
        'status': 'success',
        'data': [
          {
            'tradingsymbol': 'INFY',
            'exchange': 'NSE',
            'isin': 'INE009A01021',
            'quantity': 25,
            't1_quantity': 5,
            'average_price': 1450.0,
            'last_price': 1880.0,
            'close_price': 1865.0,
            'pnl': 12900.0,
          },
          {
            'tradingsymbol': 'NIFTYBEES',
            'exchange': 'NSE',
            'isin': 'INF732E01015',
            'quantity': 200,
            't1_quantity': 0,
            'average_price': 225.0,
            'last_price': 268.0,
            'close_price': 265.0,
            'pnl': 8600.0,
          },
        ]
      };

      final holdings = KiteConnectParser.parseEquityHoldings(mockKiteJson);
      expect(holdings.length, equals(2));

      // Stock verification
      final infy = holdings.firstWhere((h) => h.symbol == 'INFY');
      expect(infy.quantity, equals(30.0)); // 25 + 5 T1
      expect(infy.assetType, equals(AssetType.stock));
      expect(infy.investedValue, equals(30.0 * 1450.0));
      expect(infy.currentValue, equals(30.0 * 1880.0));
      expect(infy.pnl, greaterThan(0));

      // ETF verification
      final etf = holdings.firstWhere((h) => h.symbol == 'NIFTYBEES');
      expect(etf.assetType, equals(AssetType.etf));
      expect(etf.quantity, equals(200.0));
    });

    test('Parses Kite Coin Mutual Fund holdings correctly', () {
      final mockCoinJson = {
        'status': 'success',
        'data': [
          {
            'fund': 'Parag Parikh Flexi Cap Fund Direct - Growth',
            'folio': '10482910',
            'tradingsymbol': 'PPFAS_FLEXI',
            'quantity': 500.0,
            'average_price': 55.0,
            'last_price': 78.50,
            'isin': 'INF879O01019',
          }
        ]
      };

      final mfs = KiteConnectParser.parseCoinMfHoldings(mockCoinJson);
      expect(mfs.length, equals(1));
      expect(mfs.first.assetType, equals(AssetType.mf));
      expect(mfs.first.folioNumber, equals('10482910'));
      expect(mfs.first.quantity, equals(500.0));
      expect(mfs.first.currentValue, equals(500.0 * 78.50));
    });

    test('Generates comprehensive demo holdings for Zerodha Kite', () {
      final demo = KiteConnectParser.generateDemoHoldings();
      expect(demo.isNotEmpty, isTrue);
      expect(demo.any((h) => h.assetType == AssetType.stock), isTrue);
      expect(demo.any((h) => h.assetType == AssetType.etf), isTrue);
      expect(demo.any((h) => h.assetType == AssetType.mf), isTrue);
    });
  });

  group('Groww API Parser Tests', () {
    test('Parses Groww Stocks and ETFs correctly', () {
      final mockGrowwStocks = {
        'holdings': [
          {
            'companyName': 'Tata Motors Ltd',
            'tradingSymbol': 'TATAMOTORS',
            'isin': 'INE155A01022',
            'quantity': 100,
            'avgPrice': 700.0,
            'currentPrice': 980.0,
            'closePrice': 975.0,
            'type': 'EQUITY',
          },
          {
            'companyName': 'Nippon Silver ETF',
            'tradingSymbol': 'SILVER_ETF',
            'isin': 'INF732E01486',
            'quantity': 150,
            'avgPrice': 75.0,
            'currentPrice': 94.0,
            'closePrice': 93.0,
            'type': 'ETF',
          }
        ]
      };

      final holdings = GrowwParser.parseStockHoldings(mockGrowwStocks);
      expect(holdings.length, equals(2));
      expect(holdings[0].assetType, equals(AssetType.stock));
      expect(holdings[1].assetType, equals(AssetType.etf));
    });

    test('Parses Groww Mutual Funds accurately', () {
      final mockGrowwMf = {
        'holdings': [
          {
            'schemeName': 'Mirae Asset Large Cap Fund Direct',
            'folioNumber': '5829102',
            'units': 600.0,
            'investedAmount': 54000.0,
            'currentValue': 72000.0,
            'nav': 120.0,
          }
        ]
      };

      final mfs = GrowwParser.parseMfHoldings(mockGrowwMf);
      expect(mfs.length, equals(1));
      final mf = mfs.first;
      expect(mf.assetType, equals(AssetType.mf));
      expect(mf.folioNumber, equals('5829102'));
      expect(mf.quantity, equals(600.0));
      expect(mf.averagePrice, equals(90.0)); // 54000 / 600
      expect(mf.lastPrice, equals(120.0));
    });

    test('Generates comprehensive demo holdings for Groww', () {
      final demo = GrowwParser.generateDemoHoldings();
      expect(demo.isNotEmpty, isTrue);
      expect(demo.any((h) => h.assetType == AssetType.stock), isTrue);
      expect(demo.any((h) => h.assetType == AssetType.mf), isTrue);
      expect(demo.any((h) => h.assetType == AssetType.etf), isTrue);
    });
  });

  group('Broker Repository & Portfolio Synchronization Tests', () {
    late BrokerRepositoryImpl brokerRepo;
    late InMemoryPortfolioRepository portfolioRepo;

    setUp(() {
      brokerRepo = BrokerRepositoryImpl();
      portfolioRepo = InMemoryPortfolioRepository();
    });

    test('Connects Zerodha Kite and Groww demo accounts and updates status', () async {
      final zerodha = await brokerRepo.connectBroker(
        type: BrokerType.zerodha,
        clientCode: 'ZM9482',
        isDemo: true,
      );
      expect(zerodha.brokerType, equals(BrokerType.zerodha));
      expect(zerodha.clientCode, equals('ZM9482'));
      expect(zerodha.isConnected, isTrue);

      final groww = await brokerRepo.connectBroker(
        type: BrokerType.groww,
        clientCode: 'GRW-48201',
        isDemo: true,
      );
      expect(groww.brokerType, equals(BrokerType.groww));
      expect(groww.clientCode, equals('GRW-48201'));

      final list = await brokerRepo.getConnectedBrokers();
      expect(list.length, equals(2));
    });

    test('Synchronizes Zerodha portfolio into core assets repository', () async {
      final zerodha = await brokerRepo.connectBroker(
        type: BrokerType.zerodha,
        clientCode: 'ZM9482',
        isDemo: true,
      );

      await brokerRepo.syncBrokerPortfolio(zerodha.id, portfolioRepo);

      // Verify core assets updated
      final assets = await portfolioRepo.getAssets();
      expect(assets.isNotEmpty, isTrue);
      expect(assets.every((a) => a.accountId == 'broker:${zerodha.id}'), isTrue);

      // Verify broker account statistics updated
      final updatedBroker = await brokerRepo.getBrokerById(zerodha.id);
      expect(updatedBroker, isNotNull);
      expect(updatedBroker!.totalInvested, greaterThan(0));
      expect(updatedBroker.totalCurrentValue, greaterThan(0));
      expect(updatedBroker.holdingsCount, equals(assets.length));
      expect(updatedBroker.equityCount, greaterThan(0));
      expect(updatedBroker.mfCount, greaterThan(0));
      expect(updatedBroker.etfCount, greaterThan(0));
    });

    test('Disconnecting broker removes associated assets from portfolio', () async {
      final groww = await brokerRepo.connectBroker(
        type: BrokerType.groww,
        clientCode: 'GRW-48201',
        isDemo: true,
      );

      await brokerRepo.syncBrokerPortfolio(groww.id, portfolioRepo);
      var assets = await portfolioRepo.getAssets();
      expect(assets.isNotEmpty, isTrue);

      // Disconnect
      await brokerRepo.disconnectBroker(groww.id, portfolioRepo: portfolioRepo);
      final remainingBrokers = await brokerRepo.getConnectedBrokers();
      expect(remainingBrokers.isEmpty, isTrue);

      assets = await portfolioRepo.getAssets();
      expect(assets.isEmpty, isTrue);
    });
  });
}
