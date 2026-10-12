import '../../../transactions/presentation/providers/transaction_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../domain/models/asset.dart';

final assetListProvider = StreamProvider<List<Asset>>((ref) {
  return ref.watch(portfolioRepositoryProvider).watchAssets();
});

final portfolioSummaryProvider = FutureProvider<PortfolioSummary>((ref) {
  return ref.watch(portfolioRepositoryProvider).getPortfolioSummary();
});

final aggregateNetWorthProvider = StreamProvider<double>((ref) {
  final accountsStream = ref.watch(accountListProvider.stream);
  return accountsStream.asyncMap((accounts) async {
    final cash = accounts.fold(0.0, (sum, acc) => sum + acc.currentBalance);
    final assets = await ref.read(portfolioRepositoryProvider).getAssets();
    final assetsVal = assets.fold(0.0, (sum, a) => sum + a.currentValue);
    return cash + assetsVal;
  });
});
