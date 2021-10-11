part of '../../quds_mysql.dart';

/// An [IntField] with id field constrains
class IdField extends IntField {
  /// Create an instance of [IdField]
  IdField([String columnName = 'id'])
      : super(
          unsigned: true,
          autoIncrement: true,
          primaryKey: true,
          columnName: columnName,
        );
}
