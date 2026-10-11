import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../domain/models/app_theme_config.dart';

final themeConfigProvider = StreamProvider<AppThemeConfig>((ref) {
  return ref.watch(themeRepositoryProvider).watchThemeConfig();
});
