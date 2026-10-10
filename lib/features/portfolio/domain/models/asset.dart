import 'dart:math';

enum AssetType {
  stock,
  mf,
  etf,
  crypto,
  realEstate,
  gold,
  fd,
  ppf,
  nps,
  other;

  static AssetType fromString(String val) {
    return AssetType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => AssetType.other,
    );
  }

  String get displayName {
    switch (this) {
      case AssetType.stock:
        return 'Stocks';
      case AssetType.mf:
        return 'Mutual Funds';
      case AssetType.etf:
        return 'ETFs';
      case AssetType.crypto:
        return 'Crypto';
      case AssetType.realEstate:
        return 'Real Estate';
      case AssetType.gold:
        return 'Gold & Silver';
      case AssetType.fd:
        return 'Fixed Deposits';
      case AssetType.ppf:
        return 'PPF';
      case AssetType.nps:
        return 'NPS';
      case AssetType.other:
        return 'Other Assets';
    }
  }
}

class Asset {
  final String id;
  final String name;
  final AssetType type;
  final String? ticker;
  final double quantity;
  final double purchasePrice;
  final double currentPrice;
  final String purchaseCurrency;
  final DateTime purchaseDate;
  final String? accountId;
  final String icon;
  final int color;

  const Asset({
    required this.id,
    required this.name,
    required this.type,
    this.ticker,
    required this.quantity,
    required this.purchasePrice,
    required this.currentPrice,
    required this.purchaseCurrency,
    required this.purchaseDate,
    this.accountId,
    required this.icon,
    required this.color,
  });

  double get investedValue => quantity * purchasePrice;
  double get currentValue => quantity * currentPrice;
  double get absoluteReturn => currentValue - investedValue;
  double get returnPercentage =>
      investedValue > 0 ? (absoluteReturn / investedValue) * 100 : 0.0;

  /// Compound Annual Growth Rate (CAGR) formula
  double get cagr {
    final days = DateTime.now().difference(purchaseDate).inDays;
    final years = days / 365.25;
    if (years <= 0.08 || investedValue <= 0) {
      return returnPercentage; // fallback to absolute return for holding < 1 month
    }
    return (pow(currentValue / investedValue, 1.0 / years) - 1.0) * 100;
  }

  Asset copyWith({
    String? id,
    String? name,
    AssetType? type,
    String? ticker,
    double? quantity,
    double? purchasePrice,
    double? currentPrice,
    String? purchaseCurrency,
    DateTime? purchaseDate,
    String? accountId,
    String? icon,
    int? color,
  }) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      ticker: ticker ?? this.ticker,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      currentPrice: currentPrice ?? this.currentPrice,
      purchaseCurrency: purchaseCurrency ?? this.purchaseCurrency,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      accountId: accountId ?? this.accountId,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }
}

class PortfolioSummary {
  final double totalInvested;
  final double totalCurrentValue;
  final double totalGainLoss;
  final double totalGainLossPercentage;
  final double overallCagr;
  final Map<AssetType, double> allocationByType;

  const PortfolioSummary({
    required this.totalInvested,
    required this.totalCurrentValue,
    required this.totalGainLoss,
    required this.totalGainLossPercentage,
    required this.overallCagr,
    required this.allocationByType,
  });
}
