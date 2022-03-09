part of '../../quds_mysql.dart';

/// DateTime db field representation.
///
/// It's being stored as string in the db.
///
/// [DateTimeField] supports several db functions.
class DateTimeField extends FieldWithValue<DateTime> {
  /// Create an instance of [DateTimeField]
  DateTimeField(
      {String? columnName,
      bool? notNull,
      bool? isUnique,
      DateTime? defaultValue,
      String? jsonMapName})
      : super(columnName,
            defaultValue: defaultValue,
            notNull: notNull,
            isUnique: isUnique,
            jsonMapName: jsonMapName,
            jsonMapType: DateTime);

  /// Get db order statement to order from older to newer dates
  FieldOrder get earlierOrder => ascOrder;

  /// Get db order statement to order from newer to older dates
  FieldOrder get laterOrder => descOrder;

  /// Get db statement to check if this value more than another date,
  ///
  /// [other] may be [DateTime] object or [DateTimeField]
  ConditionQuery moreThan(dynamic other) {
    return ConditionQuery(operatorString: '>', before: this, after: other);
  }

  /// Get db statement to check if this value less than another date,
  ///
  /// [other] may be [DateTime] object or [DateTimeField]
  ConditionQuery lessThan(dynamic other) {
    return ConditionQuery(operatorString: '<', before: this, after: other);
  }

  /// Get db statement to check if this value more than or equal another date,
  ///
  /// [other] may be [DateTime] object or [DateTimeField]
  ConditionQuery moreThanOrEquals(dynamic other) {
    return ConditionQuery(operatorString: '>=', before: this, after: other);
  }

  /// Get db statement to check if this value less than or equal another date,
  ///
  /// [other] may be [DateTime] object or [DateTimeField]
  ConditionQuery lessThanOrEquals(dynamic other) {
    return ConditionQuery(operatorString: '<=', before: this, after: other);
  }

  /// Get db statement to check if this value more than another date,
  ///
  /// [other] may be [DateTime] object or [DateTimeField]
  ConditionQuery operator >(dynamic other) => moreThan(other);

  /// Get db statement to check if this value more than or equal another date,
  ///
  /// [other] may be [DateTime] object or [DateTimeField]
  ConditionQuery operator >=(dynamic other) => moreThanOrEquals(other);

  /// Get db statement to check if this value less than another date,
  ///
  /// [other] may be [DateTime] object or [DateTimeField]
  ConditionQuery operator <(dynamic other) => lessThan(other);

  /// Get db statement to check if this value less than or equal another date,
  ///
  /// [other] may be [DateTime] object or [DateTimeField]
  ConditionQuery operator <=(dynamic other) => lessThanOrEquals(other);

  /// Get db statement to check if this value less than another date,
  ///
  /// [other] may be [DateTime] object or [DateTimeField]
  ConditionQuery between(dynamic min, dynamic max) {
    DbFunctions.assertDateTimeStringsValues([min, max]);
    var q = ConditionQuery();
    String qString = '(${buildQuery()} BETWEEN ';
    qString += (min is DateTimeField) ? min.buildQuery() : '?';
    qString += ' AND ';
    qString += (max is DateTimeField) ? max.buildQuery() : '?';
    qString += ')';
    q.queryBuilder = () => qString;
    q.parametersBuilder = () => [
          ...getParameters(),
          if (min is NumField)
            ...min.getParameters()
          else
            (min as DateTime).toString(),
          if (max is NumField)
            ...max.getParameters()
          else
            (max as DateTime).toString()
        ];
    return q;
  }

  /// Get [IntField] with value of this field year component.
  IntField get dayOfYear => _componentAsInteger('j');

  /// Get [IntField] with value of this field fractional second component.
  IntField get fractionalSecond => _componentAsInteger('f');

  /// Get [IntField] with value of this field hour component.
  IntField get hour => _componentAsInteger('H');

  /// Get [IntField] with value of this field minute component.
  IntField get minute => _componentAsInteger('M');

  /// Get [IntField] with value of this field second component.
  IntField get second => _componentAsInteger('S');

  /// Get [IntField] with value of this field seconds from Epoch.
  IntField get secondFromEpoch => _componentAsInteger('s');

  /// Get [IntField] with value of this field day of week.
  IntField get dayOfWeek => _componentAsInteger('w');

  /// Get [IntField] with value of this field week of year.
  IntField get weekOfYear => _componentAsInteger('W');

  /// Get [IntField] with value of this field julian day.
  IntField get julianDay => _componentAsInteger('J');

  /// Get [IntField] with value of this field day component.
  ///
  /// In another words `day of month`
  IntField get day => _componentAsInteger('DAY');

  /// Get [IntField] with value of this field month component.
  IntField get month => _componentAsInteger('MONTH');

  /// Get [IntField] with value of this field year component.
  IntField get year => _componentAsInteger('YEAR');

  IntField _componentAsInteger(String functionName) {
    var result = IntField();
    result.queryBuilder = () => "$functionName(${buildQuery()})";
    result.parametersBuilder = () => [...getParameters()];
    return result;
  }

  /// Get db statement to check weather this field has same day and month parts of another [DateTime] object.
  ConditionQuery isSameDayAndMonth(DateTime d) {
    return day.equals(d.day) & month.equals(d.month);
  }

  @override
  get dbValue => value?.toUtc();

  @override
  set dbValue(dynamic v) {
    value = v == null
        ? null
        : v is mysql.Blob
            ? DateTime.parse(v.toString())
            : null;
  }

  @override
  String get columnDefinition {
    String result = '$columnName TEXT';
    if (notNull == true) result += ' NOT NULL';
    if (isUnique == true) result += ' UNIQUE';
    return result;
  }

  /// Get the db date part of this value.
  DateTimeField get datePart {
    var result = DateTimeField();
    result.queryBuilder = () => "DATE(${buildQuery()})";
    result.parametersBuilder = () => getParameters();
    return result;
  }

  /// Get a statement to check weather now has same day and month of this value.
  ConditionQuery isBirthday() {
    var now = DateTimeField.now;
    var result = ConditionQuery();
    result.queryBuilder =
        () => (day.equals(now.day) & month.equals(now.month)).buildQuery();
    result.parametersBuilder = () => getParameters();
    return result;
  }

  /// Get a statement to check weather now has same date part of this value.
  ConditionQuery isSameDatePart(DateTime d) {
    var result = ConditionQuery();
    result.queryBuilder = () =>
        (day.equals(d.day) & month.equals(d.month) & year.equals(d.year))
            .buildQuery();
    result.parametersBuilder = () => getParameters();
    return result;
  }

  /// Get an [IntField] with age calculated.
  IntField get age {
    var result = IntField();
    result.queryBuilder = () =>
        "(strftime('%Y', 'now') - strftime('%Y', ${buildQuery()})) - (strftime('%m-%d', 'now') < strftime('%m-%d', ${buildQuery()}))";
    result.parametersBuilder = () => getParameters();
    return result;
  }

  /// Get the db time part of this value.
  DateTimeField get timePart {
    var result = DateTimeField();
    result.queryBuilder = () => "TIME(${buildQuery()})";
    result.parametersBuilder = () => getParameters();
    return result;
  }

  /// Get a [DateTimeField] with `now` db representation.
  static DateTimeField get now {
    var result = DateTimeField();
    result.queryBuilder = () => "DATETIME('now')";
    result.parametersBuilder = () => [];
    return result;
  }
}
