import 'package:bms/data/database/app_database.dart';
import 'package:bms/data/database/tables/cheques_table.dart';
import 'package:drift/drift.dart';

part 'cheques_dao.g.dart';

@DriftAccessor(tables: [Cheques])
class ChequesDao extends DatabaseAccessor<AppDatabase> with _$ChequesDaoMixin {
  ChequesDao(super.db);

  Future<String> insert(ChequesCompanion entry) =>
      into(cheques).insertReturning(entry).then((c) => c.id);

  Future<Cheque?> findById(String id) =>
      (select(cheques)..where((c) => c.id.equals(id))).getSingleOrNull();

  Stream<List<Cheque>> watchByMonth(int year, int month) {
    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);
    return (select(cheques)
          ..where((c) => c.dueDate.isBetweenValues(start, end))
          ..orderBy([(c) => OrderingTerm.asc(c.dueDate)]))
        .watch();
  }

  Future<List<Cheque>> getDueWithinDays(int days) {
    final now = DateTime.now();
    final cutoff = now.add(Duration(days: days));
    return (select(cheques)
          ..where(
            (c) =>
                c.dueDate.isBetweenValues(now, cutoff) &
                c.status.equals('pending'),
          )
          ..orderBy([(c) => OrderingTerm.asc(c.dueDate)]))
        .get();
  }

  Future<List<Cheque>> getOverdueCheques() {
    final now = DateTime.now();
    return (select(cheques)
          ..where(
            (c) =>
                c.dueDate.isSmallerThanValue(now) &
                c.status.isIn(['pending', 'deposited']),
          )
          ..orderBy([(c) => OrderingTerm.asc(c.dueDate)]))
        .get();
  }

  Future<void> updateStatus(String id, String status) =>
      (update(cheques)..where((c) => c.id.equals(id))).write(
        ChequesCompanion(
          status: Value(status),
          updatedAt: Value(DateTime.now()),
        ),
      );
}
