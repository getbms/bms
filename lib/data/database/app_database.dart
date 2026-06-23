import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:bms/data/database/daos/audit_log_dao.dart';
import 'package:bms/data/database/daos/cheques_dao.dart';
import 'package:bms/data/database/daos/customers_dao.dart';
import 'package:bms/data/database/daos/inventory_dao.dart';
import 'package:bms/data/database/daos/invoices_dao.dart';
import 'package:bms/data/database/daos/petty_cash_dao.dart';
import 'package:bms/data/database/daos/returns_dao.dart';
import 'package:bms/data/database/daos/suppliers_dao.dart';
import 'package:bms/data/database/daos/users_dao.dart';
import 'package:bms/data/database/tables/audit_log_table.dart';
import 'package:bms/data/database/tables/cheques_table.dart';
import 'package:bms/data/database/tables/customers_table.dart';
import 'package:bms/data/database/tables/invoices_table.dart';
import 'package:bms/data/database/tables/payments_table.dart';
import 'package:bms/data/database/tables/petty_cash_table.dart';
import 'package:bms/data/database/tables/products_table.dart';
import 'package:bms/data/database/tables/returns_table.dart';
import 'package:bms/data/database/tables/suppliers_table.dart';
import 'package:bms/data/database/tables/users_table.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Users,
    Categories,
    Products,
    ProductUnits,
    Stock,
    StockMovements,
    Customers,
    CustomerPayments,
    Suppliers,
    Purchases,
    PurchaseItems,
    SupplierPayments,
    PurchaseOrders,
    PurchaseOrderItems,
    Invoices,
    InvoiceItems,
    NoInvoiceSales,
    Cheques,
    PettyCash,
    AuditLog,
    SalesReturns,
    ReturnItems,
  ],
  daos: [
    UsersDao,
    InventoryDao,
    InvoicesDao,
    CustomersDao,
    SuppliersDao,
    ChequesDao,
    PettyCashDao,
    AuditLogDao,
    ReturnsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Used in tests with NativeDatabase.memory() so no disk I/O is needed.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _ensureDevAccount();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(salesReturns);
            await m.createTable(returnItems);
          }
          if (from < 3) {
            await m.addColumn(users, users.lastLoginAt);
            await m.addColumn(users, users.passwordChangedAt);
          }
          if (from < 4) {
            await m.addColumn(pettyCash, pettyCash.approvalNotes);
            await m.addColumn(pettyCash, pettyCash.approvedAt);
          }
          if (from < 5) {
            await m.addColumn(cheques, cheques.depositDate);
            await m.addColumn(cheques, cheques.bounceReason);
            await m.addColumn(cheques, cheques.bounceDate);
            await m.addColumn(cheques, cheques.representationCount);
          }
          if (from < 6) {
            await m.createTable(purchaseOrders);
            await m.createTable(purchaseOrderItems);
            await m.addColumn(purchases, purchases.poId);
            await m.addColumn(purchases, purchases.supplierInvoiceNo);
            await m.addColumn(purchases, purchases.supplierInvoiceAmount);
          }
          if (from < 7) {
            // Recreate purchases table to add FK constraint on po_id.
            await m.alterTable(TableMigration(purchases));
          }
          if (from < 8) {
            // Add updatedAt/deletedAt columns for MySQL sync support.
            await m.addColumn(invoices, invoices.updatedAt);
            await m.addColumn(invoices, invoices.deletedAt);
            await m.addColumn(invoiceItems, invoiceItems.updatedAt);
            await m.addColumn(noInvoiceSales, noInvoiceSales.updatedAt);
            await m.addColumn(customerPayments, customerPayments.updatedAt);
            await m.addColumn(supplierPayments, supplierPayments.updatedAt);
            await m.addColumn(salesReturns, salesReturns.updatedAt);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA journal_mode=WAL');
          await customStatement('PRAGMA foreign_keys=ON');
          await _ensureDevAccount();
        },
      );

  static const _devUserId = '00000000-0000-0000-0000-000000000001';
  static const _devUsername = 'dev';
  static const _devPassword = 'changeme';

  Future<void> _ensureDevAccount() async {
    final existing = await (select(users)
          ..where((u) => u.id.equals(_devUserId)))
        .getSingleOrNull();

    if (existing != null) return;

    final hash = BCrypt.hashpw(_devPassword, BCrypt.gensalt(logRounds: 12));
    const uuid = Uuid();

    await into(users).insert(
      UsersCompanion.insert(
        id: _devUserId,
        name: 'Developer',
        username: _devUsername,
        passwordHash: hash,
        role: const Value('developer'),
      ),
    );

    await into(auditLog).insert(
      AuditLogCompanion.insert(
        id: uuid.v7(),
        entityType: 'user',
        entityId: _devUserId,
        action: 'create',
        userId: _devUserId,
        userName: _devUsername,
        newValue: const Value('{"role":"developer","source":"seed"}'),
      ),
    );
  }
}

QueryExecutor _openConnection() {
  if (kIsWeb) {
    return driftDatabase(
      name: 'bms_local',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'bms_local.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
