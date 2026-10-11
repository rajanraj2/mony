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
  LlmVendor _vendor = LlmVendor.openai;
  late final TextEditingController _keyCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _baseUrlCtrl;

  @override
  void initState() {
    super.initState();
    _keyCtrl = TextEditingController();
    _modelCtrl = TextEditingController(text: _vendor.defaultModel);
    _baseUrlCtrl = TextEditingController(text: _vendor.defaultBaseUrl);

    // Populate with existing config if saved
    Future.microtask(() async {
      final existing = await ref.read(llmClientRepositoryProvider).getConfig();
      if (existing != null && mounted) {
        setState(() {
          _vendor = existing.vendor;
          _keyCtrl.text = existing.apiKey;
          _modelCtrl.text = existing.modelName;
          _baseUrlCtrl.text = existing.customBaseUrl ?? existing.vendor.defaultBaseUrl;
        });
      }
    });
  }

  void _onVendorChanged(LlmVendor v) {
    setState(() {
      _vendor = v;
      _modelCtrl.text = v.defaultModel;
      _baseUrlCtrl.text = v.defaultBaseUrl;
    });
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
              Text('Configure Your AI / LLM Model', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Bring your own API key to power Mony AI. Your key is stored strictly on your local device and never transmitted to our servers.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<LlmVendor>(
            value: _vendor,
            decoration: const InputDecoration(labelText: 'AI Model Vendor', border: OutlineInputBorder()),
            items: LlmVendor.values.map((v) => DropdownMenuItem(value: v, child: Text(v.displayName))).toList(),
            onChanged: (v) => v != null ? _onVendorChanged(v) : null,
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _keyCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'API Key (sk-...)',
              hintText: 'Paste your secret API key here',
              prefixIcon: Icon(Icons.key),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _modelCtrl,
            decoration: const InputDecoration(
              labelText: 'Model Identifier',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _baseUrlCtrl,
            decoration: const InputDecoration(
              labelText: 'API Base URL (Endpoint)',
              border: OutlineInputBorder(),
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
                  child: const Text('Reset / Clear Key'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    final key = _keyCtrl.text.trim();
                    if (key.isEmpty && _vendor != LlmVendor.customOpenAiCompatible) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an API key.')));
                      return;
                    }

                    final config = LlmProviderConfig(
                      vendor: _vendor,
                      apiKey: key,
                      modelName: _modelCtrl.text.trim(),
                      customBaseUrl: _baseUrlCtrl.text.trim(),
                      isEnabled: true,
                    );

                    await ref.read(llmClientRepositoryProvider).saveConfig(config);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved AI key for ${_vendor.displayName}!')));
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save & Activate'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
