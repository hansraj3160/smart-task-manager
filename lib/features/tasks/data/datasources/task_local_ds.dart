import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;


part 'task_local_ds.g.dart';


class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()(); 
  TextColumn get title => text()();
  TextColumn get description => text()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  
 
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))(); 
  TextColumn get serverId => text().nullable()();
}

@DriftDatabase(tables: [Tasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<List<Task>> getAllTasks() => select(tasks).get();
  Future<List<Task>> getUnsyncedTasks() {
    return (select(tasks)..where((t) => t.isSynced.equals(false))).get();
  }
  Future<int> insertTask(TasksCompanion task) {
    return into(tasks).insert(task);
  }
  Future<void> markAsSynced(int localId, String remoteId) {
    return (update(tasks)..where((t) => t.id.equals(localId))).write(
      TasksCompanion(
        isSynced:  Value(true),
        serverId: Value(remoteId),
      ),
    );
  }

  Future<int> deleteTask(int id) => (delete(tasks)..where((t) => t.id.equals(id))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}