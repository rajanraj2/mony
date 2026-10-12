import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/domain/models/app_theme_config.dart';
import 'features/settings/presentation/providers/theme_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: MonyApp(),
    ),
  );
}

class MonyApp extends ConsumerWidget {
  const MonyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeConfig = ref.watch(themeConfigProvider).value;

    ThemeMode mode;
    if (themeConfig != null) {
      switch (themeConfig.themeMode) {
        case AppThemeMode.light:
          mode = ThemeMode.light;
          break;
        case AppThemeMode.dark:
        case AppThemeMode.amoledBlack:
          mode = ThemeMode.dark;
          break;
        case AppThemeMode.system:
          mode = ThemeMode.system;
          break;
      }
    } else {
      mode = ThemeMode.dark;
    }

    return MaterialApp.router(
      title: 'Mony',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      routerConfig: router,
    );
  }
}
