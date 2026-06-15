import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/daos/audit_log_dao.dart';
import '../../../features/auth/domain/auth_state.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(currentAuthStateProvider);
    final role = authState is Authenticated ? authState.user.role : 'cashier';
    final isDev = role == 'developer';
    final isAdmin = role == 'admin' || isDev;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Store info (admin+)
          if (isAdmin) ...[
            _SectionHeader(title: 'Store Info', icon: Icons.store_outlined),
            const _StoreInfoTile(),
            const SizedBox(height: 24),
          ],

          // Language
          _SectionHeader(title: 'Language', icon: Icons.language_outlined),
          const _LanguageTile(),
          const SizedBox(height: 24),

          // Products CSV import (admin+)
          if (isAdmin) ...[
            _SectionHeader(title: 'Products', icon: Icons.inventory_2_outlined),
            _ActionTile(
              icon: Icons.upload_file_outlined,
              title: 'Import Products from CSV',
              subtitle: 'Bulk add products via CSV file\nFormat: name, unit_type, cost_price, sell_price, barcode, brand, reorder_level',
              color: AppColors.primary,
              onTap: () => _importCsv(context, ref),
            ),
            const SizedBox(height: 8),
            _ActionTile(
              icon: Icons.download_outlined,
              title: 'Download CSV Template',
              subtitle: 'Get a blank template to fill in',
              color: AppColors.success,
              onTap: () => _downloadTemplate(context),
            ),
            const SizedBox(height: 24),
          ],

          // Database (developer only)
          if (isDev) ...[
            _SectionHeader(title: 'Database', icon: Icons.storage_outlined),
            _ActionTile(
              icon: Icons.cloud_download_outlined,
              title: 'Export Database',
              subtitle: 'Download all data as a JSON backup',
              color: AppColors.primary,
              onTap: () => _exportDb(context, ref),
            ),
            const SizedBox(height: 8),
            _ActionTile(
              icon: Icons.cloud_upload_outlined,
              title: 'Import Database',
              subtitle: 'Restore from a JSON backup file',
              color: AppColors.warning,
              onTap: () => _importDb(context, ref),
            ),
            const SizedBox(height: 24),
          ],

          // Audit log (admin+)
          if (isAdmin) ...[
            _SectionHeader(title: 'Audit Log', icon: Icons.history_outlined),
            _ActionTile(
              icon: Icons.list_alt_outlined,
              title: 'View Audit Log',
              subtitle: 'See all tracked changes across the system',
              color: AppColors.primary,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const _AuditLogScreen()),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // App info (all roles)
          _SectionHeader(title: 'About', icon: Icons.info_outline),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BMS - Business Manager', style: AppTextStyles.labelLarge),
                const SizedBox(height: 4),
                Text('Version 1.0.0', style: AppTextStyles.bodySmall),
                const SizedBox(height: 4),
                Text('Role: ${role.toUpperCase()}', style: AppTextStyles.bodySmall),
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
    if (inserted == 0 && skipped == 0 && errors.isEmpty) return; // user cancelled
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('CSV Import Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Inserted: $inserted', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success)),
            Text('Skipped: $skipped', style: AppTextStyles.bodyMedium),
            if (errors.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Errors:', style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
              ...errors.take(5).map((e) => Text(e, style: AppTextStyles.bodySmall)),
            ],
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
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
        title: const Text('Import Database'),
        content: const Text(
          'This will add records from the backup file. Existing records will not be overwritten. Continue?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Import')),
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
        const SnackBar(content: Text('Download not supported in web preview')),
      );
      return;
    }
    try {
      final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved: ${file.path}')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e'), backgroundColor: AppColors.error),
      );
    }
  }
}

// Store info tile

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
    // Load persisted values then sync controllers
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
      const SnackBar(
        content: Text('Store info saved'),
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
            decoration: const InputDecoration(
              labelText: 'Store Name',
              hintText: 'e.g. My Shop',
              prefixIcon: Icon(Icons.storefront_outlined),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressCtrl,
            decoration: const InputDecoration(
              labelText: 'Address',
              hintText: 'e.g. 123 Main St, Colombo',
              prefixIcon: Icon(Icons.location_on_outlined),
              isDense: true,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(
              labelText: 'Phone',
              hintText: 'e.g. 077 123 4567',
              prefixIcon: Icon(Icons.phone_outlined),
              isDense: true,
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: _saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_outlined, size: 18),
            label: Text(_saving ? 'Saving...' : 'Save Store Info'),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}

// Language tile

class _LanguageTile extends ConsumerWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(languageProvider);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: supportedLanguages.map((lang) {
          final (code, label) = lang;
          return RadioListTile<String>(
            title: Text(label, style: AppTextStyles.bodyMedium),
            value: code,
            groupValue: current,
            activeColor: AppColors.primary,
            dense: true,
            onChanged: (v) async {
              if (v != null) await ref.read(languageProvider.notifier).set(v);
            },
          );
        }).toList(),
      ),
    );
  }
}

// Reusable widgets

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
              Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// Audit Log Screen

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
        title: const Text('Audit Log'),
        actions: [
          PopupMenuButton<String?>(
            icon: Badge(
              isLabelVisible: _filterType != null,
              child: const Icon(Icons.filter_list),
            ),
            tooltip: 'Filter by type',
            onSelected: (v) => setState(() => _filterType = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('All')),
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
            return const Center(child: Text('No audit entries.', style: AppTextStyles.bodySmall));
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
                          Text('Before:', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                          Text(entry.oldValue!, style: AppTextStyles.bodySmall),
                          const SizedBox(height: 8),
                        ],
                        if (entry.newValue != null) ...[
                          Text('After:', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                          Text(entry.newValue!, style: AppTextStyles.bodySmall),
                        ],
                        const SizedBox(height: 8),
                        Text('By: ${entry.userName}  at  ${fmt.format(entry.createdAt.toLocal())}',
                            style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  actions: [TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Close'))],
                ),
              )
          : null,
    );
  }
}
