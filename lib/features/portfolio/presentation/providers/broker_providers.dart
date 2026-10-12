import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../domain/models/broker_account.dart';
import 'portfolio_providers.dart';

final connectedBrokersProvider = StreamProvider<List<BrokerAccount>>((ref) {
  final repo = ref.watch(brokerRepositoryProvider);
  return repo.watchConnectedBrokers();
});

final brokerHoldingsProvider =
    FutureProvider.family<List<BrokerHolding>, String>((ref, brokerId) async {
  final repo = ref.watch(brokerRepositoryProvider);
  return repo.fetchHoldings(brokerId);
});

final selectedBrokerFilterProvider = StateProvider<String>((ref) => 'ALL');

final selectedAssetTypeFilterProvider = StateProvider<String>((ref) => 'ALL');
