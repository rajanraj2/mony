import '../../domain/models/asset.dart';
import '../../domain/models/broker_account.dart';

class KiteConnectParser {
  /// Parses Zerodha Kite Connect equity holdings JSON
  /// e.g. from GET https://api.kite.trade/portfolio/holdings
  static List<BrokerHolding> parseEquityHoldings(Map<String, dynamic> json) {
    final list = <BrokerHolding>[];
    final data = json['data'] as List<dynamic>? ?? [];

    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      final symbol = item['tradingsymbol']?.toString() ?? 'UNKNOWN';
      final exchange = item['exchange']?.toString() ?? 'NSE';
      final isin = item['isin']?.toString() ?? '';
      final qty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
      final t1Qty = (item['t1_quantity'] as num?)?.toDouble() ?? 0.0;
      final totalQty = qty + t1Qty;
      final avgPrice = (item['average_price'] as num?)?.toDouble() ?? 0.0;
      final lastPrice = (item['last_price'] as num?)?.toDouble() ?? avgPrice;
      final closePrice = (item['close_price'] as num?)?.toDouble() ?? avgPrice;

      // Detect ETF vs Stock
      final isEtf = _isEtfSymbol(symbol);
      final assetType = isEtf ? AssetType.etf : AssetType.stock;
      final displayName = _formatKiteName(symbol);

      list.add(BrokerHolding.calculate(
        id: 'kite_${exchange}_$symbol',
        brokerType: BrokerType.zerodha,
        symbol: symbol,
        name: displayName,
        isin: isin,
        exchange: exchange,
        assetType: assetType,
        quantity: totalQty,
        averagePrice: avgPrice,
        lastPrice: lastPrice,
        closePrice: closePrice,
      ));
    }
    return list;
  }

  /// Parses Zerodha Coin Mutual Fund holdings JSON
  /// e.g. from GET https://api.kite.trade/mf/holdings
  static List<BrokerHolding> parseCoinMfHoldings(Map<String, dynamic> json) {
    final list = <BrokerHolding>[];
    final data = json['data'] as List<dynamic>? ?? [];

    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      final fundName = item['fund']?.toString() ?? 'Mutual Fund';
      final folio = item['folio']?.toString();
      final tradingsymbol = item['tradingsymbol']?.toString() ?? fundName;
      final units = (item['quantity'] as num?)?.toDouble() ?? 0.0;
      final avgPrice = (item['average_price'] as num?)?.toDouble() ?? 0.0;
      final lastPrice = (item['last_price'] as num?)?.toDouble() ?? avgPrice;

      list.add(BrokerHolding.calculate(
        id: 'kite_mf_${folio ?? tradingsymbol}',
        brokerType: BrokerType.zerodha,
        symbol: tradingsymbol,
        name: fundName,
        isin: item['isin']?.toString() ?? '',
        exchange: 'MF',
        assetType: AssetType.mf,
        quantity: units,
        averagePrice: avgPrice,
        lastPrice: lastPrice,
        closePrice: avgPrice,
        folioNumber: folio,
      ));
    }
    return list;
  }

  static bool _isEtfSymbol(String sym) {
    final s = sym.toUpperCase();
    return s.endsWith('BEES') ||
        s.endsWith('ETF') ||
        s.contains('GOLD') ||
        s.contains('SILVER') ||
        s.contains('NIFTY') ||
        s.contains('LIQUID');
  }

  static String _formatKiteName(String symbol) {
    switch (symbol.toUpperCase()) {
      case 'RELIANCE':
        return 'Reliance Industries Ltd';
      case 'TCS':
        return 'Tata Consultancy Services Ltd';
      case 'HDFCBANK':
        return 'HDFC Bank Ltd';
      case 'INFY':
        return 'Infosys Ltd';
      case 'TATAMOTORS':
        return 'Tata Motors Ltd';
      case 'NIFTYBEES':
        return 'Nippon India Nifty 50 BeES ETF';
      case 'GOLDBEES':
        return 'Nippon India ETF Gold BeES';
      default:
        return symbol;
    }
  }

  /// Pre-built realistic Zerodha Kite portfolio for Sandbox / One-Click Demo
  static List<BrokerHolding> generateDemoHoldings() {
    return [
      BrokerHolding.calculate(
        id: 'kite_NSE_RELIANCE',
        brokerType: BrokerType.zerodha,
        symbol: 'RELIANCE',
        name: 'Reliance Industries Ltd',
        isin: 'INE002A01018',
        exchange: 'NSE',
        assetType: AssetType.stock,
        quantity: 35.0,
        averagePrice: 2420.0,
        lastPrice: 2980.50,
        closePrice: 2945.0,
      ),
      BrokerHolding.calculate(
        id: 'kite_NSE_TCS',
        brokerType: BrokerType.zerodha,
        symbol: 'TCS',
        name: 'Tata Consultancy Services Ltd',
        isin: 'INE467B01029',
        exchange: 'NSE',
        assetType: AssetType.stock,
        quantity: 20.0,
        averagePrice: 3540.0,
        lastPrice: 4210.0,
        closePrice: 4185.0,
      ),
      BrokerHolding.calculate(
        id: 'kite_NSE_HDFCBANK',
        brokerType: BrokerType.zerodha,
        symbol: 'HDFCBANK',
        name: 'HDFC Bank Ltd',
        isin: 'INE040A01034',
        exchange: 'NSE',
        assetType: AssetType.stock,
        quantity: 50.0,
        averagePrice: 1520.0,
        lastPrice: 1680.0,
        closePrice: 1672.0,
      ),
      BrokerHolding.calculate(
        id: 'kite_NSE_NIFTYBEES',
        brokerType: BrokerType.zerodha,
        symbol: 'NIFTYBEES',
        name: 'Nippon India Nifty 50 BeES ETF',
        isin: 'INF732E01015',
        exchange: 'NSE',
        assetType: AssetType.etf,
        quantity: 400.0,
        averagePrice: 220.0,
        lastPrice: 268.40,
        closePrice: 266.10,
      ),
      BrokerHolding.calculate(
        id: 'kite_NSE_GOLDBEES',
        brokerType: BrokerType.zerodha,
        symbol: 'GOLDBEES',
        name: 'Nippon India ETF Gold BeES',
        isin: 'INF732E01031',
        exchange: 'NSE',
        assetType: AssetType.etf,
        quantity: 150.0,
        averagePrice: 52.50,
        lastPrice: 68.20,
        closePrice: 67.80,
      ),
      BrokerHolding.calculate(
        id: 'kite_mf_10482910',
        brokerType: BrokerType.zerodha,
        symbol: 'PARAG_PARIKH_FLEXI',
        name: 'Parag Parikh Flexi Cap Fund - Direct (Growth)',
        isin: 'INF879O01019',
        exchange: 'MF',
        assetType: AssetType.mf,
        quantity: 1420.50,
        averagePrice: 54.20,
        lastPrice: 78.45,
        closePrice: 77.80,
        folioNumber: '10482910',
      ),
      BrokerHolding.calculate(
        id: 'kite_mf_9821034',
        brokerType: BrokerType.zerodha,
        symbol: 'AXIS_SMALL_CAP',
        name: 'Axis Small Cap Fund - Direct Plan - Growth',
        isin: 'INF846K01EW2',
        exchange: 'MF',
        assetType: AssetType.mf,
        quantity: 850.0,
        averagePrice: 72.0,
        lastPrice: 104.20,
        closePrice: 103.50,
        folioNumber: '9821034',
      ),
    ];
  }
}

