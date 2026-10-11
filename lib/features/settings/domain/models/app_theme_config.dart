import 'package:flutter/material.dart';

enum AppThemeMode {
  system,
  light,
  dark,
  amoledBlack;

  String get displayName {
    switch (this) {
      case AppThemeMode.system:
        return 'Match System';
      case AppThemeMode.light:
        return 'Clean Light';
      case AppThemeMode.dark:
        return 'Obsidian Dark';
      case AppThemeMode.amoledBlack:
        return 'Pure AMOLED Black';
    }
  }
}

enum AccentColorPreset {
  emerald(Color(0xFF15803D), 'Emerald Wealth (Default)'),
  sapphire(Color(0xFF2563EB), 'Sapphire Blue'),
  amethyst(Color(0xFF7E22CE), 'Royal Amethyst'),
  crimson(Color(0xFFDC2626), 'Crimson Ruby'),
  amber(Color(0xFFD97706), 'Golden Amber'),
  cyberpunkTeal(Color(0xFF0D9488), 'Cyberpunk Teal'),
  roseGold(Color(0xFFE11D48), 'Rose Gold');

  final Color color;
  final String displayName;
  const AccentColorPreset(this.color, this.displayName);
}

enum AppIconStyle {
  rounded,
  outlined,
  sharp;

  String get displayName {
    switch (this) {
      case AppIconStyle.rounded:
        return 'Rounded Smooth (Default)';
      case AppIconStyle.outlined:
        return 'Minimal Outlined';
      case AppIconStyle.sharp:
        return 'Sharp Geometry';
    }
  }
}

class AppThemeConfig {
  final AppThemeMode themeMode;
  final AccentColorPreset accentColor;
  final AppIconStyle iconStyle;
  final bool dynamicSystemColorEnabled; // Material You dynamic colors on Android 12+

  const AppThemeConfig({
    this.themeMode = AppThemeMode.dark,
    this.accentColor = AccentColorPreset.emerald,
    this.iconStyle = AppIconStyle.rounded,
    this.dynamicSystemColorEnabled = false,
  });

  AppThemeConfig copyWith({
    AppThemeMode? themeMode,
    AccentColorPreset? accentColor,
    AppIconStyle? iconStyle,
    bool? dynamicSystemColorEnabled,
  }) {
    return AppThemeConfig(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      iconStyle: iconStyle ?? this.iconStyle,
      dynamicSystemColorEnabled: dynamicSystemColorEnabled ?? this.dynamicSystemColorEnabled,
    );
  }
}
