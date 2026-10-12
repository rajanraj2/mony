import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mony/core/theme/app_theme.dart';
import 'package:mony/features/settings/domain/models/app_theme_config.dart';
import 'package:mony/features/settings/presentation/providers/home_tiles_provider.dart';
import 'package:mony/features/transactions/domain/models/transaction.dart';

import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  group('Home Screen Quick Tiles Settings Tests', () {
    test('HomeTilesNotifier starts with all 4 tiles enabled and allows granular toggling', () {
      final notifier = HomeTilesNotifier();
      expect(notifier.state.hasAnyVisible, isTrue);
      expect(notifier.state.showQuickAnalytics, isTrue);
      expect(notifier.state.showQuickInsights, isTrue);
      expect(notifier.state.showReports, isTrue);
      expect(notifier.state.showCalendarHeatmap, isTrue);

      // Toggle off Analytics
      notifier.setQuickAnalytics(false);
      expect(notifier.state.showQuickAnalytics, isFalse);
      expect(notifier.state.showQuickInsights, isTrue);

      // Toggle off all
      notifier.toggleAll(false);
      expect(notifier.state.hasAnyVisible, isFalse);
      expect(notifier.state.showCalendarHeatmap, isFalse);

      // Re-enable
      notifier.setCalendarHeatmap(true);
      expect(notifier.state.hasAnyVisible, isTrue);
      expect(notifier.state.showCalendarHeatmap, isTrue);
    });
  });

  group('Theme Customization Tests', () {
    test('AppTheme creates valid ThemeData for warm dark and clean light modes', () {
      final darkTheme = AppTheme.dark();
      expect(darkTheme.brightness, equals(Brightness.dark));
      expect(darkTheme.scaffoldBackgroundColor, equals(AppTheme.bgDarkWarm));
      expect(darkTheme.colorScheme.primary, equals(AppTheme.primaryWarm));

      final lightTheme = AppTheme.light();
      expect(lightTheme.brightness, equals(Brightness.light));
    });

    test('AppThemeConfig copyWith properly updates themeMode', () {
      const config = AppThemeConfig();
      final light = config.copyWith(themeMode: AppThemeMode.light);
      expect(light.themeMode, equals(AppThemeMode.light));

      final dark = config.copyWith(themeMode: AppThemeMode.dark);
      expect(dark.themeMode, equals(AppThemeMode.dark));
    });
  });

  group('Simultaneous Include AND Exclude Filtering Tests', () {
    test('Applies both Include and Exclude filters together simultaneously', () {
      final now = DateTime.now();

      // Transaction 1: Food, #essential -> Included
      final t1 = Transaction(
        id: '1',
        accountId: 'acc',
        amount: 250,
        currencyCode: 'INR',
        type: TransactionType.expense,
        name: 'Groceries',
        categoryId: 'cat-food',
        labels: ['#essential', '#routine'],
        date: now,
        createdAt: now,
        updatedAt: now,
      );

      // Transaction 2: Food, #cash -> Matches included category BUT has excluded label #cash!
      final t2 = Transaction(
        id: '2',
        accountId: 'acc',
        amount: 150,
        currencyCode: 'INR',
        type: TransactionType.expense,
        name: 'Street Food',
        categoryId: 'cat-food',
        labels: ['#cash'],
        date: now,
        createdAt: now,
        updatedAt: now,
      );

      // Transaction 3: Entertainment, #discretionary -> Not in included categories
      final t3 = Transaction(
        id: '3',
        accountId: 'acc',
        amount: 800,
        currencyCode: 'INR',
        type: TransactionType.expense,
        name: 'Movie Ticket',
        categoryId: 'cat-entertainment',
        labels: ['#discretionary'],
        date: now,
        createdAt: now,
        updatedAt: now,
      );

      final list = [t1, t2, t3];

      // Criteria: Include Category "cat-food" AND Exclude Label "#cash"
      final includedCats = {'cat-food'};
      final excludedLabels = {'#cash'};

      final filtered = list.where((t) {
        // Exclude check
        if (t.labels.any((l) => excludedLabels.contains(l))) {
          return false;
        }
        // Include check
        if (includedCats.isNotEmpty && !includedCats.contains(t.categoryId)) {
          return false;
        }
        return true;
      }).toList();

      expect(filtered.length, equals(1));
      expect(filtered.first.id, equals('1'));
      expect(filtered.first.name, equals('Groceries'));
    });
  });
}
