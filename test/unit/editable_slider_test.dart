import 'package:flutter_test/flutter_test.dart';
import 'package:mony/shared/widgets/editable_slider.dart';

void main() {
  group('EditableSlider Component Logic Tests', () {
    test('Clamps manually entered inputs strictly within min and max boundaries', () {
      double currentValue = 50.0;

      void updateValue(double val) {
        currentValue = val;
      }

      final slider = EditableSlider(
        label: 'Retirement Age',
        value: currentValue,
        min: 25.0,
        max: 75.0,
        onChanged: updateValue,
      );

      expect(slider.min, equals(25.0));
      expect(slider.max, equals(75.0));

      // Test lower boundary clamp
      const rawLowInput = 10.0;
      updateValue(rawLowInput.clamp(slider.min, slider.max));
      expect(currentValue, equals(25.0));

      // Test upper boundary clamp
      const rawHighInput = 95.0;
      updateValue(rawHighInput.clamp(slider.min, slider.max));
      expect(currentValue, equals(75.0));

      // Test valid within range input
      const rawValidInput = 48.0;
      updateValue(rawValidInput.clamp(slider.min, slider.max));
      expect(currentValue, equals(48.0));
    });
  });
}
