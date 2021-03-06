part of '../../quds_mysql.dart';

/// A double db representation
class DoubleField extends NumField<double> {
  /// Create an instance of [DoubleField]
  DoubleField(
      {String? columnName,
      int? precision,
      int? scale,
      bool? notNull,
      bool? isUnique,
      String? jsonMapName})
      : super(columnName,
            precision: precision,
            scale: scale,
            notNull: notNull,
            isUnique: isUnique,
            jsonMapName: jsonMapName,
            jsonMapType: double);

  /// Get new [DoubleField] of this value - [other]
  ///
  /// [other] may be of the following:
  ///
  ///  [DoubleField] - [IntField] - [NumField] - [double] - [int]
  DoubleField operator -(dynamic other) => _getMathOperationQuery('-', other);

  /// Get new [DoubleField] of this value + [other]
  ///
  /// [other] may be of the following:
  ///
  ///  [DoubleField] - [IntField] - [NumField] - [double] - [int]
  DoubleField operator +(dynamic other) => _getMathOperationQuery('+', other);

  /// Get new [DoubleField] of this value / [other]
  ///
  /// [other] may be of the following:
  ///
  ///  [DoubleField] - [IntField] - [NumField] - [double] - [int]
  DoubleField operator /(dynamic other) => _getMathOperationQuery('/', other);

  /// Get new [DoubleField] of this value * [other]
  ///
  /// [other] may be of the following:
  ///
  ///  [DoubleField] - [IntField] - [NumField] - [double] - [int]
  DoubleField operator *(dynamic other) => _getMathOperationQuery('*', other);

  DoubleField _getMathOperationQuery(String operation, dynamic other) {
    var result = DoubleField();
    result.queryBuilder = () =>
        '(' +
        buildQuery() +
        ' $operation ' +
        DbHelper.buildQueryForOperand(other) +
        ')';
    result.parametersBuilder = () => [
          ...getParameters(),
          if (other is QueryPart)
            ...other.getParameters()
          else
            DbHelper.getDbValue(other)
        ];
    return result;
  }

  /// Get db double field with `ABS()` function applied.
  DoubleField abs() {
    var result = DoubleField();
    result.queryBuilder = () => 'ABS(' + buildQuery() + ')';
    result.parametersBuilder = () => getParameters();
    return result;
  }

  /// Get db int field represents this value after rounding.
  IntField toInt() {
    var result = IntField();
    result.queryBuilder = () => 'CAST(ROUND(' + buildQuery() + ') AS INTEGER)';
    result.parametersBuilder = () => getParameters();
    return result;
  }
}
