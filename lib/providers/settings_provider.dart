import 'dart:convert';
import 'dart:io';

import 'package:bms/data/database/app_database.dart';
import 'package:bms/features/auth/domain/auth_state.dart';
import 'package:bms/providers/auth_provider.dart';
import 'package:bms/providers/database_provider.dart';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

const _langKey = 'app_language';
const _storeNameKey = 'store_name';
const _storeAddressKey = 'store_address';
const _storePhoneKey = 'store_phone';
const _dbConnectionKey = 'db_connection_settings';

class StoreInfo {
  const StoreInfo({
    this.name = 'BMS Store',
    this.address = '',
    this.phone = '',
  });
  final String name;
  final String address;
  final String phone;
}

class StoreInfoNotifier extends Notifier<StoreInfo> {
  @override
  StoreInfo build() {
    Future.microtask(load);
    return const StoreInfo();
  }

  Future<void> load() async {
    final s = ref.read(sessionStorageProvider);
    state = StoreInfo(
      name: (await s.read(key: _storeNameKey)) ?? 'BMS Store',
      address: (await s.read(key: _storeAddressKey)) ?? '',
      phone: (await s.read(key: _storePhoneKey)) ?? '',
    );
  }

  Future<void> save({
    required String name,
    required String address,
    required String phone,
  }) async {
    final s = ref.read(sessionStorageProvider);
    await Future.wait([
      s.write(key: _storeNameKey, value: name),
      s.write(key: _storeAddressKey, value: address),
      s.write(key: _storePhoneKey, value: phone),
    ]);
    state = StoreInfo(name: name, address: address, phone: phone);
  }
}

final storeInfoProvider =
    NotifierProvider<StoreInfoNotifier, StoreInfo>(StoreInfoNotifier.new);

class LanguageNotifier extends Notifier<String> {
  @override
  String build() {
    Future.microtask(load);
    return 'en';
  }

  Future<void> load() async {
    final saved = await ref.read(sessionStorageProvider).read(key: _langKey);
    if (saved != null) state = saved;
  }

  Future<void> set(String code) async {
    state = code;
    await ref.read(sessionStorageProvider).write(key: _langKey, value: code);
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, String>(LanguageNotifier.new);

const supportedLanguages = [
  ('en', 'English'),
  ('si', 'Sinhala'),
  ('ta', 'Tamil'),
];

// ---- Database connection settings ----

enum DbConnectionType { localSqlite, localMysql, remoteMysql }

class DbConnectionSettings {
  const DbConnectionSettings({
    this.type = DbConnectionType.localSqlite,
    this.host = '127.0.0.1',
    this.port = 3306,
    this.database = 'bms',
    this.username = 'root',
    this.password = '',
  });

  factory DbConnectionSettings.fromJson(Map<String, dynamic> j) => DbConnectionSettings(
        type: DbConnectionType.values.firstWhere(
          (e) => e.name == j['type'],
          orElse: () => DbConnectionType.localSqlite,
        ),
        host: (j['host'] as String?) ?? '127.0.0.1',
        port: (j['port'] as num?)?.toInt() ?? 3306,
        database: (j['database'] as String?) ?? 'bms',
        username: (j['username'] as String?) ?? 'root',
        password: (j['password'] as String?) ?? '',
      );

  final DbConnectionType type;
  final String host;
  final int port;
  final String database;
  final String username;
  final String password;

  bool get isLocalSqlite => type == DbConnectionType.localSqlite;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'host': host,
        'port': port,
        'database': database,
        'username': username,
        'password': password,
      };

  DbConnectionSettings copyWith({
    DbConnectionType? type,
    String? host,
    int? port,
    String? database,
    String? username,
    String? password,
  }) =>
      DbConnectionSettings(
        type: type ?? this.type,
        host: host ?? this.host,
        port: port ?? this.port,
        database: database ?? this.database,
        username: username ?? this.username,
        password: password ?? this.password,
      );
}

class DbConnectionNotifier extends Notifier<DbConnectionSettings> {
  @override
  DbConnectionSettings build() {
    Future.microtask(load);
    return const DbConnectionSettings();
  }

  Future<void> load() async {
    final raw = await ref.read(sessionStorageProvider).read(key: _dbConnectionKey);
    if (raw != null) {
      try {
        state = DbConnectionSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        // corrupted - reset to default
      }
    }
  }

