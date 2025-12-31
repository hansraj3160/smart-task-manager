import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'task_local_ds.g.dart';

// -----------------------------------------------------------------------------
// 1. Table Definition
// -----------------------------------------------------------------------------
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()(); 
  TextColumn get title => text()();
  TextColumn get description => text()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  
  // Sync Logic Columns
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))(); 
  TextColumn get serverId => text().nullable()();
}

// -----------------------------------------------------------------------------
// 2. Database Class (Drift)
// -----------------------------------------------------------------------------
@DriftDatabase(tables: [Tasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // --- Core Queries ---

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
        isSynced: const Value(true),
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

// -----------------------------------------------------------------------------
// 3.  NEW: Abstract Data Source (Interface)
// -----------------------------------------------------------------------------
abstract class TaskLocalDataSource {
  Future<List<Task>> getAllTasks();
  Future<int> insertTask(TasksCompanion task);
  Future<void> updateTaskSyncStatus(int localId, String serverId);
  Future<List<Task>> getUnsyncedTasks();
}

// -----------------------------------------------------------------------------
// 4.  NEW: Implementation
// -----------------------------------------------------------------------------
class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  final AppDatabase db;

  TaskLocalDataSourceImpl(this.db);

  @override
  Future<List<Task>> getAllTasks() => db.getAllTasks();

  @override
  Future<int> insertTask(TasksCompanion task) => db.insertTask(task);

  @override
  Future<void> updateTaskSyncStatus(int localId, String serverId) => 
      db.markAsSynced(localId, serverId);

  @override
  Future<List<Task>> getUnsyncedTasks() => db.getUnsyncedTasks();
}