import 'package:bms/data/database/app_database.dart';
import 'package:bms/data/database/tables/users_table.dart';
import 'package:drift/drift.dart';

part 'users_dao.g.dart';

@DriftAccessor(tables: [Users])
class UsersDao extends DatabaseAccessor<AppDatabase> with _$UsersDaoMixin {
  UsersDao(super.db);

  Future<User?> findByUsername(String username) =>
      (select(users)..where((u) => u.username.equals(username))).getSingleOrNull();

  Future<User?> findById(String id) =>
      (select(users)..where((u) => u.id.equals(id))).getSingleOrNull();

  Future<List<User>> findAll({bool activeOnly = true}) =>
      (select(users)
            ..where((u) => activeOnly ? u.isActive.equals(true) : const Constant(true)))
          .get();

  Future<String> insertUser(UsersCompanion entry) =>
      into(users).insertReturning(entry).then((u) => u.id);

  // Renamed to updateUser to avoid clash with Drift's DatabaseConnectionUser.update
  Future<bool> updateUser(UsersCompanion entry) =>
      (update(users)..where((u) => u.id.equals(entry.id.value)))
          .write(entry)
          .then((n) => n > 0);

  Future<void> incrementFailedAttempts(String id) async {
    final user = await findById(id);
    if (user == null) return;
    await (update(users)..where((u) => u.id.equals(id))).write(
      UsersCompanion(failedAttempts: Value(user.failedAttempts + 1)),
    );
  }

  Future<void> resetFailedAttempts(String id) =>
      (update(users)..where((u) => u.id.equals(id)))
          .write(const UsersCompanion(failedAttempts: Value(0)));

  Future<void> lockAccount(String id, DateTime until) =>
      (update(users)..where((u) => u.id.equals(id)))
          .write(UsersCompanion(lockedUntil: Value(until)));

  Stream<List<User>> watchAll() =>
      (select(users)..orderBy([(u) => OrderingTerm.asc(u.name)])).watch();

  Future<void> setActive(String id, {required bool active}) =>
      (update(users)..where((u) => u.id.equals(id)))
          .write(UsersCompanion(isActive: Value(active), updatedAt: Value(DateTime.now())));
}
