import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/di/providers.dart';
import '../../domain/models/asset.dart';
import '../providers/portfolio_providers.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(portfolioSummaryProvider);
    final assetsAsync = ref.watch(assetListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Investment Portfolio & Net Worth')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(portfolioSummaryProvider);
          ref.invalidate(assetListProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Portfolio Hero Banner
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
            const SizedBox(height: 20),

            // Asset Allocation Breakdown
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
                                  SizedBox(width: 110, child: Text(entry.key.displayName, style: const TextStyle(fontWeight: FontWeight.w600))),
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
                    const SizedBox(height: 20),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Holdings List
            const Text('Holdings & Assets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            assetsAsync.when(
              data: (assets) {
                if (assets.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('No assets recorded. Tap + to add stocks, mutual funds, or gold.')),
                    ),
                  );
                }

                return Column(
                  children: assets.map((a) => _AssetTile(asset: a)).toList(),
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
        label: const Text('Add Asset'),
      ),
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

class _AssetTile extends ConsumerWidget {
  final Asset asset;

  const _AssetTile({required this.asset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = asset;
    final isPos = a.absoluteReturn >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(a.color).withOpacity(0.15),
          child: Icon(Icons.trending_up, color: Color(a.color)),
        ),
        title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${a.type.displayName} • Qty: ${a.quantity} • Bought at ₹${a.purchasePrice.toStringAsFixed(1)}'),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('₹${a.currentValue.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(
              '${isPos ? '+' : ''}${a.returnPercentage.toStringAsFixed(1)}% (${a.cagr.toStringAsFixed(1)}% CAGR)',
              style: TextStyle(color: isPos ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
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
          const Text('Add Investment Asset', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
