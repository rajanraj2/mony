import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/di/providers.dart';
import '../../domain/models/asset.dart';
import '../../domain/models/broker_account.dart';
import '../providers/broker_providers.dart';
import '../providers/portfolio_providers.dart';
import 'connect_broker_sheet.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(portfolioSummaryProvider);
    final assetsAsync = ref.watch(assetListProvider);
    final brokersAsync = ref.watch(connectedBrokersProvider);
    final selectedBrokerFilter = ref.watch(selectedBrokerFilterProvider);
    final selectedAssetType = ref.watch(selectedAssetTypeFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Investment Portfolio & Net Worth'),
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: 'Connect Broker (Zerodha / Groww)',
            onPressed: () => _showConnectBrokerModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync All Brokers',
            onPressed: () async {
              final brokerRepo = ref.read(brokerRepositoryProvider);
              final portfolioRepo = ref.read(portfolioRepositoryProvider);
              await brokerRepo.syncAllBrokers(portfolioRepo);
              ref.invalidate(portfolioSummaryProvider);
              ref.invalidate(assetListProvider);
              ref.invalidate(connectedBrokersProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All broker portfolios synced successfully!')),
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final brokerRepo = ref.read(brokerRepositoryProvider);
          final portfolioRepo = ref.read(portfolioRepositoryProvider);
          await brokerRepo.syncAllBrokers(portfolioRepo);
          ref.invalidate(portfolioSummaryProvider);
          ref.invalidate(assetListProvider);
          ref.invalidate(connectedBrokersProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Portfolio Hero Banner
            summaryAsync.when(
              data: (s) {
                final isPositive = s.totalGainLoss >= 0;
                return Card(
                  elevation: 2,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Colors.indigo.shade800,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Portfolio Value', style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 6),
                        Text(
                          '₹${s.totalCurrentValue.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Return', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                Text(
                                  '${isPositive ? '+' : ''}₹${s.totalGainLoss.toStringAsFixed(0)} (${s.totalGainLossPercentage.toStringAsFixed(1)}%)',
                                  style: TextStyle(
                                    color: isPositive ? Colors.greenAccent : Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Portfolio CAGR', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                Text(
                                  '${s.overallCagr.toStringAsFixed(1)}%',
                                  style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Invested Capital', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                Text('₹${s.totalInvested.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 16),

            // 2. Connected Broker Accounts Section
            _buildBrokerSection(context, ref, brokersAsync),
            const SizedBox(height: 16),

            // 3. Asset Allocation Breakdown
            summaryAsync.when(
              data: (s) {
                if (s.allocationByType.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Asset Allocation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: s.allocationByType.entries.map((entry) {
                            final pct = s.totalCurrentValue > 0 ? (entry.value / s.totalCurrentValue) : 0.0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 110,
                                    child: Text(entry.key.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: pct,
                                        minHeight: 8,
                                        valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text('${(pct * 100).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // 4. Holdings Section Header with Filter Chips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Holdings & Assets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton.icon(
                  onPressed: () => _showConnectBrokerModal(context),
                  icon: const Icon(Icons.add_link, size: 18),
                  label: const Text('Link Broker'),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(ref, 'All Sources', selectedBrokerFilter == 'ALL', () {
                    ref.read(selectedBrokerFilterProvider.notifier).state = 'ALL';
                  }),
                  const SizedBox(width: 6),
                  _buildFilterChip(ref, 'Zerodha Kite', selectedBrokerFilter == 'ZERODHA', () {
                    ref.read(selectedBrokerFilterProvider.notifier).state = 'ZERODHA';
                  }, color: const Color(0xFFE05A47)),
                  const SizedBox(width: 6),
                  _buildFilterChip(ref, 'Groww', selectedBrokerFilter == 'GROWW', () {
                    ref.read(selectedBrokerFilterProvider.notifier).state = 'GROWW';
                  }, color: const Color(0xFF00D09C)),
                  const SizedBox(width: 6),
                  _buildFilterChip(ref, 'Manual Assets', selectedBrokerFilter == 'MANUAL', () {
                    ref.read(selectedBrokerFilterProvider.notifier).state = 'MANUAL';
                  }),
                  const SizedBox(width: 12),
                  const Text('|', style: TextStyle(color: Colors.white24)),
                  const SizedBox(width: 12),
                  _buildFilterChip(ref, 'All Types', selectedAssetType == 'ALL', () {
                    ref.read(selectedAssetTypeFilterProvider.notifier).state = 'ALL';
                  }),
                  const SizedBox(width: 6),
                  _buildFilterChip(ref, 'Stocks', selectedAssetType == 'STOCK', () {
                    ref.read(selectedAssetTypeFilterProvider.notifier).state = 'STOCK';
                  }),
                  const SizedBox(width: 6),
                  _buildFilterChip(ref, 'Mutual Funds', selectedAssetType == 'MF', () {
                    ref.read(selectedAssetTypeFilterProvider.notifier).state = 'MF';
                  }),
                  const SizedBox(width: 6),
                  _buildFilterChip(ref, 'ETFs', selectedAssetType == 'ETF', () {
                    ref.read(selectedAssetTypeFilterProvider.notifier).state = 'ETF';
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 5. Holdings List
            assetsAsync.when(
              data: (assets) {
                // Apply filters
                final filtered = assets.where((a) {
                  // Broker filter
                  if (selectedBrokerFilter == 'ZERODHA') {
                    if (a.accountId == null || !a.accountId!.contains('zerodha')) return false;
                  } else if (selectedBrokerFilter == 'GROWW') {
                    if (a.accountId == null || !a.accountId!.contains('groww')) return false;
                  } else if (selectedBrokerFilter == 'MANUAL') {
                    if (a.accountId != null && a.accountId!.startsWith('broker:')) return false;
                  }

                  // Asset type filter
                  if (selectedAssetType == 'STOCK' && a.type != AssetType.stock) return false;
                  if (selectedAssetType == 'MF' && a.type != AssetType.mf) return false;
                  if (selectedAssetType == 'ETF' && a.type != AssetType.etf) return false;

                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.account_balance_wallet_outlined, size: 40, color: Colors.white38),
                            const SizedBox(height: 8),
                            const Text(
                              'No matching holdings found.',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Connect Zerodha or Groww to automatically import all your stocks, mutual funds & ETFs.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.white54),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => _showConnectBrokerModal(context),
                              icon: const Icon(Icons.link),
                              label: const Text('Connect Broker'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: filtered.map((a) => _AssetTile(asset: a)).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAssetDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Manual Asset'),
      ),
    );
  }

  Widget _buildFilterChip(
    WidgetRef ref,
    String label,
    bool isSelected,
    VoidCallback onTap, {
    Color? color,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : Colors.white70,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: color ?? const Color(0xFF2563EB),
      backgroundColor: const Color(0xFF1E242E),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }

  Widget _buildBrokerSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<BrokerAccount>> brokersAsync,
  ) {
    return brokersAsync.when(
      data: (brokers) {
        if (brokers.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.account_balance, color: Color(0xFF60A5FA), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Broker Portfolios',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              'Connect Zerodha or Groww for real-time stock & MF sync',
                              style: TextStyle(fontSize: 12, color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showConnectBrokerModal(context, initial: BrokerType.zerodha),
                          icon: const Icon(Icons.show_chart, color: Color(0xFFE05A47), size: 18),
                          label: const Text('Connect Zerodha', style: TextStyle(color: Color(0xFFE05A47))),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE05A47)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showConnectBrokerModal(context, initial: BrokerType.groww),
                          icon: const Icon(Icons.eco, color: Color(0xFF00D09C), size: 18),
                          label: const Text('Connect Groww', style: TextStyle(color: Color(0xFF00D09C))),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF00D09C)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Connected Brokers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton.icon(
                  onPressed: () => _showConnectBrokerModal(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Account'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...brokers.map((broker) => _BrokerCard(broker: broker)),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showConnectBrokerModal(BuildContext context, {BrokerType? initial}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ConnectBrokerSheet(initialBroker: initial),
    );
  }

  void _showAddAssetDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddAssetBottomSheet(),
    );
  }
}

class _BrokerCard extends ConsumerWidget {
  final BrokerAccount broker;

  const _BrokerCard({required this.broker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPos = broker.totalPnl >= 0;
    final isDayPos = broker.dayPnl >= 0;
    final brandColor = broker.brokerType.brandColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: brandColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(broker.brokerType.icon, color: brandColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            broker.accountName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: brandColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              broker.brokerType.shortName,
                              style: TextStyle(color: brandColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${broker.holdingsCount} Holdings (${broker.equityCount} Stocks • ${broker.mfCount} MFs • ${broker.etfCount} ETFs)',
                        style: const TextStyle(fontSize: 12, color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.sync, color: Colors.white70),
                  tooltip: 'Sync Portfolio Now',
                  onPressed: () async {
                    final brokerRepo = ref.read(brokerRepositoryProvider);
                    final portfolioRepo = ref.read(portfolioRepositoryProvider);
                    await brokerRepo.syncBrokerPortfolio(broker.id, portfolioRepo);
                    ref.invalidate(portfolioSummaryProvider);
                    ref.invalidate(assetListProvider);
                    ref.invalidate(connectedBrokersProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${broker.accountName} synced successfully!')),
                      );
                    }
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white60),
                  onSelected: (val) async {
                    if (val == 'disconnect') {
                      final brokerRepo = ref.read(brokerRepositoryProvider);
                      final portfolioRepo = ref.read(portfolioRepositoryProvider);
                      await brokerRepo.disconnectBroker(broker.id, portfolioRepo: portfolioRepo);
                      ref.invalidate(portfolioSummaryProvider);
                      ref.invalidate(assetListProvider);
                      ref.invalidate(connectedBrokersProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${broker.accountName} disconnected.')),
                        );
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'disconnect',
                      child: Row(
                        children: [
                          Icon(Icons.link_off, color: Colors.redAccent, size: 18),
                          SizedBox(width: 8),
                          Text('Disconnect Account', style: TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current Valuation', style: TextStyle(fontSize: 11, color: Colors.white60)),
                    Text(
                      '₹${broker.totalCurrentValue.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Returns', style: TextStyle(fontSize: 11, color: Colors.white60)),
                    Text(
                      '${isPos ? '+' : ''}₹${broker.totalPnl.toStringAsFixed(0)} (${broker.totalPnlPercentage.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isPos ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('1-Day Change', style: TextStyle(fontSize: 11, color: Colors.white60)),
                    Text(
                      '${isDayPos ? '+' : ''}₹${broker.dayPnl.toStringAsFixed(0)} (${broker.dayPnlPercentage.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDayPos ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetTile extends ConsumerWidget {
  final Asset asset;

  const _AssetTile({required this.asset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = asset;
    final isPos = a.absoluteReturn >= 0;

    // Detect if this asset came from a connected broker
    final isZerodha = a.accountId != null && a.accountId!.contains('zerodha');
    final isGroww = a.accountId != null && a.accountId!.contains('groww');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(a.color).withOpacity(0.15),
          child: Icon(
            a.type == AssetType.mf
                ? Icons.pie_chart
                : (a.type == AssetType.etf ? Icons.layers : Icons.trending_up),
            color: Color(a.color),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                a.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isZerodha) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE05A47).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Kite',
                  style: TextStyle(color: Color(0xFFE05A47), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ] else if (isGroww) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D09C).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Groww',
                  style: TextStyle(color: Color(0xFF00D09C), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${a.type.displayName} • Qty: ${a.quantity.toStringAsFixed(a.quantity % 1 == 0 ? 0 : 2)} • Avg: ₹${a.purchasePrice.toStringAsFixed(1)} • CMP: ₹${a.currentPrice.toStringAsFixed(1)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '₹${a.currentValue.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text(
              '${isPos ? '+' : ''}${a.returnPercentage.toStringAsFixed(1)}% (${a.cagr.toStringAsFixed(1)}% CAGR)',
              style: TextStyle(
                color: isPos ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddAssetBottomSheet extends ConsumerStatefulWidget {
  const _AddAssetBottomSheet();

  @override
  ConsumerState<_AddAssetBottomSheet> createState() => _AddAssetBottomSheetState();
}

class _AddAssetBottomSheetState extends ConsumerState<_AddAssetBottomSheet> {
  final _nameCtrl = TextEditingController();
  final _tickerCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  AssetType _type = AssetType.stock;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Manual Investment Asset', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          DropdownButtonFormField<AssetType>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Asset Class', border: OutlineInputBorder()),
            items: AssetType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))).toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 12),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Asset Name (e.g. Apple, HDFC Top 100, Gold)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _tickerCtrl, decoration: const InputDecoration(labelText: 'Ticker (optional, e.g. AAPL, INFOSYS)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextField(controller: _qtyCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: _priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Purchase Price', prefixText: '₹ ', border: OutlineInputBorder()))),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final qty = double.tryParse(_qtyCtrl.text);
              final price = double.tryParse(_priceCtrl.text);
              if (_nameCtrl.text.isEmpty || qty == null || price == null) return;

              final asset = Asset(
                id: const Uuid().v4(),
                name: _nameCtrl.text.trim(),
                type: _type,
                ticker: _tickerCtrl.text.trim().isEmpty ? null : _tickerCtrl.text.trim(),
                quantity: qty,
                purchasePrice: price,
                currentPrice: price,
                purchaseCurrency: 'INR',
                purchaseDate: DateTime.now(),
                icon: 'trending_up',
                color: 0xFF1B6B3A,
              );

              await ref.read(portfolioRepositoryProvider).createAsset(asset);
              ref.invalidate(portfolioSummaryProvider);
              ref.invalidate(assetListProvider);
              if (mounted) Navigator.pop(context);
            },
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('Record Asset'),
          ),
        ],
      ),
    );
  }
}
