import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../domain/models/broker_account.dart';
import '../providers/broker_providers.dart';
import '../providers/portfolio_providers.dart';

class ConnectBrokerSheet extends ConsumerStatefulWidget {
  final BrokerType? initialBroker;

  const ConnectBrokerSheet({super.key, this.initialBroker});

  @override
  ConsumerState<ConnectBrokerSheet> createState() => _ConnectBrokerSheetState();
}

class _ConnectBrokerSheetState extends ConsumerState<ConnectBrokerSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Zerodha Form
  final _zerodhaClientIdCtrl = TextEditingController(text: 'ZM9482');
  final _zerodhaApiKeyCtrl = TextEditingController();
  final _zerodhaAccessTokenCtrl = TextEditingController();
  final _zerodhaEnctokenCtrl = TextEditingController();

  // Groww Form
  final _growwClientIdCtrl = TextEditingController(text: 'GRW-48201');
  final _growwTokenCtrl = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialBroker == BrokerType.groww ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _zerodhaClientIdCtrl.dispose();
    _zerodhaApiKeyCtrl.dispose();
    _zerodhaAccessTokenCtrl.dispose();
    _zerodhaEnctokenCtrl.dispose();
    _growwClientIdCtrl.dispose();
    _growwTokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleConnect({
    required BrokerType type,
    bool isDemo = false,
  }) async {
    setState(() => _isLoading = true);
    final brokerRepo = ref.read(brokerRepositoryProvider);
    final portfolioRepo = ref.read(portfolioRepositoryProvider);

    try {
      final clientCode = type == BrokerType.zerodha
          ? _zerodhaClientIdCtrl.text.trim()
          : _growwClientIdCtrl.text.trim();

      final broker = await brokerRepo.connectBroker(
        type: type,
        clientCode: clientCode.isEmpty
            ? (type == BrokerType.zerodha ? 'ZM9482' : 'GRW-48201')
            : clientCode,
        apiKey: type == BrokerType.zerodha ? _zerodhaApiKeyCtrl.text.trim() : null,
        accessToken: type == BrokerType.zerodha
            ? _zerodhaAccessTokenCtrl.text.trim()
            : _growwTokenCtrl.text.trim(),
        enctoken: type == BrokerType.zerodha ? _zerodhaEnctokenCtrl.text.trim() : null,
        isDemo: isDemo,
      );

      // Perform real-time portfolio sync into Mony assets
      await brokerRepo.syncBrokerPortfolio(broker.id, portfolioRepo);

      ref.invalidate(portfolioSummaryProvider);
      ref.invalidate(assetListProvider);
      ref.invalidate(connectedBrokersProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF15803D),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('${type.displayName} connected & portfolio synced successfully!'),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Failed to connect: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141416),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Connect Broker Account',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Text(
            'Sync real-time equity, ETF & mutual fund holdings directly into your portfolio.',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1F242D),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _tabController.index == 0
                    ? const Color(0xFFE05A47)
                    : const Color(0xFF00D09C),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              onTap: (_) => setState(() {}),
              tabs: const [
                Tab(
                  icon: Icon(Icons.show_chart),
                  text: 'Zerodha (Kite)',
                ),
                Tab(
                  icon: Icon(Icons.eco),
                  text: 'Groww',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab Content
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _tabController.index == 0
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: _buildZerodhaForm(),
            secondChild: _buildGrowwForm(),
          ),

          const SizedBox(height: 16),

          // Security Badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: Color(0xFF4ADE80), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Zero-Cloud Security: Broker API keys & session tokens are encrypted locally on this device. We never transmit your secrets.',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZerodhaForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _zerodhaClientIdCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Kite Client ID / User ID',
            hintText: 'e.g. ZM9482',
            prefixIcon: Icon(Icons.person_outline, color: Color(0xFFE05A47)),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _zerodhaEnctokenCtrl,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Kite Session Enctoken (Recommended)',
            hintText: 'Paste Kite enctoken cookie from web',
            prefixIcon: Icon(Icons.key, color: Color(0xFFE05A47)),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '— OR Kite Connect API Credentials —',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 11),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _zerodhaApiKeyCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _zerodhaAccessTokenCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Access Token',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _isLoading
                    ? null
                    : () => _handleConnect(type: BrokerType.zerodha, isDemo: false),
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.link),
                label: const Text('Connect Live Kite'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE05A47),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () => _handleConnect(type: BrokerType.zerodha, isDemo: true),
                icon: const Icon(Icons.play_circle_outline, color: Color(0xFFE05A47)),
                label: const Text('One-Click Demo', style: TextStyle(color: Color(0xFFE05A47))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE05A47)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGrowwForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _growwClientIdCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Groww Client Code / Account ID',
            hintText: 'e.g. GRW-48201',
            prefixIcon: Icon(Icons.person_outline, color: Color(0xFF00D09C)),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _growwTokenCtrl,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Groww API / Bearer Token',
            hintText: 'Paste Groww API Bearer token',
            prefixIcon: Icon(Icons.key, color: Color(0xFF00D09C)),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _isLoading
                    ? null
                    : () => _handleConnect(type: BrokerType.groww, isDemo: false),
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.link),
                label: const Text('Connect Live Groww'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00D09C),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () => _handleConnect(type: BrokerType.groww, isDemo: true),
                icon: const Icon(Icons.play_circle_outline, color: Color(0xFF00D09C)),
                label: const Text('One-Click Demo', style: TextStyle(color: Color(0xFF00D09C))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF00D09C)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
