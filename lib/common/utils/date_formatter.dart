import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat shortDateFormat = DateFormat('dd MMM');
  static final DateFormat monthYearFormat = DateFormat('MMMM yyyy');

  static String formatDate(DateTime date) {
    return dateFormat.format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return dateTimeFormat.format(dateTime);
  }

  static String formatShortDate(DateTime date) {
    return shortDateFormat.format(date);
  }

  static String formatMonthYear(DateTime date) {
    return monthYearFormat.format(date);
  }

  static String getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hôm nay';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays == -1) {
      return 'Ngày mai';
    } else if (difference.inDays > 1 && difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inDays < -1 && difference.inDays > -7) {
      return 'Trong ${-difference.inDays} ngày';
    } else {
      return formatDate(date);
    }
  }
}
