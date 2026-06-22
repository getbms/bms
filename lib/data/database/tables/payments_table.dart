import 'package:drift/drift.dart';

/// Explicit split tables -- no polymorphic FK pattern.

class CustomerPayments extends Table {
  TextColumn get id => text()();
  TextColumn get customerId => text()();
  RealColumn get amount => real()();

  /// cash | card | cheque | bank_transfer
  TextColumn get method => text().withDefault(const Constant('cash'))();

  TextColumn get referenceNo => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get userId => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SupplierPayments extends Table {
  TextColumn get id => text()();
  TextColumn get supplierId => text()();
  RealColumn get amount => real()();
  TextColumn get method => text().withDefault(const Constant('cash'))();
  TextColumn get chequeId => text().nullable()();
  TextColumn get referenceNo => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get userId => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
