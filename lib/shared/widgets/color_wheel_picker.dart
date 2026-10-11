import 'dart:math';
import 'package:flutter/material.dart';
import '../../features/settings/domain/models/custom_color_model.dart';

class ColorWheelPicker extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<GradientPreset>? onGradientSelected;

  const ColorWheelPicker({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
    this.onGradientSelected,
  });

  static Future<Color?> show(BuildContext context, {Color initialColor = const Color(0xFF15803D)}) {
    Color selected = initialColor;
    return showModalBottomSheet<Color>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF151B23),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Custom Color & Gradient Picker', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(ctx, selected), icon: const Icon(Icons.check, color: Colors.green)),
              ],
            ),
            const SizedBox(height: 16),
            ColorWheelPicker(
              initialColor: initialColor,
              onColorChanged: (c) => selected = c,
            ),
          ],
        ),
      ),
    );
  }

  @override
  State<ColorWheelPicker> createState() => _ColorWheelPickerState();
}

class _ColorWheelPickerState extends State<ColorWheelPicker> {
  late double _hue;
  late double _saturation;
  late double _lightness;

  @override
  void initState() {
    super.initState();
    final hsl = HSLColor.fromColor(widget.initialColor);
    _hue = hsl.hue;
    _saturation = hsl.saturation;
    _lightness = hsl.lightness;
  }

  Color get _currentColor => HSLColor.fromAHSL(1.0, _hue, _saturation, _lightness).toColor();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live Swatch & Hex Code
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _currentColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [BoxShadow(color: _currentColor.withOpacity(0.5), blurRadius: 12)],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hex Color Code', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                Text(
                  '#${_currentColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 360-Degree Hue Color Spectrum Slider
        const Text('Hue Spectrum (360° Color Wheel)', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
        Slider(
          value: _hue,
          min: 0,
          max: 360,
          onChanged: (v) {
            setState(() => _hue = v);
            widget.onColorChanged(_currentColor);
          },
        ),

        // Saturation Slider
        const Text('Saturation', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
        Slider(
          value: _saturation,
          min: 0.1,
          max: 1.0,
          onChanged: (v) {
            setState(() => _saturation = v);
            widget.onColorChanged(_currentColor);
          },
        ),

        // Lightness Slider
        const Text('Brightness / Lightness', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
        Slider(
          value: _lightness,
          min: 0.1,
          max: 0.9,
          onChanged: (v) {
            setState(() => _lightness = v);
            widget.onColorChanged(_currentColor);
          },
        ),
        const SizedBox(height: 16),

        // Multi-Color Gradient Presets
        const Text('Gradient Presets', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: GradientPreset.presets.map((preset) {
            return InkWell(
              onTap: () {
                final primary = preset.colors.first;
                final hsl = HSLColor.fromColor(primary);
                setState(() {
                  _hue = hsl.hue;
                  _saturation = hsl.saturation;
                  _lightness = hsl.lightness;
                });
                widget.onColorChanged(primary);
                if (widget.onGradientSelected != null) {
                  widget.onGradientSelected!(preset);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 100,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: preset.colors),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                alignment: Alignment.center,
                child: Text(preset.name, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
