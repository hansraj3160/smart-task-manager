import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'task_local_ds.g.dart';


// 1. Table Definition

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()(); 
  TextColumn get title => text()();
  TextColumn get description => text()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get userId => integer().nullable()();
  // Sync Logic 
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))(); 
  TextColumn get serverId => text().nullable()();
  // NEW COLUMNS (Offline Support ke liye)
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get startTaskAt => dateTime().nullable()();
  DateTimeColumn get endTaskAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}
// 2. Database Class (Drift)

@DriftDatabase(tables: [Tasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
int get schemaVersion => 3;

  // --- Core Queries ---
 @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
           await m.addColumn(tasks, tasks.userId);
        }
        // STEP: Add Migration for Version 3
        if (from < 3) {
          await m.addColumn(tasks, tasks.isDeleted);
        }
      },
    );
}

  Future<List<Task>> getAllTasks(int userId) {
    return (select(tasks)..where((t) => 
      t.userId.equals(userId) & t.isDeleted.equals(false)
    )).get();
  }
  
 Future<List<Task>> getUnsyncedTasks(int userId) {
    return (select(tasks)
      ..where((t) => t.isSynced.equals(false) & t.userId.equals(userId)))
      .get();
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
Future<void> markTaskAsDeleted(String id) async{
   int? localId = int.tryParse(id);
    if (localId != null) {
      // Try by Local ID
      final count = await (update(tasks)..where((t) => t.id.equals(localId))).write(
        TasksCompanion(isDeleted: const Value(true), isSynced: const Value(false))
      );
      if (count > 0) return;
    }
    // Try by Server ID
    await (update(tasks)..where((t) => t.serverId.equals(id))).write(
      TasksCompanion(isDeleted: const Value(true), isSynced: const Value(false))
    );
  
  }

  Future<void> deleteAllTasks() => delete(tasks).go();
  Future<int> deleteTask(int id) => (delete(tasks)..where((t) => t.id.equals(id))).go();
  Future<void> deleteTaskPermanently(int localId) {
    return (delete(tasks)..where((t) => t.id.equals(localId))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}


// 3.  NEW: Abstract Data Source (Interface)

abstract class TaskLocalDataSource {
  Future<List<Task>> getAllTasks(int userId);
  Future<int> insertTask(TasksCompanion task);
  Future<void> updateTaskSyncStatus(int localId, String serverId);
 Future<List<Task>> getUnsyncedTasks(int userId);
  Future<void> updateLocalTaskStatus(String serverId, String newStatus);
  Future<void> cacheTasks(List<TasksCompanion> tasks);
  Future<void> markTaskAsDeleted(String id);
  Future<void> deleteTaskPermanently(int id);
  Future<void> clearAllData();
}


// 4.  NEW: Implementation

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  final AppDatabase db;

  TaskLocalDataSourceImpl(this.db);

 @override
  Future<List<Task>> getAllTasks(int userId) => db.getAllTasks(userId);
  @override
  Future<int> insertTask(TasksCompanion task) => db.insertTask(task);
@override
  Future<void> markTaskAsDeleted(String id) => db.markTaskAsDeleted(id);
  
  @override
  Future<void> deleteTaskPermanently(int id) => db.deleteTask(id);
  @override
  Future<void> updateTaskSyncStatus(int localId, String serverId) => 
      db.markAsSynced(localId, serverId);

 @override
  Future<List<Task>> getUnsyncedTasks(int userId) => db.getUnsyncedTasks(userId);@override
  Future<void> updateLocalTaskStatus(String id, String newStatus)async {
   int? localId = int.tryParse(id);

    if (localId != null) {
     
      final count = await (db.update(db.tasks)..where((t) => t.id.equals(localId))).write(
        TasksCompanion(
          status: Value(newStatus),
          isSynced: const Value(false),
        ),
      );
      
      if (count > 0) return;
    } 
    await (db.update(db.tasks)..where((t) => t.serverId.equals(id))).write(
      TasksCompanion(
        status: Value(newStatus),
        isSynced: const Value(false),
      ),
    );
  }
@override
  Future<void> cacheTasks(List<TasksCompanion> tasks) async {
    await db.transaction(() async {
      for (var task in tasks) {
        final serverId = task.serverId.value;
        if (serverId != null) {
         
          final exists = await (db.select(db.tasks)..where((t) => t.serverId.equals(serverId))).getSingleOrNull();
          
          if (exists != null) {
            
            await (db.update(db.tasks)..where((t) => t.id.equals(exists.id))).write(task);
          } else {
           
            await db.into(db.tasks).insert(task);
          }
        }
      }
    });
  }
  @override
  Future<void> clearAllData() async {
    await db.deleteAllTasks(); // Database table empty karo
  }
}