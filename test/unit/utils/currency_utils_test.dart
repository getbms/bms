import 'package:bms/core/utils/currency_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurrencyUtils', () {
    group('format', () {
      test('formats whole number with two decimal places', () {
        expect(CurrencyUtils.format(1000), 'Rs. 1,000.00');
      });

      test('formats decimal amount correctly', () {
        expect(CurrencyUtils.format(9.5), 'Rs. 9.50');
      });

      test('formats zero', () {
        expect(CurrencyUtils.format(0), 'Rs. 0.00');
      });

      test('formats large amount with thousands separator', () {
        expect(CurrencyUtils.format(1234567.89), 'Rs. 1,234,567.89');
      });
    });

    group('formatCompact', () {
      test('formats whole number without decimal places', () {
        expect(CurrencyUtils.formatCompact(1500), 'Rs. 1,500');
      });

      test('truncates fractional part', () {
        // NumberFormat('#,##0') rounds to nearest integer
        expect(CurrencyUtils.formatCompact(9.9), 'Rs. 10');
      });

      test('formats zero', () {
        expect(CurrencyUtils.formatCompact(0), 'Rs. 0');
      });
    });

    group('roundToTwo', () {
      test('rounds 1.456 to 1.46', () {
        // 1.456 * 100 = 145.6 → .round() = 146 → / 100 = 1.46
        expect(CurrencyUtils.roundToTwo(1.456), 1.46);
      });

      test('returns exact value when already two decimals', () {
        expect(CurrencyUtils.roundToTwo(3.14), 3.14);
      });

      test('returns zero for zero', () {
        expect(CurrencyUtils.roundToTwo(0), 0.0);
      });

      test('rounds down when third decimal < 5', () {
        expect(CurrencyUtils.roundToTwo(2.344), 2.34);
      });
    });

    group('applyDiscount', () {
      test('returns original amount when discount is zero', () {
        expect(CurrencyUtils.applyDiscount(100, 0), 100.0);
      });

      test('returns zero when discount is 100%', () {
        expect(CurrencyUtils.applyDiscount(100, 100), 0.0);
      });

      test('rounds to two decimal places', () {
        expect(CurrencyUtils.applyDiscount(100, 33), 67.0);
      });

      test('applies 10% discount correctly', () {
        expect(CurrencyUtils.applyDiscount(250, 10), 225.0);
      });

      test('handles fractional discount percent', () {
        expect(CurrencyUtils.applyDiscount(100, 5.5), 94.5);
      });
    });

    group('marginPercent', () {
      test('returns zero when sell price is zero', () {
        expect(CurrencyUtils.marginPercent(50, 0), 0.0);
      });

      test('calculates correct gross margin', () {
        expect(CurrencyUtils.marginPercent(60, 100), 40.0);
      });

      test('returns zero margin when cost equals sell price', () {
        expect(CurrencyUtils.marginPercent(100, 100), 0.0);
      });

      test('returns 100% margin when cost is zero', () {
        expect(CurrencyUtils.marginPercent(0, 100), 100.0);
      });

      test('returns negative margin when cost exceeds sell price', () {
        expect(CurrencyUtils.marginPercent(120, 100), lessThan(0));
      });
    });
  });
}
