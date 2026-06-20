import 'package:drift/drift.dart';

class Cheques extends Table {
  TextColumn get id => text()();

  /// received (from customer) | issued (to supplier)
  TextColumn get type => text()();

  /// customer id or supplier id -- intentionally not a FK since it can reference either table
  TextColumn get partyId => text()();
  TextColumn get partyType => text()(); // customer | supplier
  TextColumn get partyName => text()(); // snapshot for display

  RealColumn get amount => real()();
  TextColumn get chequeNo => text().nullable()();
  TextColumn get bank => text().nullable()();
  DateTimeColumn get dueDate => dateTime()();

  /// pending | deposited | cleared | bounced
  TextColumn get status => text().withDefault(const Constant('pending'))();

  TextColumn get notes => text().nullable()();
  DateTimeColumn get depositDate => dateTime().nullable()();
  TextColumn get bounceReason => text().nullable()();
  DateTimeColumn get bounceDate => dateTime().nullable()();
  IntColumn get representationCount => integer().withDefault(const Constant(0))();
  TextColumn get createdBy => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