class GrowwParser {
  /// Parses Groww stocks and ETFs JSON response
  static List<BrokerHolding> parseStockHoldings(Map<String, dynamic> json) {
    final list = <BrokerHolding>[];
    final holdings = json['holdings'] as List<dynamic>? ?? [];

    for (final item in holdings) {
      if (item is! Map<String, dynamic>) continue;
      final name = item['companyName']?.toString() ?? 'Equity Stock';
      final symbol = item['tradingSymbol']?.toString() ?? name;
      final isin = item['isin']?.toString() ?? '';
      final qty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
      final avgPrice = (item['avgPrice'] as num?)?.toDouble() ?? 0.0;
      final currentPrice = (item['currentPrice'] as num?)?.toDouble() ?? avgPrice;
      final closePrice = (item['closePrice'] as num?)?.toDouble() ?? avgPrice;
      final typeStr = (item['type']?.toString() ?? '').toUpperCase();

      final assetType = typeStr == 'ETF' || symbol.contains('ETF')
          ? AssetType.etf
          : AssetType.stock;

      list.add(BrokerHolding.calculate(
        id: 'groww_stock_$symbol',
        brokerType: BrokerType.groww,
        symbol: symbol,
        name: name,
        isin: isin,
        exchange: 'NSE',
        assetType: assetType,
        quantity: qty,
        averagePrice: avgPrice,
        lastPrice: currentPrice,
        closePrice: closePrice,
      ));
    }
    return list;
  }

