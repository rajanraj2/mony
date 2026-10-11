import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../domain/models/app_theme_config.dart';
import '../providers/theme_providers.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(themeConfigProvider);
    final theme = themeAsync.value ?? const AppThemeConfig();
    final repo = ref.read(themeRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Themes, Colors & Styling')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Theme Mode (Light / Dark / AMOLED / System)
          const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: AppThemeMode.values.map((mode) {
                final isSelected = theme.themeMode == mode;
                return RadioListTile<AppThemeMode>(
                  title: Text(mode.displayName, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  value: mode,
                  groupValue: theme.themeMode,
                  onChanged: (val) => val != null ? repo.updateThemeMode(val) : null,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Primary Accent Palette Picker
          const Text('Primary Accent Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: AccentColorPreset.values.map((preset) {
                  final isSelected = theme.accentColor == preset;
                  return GestureDetector(
                    onTap: () => repo.updateAccentColor(preset),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: preset.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(color: preset.color.withOpacity(0.5), blurRadius: 10, spreadRadius: 2),
                        ],
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 22) : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Icon Shape Style
          const Text('Icon Family & Shape', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: AppIconStyle.values.map((style) {
                final isSelected = theme.iconStyle == style;
                return RadioListTile<AppIconStyle>(
                  title: Text(style.displayName, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  value: style,
                  groupValue: theme.iconStyle,
                  onChanged: (val) => val != null ? repo.updateIconStyle(val) : null,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Reset to Defaults
          Center(
            child: TextButton.icon(
              onPressed: () => repo.resetToDefaults(),
              icon: const Icon(Icons.restore),
              label: const Text('Reset to Default Emerald Theme'),
            ),
          ),
        ],
      ),
    );
  }
}
