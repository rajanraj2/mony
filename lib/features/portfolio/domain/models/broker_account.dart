import 'package:flutter/material.dart';
import 'asset.dart';

enum BrokerType {
  zerodha,
  groww;

  String get displayName {
    switch (this) {
      case BrokerType.zerodha:
        return 'Zerodha (Kite)';
      case BrokerType.groww:
        return 'Groww';
    }
  }

  Color get brandColor {
    switch (this) {
      case BrokerType.zerodha:
        return const Color(0xFFE05A47); // Kite Orange / Red
      case BrokerType.groww:
        return const Color(0xFF00D09C); // Groww Emerald Teal
    }
  }

  int get brandColorValue => brandColor.value;

  String get shortName {
    switch (this) {
      case BrokerType.zerodha:
        return 'Kite';
      case BrokerType.groww:
        return 'Groww';
    }
  }

  IconData get icon => Icons.account_balance;
}

enum BrokerStatus {
  connected,
  syncing,
  expired,
  disconnected;

  String get displayName {
    switch (this) {
      case BrokerStatus.connected:
        return 'Connected';
      case BrokerStatus.syncing:
        return 'Syncing...';
      case BrokerStatus.expired:
        return 'Session Expired';
      case BrokerStatus.disconnected:
        return 'Disconnected';
    }
  }
}

enum BrokerAuthType {
  apiKeyAndSecret,
  sessionToken,
  demoSandbox;
}

class BrokerAccount {
  final String id;
  final BrokerType brokerType;
  final String clientCode;
  final String accountName;
  final BrokerStatus status;
  final BrokerAuthType authType;
  final String? apiKey;
  final String? accessToken;
  final String? enctoken;
  final DateTime connectedAt;
  final DateTime lastSyncedAt;
  final double totalInvested;
  final double totalCurrentValue;
  final double totalPnl;
  final double totalPnlPercentage;
  final double dayPnl;
  final double dayPnlPercentage;
  final int holdingsCount;
  final int equityCount;
  final int mfCount;
  final int etfCount;

  const BrokerAccount({
    required this.id,
    required this.brokerType,
    required this.clientCode,
    required this.accountName,
    required this.status,
    required this.authType,
    this.apiKey,
    this.accessToken,
    this.enctoken,
    required this.connectedAt,
    required this.lastSyncedAt,
    this.totalInvested = 0.0,
    this.totalCurrentValue = 0.0,
    this.totalPnl = 0.0,
    this.totalPnlPercentage = 0.0,
    this.dayPnl = 0.0,
    this.dayPnlPercentage = 0.0,
    this.holdingsCount = 0,
    this.equityCount = 0,
    this.mfCount = 0,
    this.etfCount = 0,
  });

  bool get isConnected => status == BrokerStatus.connected || status == BrokerStatus.syncing;

  BrokerAccount copyWith({
    String? id,
    BrokerType? brokerType,
    String? clientCode,
    String? accountName,
    BrokerStatus? status,
    BrokerAuthType? authType,
    String? apiKey,
    String? accessToken,
    String? enctoken,
    DateTime? connectedAt,
    DateTime? lastSyncedAt,
    double? totalInvested,
    double? totalCurrentValue,
    double? totalPnl,
    double? totalPnlPercentage,
    double? dayPnl,
    double? dayPnlPercentage,
    int? holdingsCount,
    int? equityCount,
    int? mfCount,
    int? etfCount,
  }) {
    return BrokerAccount(
      id: id ?? this.id,
      brokerType: brokerType ?? this.brokerType,
      clientCode: clientCode ?? this.clientCode,
      accountName: accountName ?? this.accountName,
      status: status ?? this.status,
      authType: authType ?? this.authType,
      apiKey: apiKey ?? this.apiKey,
      accessToken: accessToken ?? this.accessToken,
      enctoken: enctoken ?? this.enctoken,
      connectedAt: connectedAt ?? this.connectedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      totalInvested: totalInvested ?? this.totalInvested,
      totalCurrentValue: totalCurrentValue ?? this.totalCurrentValue,
      totalPnl: totalPnl ?? this.totalPnl,
      totalPnlPercentage: totalPnlPercentage ?? this.totalPnlPercentage,
      dayPnl: dayPnl ?? this.dayPnl,
      dayPnlPercentage: dayPnlPercentage ?? this.dayPnlPercentage,
      holdingsCount: holdingsCount ?? this.holdingsCount,
      equityCount: equityCount ?? this.equityCount,
      mfCount: mfCount ?? this.mfCount,
      etfCount: etfCount ?? this.etfCount,
    );
  }
}

class BrokerHolding {
  final String id;
  final BrokerType brokerType;
  final String symbol;
  final String name;
  final String isin;
  final String exchange; // NSE, BSE, MF
  final AssetType assetType; // stock, mf, etf, gold, etc.
  final double quantity;
  final double averagePrice;
  final double lastPrice;
  final double closePrice;
  final double investedValue;
  final double currentValue;
  final double pnl;
  final double pnlPercentage;
  final double dayChange;
  final double dayChangePercentage;
  final String? folioNumber;
  final DateTime lastUpdated;

  const BrokerHolding({
    required this.id,
    required this.brokerType,
    required this.symbol,
    required this.name,
    required this.isin,
    required this.exchange,
    required this.assetType,
    required this.quantity,
    required this.averagePrice,
    required this.lastPrice,
    required this.closePrice,
    required this.investedValue,
    required this.currentValue,
    required this.pnl,
    required this.pnlPercentage,
    required this.dayChange,
    required this.dayChangePercentage,
    this.folioNumber,
    required this.lastUpdated,
  });

  /// Factory from raw values with automatic financial calculations
  factory BrokerHolding.calculate({
    required String id,
    required BrokerType brokerType,
    required String symbol,
    required String name,
    required String isin,
    required String exchange,
    required AssetType assetType,
    required double quantity,
    required double averagePrice,
    required double lastPrice,
    required double closePrice,
    String? folioNumber,
    DateTime? lastUpdated,
  }) {
    final invested = quantity * averagePrice;
    final current = quantity * lastPrice;
    final pnl = current - invested;
    final pnlPct = invested > 0 ? (pnl / invested) * 100 : 0.0;
    final dayDelta = lastPrice - closePrice;
    final dayChangeTotal = quantity * dayDelta;
    final dayPct = closePrice > 0 ? (dayDelta / closePrice) * 100 : 0.0;

    return BrokerHolding(
      id: id,
      brokerType: brokerType,
      symbol: symbol,
      name: name,
      isin: isin,
      exchange: exchange,
      assetType: assetType,
      quantity: quantity,
      averagePrice: averagePrice,
      lastPrice: lastPrice,
      closePrice: closePrice,
      investedValue: invested,
      currentValue: current,
      pnl: pnl,
      pnlPercentage: pnlPct,
      dayChange: dayChangeTotal,
      dayChangePercentage: dayPct,
      folioNumber: folioNumber,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }
}
