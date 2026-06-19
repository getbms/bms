import 'dart:io';

import 'package:bms/core/theme/app_colors.dart';
import 'package:bms/core/theme/app_text_styles.dart';
import 'package:bms/data/database/app_database.dart';
import 'package:bms/features/auth/domain/auth_state.dart';
import 'package:bms/l10n/l10n.dart';
import 'package:bms/providers/auth_provider.dart';
import 'package:bms/providers/settings_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(currentAuthStateProvider);
    final role = authState is Authenticated ? authState.user.role : 'cashier';
    final isDev = role == 'developer';
    final isAdmin = role == 'admin' || isDev;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (isAdmin) ...[
            _SectionHeader(title: context.l10n.storeInfo, icon: Icons.store_outlined),
            const _StoreInfoTile(),
            const SizedBox(height: 24),
          ],

          _SectionHeader(title: context.l10n.languageSection, icon: Icons.language_outlined),
          const _LanguageTile(),
          const SizedBox(height: 24),

          if (isAdmin) ...[
            _SectionHeader(title: context.l10n.productsSection, icon: Icons.inventory_2_outlined),
            _ActionTile(
              icon: Icons.upload_file_outlined,
              title: context.l10n.importProductsCsv,
              subtitle: context.l10n.importProductsCsvHint,
              color: AppColors.primary,
              onTap: () => _importCsv(context, ref),
            ),
            const SizedBox(height: 8),
            _ActionTile(
              icon: Icons.download_outlined,
              title: context.l10n.downloadTemplate,
              subtitle: context.l10n.downloadTemplateHint,
              color: AppColors.success,
              onTap: () => _downloadTemplate(context),
            ),
            const SizedBox(height: 24),
          ],

          if (isDev) ...[
            _SectionHeader(title: context.l10n.databaseSection, icon: Icons.storage_outlined),
            _ActionTile(
              icon: Icons.cloud_download_outlined,
              title: context.l10n.exportDatabase,
              subtitle: context.l10n.exportDatabaseHint,
              color: AppColors.primary,
              onTap: () => _exportDb(context, ref),
            ),
            const SizedBox(height: 8),
            _ActionTile(
              icon: Icons.cloud_upload_outlined,
              title: context.l10n.importDatabase,
              subtitle: context.l10n.importDatabaseHint,
              color: AppColors.warning,
              onTap: () => _importDb(context, ref),
            ),
            const SizedBox(height: 24),

            _SectionHeader(title: context.l10n.dbConnectionSection, icon: Icons.dns_outlined),
            const _DbConnectionTile(),
            const SizedBox(height: 24),
          ],

          if (isAdmin) ...[
            _SectionHeader(title: context.l10n.auditLogSection, icon: Icons.history_outlined),
            _ActionTile(
              icon: Icons.list_alt_outlined,
              title: context.l10n.viewAuditLog,
              subtitle: context.l10n.viewAuditLogHint,
              color: AppColors.primary,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const _AuditLogScreen()),
              ),
            ),
            const SizedBox(height: 24),
          ],

          _SectionHeader(title: context.l10n.aboutSection, icon: Icons.info_outline),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.appNameVersion, style: AppTextStyles.labelLarge),
                const SizedBox(height: 4),
                Text(context.l10n.appVersion, style: AppTextStyles.bodySmall),
                const SizedBox(height: 4),
                Text('${context.l10n.roleLabel} ${role.toUpperCase()}', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importCsv(BuildContext context, WidgetRef ref) async {
    (int, int, List<String>) result;
    try {
      result = await ref.read(settingsActionsProvider).importProductsFromCsv();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (!context.mounted) return;
    final (inserted, skipped, errors) = result;
    if (inserted == 0 && skipped == 0 && errors.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.csvImportComplete),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${context.l10n.inserted} $inserted', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success)),
            Text('${context.l10n.skipped} $skipped', style: AppTextStyles.bodyMedium),
            if (errors.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(context.l10n.errors, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
              ...errors.take(5).map((e) => Text(e, style: AppTextStyles.bodySmall)),
            ],
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.ok))],
      ),
    );
  }

  Future<void> _downloadTemplate(BuildContext context) {
    const csv = 'name,unit_type,cost_price,sell_price,barcode,brand,reorder_level\n'
        'Sample Product,pcs,100.00,150.00,,Brand Name,10\n';
    return _downloadBytes(
      context,
      Uint8List.fromList(csv.codeUnits),
      'products_template.csv',
    );
  }

  Future<void> _exportDb(BuildContext context, WidgetRef ref) async {
    try {
      final bytes = await ref.read(settingsActionsProvider).exportDatabaseAsJson();
      if (!context.mounted) return;
      final filename = 'bms_backup_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.json';
      _downloadBytes(context, bytes, filename);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _importDb(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.importDatabase),
        content: Text(context.l10n.importDatabaseMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(context.l10n.importDatabaseConfirm)),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final msg = await ref.read(settingsActionsProvider).importDatabaseFromJson();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _downloadBytes(BuildContext context, Uint8List bytes, String filename) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.downloadNotSupportedWeb)),
      );
      return;
    }
    try {
      final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.fileSaved(file.path))),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e'), backgroundColor: AppColors.error),
      );
    }
  }
}

