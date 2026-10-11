import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mony/shared/utils/icon_registry.dart';
import 'package:mony/features/settings/domain/models/custom_color_model.dart';

void main() {
  group('Searchable Icon Registry Tests', () {
    test('IconRegistry contains icons across all financial categories', () {
      expect(IconRegistry.allIcons.length, greaterThan(25));
      expect(IconRegistry.allIcons.any((i) => i.id == 'account_balance'), isTrue);
      expect(IconRegistry.allIcons.any((i) => i.id == 'trending_up'), isTrue);
    });

    test('Searching by tag finds related items (e.g. "zomato" -> restaurant, "uber" -> car)', () {
      final foodResults = IconRegistry.search('zomato');
      expect(foodResults, isNotEmpty);
      expect(foodResults.first.id, equals('restaurant'));

      final rideResults = IconRegistry.search('uber');
      expect(rideResults, isNotEmpty);
      expect(rideResults.first.id, equals('directions_car'));

      final cryptoResults = IconRegistry.search('crypto');
      expect(cryptoResults, isNotEmpty);
      expect(cryptoResults.first.id, equals('show_chart'));
    });

    test('Searching with empty string returns full icon catalog', () {
      expect(IconRegistry.search('').length, equals(IconRegistry.allIcons.length));
    });

    test('IconRegistry returns fallback icon when id is not recognized', () {
      final icon = IconRegistry.getIconOrDefault('non_existent_icon_123', Icons.help_outline);
      expect(icon, equals(Icons.help_outline));
    });
  });

  group('Gradient & Color Presets Tests', () {
    test('GradientPreset has multi-color combinations', () {
      expect(GradientPreset.presets.length, greaterThanOrEqualTo(5));
      final aurora = GradientPreset.presets.firstWhere((p) => p.id == 'aurora_emerald');
      expect(aurora.colors.length, greaterThanOrEqualTo(2));
      expect(aurora.name, contains('Emerald'));
    });
  });
}
