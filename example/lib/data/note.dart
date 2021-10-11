import 'package:quds_mysql/quds_mysql.dart';

class Note extends DbModel {
  var title = StringField(columnName: 'title');
  var importance = IntField(columnName: 'importance');
  var isRead = BoolField(columnName: 'isRead');
  @override
  List<FieldWithValue>? getFields() => [title, importance, isRead];
}
