import 'package:example/data/note.dart';
import 'package:quds_mysql/quds_mysql.dart' as my_db;
import 'package:quds_mysql/quds_mysql.dart';
import 'data/notes_repository.dart';

Future<void> runApp() async {
  my_db.DbHelper.mainDb = 'motors';
  var notesManager = NotesRepository();
  await notesManager.deleteAllEntries(withRelatedItems: false);
  var notes = [
    for (int i = 0; i < 1000; i++)
      Note()
        ..title.value = 'hi-$i'
        ..isRead.value = i % 2 == 0
        ..importance.value = 1
  ];
  await notesManager.insertCollection(notes);
  for (var n in notes) {
    n
      ..title.value = 'New title'
      ..jsonArrayValues.value = [1, '2']
      ..jsonMap.value = {'hi': 1, 'done': true};
  }
  await notesManager.updateCollectionById(notes);

  var selectNotes = {
    await notesManager.selectWhere((e) => e.importance.equals(1))
  };

  print(selectNotes.length);

  var std = await StudentsRepository()
      .selectFirstWhere((model) => model.id.equals(1024));
  std?.isActive.value = 1;
  if (std != null) StudentsRepository().updateEntry(std);
  print(std);
}

class Student extends DbModel {
  var name = StringField(columnName: 'name');
  var secondName = StringField(columnName: 'second_name');
  var thirdName = StringField(columnName: 'third_name');
  var familyName = StringField(columnName: 'family_name');
  var mobile = StringField(columnName: 'mobile');
  var identity = StringField(columnName: 'identity');
  var deviceid = StringField(columnName: 'deviceid');
  var schoolId = IntField(columnName: 'school_id');
  var code = StringField(columnName: 'code');
  var isActive = IntField(columnName: 'is_active');
  var licenseType = IntField(columnName: 'license_type');
  var typeApp = IntField(columnName: 'type_app');
  var examCount = IntField(columnName: 'exam_count');
  var fromApp = IntField(columnName: 'from_app');
  var isDeleteDevice = IntField(columnName: 'is_delete_device');
  @override
  List<FieldWithValue>? getFields() => [
        name,
        secondName,
        thirdName,
        familyName,
        mobile,
        identity,
        deviceid,
        schoolId,
        code,
        isActive,
        licenseType,
        typeApp,
        examCount,
        fromApp,
        isDeleteDevice
      ];
}

class StudentsRepository extends DbRepository<Student> {
  static final StudentsRepository _instance = StudentsRepository._();
  factory StudentsRepository() => _instance;

  StudentsRepository._() : super(() => Student());

  @override
  String get tableName => 'students';
}
