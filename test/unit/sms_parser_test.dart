import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bank SMS Regex Parser Pattern Tests', () {
    test('HDFC Debit regex extracts amount and merchant name', () {
      final pattern = RegExp(
        r'(?:Rs\.?|INR)\s*(?<amount>[\d,]+(?:\.\d{2})?)\s*(?:debited|spent).*?(?:at|to|for|info)\s*(?<merchant>[a-zA-Z0-9\s&*-]+?)(?:\.|\s+on|\s+avail)',
        caseSensitive: false,
      );

      const sampleSms = 'Rs. 450.00 debited from HDFC Bank acct for Zomato on 10-Oct-26.';
      final match = pattern.firstMatch(sampleSms);

      expect(match, isNotNull);
      expect(match!.namedGroup('amount'), equals('450.00'));
      expect(match.namedGroup('merchant')?.trim(), equals('Zomato'));
    });

    test('SBI Debit regex extracts amount and merchant name', () {
      final pattern = RegExp(
        r'(?:Rs\.?|INR)\s*(?<amount>[\d,]+(?:\.\d{2})?)\s*(?:debited|transferred).*?(?:to|at)\s*(?<merchant>[a-zA-Z0-9\s&*-]+?)(?:\.|\s+ref|\s+on)',
        caseSensitive: false,
      );

      const sampleSms = 'INR 1,200.50 debited from SBI acct to Swiggy on 10/10/26.';
      final match = pattern.firstMatch(sampleSms);

      expect(match, isNotNull);
      expect(match!.namedGroup('amount')?.replaceAll(',', ''), equals('1200.50'));
      expect(match.namedGroup('merchant')?.trim(), equals('Swiggy'));
    });

    test('UPI Generic regex handles wallet payments', () {
      final pattern = RegExp(
        r'(?:paid|sent|debited)\s*(?:Rs\.?|INR)\s*(?<amount>[\d,]+(?:\.\d{2})?)\s*(?:to|at)\s*(?<merchant>[a-zA-Z0-9\s&*-]+?)(?:\.|\s+using|\s+on)',
        caseSensitive: false,
      );

      const sampleSms = 'Paid Rs. 85.00 to Chai Point using Google Pay.';
      final match = pattern.firstMatch(sampleSms);

      expect(match, isNotNull);
      expect(match!.namedGroup('amount'), equals('85.00'));
      expect(match.namedGroup('merchant')?.trim(), equals('Chai Point'));
    });
  });
}
