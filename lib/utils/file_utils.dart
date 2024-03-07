
import 'dart:math';

abstract class FileUtils {
  static String getFileSizeString({required int bytes, int decimals = 2}) {
    const suffixes = ["Б", "КБ", "МБ", "ГБ"];
    if (bytes == 0) return '0${suffixes[0]}';
    var i = (log(bytes) / log(1024)).floor();
    return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) + suffixes[i];
  }
}