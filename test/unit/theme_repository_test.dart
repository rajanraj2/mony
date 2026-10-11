import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mony/features/settings/domain/models/app_theme_config.dart';
import 'package:mony/features/settings/data/repositories/theme_repository_impl.dart';

void main() {
  group('Custom Themes, Accent Colors & Icons Tests', () {
    late ThemeRepositoryImpl repo;

    setUp(() {
      repo = ThemeRepositoryImpl();
    });

    test('Default theme config is Obsidian Dark with Emerald accent and rounded icons', () async {
      final config = await repo.getThemeConfig();
      expect(config.themeMode, equals(AppThemeMode.dark));
      expect(config.accentColor, equals(AccentColorPreset.emerald));
      expect(config.iconStyle, equals(AppIconStyle.rounded));
      expect(config.dynamicSystemColorEnabled, isFalse);
    });

    test('Changing theme mode to AMOLED black updates state', () async {
      await repo.updateThemeMode(AppThemeMode.amoledBlack);
      final config = await repo.getThemeConfig();
      expect(config.themeMode, equals(AppThemeMode.amoledBlack));
      expect(config.themeMode.displayName, equals('Pure AMOLED Black'));
    });

    test('Changing accent color updates palette across presets', () async {
      await repo.updateAccentColor(AccentColorPreset.sapphire);
      var config = await repo.getThemeConfig();
      expect(config.accentColor, equals(AccentColorPreset.sapphire));
      expect(config.accentColor.color, equals(const Color(0xFF2563EB)));

      await repo.updateAccentColor(AccentColorPreset.amethyst);
      config = await repo.getThemeConfig();
      expect(config.accentColor, equals(AccentColorPreset.amethyst));
    });

    test('Updating icon style switches geometry configuration', () async {
      await repo.updateIconStyle(AppIconStyle.outlined);
      final config = await repo.getThemeConfig();
      expect(config.iconStyle, equals(AppIconStyle.outlined));
      expect(config.iconStyle.displayName, equals('Minimal Outlined'));
    });

    test('Reset to defaults restores Emerald Dark theme', () async {
      await repo.updateAccentColor(AccentColorPreset.crimson);
      await repo.updateThemeMode(AppThemeMode.light);
      await repo.resetToDefaults();

      final config = await repo.getThemeConfig();
      expect(config.themeMode, equals(AppThemeMode.dark));
      expect(config.accentColor, equals(AccentColorPreset.emerald));
    });
  });
}
