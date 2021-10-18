part of '../quds_mysql.dart';

bool _donationDisplayed = false;

/// Provide some helping methods for managing the database.
class DbHelper {
  /// To prevent creating instances of [DbHelper].
  DbHelper._();

  static final Map<String, List<Type>> _fieldType = {
    // 1 Byte
    'TINYINT': [Int8],
    // 2 Bytes
    'SMALLINT': [Int16],
    // 3 Bytes
    'MEDIUMINT': [],
    // 4 Bytes
    'INT': [Int32],
    // 8 Bytes
    'BIGINT': [int, Int64],
    // 'INTEGER ': [Uint16, Uint32, Uint64, Uint8],

    'TEXT': [String],
    'JSON': [Map, List, Object],
    'BOOLEAN': [
      bool,
    ],
    'DATETIME': [
      DateTime,
    ],
    'DOUBLE': [
      double,
      // Float,
    ],
    'BLOB': [Uint8List],
    'NUMERIC': [num]
  };

  /// Get the db field type name of dart native type.
  static String _getFieldTypeAffinity(Type type) {
    return _fieldType.keys
        .firstWhere((element) => _fieldType[element]!.contains(type));
  }

  /// Get a sql statement to joint operand like (+, >) with another field or value.
  static String buildQueryForOperand(dynamic v) =>
      v is QueryPart ? v.buildQuery() : '?';

  /// The main db path where all tables to be saved untill one is customized.
  static String mainDb = 'db';

  static String dbUser = 'root';
  static String? dbPassword;
  static String host = 'localhost';
  static int port = 3306;
  static bool useCompression = false;
  static bool useSSL = false;
  static int maxPacketSize = 16 * 1024 * 1024;
  static Duration timeout = const Duration(seconds: 30);
  static int characterSet = mysql.CharacterSet.UTF8MB4;

  static final Map<String, mysql.MySqlConnection> _connections = {};

  static bool _initialized = false;
  static Future<void> _initializeDb() async {
    if (_initialized) return;
    _initialized = true;

    if (!_donationDisplayed) {
      _donationDisplayed = true;
      log('_______________Quds MySql________________');
      log('Hi great developer!');
      log('Would you donate to Quds MySql developers team?\nIt will be great help to our team to continue the developement!');
      log('_____________Donation Link____________');
      log('https://www.paypal.com/donate?hosted_button_id=94Y2Q9LQR9XHS');
    }
  }

  /// Check [DbRepository] 's table in the db and create or modify as required.
  static Future<mysql.MySqlConnection> _checkDbAndTable(
      DbRepository dbProvider) async {
    await _initializeDb();
    var map = _connections;

    String dbName =
        (dbProvider._specialDb == null || dbProvider._specialDb!.trim().isEmpty)
            ? DbHelper.mainDb
            : dbProvider._specialDb!;
    String mapKey = dbName + '.' + dbProvider.tableName;

    if (map[mapKey] != null) return map[mapKey]!;

    var connection = await mysql.MySqlConnection.connect(
        dbProvider.connectionSettings ??
            mysql.ConnectionSettings(
                host: host,
                port: port,
                user: dbUser,
                password: dbPassword,
                db: mainDb,
                useCompression: useCompression,
                useSSL: useSSL,
                maxPacketSize: maxPacketSize,
                timeout: timeout,
                characterSet: characterSet));
    // initializeSupportFunctions(database);

    await _createTablesInDB(dbProvider, connection);
    map[mapKey] = connection;
    return connection;
  }

  /// Create [DbRepository] 's table in the db.
  static Future<bool> _createTablesInDB(
      DbRepository provider, mysql.MySqlConnection db) async {
    try {
      await provider._checkAndCreateTableIfNotExist(db);
      await provider._checkEachColumn(db);
      return true;
    } catch (e) {
      return false;
    }
  }

  static dynamic _getMapValue(dynamic value, Type returnType) {
    switch (returnType) {
      case int:
        return value is int
            ? value
            : value == null
                ? null
                : int.tryParse(value.toString());
      case double:
        return value is double
            ? value
            : value == null
                ? null
                : double.tryParse(value.toString());
      case num:
        return value is num
            ? value
            : value == null
                ? null
                : num.tryParse(value.toString());
      case DateTime:
        return value is DateTime
            ? value
            : value == null
                ? null
                : DateTime.tryParse(value.toString());
      case bool:
        return value is bool
            ? value
            : value == null
                ? null
                : ['true', '1'].contains(value.toString().toLowerCase().trim());
      case String:
        return value is String ? value : value?.toString();

      case Map:
        return value is Map
            ? value
            : value == null
                ? null
                : value is String
                    ? json.decode(value)
                    : null;

      case List:
        return value is List
            ? value
            : value == null
                ? null
                : value is String
                    ? json.decode(value)
                    : null;
    }
    return null;
  }

  /// Get dart native value of some db value.
  static getValueFromDbValue(Type type, Object? dbValue) {
    if (dbValue is mysql.Blob) dbValue = dbValue.toString();

    if (type == bool) return dbValue == null ? null : dbValue == 1;

    if (type == DateTime) {
      return dbValue == null ? null : DateTime.parse(dbValue.toString());
    }

    if (type == Map) {
      return dbValue == null ? null : json.decode(dbValue as String);
    }
    if (type == List) {
      return dbValue == null ? null : json.decode(dbValue as String);
    }
    return dbValue;
  }

  /// Get db value of some dart native value.
  static getDbValue(Object? value) {
    var type = value.runtimeType;
    if (type == bool) {
      return value == null
          ? null
          : value as bool
              ? 1
              : 0;
    }

    if (type == DateTime) {
      return (value as DateTime?)?.millisecondsSinceEpoch;
    }

    if (value is Map) return json.encode(value);
    if (value is List) return json.encode(value);

    return value;
  }
}
