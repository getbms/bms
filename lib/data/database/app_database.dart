import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'daos/audit_log_dao.dart';
import 'daos/cheques_dao.dart';
import 'daos/customers_dao.dart';
import 'daos/inventory_dao.dart';
import 'daos/invoices_dao.dart';
import 'daos/petty_cash_dao.dart';
import 'daos/suppliers_dao.dart';
import 'daos/users_dao.dart';
import 'tables/audit_log_table.dart';
import 'tables/cheques_table.dart';
import 'tables/customers_table.dart';
import 'tables/invoices_table.dart';
import 'tables/payments_table.dart';
import 'tables/petty_cash_table.dart';
import 'tables/products_table.dart';
import 'tables/suppliers_table.dart';
import 'tables/users_table.dart';

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
    Invoices,
    InvoiceItems,
    NoInvoiceSales,
    Cheques,
    PettyCash,
    AuditLog,
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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _ensureDevAccount();
        },
        onUpgrade: (m, from, to) async {
          // Migrations added here for each schema bump.
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA journal_mode=WAL');
          await customStatement('PRAGMA foreign_keys=ON');
          // Always ensure the dev account exists (handles reinstalls / cleared data).
          await _ensureDevAccount();
        },
      );

  static const _devUserId = '00000000-0000-0000-0000-000000000001';
  static const _devUsername = 'iamvirul';
  static const _devPassword = '200528100634@Vn';

  /// Inserts the developer account if it doesn't already exist.
  /// Runs on every open so the account survives data clears without a full
  /// schema recreate. Hashes the password at runtime — no static hash stored.
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
        name: 'iamvirul',
        username: _devUsername,
        passwordHash: hash,
        role: const Value('developer'),
      ),
    );

    // Audit the seed so there is a traceable record of account creation.
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
  return driftDatabase(
    name: 'bms_local',
    web: kIsWeb
        ? DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
          )
        : null,
  );
}