  Future<void> save(DbConnectionSettings settings) async {
    state = settings;
    await ref.read(sessionStorageProvider).write(
          key: _dbConnectionKey,
          value: jsonEncode(settings.toJson()),
        );
  }
}

final dbConnectionSettingsProvider =
    NotifierProvider<DbConnectionNotifier, DbConnectionSettings>(DbConnectionNotifier.new);

final auditLogProvider =
    FutureProvider.autoDispose.family<List<AuditLogData>, String?>(
  (ref, entityType) =>
      ref.watch(auditLogDaoProvider).getAll(entityType: entityType),
);

class SettingsActions {
  SettingsActions(this._ref);
  final Ref _ref;
  final _uuid = const Uuid();

  AppDatabase get _db => _ref.read(appDatabaseProvider);

  String get _actorId {
    final s = _ref.read(currentAuthStateProvider);
    return s is Authenticated ? s.user.id : 'system';
  }

  String get _actorName {
    final s = _ref.read(currentAuthStateProvider);
    return s is Authenticated ? s.user.name : 'system';
  }

  /// Returns (inserted, skipped, errors).
  Future<(int, int, List<String>)> importProductsFromCsv() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return (0, 0, <String>[]);

    final bytes = await _readPickedFile(result.files.first);
    if (bytes == null) return (0, 0, <String>['Could not read file']);

    final csv = utf8.decode(bytes);
    final lines = csv.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) return (0, 0, <String>['Empty file']);

    // Skip header row if it starts with non-numeric (name column)
    final dataLines = lines.first.toLowerCase().contains('name') ? lines.skip(1).toList() : lines;

    int inserted = 0;
    int skipped = 0;
    final errors = <String>[];

    for (final line in dataLines) {
      try {
        final cols = _parseCsvLine(line);
        if (cols.length < 4) {
          skipped++;
          continue;
        }
        final name = cols[0].trim();
        final unitType = cols.length > 1 && cols[1].trim().isNotEmpty ? cols[1].trim() : 'pcs';
        final costPrice = double.tryParse(cols[2].trim()) ?? 0;
        final sellPrice = double.tryParse(cols[3].trim()) ?? 0;
        final barcode = cols.length > 4 && cols[4].trim().isNotEmpty ? cols[4].trim() : null;
        final brand = cols.length > 5 && cols[5].trim().isNotEmpty ? cols[5].trim() : null;
        final reorderLevel = cols.length > 6 ? (int.tryParse(cols[6].trim()) ?? 10) : 10;

        if (name.isEmpty || sellPrice <= 0) { skipped++; continue; }

        final id = _uuid.v7();
        await _db.into(_db.products).insert(
          ProductsCompanion.insert(
            id: id,
            name: name,
            unitType: Value(unitType),
            costPrice: Value(costPrice),
            sellPrice: Value(sellPrice),
            barcode: Value(barcode),
            brand: Value(brand),
            reorderLevel: Value(reorderLevel),
          ),
          mode: InsertMode.insertOrIgnore,
        );
        await _db.into(_db.stock).insert(
          StockCompanion.insert(productId: id, qty: const Value(0)),
          mode: InsertMode.insertOrIgnore,
        );
        inserted++;
      } catch (e) {
        errors.add('Line error: $e');
      }
    }

    await _ref.read(auditLogDaoProvider).log(
      id: _uuid.v7(),
      entityType: 'product',
      entityId: 'bulk_import',
      action: 'create',
      userId: _actorId,
      userName: _actorName,
      newValue: {'inserted': inserted, 'skipped': skipped, 'source': 'csv'},
    );