class _StoreInfoTile extends ConsumerStatefulWidget {
  const _StoreInfoTile();

  @override
  ConsumerState<_StoreInfoTile> createState() => _StoreInfoTileState();
}

class _StoreInfoTileState extends ConsumerState<_StoreInfoTile> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final info = ref.read(storeInfoProvider);
    _nameCtrl = TextEditingController(text: info.name);
    _addressCtrl = TextEditingController(text: info.address);
    _phoneCtrl = TextEditingController(text: info.phone);
    ref.read(storeInfoProvider.notifier).load().then((_) {
      if (!mounted) return;
      final loaded = ref.read(storeInfoProvider);
      _nameCtrl.text = loaded.name;
      _addressCtrl.text = loaded.address;
      _phoneCtrl.text = loaded.phone;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(storeInfoProvider.notifier).save(
          name: _nameCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.storeInfoSaved),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: context.l10n.storeName,
              hintText: context.l10n.storeNameHint,
              prefixIcon: const Icon(Icons.storefront_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressCtrl,
            decoration: InputDecoration(
              labelText: context.l10n.address,
              hintText: context.l10n.storeAddressHint,
              prefixIcon: const Icon(Icons.location_on_outlined),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            decoration: InputDecoration(
              labelText: context.l10n.phone,
              hintText: context.l10n.storePhoneHint,
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              icon: _saving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: Text(_saving ? context.l10n.saving : context.l10n.saveStoreInfo),
              onPressed: _saving ? null : _save,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends ConsumerWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(languageProvider);
    return Material(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(12),
      child: RadioGroup<String>(
        groupValue: current,
        onChanged: (v) async {
          if (v != null) await ref.read(languageProvider.notifier).set(v);
        },
        child: Column(
          children: supportedLanguages.map((lang) {
            final (code, label) = lang;
            return RadioListTile<String>(
              title: Text(label, style: AppTextStyles.bodyMedium),
              value: code,
              activeColor: AppColors.primary,
              dense: true,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _DbConnectionTile extends ConsumerStatefulWidget {
  const _DbConnectionTile();

  @override
  ConsumerState<_DbConnectionTile> createState() => _DbConnectionTileState();
}

class _DbConnectionTileState extends ConsumerState<_DbConnectionTile> {
  late TextEditingController _hostCtrl;
  late TextEditingController _portCtrl;
  late TextEditingController _dbCtrl;
  late TextEditingController _userCtrl;
  late TextEditingController _passCtrl;
  bool _obscurePass = true;
  bool _saving = false;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(dbConnectionSettingsProvider);
    _hostCtrl = TextEditingController(text: s.host);
    _portCtrl = TextEditingController(text: s.port.toString());
    _dbCtrl = TextEditingController(text: s.database);
    _userCtrl = TextEditingController(text: s.username);
    _passCtrl = TextEditingController(text: s.password);
    ref.read(dbConnectionSettingsProvider.notifier).load().then((_) {
      if (!mounted) return;
      final loaded = ref.read(dbConnectionSettingsProvider);
      _hostCtrl.text = loaded.host;
      _portCtrl.text = loaded.port.toString();
      _dbCtrl.text = loaded.database;
      _userCtrl.text = loaded.username;
      _passCtrl.text = loaded.password;
    });
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _dbCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  DbConnectionSettings _buildSettings(DbConnectionType type) => DbConnectionSettings(
        type: type,
        host: _hostCtrl.text.trim(),
        port: int.tryParse(_portCtrl.text.trim()) ?? 3306,
        database: _dbCtrl.text.trim(),
        username: _userCtrl.text.trim(),
        password: _passCtrl.text,
      );

  Future<void> _save(DbConnectionType type) async {
    setState(() => _saving = true);
    await ref.read(dbConnectionSettingsProvider.notifier).save(_buildSettings(type));
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connection settings saved'), backgroundColor: AppColors.success),
    );
  }

  Future<void> _testConnection(DbConnectionType type) async {
    setState(() => _testing = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _testing = false);

    if (type == DbConnectionType.localSqlite) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.sqliteConnOk),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.mysqlSyncPlanned(_hostCtrl.text.trim(), _portCtrl.text.trim()),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(dbConnectionSettingsProvider);
    final type = current.type;
    final isMysql = type != DbConnectionType.localSqlite;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l10n.dbBackend, style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<DbConnectionType>(
            segments: [
              ButtonSegment(
                value: DbConnectionType.localSqlite,
                label: Text(context.l10n.dbSqliteLocal),
                icon: const Icon(Icons.storage_rounded, size: 16),
              ),
              ButtonSegment(
                value: DbConnectionType.localMysql,
                label: Text(context.l10n.dbMysqlLocal),
                icon: const Icon(Icons.computer_rounded, size: 16),
              ),
              ButtonSegment(
                value: DbConnectionType.remoteMysql,
                label: Text(context.l10n.dbMysqlRemote),
                icon: const Icon(Icons.cloud_outlined, size: 16),
              ),
            ],
            selected: {type},
            onSelectionChanged: (s) async {
              final newType = s.first;
              await ref.read(dbConnectionSettingsProvider.notifier).save(
                    _buildSettings(newType),
                  );
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              textStyle: WidgetStateProperty.all(AppTextStyles.bodySmall),
            ),
          ),
          if (isMysql) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _hostCtrl,
                    decoration: InputDecoration(
                      labelText: context.l10n.dbHost,
                      hintText: context.l10n.dbHostHint,
                      prefixIcon: const Icon(Icons.dns_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 88,
                  child: TextField(
                    controller: _portCtrl,
                    decoration: InputDecoration(labelText: context.l10n.dbPort),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dbCtrl,
              decoration: InputDecoration(
                labelText: context.l10n.dbName,
                hintText: context.l10n.dbNameHint,
                prefixIcon: const Icon(Icons.table_chart_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _userCtrl,
              decoration: InputDecoration(
                labelText: context.l10n.dbUsername,
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              obscureText: _obscurePass,
              decoration: InputDecoration(
                labelText: context.l10n.dbPassword,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                icon: _testing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_tethering_rounded, size: 16),
                label: Text(context.l10n.test),
                onPressed: (_saving || _testing) ? null : () => _testConnection(type),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: _saving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined, size: 16),
                label: Text(_saving ? context.l10n.saving : context.l10n.save),
                onPressed: (_saving || _testing) ? null : () => _save(type),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(title, style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary)),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.labelLarge),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuditLogScreen extends ConsumerStatefulWidget {
  const _AuditLogScreen();

  @override
  ConsumerState<_AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<_AuditLogScreen> {
  String? _filterType;

  static const _types = ['user', 'product', 'invoice', 'cheque', 'stock', 'petty_cash', 'database'];

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(auditLogProvider(_filterType));

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.auditLogTitle),
        actions: [
          PopupMenuButton<String?>(
            icon: Badge(
              isLabelVisible: _filterType != null,
              child: const Icon(Icons.filter_list),
            ),
            tooltip: context.l10n.filterByType,
            onSelected: (v) => setState(() => _filterType = v),
            itemBuilder: (_) => [
              PopupMenuItem(child: Text(context.l10n.filterAll2)),
              ..._types.map((t) => PopupMenuItem(value: t, child: Text(t))),
            ],
          ),
        ],
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (logs) {
          if (logs.isEmpty) {
            return Center(child: Text(context.l10n.noAuditEntries, style: AppTextStyles.bodySmall));
          }
          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (_, i) => _AuditRow(entry: logs[i]),
          );
        },
      ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({required this.entry});
  final AuditLogData entry;

  Color _actionColor(String action) => switch (action) {
        'create' => AppColors.success,
        'delete' => AppColors.error,
        'void' => AppColors.error,
        'approve' => AppColors.success,
        'reject' => AppColors.error,
        _ => AppColors.warning,
      };

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy  HH:mm');
    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _actionColor(entry.action).withAlpha(20),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          entry.action.toUpperCase(),
          style: AppTextStyles.bodySmall.copyWith(
            color: _actionColor(entry.action),
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(entry.entityType, style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
          ),
          const SizedBox(width: 8),
          Text(entry.userName, style: AppTextStyles.labelLarge),
        ],
      ),
      subtitle: Text(fmt.format(entry.createdAt.toLocal()), style: AppTextStyles.bodySmall),
      onTap: entry.newValue != null || entry.oldValue != null
          ? () => showDialog<void>(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  title: Text('${entry.action} / ${entry.entityType}'),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (entry.oldValue != null) ...[
                          Text(context.l10n.auditBefore, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                          Text(entry.oldValue!, style: AppTextStyles.bodySmall),
                          const SizedBox(height: 8),
                        ],
                        if (entry.newValue != null) ...[
                          Text(context.l10n.auditAfter, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                          Text(entry.newValue!, style: AppTextStyles.bodySmall),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          '${context.l10n.by} ${entry.userName}  ${context.l10n.auditAt}  ${fmt.format(entry.createdAt.toLocal())}',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  actions: [TextButton(onPressed: () => Navigator.pop(dialogCtx), child: Text(context.l10n.close))],
                ),
              )
          : null,
    );
  }
}
