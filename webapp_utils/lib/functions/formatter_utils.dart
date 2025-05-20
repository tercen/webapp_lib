import 'package:intl/intl.dart';
import 'package:sci_tercen_client/sci_client.dart';

class DateFormatter {
  static String formatShort(Date dt) {
    final dateFormatter = DateFormat('yyyy/MM/dd');
    var parseDt = DateTime.parse(dt.value);
    return dateFormatter.format(parseDt);
  }

  static String format(Date dt) {
    final dateFormatter = DateFormat('yyyy/MM/dd hh:mm');
    var parseDt = DateTime.parse(dt.value);
    return dateFormatter.format(parseDt);
  }

  static String formatLong(Date dt, {bool shortYear = false}) {
    final year = shortYear ? 'yy' : 'yyyy';
    final dateFormatter = DateFormat('$year/MM/dd hh:mm:ss.SSS');
    var parseDt = DateTime.parse(dt.value);
    return dateFormatter.format(parseDt);
  }
}