  /// Parses Groww Mutual Funds JSON response
  static List<BrokerHolding> parseMfHoldings(Map<String, dynamic> json) {
    final list = <BrokerHolding>[];
    final holdings = json['holdings'] as List<dynamic>? ?? [];

    for (final item in holdings) {
      if (item is! Map<String, dynamic>) continue;
      final schemeName = item['schemeName']?.toString() ?? 'Mutual Fund';
      final folio = item['folioNumber']?.toString();
      final units = (item['units'] as num?)?.toDouble() ?? 0.0;
      final nav = (item['nav'] as num?)?.toDouble() ?? 0.0;
      final invested = (item['investedAmount'] as num?)?.toDouble() ?? 0.0;
      final avgPrice = units > 0 ? (invested / units) : nav;

      list.add(BrokerHolding.calculate(
        id: 'groww_mf_${folio ?? schemeName}',
        brokerType: BrokerType.groww,
        symbol: schemeName.replaceAll(' ', '_').toUpperCase(),
        name: schemeName,
        isin: item['isin']?.toString() ?? '',
        exchange: 'MF',
        assetType: AssetType.mf,
        quantity: units,
        averagePrice: avgPrice,
        lastPrice: nav,
        closePrice: nav,
        folioNumber: folio,
      ));
    }
    return list;
  }

  /// Pre-built realistic Groww portfolio for Sandbox / One-Click Demo
  static List<BrokerHolding> generateDemoHoldings() {
    return [
      BrokerHolding.calculate(
        id: 'groww_NSE_TATAMOTORS',
        brokerType: BrokerType.groww,
        symbol: 'TATAMOTORS',
        name: 'Tata Motors Ltd',
        isin: 'INE155A01022',
        exchange: 'NSE',
        assetType: AssetType.stock,
        quantity: 120.0,
        averagePrice: 680.0,
        lastPrice: 995.40,
        closePrice: 984.0,
      ),
      BrokerHolding.calculate(
        id: 'groww_NSE_ICICIBANK',
        brokerType: BrokerType.groww,
        symbol: 'ICICIBANK',
        name: 'ICICI Bank Ltd',
        isin: 'INE090A01021',
        exchange: 'NSE',
        assetType: AssetType.stock,
        quantity: 75.0,
        averagePrice: 940.0,
        lastPrice: 1220.0,
        closePrice: 1210.0,
      ),
      BrokerHolding.calculate(
        id: 'groww_NSE_SBIN',
        brokerType: BrokerType.groww,
        symbol: 'SBIN',
        name: 'State Bank of India',
        isin: 'INE062A01020',
        exchange: 'NSE',
        assetType: AssetType.stock,
        quantity: 60.0,
        averagePrice: 620.0,
        lastPrice: 810.50,
        closePrice: 805.0,
      ),
      BrokerHolding.calculate(
        id: 'groww_mf_5829102',
        brokerType: BrokerType.groww,
        symbol: 'MIRAE_ASSET_LARGE_CAP',
        name: 'Mirae Asset Large Cap Fund - Direct (Growth)',
        isin: 'INF769K01169',
        exchange: 'MF',
        assetType: AssetType.mf,
        quantity: 820.0,
        averagePrice: 85.0,
        lastPrice: 118.25,
        closePrice: 117.50,
        folioNumber: '5829102',
      ),
      BrokerHolding.calculate(
        id: 'groww_mf_9182374',
        brokerType: BrokerType.groww,
        symbol: 'QUANT_ACTIVE_FUND',
        name: 'Quant Active Fund - Direct Plan - Growth',
        isin: 'INF966L01AA3',
        exchange: 'MF',
        assetType: AssetType.mf,
        quantity: 340.0,
        averagePrice: 380.0,
        lastPrice: 565.0,
        closePrice: 560.0,
        folioNumber: '9182374',
      ),
      BrokerHolding.calculate(
        id: 'groww_NSE_SILVERBEES',
        brokerType: BrokerType.groww,
        symbol: 'SILVERBEES',
        name: 'Nippon India Silver ETF',
        isin: 'INF732E01486',
        exchange: 'NSE',
        assetType: AssetType.etf,
        quantity: 250.0,
        averagePrice: 72.0,
        lastPrice: 94.60,
        closePrice: 93.80,
      ),
    ];
  }
}
