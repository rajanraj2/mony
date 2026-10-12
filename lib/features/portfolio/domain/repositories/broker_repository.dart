import '../models/broker_account.dart';
import 'portfolio_repository.dart';

abstract class IBrokerRepository {
  Stream<List<BrokerAccount>> watchConnectedBrokers();
  Future<List<BrokerAccount>> getConnectedBrokers();
  Future<BrokerAccount?> getBrokerById(String id);

  Future<BrokerAccount> connectBroker({
    required BrokerType type,
    required String clientCode,
    String? accountName,
    String? apiKey,
    String? accessToken,
    String? enctoken,
    bool isDemo = false,
  });

  Future<void> disconnectBroker(
    String brokerAccountId, {
    IPortfolioRepository? portfolioRepo,
  });

  Future<List<BrokerHolding>> fetchHoldings(String brokerAccountId);

  Future<void> syncBrokerPortfolio(
    String brokerAccountId,
    IPortfolioRepository portfolioRepo,
  );

  Future<void> syncAllBrokers(IPortfolioRepository portfolioRepo);
}
