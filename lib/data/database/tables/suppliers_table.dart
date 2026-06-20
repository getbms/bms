import 'package:drift/drift.dart';

class Suppliers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get paymentTerms => text().nullable()();
  RealColumn get balance => real().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PurchaseOrders extends Table {
  TextColumn get id => text()();
  TextColumn get supplierId => text().references(Suppliers, #id)();
  TextColumn get poNumber => text().unique()();

  /// draft | sent | partially_received | received | cancelled
  TextColumn get status => text().withDefault(const Constant('draft'))();
  TextColumn get notes => text().nullable()();
  RealColumn get total => real().withDefault(const Constant(0))();
  TextColumn get createdBy => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PurchaseOrderItems extends Table {
  TextColumn get id => text()();
  TextColumn get poId => text().references(PurchaseOrders, #id)();
  TextColumn get productId => text()();
  RealColumn get orderedQty => real()();
  RealColumn get costPrice => real()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Purchases extends Table {
  TextColumn get id => text()();
  TextColumn get supplierId => text().references(Suppliers, #id)();
  TextColumn get poId =>
      text().nullable().references(PurchaseOrders, #id, onDelete: KeyAction.setNull)();
  TextColumn get grnNumber => text().nullable().unique()();
  TextColumn get supplierInvoiceNo => text().nullable()();
  RealColumn get supplierInvoiceAmount => real().nullable()();
  RealColumn get total => real().withDefault(const Constant(0))();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  TextColumn get userId => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PurchaseItems extends Table {
  TextColumn get id => text()();
  TextColumn get purchaseId => text().references(Purchases, #id)();
  TextColumn get productId => text()();
  RealColumn get qty => real()();
  RealColumn get costPrice => real()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