    return (inserted, skipped, errors);
  }

  Future<Uint8List> exportDatabaseAsJson() async {
    final db = _db;
    final products = await db.select(db.products).get();
    final customers = await db.select(db.customers).get();
    final suppliers = await db.select(db.suppliers).get();
    final cheques = await db.select(db.cheques).get();
    final invoices = await db.select(db.invoices).get();
    final pettyCash = await db.select(db.pettyCash).get();
    final stock = await db.select(db.stock).get();

    final payload = {
      'exported_at': DateTime.now().toIso8601String(),
      'version': 1,
      'products': products.map((p) => {
        'id': p.id, 'name': p.name, 'unit_type': p.unitType,
        'cost_price': p.costPrice, 'sell_price': p.sellPrice,
        'barcode': p.barcode, 'brand': p.brand,
      }).toList(),
      'customers': customers.map((c) => {
        'id': c.id, 'name': c.name, 'phone': c.phone,
        'address': c.address, 'balance': c.balance,
      }).toList(),
      'suppliers': suppliers.map((s) => {
        'id': s.id, 'name': s.name, 'phone': s.phone,
        'balance': s.balance,
      }).toList(),
      'cheques': cheques.map((c) => {
        'id': c.id, 'type': c.type, 'party_name': c.partyName,
        'amount': c.amount, 'due_date': c.dueDate.toIso8601String(),
        'status': c.status,
      }).toList(),
      'invoices': invoices.map((i) => {
        'id': i.id, 'invoice_no': i.invoiceNo,
        'total': i.total, 'created_at': i.createdAt.toIso8601String(),
      }).toList(),
      'petty_cash': pettyCash.map((p) => {
        'id': p.id, 'description': p.description,
        'amount': p.amount, 'type': p.type, 'category': p.category,
        'status': p.status,
      }).toList(),
      'stock': stock.map((s) => {
        'product_id': s.productId, 'qty': s.qty,
      }).toList(),
    };

    await _ref.read(auditLogDaoProvider).log(
      id: _uuid.v7(),
      entityType: 'database',
      entityId: 'export',
      action: 'create',
      userId: _actorId,
      userName: _actorName,
      newValue: {'format': 'json'},
    );

    return Uint8List.fromList(utf8.encode(const JsonEncoder.withIndent('  ').convert(payload)));
  }

  Future<String> importDatabaseFromJson() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return 'Cancelled';

    final bytes = await _readPickedFile(result.files.first);
    if (bytes == null) return 'Could not read file';

    try {
      final payload = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final db = _db;

      for (final Map<String, dynamic> p in ((payload['products'] as List?)?.cast<Map<String, dynamic>>() ?? [])) {
        await db.into(db.products).insert(
          ProductsCompanion.insert(
            id: p['id'] as String,
            name: p['name'] as String,
            unitType: Value((p['unit_type'] as String?) ?? 'pcs'),
            costPrice: Value((p['cost_price'] as num?)?.toDouble() ?? 0),
            sellPrice: Value((p['sell_price'] as num?)?.toDouble() ?? 0),
            barcode: Value(p['barcode'] as String?),
            brand: Value(p['brand'] as String?),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }

      for (final Map<String, dynamic> c in ((payload['customers'] as List?)?.cast<Map<String, dynamic>>() ?? [])) {
        await db.into(db.customers).insert(
          CustomersCompanion.insert(
            id: c['id'] as String,
            name: c['name'] as String,
            phone: Value(c['phone'] as String?),
            address: Value(c['address'] as String?),
            balance: Value((c['balance'] as num?)?.toDouble() ?? 0),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }

      for (final Map<String, dynamic> s in ((payload['stock'] as List?)?.cast<Map<String, dynamic>>() ?? [])) {
        await db.into(db.stock).insert(
          StockCompanion.insert(
            productId: s['product_id'] as String,
            qty: Value((s['qty'] as num?)?.toDouble() ?? 0),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }

      await _ref.read(auditLogDaoProvider).log(
        id: _uuid.v7(),
        entityType: 'database',
        entityId: 'import',
        action: 'create',
        userId: _actorId,
        userName: _actorName,
        newValue: {'format': 'json', 'source': result.files.first.name},
      );

      return 'Import complete';
    } catch (e) {
      return 'Import failed: $e';
    }
  }

  // File reading - on macOS/desktop file_picker populates path, not bytes.
  // Always prefer bytes when available, fall back to reading from path.
  Future<Uint8List?> _readPickedFile(PlatformFile file) async {
    if (file.bytes != null) return file.bytes;
    final path = file.path;
    if (path != null) {
      try {
        return await File(path).readAsBytes();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  List<String> _parseCsvLine(String line) {
    final cols = <String>[];
    final buf = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if (ch == ',' && !inQuotes) {
        cols.add(buf.toString());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    cols.add(buf.toString());
    return cols;
  }
}

final settingsActionsProvider =
    Provider<SettingsActions>((ref) => SettingsActions(ref));
