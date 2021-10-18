import 'package:example/data/note.dart';
import 'package:quds_mysql/quds_mysql.dart' as my_db;
import 'data/notes_repository.dart';

Future<void> runApp() async {
  my_db.DbHelper.mainDb = 'flutter';
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
}
