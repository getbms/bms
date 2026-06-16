import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/database/app_database.dart';
import '../data/database/daos/audit_log_dao.dart';
import '../data/database/daos/cheques_dao.dart';
import '../data/database/daos/customers_dao.dart';
import '../data/database/daos/inventory_dao.dart';
import '../data/database/daos/invoices_dao.dart';
import '../data/database/daos/petty_cash_dao.dart';
import '../data/database/daos/reports_dao.dart';
import '../data/database/daos/returns_dao.dart';
import '../data/database/daos/suppliers_dao.dart';
import '../data/database/daos/users_dao.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

@Riverpod(keepAlive: true)
UsersDao usersDao(Ref ref) => ref.watch(appDatabaseProvider).usersDao;

@Riverpod(keepAlive: true)
InventoryDao inventoryDao(Ref ref) => ref.watch(appDatabaseProvider).inventoryDao;

@Riverpod(keepAlive: true)
InvoicesDao invoicesDao(Ref ref) => ref.watch(appDatabaseProvider).invoicesDao;

@Riverpod(keepAlive: true)
CustomersDao customersDao(Ref ref) => ref.watch(appDatabaseProvider).customersDao;

@Riverpod(keepAlive: true)
SuppliersDao suppliersDao(Ref ref) => ref.watch(appDatabaseProvider).suppliersDao;

@Riverpod(keepAlive: true)
ChequesDao chequesDao(Ref ref) => ref.watch(appDatabaseProvider).chequesDao;

@Riverpod(keepAlive: true)
PettyCashDao pettyCashDao(Ref ref) => ref.watch(appDatabaseProvider).pettyCashDao;

@Riverpod(keepAlive: true)
AuditLogDao auditLogDao(Ref ref) => ref.watch(appDatabaseProvider).auditLogDao;

@Riverpod(keepAlive: true)
ReturnsDao returnsDao(Ref ref) => ref.watch(appDatabaseProvider).returnsDao;

@Riverpod(keepAlive: true)
ReportsDao reportsDao(Ref ref) => ReportsDao(ref.watch(appDatabaseProvider));
