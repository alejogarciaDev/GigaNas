import 'package:intl/intl.dart';

class Formatters {
  static String formatBytes(int bytes, [int decimals = 1]) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB"];
    int i = 0;
    double count = bytes.toDouble();
    while (count >= 1024 && i < suffixes.length - 1) {
      count /= 1024;
      i++;
    }
    return "${count.toStringAsFixed(decimals)} ${suffixes[i]}";
  }

  static String formatDate(DateTime dt) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  static String formatTimestamp(int seconds) {
    if (seconds <= 0) return "--";
    final dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  static String formatPhotoDateHeader(String isoDate) {
    try {
      final parts = isoDate.split("-");
      if (parts.length == 3) {
        final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        return DateFormat('EEEE, d MMMM yyyy', 'es').format(dt);
      }
    } catch (_) {}
    return isoDate;
  }
}
