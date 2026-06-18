import 'package:bms/data/database/tables/users_table.dart';
import 'package:drift/drift.dart';

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100).unique()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get barcode => text().nullable().unique()();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get brand => text().nullable()();

  /// pcs | kg | liter | box
  TextColumn get unitType => text().withDefault(const Constant('pcs'))();

  RealColumn get costPrice => real().withDefault(const Constant(0))();
  RealColumn get sellPrice => real().withDefault(const Constant(0))();
  IntColumn get reorderLevel => integer().withDefault(const Constant(10))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get trackBatch => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Allows a product to be bought in one unit and sold in another.
/// e.g., product unit = carton, sell unit = pcs, conversionFactor = 24
class ProductUnits extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get unitName => text().withLength(min: 1, max: 50)();
  RealColumn get conversionFactor => real()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('StockLevel')
class Stock extends Table {
  TextColumn get productId => text().references(Products, #id)();
  RealColumn get qty => real().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {productId};
}

/// Immutable ledger of every stock movement -- never update, only insert.
class StockMovements extends Table {
  TextColumn get id => text()();

  /// in | out | adjust | return_in | return_out
  TextColumn get type => text()();
  TextColumn get productId => text().references(Products, #id)();
  RealColumn get qty => real()();
  TextColumn get reason => text().nullable()();
  TextColumn get userId => text().references(Users, #id)();

  /// Invoice id, purchase id, or adjustment id that triggered this movement
  TextColumn get refId => text().nullable()();
  TextColumn get refType => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
