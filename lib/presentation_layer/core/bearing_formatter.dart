import 'angle_converter.dart';
import 'bearing_format.dart';

/// Utility class for formatting bearings and angles
class BearingFormatter {
  /// Format a decimal angle according to the specified format
  static String format(double decimal, BearingFormat format) {
    final dms = AngleConverter.decimalToDMS(decimal);
    final d = dms['degrees']!.abs();
    final m = dms['minutes']!;
    final s = dms['seconds']!;
    final sign = decimal < 0 ? '-' : '';

    switch (format) {
      case BearingFormat.dms:
        // final paddedD = d < 10
        //     ? d.toString().padLeft(3, '0')
        //     : d < 100
        //         ? d.toString().padLeft(2, '0')
        //         : d.toString();
        return '$sign$d.${m.toString().padLeft(2, '0')}.${s.toString().padLeft(2, '0')}';
      case BearingFormat.dmsCompact:
        // final paddedD = d < 10
        //     ? d.toString().padLeft(3, '0')
        //     : d < 100
        //         ? d.toString().padLeft(2, '0')
        //         : d.toString();
        return '$sign$d.${m.toString().padLeft(2, '0')}${s.toString().padLeft(2, '0')}';
      case BearingFormat.dm:
        return '$sign$d.$m';
      case BearingFormat.dmsNoSeparator:
        return '$sign$d$m$s';
      case BearingFormat.dmsSymbols:
        return '$sign$d° $m\' $s"';
      case BearingFormat.dmsSymbolsCompact:
        return '$sign$d°$m\'$s"';
    }
  }
}
