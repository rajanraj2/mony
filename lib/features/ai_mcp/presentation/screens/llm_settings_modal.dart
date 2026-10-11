import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../domain/models/llm_provider_config.dart';

class LlmSettingsModal extends ConsumerStatefulWidget {
  const LlmSettingsModal({super.key});

  @override
  ConsumerState<LlmSettingsModal> createState() => _LlmSettingsModalState();
}

class _LlmSettingsModalState extends ConsumerState<LlmSettingsModal> {
  final _keyCtrl = TextEditingController();
  String _detectedLabel = 'Paste any key to auto-detect';
  Color _detectedColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final existing = await ref.read(llmClientRepositoryProvider).getConfig();
      if (existing != null && mounted) {
        setState(() {
          _keyCtrl.text = existing.apiKey;
          _updateDetection(existing.apiKey);
        });
      }
    });

    _keyCtrl.addListener(() => _updateDetection(_keyCtrl.text));
  }

  void _updateDetection(String key) {
    if (key.trim().isEmpty) {
      setState(() {
        _detectedLabel = 'Paste any key to auto-detect';
        _detectedColor = Colors.grey;
      });
      return;
    }
    final detected = LlmVendor.detectFromKey(key);
    setState(() {
      _detectedLabel = '✓ Detected: ${detected.vendor.displayName} (${detected.model})';
      _detectedColor = Colors.green;
    });
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Connect Any AI Model', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Just paste your API key below. Mony automatically detects whether it belongs to OpenAI, Anthropic, Gemini, Groq, OpenRouter, or Ollama and configures the model and endpoint for you.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _keyCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Paste API Key Here',
              hintText: 'sk-..., sk-ant-..., AIzaSy..., gsk_..., or "ollama"',
              prefixIcon: const Icon(Icons.vpn_key),
              suffixIcon: _keyCtrl.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _keyCtrl.clear())
                  : null,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),

          // Detection Indicator Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _detectedColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _detectedColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 16, color: _detectedColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _detectedLabel,
                    style: TextStyle(color: _detectedColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await ref.read(llmClientRepositoryProvider).clearConfig();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    final key = _keyCtrl.text.trim();
                    if (key.isEmpty) return;

                    final config = LlmProviderConfig(apiKey: key);
                    await ref.read(llmClientRepositoryProvider).saveConfig(config);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Activated ${config.detected.vendor.displayName}!')),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save & Connect'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
