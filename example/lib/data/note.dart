import 'package:quds_mysql/quds_mysql.dart';

class Note extends DbModel {
  var title = StringField(columnName: 'title');
  var importance = IntField(columnName: 'importance');
  var isRead = BoolField(columnName: 'isRead');
  var jsonArrayValues = ListField(columnName: 'jsonArrayValues');
  var jsonMap = JsonField(columnName: 'jsonMap');
  @override
  List<FieldWithValue>? getFields() =>
      [title, importance, isRead, jsonArrayValues, jsonMap];
}
