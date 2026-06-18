import 'package:bms/data/database/app_database.dart';
import 'package:bms/data/database/tables/petty_cash_table.dart';
import 'package:drift/drift.dart';

part 'petty_cash_dao.g.dart';

@DriftAccessor(tables: [PettyCash])
class PettyCashDao extends DatabaseAccessor<AppDatabase> with _$PettyCashDaoMixin {
  PettyCashDao(super.db);

  Future<String> insert(PettyCashCompanion entry) =>
      into(pettyCash).insertReturning(entry).then((p) => p.id);

  Future<List<PettyCashEntry>> getByDateRange(DateTime from, DateTime to) =>
      (select(pettyCash)
            ..where((p) => p.createdAt.isBetweenValues(from, to))
            ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
          .get();

  Future<List<PettyCashEntry>> getPendingApprovals() =>
      (select(pettyCash)..where((p) => p.status.equals('pending'))).get();

  Future<void> approve(String id, String approvedBy) =>
      (update(pettyCash)..where((p) => p.id.equals(id))).write(
        PettyCashCompanion(
          status: const Value('approved'),
          approvedBy: Value(approvedBy),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> reject(String id) =>
      (update(pettyCash)..where((p) => p.id.equals(id))).write(
        PettyCashCompanion(
          status: const Value('rejected'),
          updatedAt: Value(DateTime.now()),
        ),
      );
}
