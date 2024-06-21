part of '../../quds_mysql.dart';

/// A string db field representation.
class StringField extends FieldWithValue<String> {
  /// Create an instance of [StringField]
  StringField(
      {String? columnName,
      bool? notNull,
      bool? isUnique,
      String? jsonMapName,
      String? defaultValue})
      : super(columnName,
            notNull: notNull,
            isUnique: isUnique,
            jsonMapName: jsonMapName,
            jsonMapType: String) {
    value = defaultValue;
  }

  /// Get string db value with `LOWER()` function applied.
  StringField toLowerCase() {
    var result = StringField();
    result.queryBuilder = () => 'LOWER(${buildQuery()})';
    result.parametersBuilder = () => getParameters();
    return result;
  }

  /// Get string db value with `UPPER()` function applied.
  StringField toUpperCase() {
    var result = StringField();
    result.queryBuilder = () => 'UPPER(${buildQuery()})';
    result.parametersBuilder = () => getParameters();
    return result;
  }

  /// Get string db value with `SUBSTR()` function applied.
  StringField subString(int startIndex, int length) {
    var result = StringField();
    result.queryBuilder = () => 'SUBSTR(${buildQuery()},$startIndex,$length)';
    result.parametersBuilder = () => getParameters();
    return result;
  }

  /// Get a db int field with first character unicode.
  IntField unicodeOfFirstCharacter() {
    var result = IntField();
    result.queryBuilder = () => 'UNICODE(${buildQuery()})';
    result.parametersBuilder = () => getParameters();
    return result;
  }

  /// Get db string field with replaced string.
  ///
  /// [pattern] is the string to be replaced.
  ///
  /// [replacement] is the string to replace the [pattern], [replacement] may be [StringField] or [String]
  StringField replace(String pattern, dynamic replacement) {
    assert(replacement is String || replacement is StringField);

    var result = StringField();
    result.queryBuilder = () => replacement is StringField
        ? 'REPLACE(${buildQuery()},?,${replacement.buildQuery()})'
        : 'REPLACE(${buildQuery()},?,?)';
    result.parametersBuilder = () => getParameters()
      ..addAll([pattern, if (replacement is String) replacement]);
    return result;
  }

  /// Get db int field with the starct index of contained [str],
  /// if not contained, returned field value will be -1.
  IntField indexOf(dynamic str) {
    assert(str is String || str is StringField);

    var result = IntField();
    result.queryBuilder = () => str is StringField
        ? 'INSTR(${buildQuery()},${str.buildQuery()})'
        : 'INSTR(${buildQuery()},?)';
    result.parametersBuilder =
        () => getParameters()..addAll([if (str is String) str]);
    return result;
  }

  StringField _buildTrimFunction(String trimName, String? ch) {
    var result = StringField();
    result.queryBuilder = () => (ch != null && ch.isNotEmpty)
        ? '$trimName(${buildQuery()},?)'
        : '$trimName(${buildQuery()})';
    result.parametersBuilder =
        () => getParameters()..addAll([if ((ch != null && ch.isNotEmpty)) ch]);
    return result;
  }

  /// Get db string field with white spaces removed from left and right.
  StringField trim([String? ch]) => _buildTrimFunction('TRIM', ch);

  /// Get db string field with white spaces removed from left.
  StringField trimLeft([String? ch]) => _buildTrimFunction('LTRIM', ch);

  /// Get db string field with white spaces removed from right.
  StringField trimRight([String? ch]) => _buildTrimFunction('RTRIM', ch);

  /// Get db int field with the length of this string content.
  IntField get length {
    var result = IntField();
    result.queryBuilder = () => 'LENGTH(${buildQuery()})';
    result.parametersBuilder = () => getParameters();
    return result;
  }

  /// Concat this string db value with [other],
  /// [other] may be [StringField] or [String]
  StringField concat(dynamic other) {
    assert(other is String || other is StringField);

    var result = StringField();
    result.queryBuilder = () =>
        '(${buildQuery()} || ' +
        (other is StringField ? other.buildQuery() : '?') +
        ')';
    result.parametersBuilder = () => getParameters()
      ..addAll(
          [if (other is StringField) ...(other.getParameters()) else other]);

    return result;
  }

  /// Concat this string db value with [other],
  /// [other] may be [StringField] or [String]
  StringField operator +(other) => concat(other);

