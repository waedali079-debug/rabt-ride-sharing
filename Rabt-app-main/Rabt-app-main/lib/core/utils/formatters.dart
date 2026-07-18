import 'package:intl/intl.dart';

class Formatters {
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: 'ر.س', decimalDigits: 2);
    return formatter.format(amount);
  }

  static String formatDate(DateTime date) {
    final formatter = DateFormat('yyyy/MM/dd');
    return formatter.format(date);
  }

  static String formatTime(DateTime time) {
    final formatter = DateFormat('HH:mm');
    return formatter.format(time);
  }

  static String formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('yyyy/MM/dd HH:mm');
    return formatter.format(dateTime);
  }

  static String formatPhoneNumber(String phone) {
    // Format: +9627XXXXXXXX
    if (phone.length >= 12) {
      return '${phone.substring(0, 4)} ${phone.substring(4, 7)} ${phone.substring(7, 10)} ${phone.substring(10)}';
    }
    return phone;
  }

  static String formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} كم';
    }
    return '${meters.toStringAsFixed(0)} م';
  }

  static String formatDuration(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMins = minutes % 60;
      return '${hours}h ${remainingMins}د';
    }
    return '$minutes دقيقة';
  }
}
