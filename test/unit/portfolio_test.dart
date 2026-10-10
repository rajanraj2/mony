import 'package:flutter_test/flutter_test.dart';
import 'package:mony/features/portfolio/domain/models/asset.dart';

void main() {
  group('Asset Portfolio & CAGR Calculations', () {
    test('Asset investedValue and currentValue calculate accurately', () {
      final asset = Asset(
        id: '1',
        name: 'Apple Inc.',
        type: AssetType.stock,
        ticker: 'AAPL',
        quantity: 10,
        purchasePrice: 150.0,
        currentPrice: 225.0,
        purchaseCurrency: 'USD',
        purchaseDate: DateTime(2025, 10, 10),
        icon: 'trending_up',
        color: 0xFF123456,
      );

      expect(asset.investedValue, equals(1500.0));
      expect(asset.currentValue, equals(2250.0));
      expect(asset.absoluteReturn, equals(750.0));
      expect(asset.returnPercentage, equals(50.0));
    });

    test('Asset CAGR calculates annualized return over multi-year holding', () {
      final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
      final asset = Asset(
        id: '2',
        name: 'Nifty 50 Index Fund',
        type: AssetType.mf,
        quantity: 100,
        purchasePrice: 100.0,
        currentPrice: 120.0, // 20% 1-year return
        purchaseCurrency: 'INR',
        purchaseDate: oneYearAgo,
        icon: 'trending_up',
        color: 0xFF123456,
      );

      expect(asset.cagr, closeTo(20.0, 1.0));
    });

    test('AssetType displays user-friendly name', () {
      expect(AssetType.stock.displayName, equals('Stocks'));
      expect(AssetType.mf.displayName, equals('Mutual Funds'));
      expect(AssetType.gold.displayName, equals('Gold & Silver'));
    });
  });
}
