import 'package:drift/drift.dart';

import 'invoices_table.dart';

class SalesReturns extends Table {
  TextColumn get id => text()();
  TextColumn get invoiceId => text().references(Invoices, #id)();
  TextColumn get returnNo => text().unique()();

  /// refund | credit | exchange
  TextColumn get type => text().withDefault(const Constant('refund'))();

  RealColumn get totalAmount => real().withDefault(const Constant(0))();
  TextColumn get reason => text().nullable()();
  TextColumn get userId => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ReturnItems extends Table {
  TextColumn get id => text()();
  TextColumn get returnId => text().references(SalesReturns, #id)();
  TextColumn get productId => text()();
  TextColumn get productName => text()(); // snapshot
  RealColumn get qty => real()();
  RealColumn get unitPrice => real()();
  RealColumn get subtotal => real()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
