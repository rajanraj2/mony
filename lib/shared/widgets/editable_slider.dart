import 'package:flutter/material.dart';

class EditableSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final double? step;
  final String? prefix;
  final String? suffix;
  final int decimalDigits;
  final ValueChanged<double> onChanged;

  const EditableSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.step,
    this.prefix,
    this.suffix,
    this.decimalDigits = 0,
    required this.onChanged,
  });

  String get _formattedValue {
    final formattedNumber = decimalDigits > 0
        ? value.toStringAsFixed(decimalDigits)
        : value.toInt().toString();
    return '${prefix ?? ""}$formattedNumber${suffix ?? ""}';
  }

  void _showDirectInputDialog(BuildContext context) {
    final controller = TextEditingController(
      text: decimalDigits > 0 ? value.toStringAsFixed(decimalDigits) : value.toInt().toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $label'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter exact value (between ${min.toInt()} and ${max.toInt()}):', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: prefix,
                suffixText: suffix,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.trim());
              if (parsed != null) {
                final clamped = parsed.clamp(min, max);
                onChanged(clamped);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            InkWell(
              onTap: () => _showDirectInputDialog(context),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formattedValue,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.edit_outlined, size: 13, color: Theme.of(context).colorScheme.primary),
                  ],
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
