import 'package:intl/intl.dart';

abstract final class CurrencyUtils {
  static final NumberFormat _fmt = NumberFormat('#,##0.00');
  static final NumberFormat _fmtCompact = NumberFormat('#,##0');

  static String format(double amount) => 'Rs. ${_fmt.format(amount)}';
  static String formatCompact(double amount) => 'Rs. ${_fmtCompact.format(amount)}';

  static double roundToTwo(double value) =>
      double.parse(value.toStringAsFixed(2));

  /// Applies a percentage discount to an amount.
  static double applyDiscount(double amount, double discountPercent) {
    assert(discountPercent >= 0 && discountPercent <= 100, 'Discount must be 0-100');
    return roundToTwo(amount * (1 - discountPercent / 100));
  }

  /// Calculates gross profit margin as a percentage.
  static double marginPercent(double costPrice, double sellPrice) {
    if (sellPrice == 0) return 0;
    return roundToTwo(((sellPrice - costPrice) / sellPrice) * 100);
  }
}
