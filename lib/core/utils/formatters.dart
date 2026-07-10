import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class Formatters {
  Formatters._();

  static final _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: AppConstants.currency,
    decimalDigits: 0,
  );

  static final _currencyDec = NumberFormat.currency(
    locale: 'en_IN',
    symbol: AppConstants.currency,
    decimalDigits: 2,
  );

  static String currency(num amount, {bool decimals = false}) {
    return decimals ? _currencyDec.format(amount) : _currency.format(amount);
  }

  static String rating(double value) => value.toStringAsFixed(1);

  static String distance(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  static String deliveryTime(int mins) {
    if (mins < 60) return '$mins mins';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  static String orderId(String id) {
    if (id.length <= 8) return '#$id';
    return '#${id.substring(0, 8).toUpperCase()}';
  }

  static String relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM yyyy').format(dt);
  }

  static String dateTime(DateTime dt) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  static String discountPercent(double mrp, double price) {
    if (mrp <= price) return '';
    final pct = ((mrp - price) / mrp * 100).round();
    return '$pct% OFF';
  }
}
