import 'dart:async';
import '../../domain/models/app_theme_config.dart';
import '../../domain/repositories/theme_repository.dart';

class ThemeRepositoryImpl implements IThemeRepository {
  final _controller = StreamController<AppThemeConfig>.broadcast();
  AppThemeConfig _currentConfig = const AppThemeConfig();

  ThemeRepositoryImpl() {
    _controller.add(_currentConfig);
  }

  @override
  Stream<AppThemeConfig> watchThemeConfig() => _controller.stream;

  @override
  Future<AppThemeConfig> getThemeConfig() async => _currentConfig;

  @override
  Future<void> updateThemeMode(AppThemeMode mode) async {
    _currentConfig = _currentConfig.copyWith(themeMode: mode);
    _controller.add(_currentConfig);
  }

  @override
  Future<void> updateAccentColor(AccentColorPreset accent) async {
    _currentConfig = _currentConfig.copyWith(accentColor: accent);
    _controller.add(_currentConfig);
  }

  @override
  Future<void> updateIconStyle(AppIconStyle style) async {
    _currentConfig = _currentConfig.copyWith(iconStyle: style);
    _controller.add(_currentConfig);
  }

  @override
  Future<void> toggleDynamicSystemColor(bool enabled) async {
    _currentConfig = _currentConfig.copyWith(dynamicSystemColorEnabled: enabled);
    _controller.add(_currentConfig);
  }

  @override
  Future<void> resetToDefaults() async {
    _currentConfig = const AppThemeConfig();
    _controller.add(_currentConfig);
  }
}
