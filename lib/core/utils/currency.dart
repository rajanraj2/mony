import 'package:intl/intl.dart';

/// Formats an amount using the provided ISO 4217 currency code.
String formatCurrency(double amount, String currencyCode) {
  final format = NumberFormat.currency(
    symbol: _symbol(currencyCode),
    decimalDigits: 2,
  );
  return format.format(amount);
}

String _symbol(String code) {
  const symbols = {
    'INR': '₹',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'AUD': 'A\$',
    'CAD': 'C\$',
    'SGD': 'S\$',
    'AED': 'AED ',
  };
  return symbols[code.toUpperCase()] ?? '$code ';
}
