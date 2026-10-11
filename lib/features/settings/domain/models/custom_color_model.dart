import 'package:flutter/material.dart';

class GradientPreset {
  final String id;
  final String name;
  final List<Color> colors;

  const GradientPreset({
    required this.id,
    required this.name,
    required this.colors,
  });

  static const List<GradientPreset> presets = [
    GradientPreset(
      id: 'aurora_emerald',
      name: 'Aurora Emerald',
      colors: [Color(0xFF15803D), Color(0xFF047857), Color(0xFF0F766E)],
    ),
    GradientPreset(
      id: 'midnight_sapphire',
      name: 'Midnight Sapphire',
      colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF0284C7)],
    ),
    GradientPreset(
      id: 'royal_amethyst',
      name: 'Royal Amethyst',
      colors: [Color(0xFF581C87), Color(0xFF7E22CE), Color(0xFFA855F7)],
    ),
    GradientPreset(
      id: 'sunset_crimson',
      name: 'Sunset Crimson',
      colors: [Color(0xFF991B1B), Color(0xFFDC2626), Color(0xFFF97316)],
    ),
    GradientPreset(
      id: 'cyberpunk_neon',
      name: 'Cyberpunk Neon',
      colors: [Color(0xFF0F172A), Color(0xFF0D9488), Color(0xFF06B6D4)],
    ),
    GradientPreset(
      id: 'gold_bullion',
      name: 'Gold Bullion',
      colors: [Color(0xFF78350F), Color(0xFFB45309), Color(0xFFF59E0B)],
    ),
  ];
}
