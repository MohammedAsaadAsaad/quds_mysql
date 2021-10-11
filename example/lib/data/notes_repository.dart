import 'package:quds_mysql/quds_mysql.dart';
import 'note.dart';

class NotesRepository extends DbRepository<Note> {
  NotesRepository._() : super(() => Note());
  static final NotesRepository _internal = NotesRepository._();
  factory NotesRepository() => _internal;

  @override
  String get tableName => 'Notes';
}
