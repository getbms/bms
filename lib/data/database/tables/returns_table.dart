import 'package:bms/data/database/tables/invoices_table.dart';
import 'package:drift/drift.dart';

class SalesReturns extends Table {
  TextColumn get id => text()();
  TextColumn get invoiceId => text().references(Invoices, #id)();
  TextColumn get returnNo => text().unique()();

  /// refund | credit | exchange
  TextColumn get type => text()
      .withDefault(const Constant('refund'))
      // ignore: recursive_getters
      .check(type.isIn(['refund', 'credit', 'exchange']))();

  RealColumn get totalAmount => real().withDefault(const Constant(0))();
  TextColumn get reason => text().nullable()();
  TextColumn get userId => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ReturnItems extends Table {
  TextColumn get id => text()();
  TextColumn get returnId => text().references(SalesReturns, #id)();
  TextColumn get productId => text()();
  TextColumn get productName => text()(); // snapshot
  // ignore: recursive_getters
  RealColumn get qty => real().check(qty.isBiggerThanValue(0))();
  // ignore: recursive_getters
  RealColumn get unitPrice => real().check(unitPrice.isBiggerOrEqualValue(0))();
  // ignore: recursive_getters
  RealColumn get subtotal => real().check(subtotal.isBiggerOrEqualValue(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