  /// Get sql statement to check this value if contains [text].
  ConditionQuery contains(String text) {
    return ConditionQuery(
        before: this, after: '%$text%', operatorString: 'LIKE');
  }

  /// Get sql statement to check this value if contained in [text].
  ConditionQuery containedIn(String text) {
    return locateIn(text).moreThan(0);
  }

  /// Get the position of this field in [text]
  IntField locateIn(String text) {
    var result = IntField();
    result.queryBuilder = () => 'LOCATE(${buildQuery()},?)';
    result.parametersBuilder = () => [...getParameters(), text];
    return result;
  }

  /// Get sql statement to check this value if ends with [text].
  ConditionQuery endsWith(String text) {
    return ConditionQuery(
        before: this, after: '%$text', operatorString: 'LIKE');
  }

  /// Get sql statement to check this value if start with [text].
  ConditionQuery startsWith(String text) {
    return ConditionQuery(
        before: this, after: '$text%', operatorString: 'LIKE');
  }

  /// Get sql statement to order this field by its values lengths `descending`.
  FieldOrder get longerOrder {
    FieldOrder result = FieldOrder();
    result.queryBuilder = () => 'LENGTH(' + buildQuery() + ') DESC';
    result.parametersBuilder = () => getParameters();
    return result;
  }

  /// Get sql statement to order this field by its values lengths `ascending`.
  FieldOrder get shorterOrder {
    FieldOrder result = FieldOrder();
    result.queryBuilder = () => 'LENGTH(' + buildQuery() + ') ASC';
    result.parametersBuilder = () => getParameters();
    return result;
  }

  /// Get a sql statement representation that check weather this value is more than [other].
  ///
  /// [other] may be of the following:
  ///
  ///  [StringField] - [String]
  ConditionQuery moreThan(dynamic other) {
    return ConditionQuery(operatorString: '>', before: this, after: other);
  }

  /// Get a sql statement representation that check weather this value is less than [other].
  ///
  /// [other] may be of the following:
  ///
  ///  [StringField] - [String]
  ConditionQuery lessThan(dynamic other) {
    return ConditionQuery(operatorString: '<', before: this, after: other);
  }

  /// Get a sql statement representation that check weather this value is between two values.
  ///
  /// [min],[max] may be of the following:
  ///
  ///  [StringField] - [String]
  ConditionQuery between(min, max) {
    DbFunctions.assertNumValues([min, max]);
    var q = ConditionQuery();
    String qString = '(${buildQuery()} BETWEEN ';
    qString += (min is NumField) ? min.buildQuery() : '?';
    qString += ' AND ';
    qString += (max is NumField) ? max.buildQuery() : '?';
    qString += ')';
    q.queryBuilder = () => qString;
    q.parametersBuilder = () => [
          ...getParameters(),
          if (min is StringField) ...min.getParameters() else min,
          if (max is StringField) ...max.getParameters() else max
        ];
    return q;
  }

  /// Get a sql statement representation that check weather this value is more than or equal [other].
  ///
  /// [other] may be of the following:
  ///
  ///  [StringField] - [String]
  ConditionQuery moreThanOrEquals(dynamic other) {
    return ConditionQuery(operatorString: '>=', before: this, after: other);
  }

  /// Get a sql statement representation that check weather this value is less than or equal [other].
  ///
  /// [other] may be of the following:
  ///
  ///  [StringField] - [String]
  ConditionQuery lessThanOrEquals(dynamic other) {
    return ConditionQuery(operatorString: '<=', before: this, after: other);
  }

  /// Get a sql statement representation that check weather this value is more than [other].
  ///
  /// [other] may be of the following:
  ///
  ///  [StringField] - [String]
  ConditionQuery operator >(dynamic other) => moreThan(other);

  /// Get a sql statement representation that check weather this value is more than or equal [other].
  ///
  /// [other] may be of the following:
  ///
  ///  [StringField] - [String]
  ConditionQuery operator >=(dynamic other) => moreThanOrEquals(other);

  /// Get a sql statement representation that check weather this value is less than [other].
  ///
  /// [other] may be of the following:
  ///
  ///  [StringField] - [String]
  ConditionQuery operator <(dynamic other) => lessThan(other);

  /// Get a sql statement representation that check weather this value is less than or equal [other].
  ///
  /// [other] may be of the following:
  ///
  ///  [StringField] - [String]
  ConditionQuery operator <=(dynamic other) => lessThanOrEquals(other);
}
