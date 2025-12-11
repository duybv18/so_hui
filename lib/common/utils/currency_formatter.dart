import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static final NumberFormat numberFormat = NumberFormat('#,##0', 'vi_VN');

  static String formatCurrency(double amount) {
    return currencyFormat.format(amount);
  }

  static String formatNumber(double number) {
    return numberFormat.format(number);
  }

  static String formatCompact(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)} tỷ';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)} tr';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} k';
    } else {
      return amount.toStringAsFixed(0);
    }
  }
}
