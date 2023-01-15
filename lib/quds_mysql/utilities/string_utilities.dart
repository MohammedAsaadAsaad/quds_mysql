part of '../../quds_mysql.dart';

extension _StringUtilities on String {
  String removeLastComma() {
    if (endsWith(',')) return substring(0, length - 1);
    return this;
  }
}
