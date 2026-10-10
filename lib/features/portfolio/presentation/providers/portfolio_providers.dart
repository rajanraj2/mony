import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../domain/models/asset.dart';

final assetListProvider = StreamProvider<List<Asset>>((ref) {
  return ref.watch(portfolioRepositoryProvider).watchAssets();
});

final portfolioSummaryProvider = FutureProvider<PortfolioSummary>((ref) {
  return ref.watch(portfolioRepositoryProvider).getPortfolioSummary();
});

final aggregateNetWorthProvider = FutureProvider<double>((ref) {
  return ref.watch(portfolioRepositoryProvider).getAggregateNetWorth();
});
