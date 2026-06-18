import 'package:drift/drift.dart';

@DataClassName('PettyCashEntry')
class PettyCash extends Table {
  TextColumn get id => text()();

  /// in | out
  TextColumn get type => text()();

  RealColumn get amount => real()();
  TextColumn get category => text()(); // transport | utilities | repairs | misc | etc.
  TextColumn get description => text()();
  TextColumn get receiptPhotoPath => text().nullable()();
  TextColumn get userId => text()();
  TextColumn get approvedBy => text().nullable()();
  TextColumn get approvalNotes => text().nullable()();
  DateTimeColumn get approvedAt => dateTime().nullable()();

  /// pending | approved | rejected
  TextColumn get status => text().withDefault(const Constant('pending'))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
