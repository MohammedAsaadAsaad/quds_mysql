import 'package:quds_mysql/quds_mysql.dart' as my_db;
import 'package:quds_mysql/quds_mysql.dart';

Future<void> runApp() async {
  my_db.DbHelper.mainDb = 'testdb';
  my_db.DbHelper.dbUser = 'root';
  my_db.DbHelper.dbPassword = '0';
  my_db.DbHelper.port = 2020;
  await Future.delayed(const Duration(seconds: 1));

  var repo = StudentsRepository();
  var std = Student();
  var date = DateTime(2000);
  print(date);
  std.birthDate.value = date;
  print(std.birthDate.value);

  await repo.updateEntry(std);
  print(std.birthDate.value);

  int id = std.id.value!;
  var std2 = await repo.loadEntryById(id);
  print(std2!.birthDate.value?.toLocal());

  await repo.updateEntry(std2);
  var std3 = await repo.loadEntryById(id);
  print(std3!.birthDate.value?.toLocal());
  // DateTime start = DateTime.now();
  // var repo = StudentsRepository();

  // for (int i = 0; i < 1000; i++) {
  //   var std = await repo.selectFirstWhere((model) => model.id.equals(1024));
  //   if (std != null) {
  //     std.isActive.value = 1;
  //     await repo.updateEntry(std);
  //   }

  //   await StudentsRepository().countEntries(
  //       where: (s) =>
  //           (s.modificationTime > DateTime(2022, 3, 1, 10, 10, 10)) &
  //           s.creationTime.month.equals(1));
  // }

  // print(DateTime.now().difference(start).inMilliseconds.toString() + ' ms');
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
  var birthDate = DateTimeField(columnName: 'birth_date');

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
        isDeleteDevice,
        birthDate
      ];
}

class StudentsRepository extends DbRepository<Student> {
  static final StudentsRepository _instance = StudentsRepository._();
  factory StudentsRepository() => _instance;

  StudentsRepository._() : super(() => Student());

  @override
  String get tableName => 'students';
}
