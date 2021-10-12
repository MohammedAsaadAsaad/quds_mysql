# Quds MySql
Is an automated version of mysql1!

## How to use
* See the `./example` directory for an example.
#### 1. To create a model
Model classes should extend DbModel class.
Define the schema of your model
```
class Note extends DbModel {
  var title = StringField(columnName: 'title');
  var content = StringField(columnName: 'content');
  var isImportant = BoolField(columnName: 'isImportant');
 
  @override
  List<FieldWithValue>? getFields() => [title, content, isImportant];
}
```
<b>Note that:</b>
Every model has default fields:
- id (Auto incremental integer field)
- creationTime (automatically set once when created)
- modificationTime (automatically set when created, and with every update operation)

<br/>

#### 2. To create a table manager
```
class NotesRepository extends DbRepository<Note> {
  NotesRepository() : super(() => Note());

  @override
  String get tableName => 'Notes';
}
```
As shown, to set the name of the table:
```
  @override
  String get tableName => 'Notes';
```

<b>Note that:</b>
In Repository class constructor, you should provide it with model object creation function.
```
  NotesRepository() : super(() => Note());
```

To create a repository instance,

```
NotesRepository NotesRepository = NotesRepository();
```


#### 3. Crud operations: 
##### Creation: (Insertion)
<b> single:</b>
``` 
    Note n = Note();
    n.title.value = 'New note';
    n.content.value = 'Note content, describe your self';
    n.isImportant.value = ([true, false]..shuffle()).first;
    await NotesRepository.insertEntry(n);
```
    
<b> multiple</b>:
```
    await NotesRepository.insertCollection([n1,n2,n3,...]);
```

##### Reading (Query):
```
var allNotes = await NotesRepository.select();
var importantNotes = await NotesRepository.select(where:(n)=>n.isImportant.isTrue);
var imortantRed = await NotesRepository.select(where:(n)=>n.isImportant.isTrue);
```

##### Updating:
```
n.title = 'new title';
await NotesRepository.updateEntry(n);
```

##### Deletion:
```
await NotesRepository.deleteEntry(n);
```


## Monitoring changes:
To handle the changes in some table:
```
  NotesRepository.addEntryChangeListner((changeType, entry) {
      switch (changeType) {
        case EntryChangeType.Insertion:
          //New Note added (entry)
          break;
        case EntryChangeType.Deletion:
          //(entry) has been deleted
          break;
        case EntryChangeType.Modification:
          //(entry) has been modified
          break;
      }
    });
```

