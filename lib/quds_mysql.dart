/// An expansion package that simplifies creating databases and tables, crud operations, queries with modelization using mysql1
library quds_mysql;

// import 'dart:ffi';
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';
import 'dart:typed_data';
import 'dart:core';
import 'package:mysql1/mysql1.dart' as mysql;

// library quds_db;
part 'quds_mysql/data_page_query.dart';
part 'quds_mysql/data_page_query_result.dart';
part 'quds_mysql/db_functions.dart';
part 'quds_mysql/db_helper.dart';
part 'quds_mysql/db_model.dart';
part 'quds_mysql/db_table_provider.dart';
part 'quds_mysql/entry_change_type.dart';

//Query parts
part 'quds_mysql/query_parts/query_part.dart';
part 'quds_mysql/query_parts/condition.dart';
part 'quds_mysql/query_parts/field_with_value.dart';
part 'quds_mysql/query_parts/order_field.dart';
part 'quds_mysql/query_parts/operator_query.dart';

//Db fields
part 'quds_mysql/db_fields/enum_field.dart';
part 'quds_mysql/db_fields/blob_field.dart';
part 'quds_mysql/db_fields/bool_field.dart';
// part 'quds_mysql/db_fields/datetime_field.dart';
part 'quds_mysql/db_fields/double_field.dart';
part 'quds_mysql/db_fields/int_field.dart';
part 'quds_mysql/db_fields/num_field.dart';
part 'quds_mysql/db_fields/string_field.dart';
part 'quds_mysql/db_fields/json_field.dart';
part 'quds_mysql/db_fields/id_field.dart';
part 'quds_mysql/db_fields/datetime_field.dart';
