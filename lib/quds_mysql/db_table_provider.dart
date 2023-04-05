// ignore_for_file: avoid_print

part of '../quds_mysql.dart';

/// Represents a table in db with CRUD and other helping functions.
abstract class DbRepository<T extends DbModel> {
  mysql.ConnectionSettings? connectionSettings;
  String? _specialDb;

  /// Get the name of this table.
  String get tableName;

  /// Get the id column name in this table.
  String get idColumnName => 'id';

  String get _createStatement {
    T tempEntry = _createInstance();

    String cS = 'CREATE TABLE IF NOT EXISTS ' + tableName;
    cS += '(';
    tempEntry.getAllFields().forEach((e) {
      cS += e!.columnDefinition + ',';
    });

    //Remove last ','
    cS = cS.removeLastComma();

    cS += ')';
    return cS;
  }

  late mysql.MySqlConnection _connection;
  bool _databaseInitialized = false;

  /// Initialize the database, check this table, create an modify as required.
  Future<mysql.MySqlConnection> _initializeConnection() async {
    if (_databaseInitialized) return _connection;

    _connection = await DbHelper._checkDbAndTable(this);

    _databaseInitialized = true;
    return _connection;
  }

  /// Close this table database. Cannot be accessed anymore
  Future<bool> closeDB() async {
    try {
      if (_databaseInitialized /*&& database.isOpen*/) {
        await _connection.close();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createTable() async =>
      _checkAndCreateTableIfNotExist(await _initializeConnection());

  Future<bool> _checkAndCreateTableIfNotExist(mysql.MySqlConnection db) async {
    try {
      await db.query(_createStatement);
      return true;
    } catch (e) {
      print('SqlException: $e');
      return false;
    }
  }

  Future<bool> _checkEachColumn(mysql.MySqlConnection db) async {
    var tableInfo =
        await db.query('DESCRIBE ${_specialDb ?? DbHelper.mainDb}.$tableName');

    var foundColumns = <String, String>{};
    for (var m in tableInfo) {
      var v = m.values!.toList();
      foundColumns[v[0].toString().toLowerCase()] = '${v[1]}';
    }

    T tempEntry = _createInstance();
    var fields = tempEntry.getAllFields();
    for (var f in fields) {
      if (!foundColumns.containsKey(f!.columnName?.toLowerCase())) {
        //Missed key
        await db.query('ALTER TABLE $tableName\n'
            'ADD ${f.columnDefinition}');
      }
    }
    return true;
  }

  Future<bool> dropTable() async {
    var con = await _initializeConnection();
    await con.query('DROP TABLE $tableName;');
    return true;
  }

  String _insertSqlGenerator(Map<String, dynamic> map, [bool withDef = true]) {
    StringBuffer sqlStatement = StringBuffer();
    if (withDef) {
      sqlStatement.write('INSERT INTO $tableName (');
      sqlStatement.writeAll(map.keys, ',');

      sqlStatement.write(')');
      sqlStatement.write(' VALUES ');
    }
    sqlStatement.write('(');
    sqlStatement.writeAll([for (int i = 0; i < map.length; i++) '?'], ',');

    sqlStatement.write(')');
    return sqlStatement.toString();
  }

//CRUD Methods
  /// Insert new entry to this table.
  Future<bool> insertEntry(T entry) async {
    try {
      await entry.beforeSave(true);

      int result = 0;
      var con = await _initializeConnection();
      var map = <String, dynamic>{};
      entry.creationTime.value = DateTime.now();
      entry.modificationTime.value = DateTime.now();
      _setEntryToMap(entry, map);
      String sqlStatement = _insertSqlGenerator(map);
      result = (await con.query(sqlStatement, map.values.toList())).insertId!;
      entry.id.value = result;
      await entry.afterSave(true);
      _fireChangeListners(EntryChangeType.Insertion, entry);
      return result > 0;
    } catch (e) {
      return false;
    }
  }

  /// Insert a collection of [entries] to this table.
  Future<void> insertCollection(List<T> entries) async {
    if (entries.isEmpty) return;
    // try {
    var con = await _initializeConnection();
    var model = entries.first;
    var now = DateTime.now();
    for (var e in entries) {
      e.creationTime.value = now;
      e.modificationTime.value = now;
    }
    var modelMap = <String, Object?>{};

    for (var e in entries) {
      await e.beforeSave(true);
    }

    _setEntryToMap(model, modelMap);
    List<Object?> values = modelMap.values.toList();
    var sql = StringBuffer(_insertSqlGenerator(modelMap));
    for (int i = 1; i < entries.length; i++) {
      var map = <String, Object?>{};
      var e = entries[i];
      _setEntryToMap(e, map);
      values.addAll(map.values.toList());
      sql.write(', ${_insertSqlGenerator(map, false)}');
    }
    var currId = (await con.query(sql.toString(), values)).insertId!;

    for (var e in entries) {
      e.id.value = currId++;
      await e.afterSave(true);
      _fireChangeListners(EntryChangeType.Insertion, e);
    }
  }

  String _updateSqlGenerator(Map<String, dynamic> map, String where) {
    map.remove(idColumnName);
    String sqlStatement = 'UPDATE $tableName SET ';
    for (var m in map.entries) {
      sqlStatement += '${m.key}=?,';
    }
    sqlStatement = sqlStatement.substring(0, sqlStatement.length - 1);
    sqlStatement += ' WHERE $where;';
    return sqlStatement;
  }

  /// Update a collection of [entries] in this table.
  ///
  /// The considerable identity here is [DbModel.id]
  Future<void> updateCollectionById(List<T> entries) async {
    if (entries.isEmpty) return;
    try {
      var con = await _initializeConnection();
      await con.transaction((con) async {
        for (var entry in entries) {
          await entry.beforeSave(true);
          var map = <String, Object?>{};
          entry.modificationTime.value = DateTime.now();
          _setEntryToMap(entry, map);
          map.removeWhere((key, value) => value == null);

          String sqlStatement =
              _updateSqlGenerator(map, '$idColumnName=${entry.id.value}');
          await con.query(sqlStatement, map.values.map((e) => e!).toList());

          await entry.afterSave(true);
          _fireChangeListners(EntryChangeType.Modification, entry);
        }
      });
    } catch (e) {
      return;
    }
  }

  /// Insert a collection of [entries] using a transaction.
  Future<bool> insertCollectionInTransaction(List<T> entries) async {
    if (entries.isEmpty) return true;
    try {
      await insertCollection(entries);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update an entry in this table.
  Future<bool> updateEntry(T entry) async {
    if (entry.id.value == null) return await insertEntry(entry);

    try {
      await entry.beforeSave(false);
      var con = await _initializeConnection();
      var map = <String, dynamic>{};
      entry.modificationTime.value = DateTime.now();
      _setEntryToMap(entry, map);
      var sql = _updateSqlGenerator(map, "$idColumnName=${entry.id.value}");
      await con.query(sql, map.values.toList());
      await entry.afterSave(false);
      _fireChangeListners(EntryChangeType.Modification, entry);
      return true;
    } catch (e) {
      return false;
    }
  }

  void _setEntryToMap(T entry, Map<String, Object?> map) {
    var fields = entry.getAllFields();
    for (var f in fields) {
      map[f!.columnName!] = f.dbValue;
    }
  }

  final T Function() _factoryOfT;

  /// Create an instance of DbRepository
  DbRepository(this._factoryOfT, {String? specialDb, this.connectionSettings}) {
    _specialDb = specialDb;
  }
  T _createInstance() {
    T result = _factoryOfT();
    result.getAllFields().forEach((e) {
      e!._tableName = tableName;
    });
    return result;
  }

  T _entryFromMap(mysql.ResultRow r) {
    var rMap = r;
    T e = _createInstance();
    var fields = e.getAllFields();

    for (var e in rMap.fields.entries) {
      FieldWithValue? f = fields.firstWhere(
          (element) => element?.columnName == e.key,
          orElse: () => null);
      if (f != null) {
        f.setValue(e.value);
      }
    }
    return e;
  }

  /// Generate an entry using json map.
  T entryFromMap(mysql.ResultRow r) => _entryFromMap(r);

  /// Make query with pagination.
  Future<DataPageQueryResult<T>> loadAllEntriesByPaging(
      {required DataPageQuery<T> pageQuery,
      ConditionQuery Function(T model)? where,
      List<FieldOrder> Function(T model)? orderBy,
      List<FieldWithValue> Function(T model)? desiredFields}) async {
    int count = await countEntries(where: where);
    return DataPageQueryResult<T>(
        count,
        await select(
            limit: pageQuery.resultsPerPage,
            offset: (pageQuery.page - 1) * pageQuery.resultsPerPage,
            where: where,
            orderBy: orderBy,
            desiredFields: desiredFields),
        pageQuery.page,
        pageQuery.resultsPerPage);
  }

  /// Get an entry by its id as key.
  Future<T?> loadEntryById(int id) async {
    var result = (await select(where: (m) => m.id.equals(id), limit: 1));
    return result.isNotEmpty ? result.first : null;
  }

  /// Count the entries of this table with [where] if required.
  Future<int> countEntries({
    ConditionQuery Function(T model)? where,
  }) async {
    return await queryFirstValue((s) => s.id.count(), where: where);
  }

  /// Delete an entry from this table.
  Future<int> deleteEntry(T entry) async {
    await entry.beforeDelete();

    int result = 0;
    var con = await _initializeConnection();
    var affectedRows = (await con.query(
            'DELETE FROM $tableName WHERE $idColumnName=${entry.id.value}'))
        .affectedRows;
    result = affectedRows != null && affectedRows > 0 ? 1 : 0;
    if (result == 1) {
      await entry.afterDelete();
      _fireChangeListners(EntryChangeType.Deletion, entry);
    }
    return result;
  }

  /// Remove all entries in this table permenantly.
  Future deleteAllEntries({bool withRelatedItems = true}) async {
    await delete(withRelatedItems: withRelatedItems);
  }

  /// Get a collection of entries from this table using thier ids.
  Future<List<T>> getEntriesByIds(List<int> ids) async {
    return await select(where: (r) => r.id.inCollection(ids));
  }

  /// Get a random entry from this table.
  Future<T?> getRandomEntry({ConditionQuery Function(T model)? where}) async {
    return selectFirst(where: where, orderBy: (s) => [s.id.randomOrder]);
  }

  bool _processing = false;
  final List<Function()> _watchers = [];

  /// Set this provider as processing some operation.
  set isProcessing(bool value) {
    if (value != _processing) {
      _processing = value;
      _callWatchers();
    }
  }

  /// Get weather this provider is processing an operation.
  bool get isProcessing => _processing;

  void _callWatchers() {
    for (var w in _watchers) {
      w.call();
    }
  }

  /// Add a listener that be called when some change occured.
  void addListener(Function() listener) => _watchers.add(listener);

  /// Remove a change listner.
  void removeListener(Function() listener) => _watchers.remove(listener);

  /// Get [entries] from the table that match [where] condition.
  Future<List<T>> selectWhere(ConditionQuery Function(T e) where,
          {List<FieldOrder> Function(T e)? orderBy,
          int? offset,
          int? limit,
          List<FieldWithValue> Function(T e)? desiredFields}) async =>
      select(
          where: where,
          orderBy: orderBy,
          offset: offset,
          limit: limit,
          desiredFields: desiredFields);

  /// Get [entries] from the table.
  Future<List<T>> select(
      {ConditionQuery Function(T e)? where,
      List<FieldOrder> Function(T e)? orderBy,
      int? offset,
      int? limit,
      List<FieldWithValue> Function(T e)? desiredFields}) async {
    List<T> result = [];

    for (var r in await query(
        queries: desiredFields,
        where: where,
        orderBy: orderBy,
        offset: offset,
        limit: limit)) {
      T entry = _entryFromMap(r);
      result.add(entry);
    }
    return result;
  }

  /// Query some rows with specified fields from this table.
  Future query(
      {List<QueryPart> Function(T e)? queries,
      ConditionQuery Function(T e)? where,
      ConditionQuery Function(T e)? having,
      int? offset,
      int? limit,
      List<FieldWithValue> Function(T e)? groupBy,
      List<FieldOrder> Function(T e)? orderBy}) async {
    List<QueryPart> Function(T a, DbModel? b)? quers;
    if (queries != null) {
      quers = (a, b) => queries.call(a).map((e) => e).toList();
    }
    return _query(
        queries: quers,
        where: where,
        offset: offset,
        having: having,
        limit: limit,
        groupBy: groupBy,
        orderBy: orderBy);
  }

  Future _queryJoin<O extends DbModel>(
      {List<QueryPart> Function(T a, O? b)? queries,
      Function(T a, O b)? joinCondition,
      DbRepository<O>? otherJoinTable,
      String? joinType,
      ConditionQuery Function(T e)? where,
      int? offset,
      int? limit,
      List<FieldWithValue> Function(T e)? groupBy,
      List<FieldOrder> Function(T e)? orderBy}) async {
    return _query(
        queries: queries,
        joinCondition: joinCondition,
        joinType: joinType,
        otherJoinTable: otherJoinTable,
        where: where,
        offset: offset,
        limit: limit,
        groupBy: groupBy,
        orderBy: orderBy);
  }

  /// Apply inner join.
  Future innerJoinQuery<O extends DbModel>(
      List<QueryPart> Function(T a, O? b) queries,
      ConditionQuery Function(T a, O? b) joinCondition,
      DbRepository<O> otherJoinProvider,
      ConditionQuery Function(T e) where,
      int offset,
      int limit,
      List<FieldWithValue> Function(T e) groupBy,
      List<FieldOrder> Function(T e) orderBy) async {
    return _queryJoin(
        queries: queries,
        joinCondition: joinCondition,
        joinType: 'INNER',
        otherJoinTable: otherJoinProvider,
        where: where,
        offset: offset,
        limit: limit,
        groupBy: groupBy,
        orderBy: orderBy);
  }

  /// Apply left join.
  Future leftJoinQuery<O extends DbModel>(
      List<QueryPart> Function(T a, O? b) queries,
      ConditionQuery Function(T a, O b) joinCondition,
      DbRepository<O> otherJoinProvider,
      ConditionQuery Function(T e) where,
      int offset,
      int limit,
      List<FieldWithValue> Function(T e) groupBy,
      List<FieldOrder> Function(T e) orderBy) async {
    return _queryJoin(
        queries: queries,
        joinCondition: joinCondition,
        joinType: 'LEFT',
        otherJoinTable: otherJoinProvider,
        where: where,
        offset: offset,
        limit: limit,
        groupBy: groupBy,
        orderBy: orderBy);
  }

  Future _query<O extends DbModel>(
      {List<QueryPart> Function(T a, O? b)? queries,
      DbRepository<O>? otherJoinTable,
      Function(T a, O b)? joinCondition,
      String? joinType,
      ConditionQuery Function(T e)? where,
      ConditionQuery Function(T e)? having,
      int? offset,
      int? limit,
      List<FieldWithValue> Function(T e)? groupBy,
      List<FieldOrder> Function(T e)? orderBy}) async {
    var a = _createInstance();
    var b = otherJoinTable?._createInstance();
    String queryString = '';
    List queryArgs = [];
    var queriesResults = queries == null ? null : queries(a, b);

    if (queriesResults == null || queriesResults.isEmpty) {
      queryString = '*';
    } else {
      for (var element in queriesResults) {
        var q = element.buildQuery();
        queryString += q + ',';
        queryArgs.addAll(element.getParameters());
      }

      queryString = queryString.removeLastComma();
    }
    queryString = 'SELECT $queryString FROM $tableName';

    if (joinCondition != null && joinType != null && otherJoinTable != null) {
      String joinString = ' $joinType JOIN ${otherJoinTable.tableName}';

      var abQuery = joinCondition(a, b!);
      joinString += ' ON';
      joinString += abQuery.buildQuery();
      queryString += ' $joinString ';
      queryArgs.addAll(abQuery.getParameters());
    }
    String? whereString;
    List? whereArgs;
    ConditionQuery whereConditions;
    if (where != null) {
      whereConditions = where(a);
      whereString = whereConditions.buildQuery();
      whereArgs = whereConditions.getParameters();
    }

    if (whereString != null) queryString += ' WHERE $whereString';
    if (whereArgs != null) queryArgs.addAll(whereArgs);

    String groupByText;
    if (groupBy != null) {
      groupByText = '';
      var goupByQueries = groupBy(a).toList();
      groupByText = goupByQueries
          .map((e) => e.buildQuery())
          .toList()
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '');

      for (var element in goupByQueries) {
        queryArgs.addAll(element.getParameters());
      }

      queryString += ' GROUP BY $groupByText';
      if (having != null) {
        var havingQuery = having(a);
        queryString += ' HAVING ' + havingQuery.buildQuery();
        queryArgs.addAll(havingQuery.getParameters());
      }
    }
    String? orderByText;
    if (orderBy != null) {
      orderByText = '';
      var orderQueries = orderBy(a).toList();
      orderByText = orderQueries
          .map((e) => e.buildQuery())
          .toList()
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '');

      for (var element in orderQueries) {
        queryArgs.addAll(element.getParameters());
      }
    }
    if (orderByText != null) queryString += ' ORDER BY $orderByText';

    if (limit != null) queryString += ' LIMIT $limit';
    if (offset != null) queryString += ' OFFSET $offset';
    var con = await _initializeConnection();
    try {
      var results = await con.query(queryString, queryArgs);

      var r = results.toList();
      return r;
    } catch (e) {
      if (e.toString() != 'Bad state: Cannot write to socket, it is closed') {
        throw Exception({
          'original_exception': e,
          'query_text': queryString,
          'query_args': queryArgs
        });
      }
      await closeDB();
      _connection = await DbHelper._checkDbAndTable(this, forceReconnect: true);
      return await _query<O>(
        queries: queries,
        otherJoinTable: otherJoinTable,
        joinCondition: joinCondition,
        joinType: joinType,
        where: where,
        having: having,
        offset: offset,
        groupBy: groupBy,
        orderBy: orderBy,
      );
    }
  }

  /// Delete entries from this table,
  /// if [where] is null it will delete every entry, otherwise it delete only matching entries.
  Future delete({
    bool withRelatedItems = true,
    ConditionQuery Function(T e)? where,
  }) async {
    if (!withRelatedItems) {
      if (where != null) {
        var ids = (await select(where: where, desiredFields: (s) => [s.id]))
            .map((e) => e.id.value!);

        int result = 0;
        var con = await _initializeConnection();
        var affectedRows = (await con.query(
                'DELETE FROM $tableName WHERE $idColumnName IN ?', [ids]))
            .affectedRows;
        result = affectedRows != null && affectedRows > 0 ? 1 : 0;
        return result;
      } else {
        int result = 0;
        var con = await _initializeConnection();
        var affectedRows =
            (await con.query('DELETE FROM $tableName')).affectedRows;
        result = affectedRows != null && affectedRows > 0 ? 1 : 0;
        return result;
      }
    } else {
      for (var entry in await select(where: where)) {
        await deleteEntry(entry);
      }
    }
  }

  /// Get first row first field value
  Future queryFirstValue(QueryPart Function(T model) query,
      {ConditionQuery Function(T model)? where,
      List<FieldOrder> Function(T model)? orderBy}) async {
    // assert(query != null);
    var result = await this.query(
        queries: (model) => [query.call(model)],
        where: where,
        limit: 1,
        orderBy: orderBy);

    if (result != null) {
      if (result is List) {
        if (result.isNotEmpty) if (result[0] != null) return result[0].first;
      }
    }
    return null;
  }

  /// Get first entry matching the query.
  Future<T?> selectFirst(
      {ConditionQuery Function(T model)? where,
      List<FieldOrder> Function(T model)? orderBy,
      int? offset,
      List<FieldWithValue> Function(T model)? desiredFields}) async {
    var result = (await select(
        where: where, orderBy: orderBy, limit: 1, offset: offset));
    return result.isNotEmpty ? result.first : null;
  }

  /// Get first entry matching [where].
  Future<T?> selectFirstWhere(ConditionQuery Function(T model) where,
      {List<FieldOrder> Function(T model)? orderBy,
      int? offset,
      List<FieldWithValue> Function(T model)? desiredFields}) async {
    var result = (await select(
        where: where, orderBy: orderBy, limit: 1, offset: offset));
    return result.isNotEmpty ? result.first : null;
  }

  final List<Function(EntryChangeType changeType, T entry)> _entryListners = [];

  /// Add a listener that be called when some [EntryChangeType] occured.
  void addEntryChangeListner(
          Function(EntryChangeType changeType, T entry) lisnter) =>
      _entryListners.add(lisnter);

  /// rempve a listener from change listners
  void removeEntryChangeListner(
          Function(EntryChangeType changeType, T entry) lisnter) =>
      _entryListners.remove(lisnter);

  void _fireChangeListners(EntryChangeType type, T entry) {
    for (var listner in _entryListners) {
      listner.call(type, entry);
    }
  }
}
