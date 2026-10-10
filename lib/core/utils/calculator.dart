class SimpleCalculator {
  SimpleCalculator._();

  /// Evaluates basic arithmetic (+ - * /) from an input string.
  /// Returns null if expression is invalid.
  static double? evaluate(String expression) {
    try {
      final sanitized = expression.replaceAll(' ', '').replaceAll(',', '');
      if (sanitized.isEmpty) return null;

      // Handle simple single number
      final direct = double.tryParse(sanitized);
      if (direct != null) return direct;

      // Tokenize
      final tokens = <String>[];
      var currentNumber = StringBuffer();

      for (var i = 0; i < sanitized.length; i++) {
        final char = sanitized[i];
        if ('+-*/'.contains(char)) {
          if (currentNumber.isNotEmpty) {
            tokens.add(currentNumber.toString());
            currentNumber = StringBuffer();
          }
          tokens.add(char);
        } else if (RegExp(r'[0-9.]').hasMatch(char)) {
          currentNumber.write(char);
        } else {
          return null; // invalid character
        }
      }
      if (currentNumber.isNotEmpty) {
        tokens.add(currentNumber.toString());
      }

      if (tokens.isEmpty) return null;

      // Step 1: Handle * and /
      final intermediate = <String>[];
      var i = 0;
      while (i < tokens.length) {
        final token = tokens[i];
        if (token == '*' || token == '/') {
          if (intermediate.isEmpty || i + 1 >= tokens.length) return null;
          final prev = double.tryParse(intermediate.removeLast());
          final next = double.tryParse(tokens[i + 1]);
          if (prev == null || next == null) return null;
          final res = token == '*' ? prev * next : (next != 0 ? prev / next : double.nan);
          intermediate.add(res.toString());
          i += 2;
        } else {
          intermediate.add(token);
          i++;
        }
      }

      // Step 2: Handle + and -
      if (intermediate.isEmpty) return null;
      var total = double.tryParse(intermediate[0]) ?? 0.0;
      var j = 1;
      while (j < intermediate.length) {
        final op = intermediate[j];
        if (j + 1 >= intermediate.length) return null;
        final next = double.tryParse(intermediate[j + 1]);
        if (next == null) return null;
        if (op == '+') total += next;
        if (op == '-') total -= next;
        j += 2;
      }

      return total;
    } catch (_) {
      return null;
    }
  }
}
