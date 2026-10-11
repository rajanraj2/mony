import '../models/app_theme_config.dart';

abstract class IThemeRepository {
  Stream<AppThemeConfig> watchThemeConfig();
  Future<AppThemeConfig> getThemeConfig();
  Future<void> updateThemeMode(AppThemeMode mode);
  Future<void> updateAccentColor(AccentColorPreset accent);
  Future<void> updateIconStyle(AppIconStyle style);
  Future<void> toggleDynamicSystemColor(bool enabled);
  Future<void> resetToDefaults();
}
