import 'package:bms/core/theme/app_colors.dart';
import 'package:bms/core/theme/app_text_styles.dart';
import 'package:bms/data/database/app_database.dart';
import 'package:bms/features/auth/domain/auth_state.dart';
import 'package:bms/l10n/l10n.dart';
import 'package:bms/providers/auth_provider.dart';
import 'package:bms/providers/users_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _devUserId = '00000000-0000-0000-0000-000000000001';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(currentAuthStateProvider);
    final currentUser = authState is Authenticated ? authState.user : null;
    final isDeveloper = currentUser?.role == 'developer';
    final usersAsync = ref.watch(usersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.userManagement),
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (users) {
          final visible = isDeveloper
              ? users
              : users.where((u) => u.role == 'cashier').toList();

          if (visible.isEmpty) {
            return Center(
              child: Text(context.l10n.noUsersFound, style: AppTextStyles.bodySmall),
            );
          }

          return ListView.builder(
            itemCount: visible.length,
            itemBuilder: (_, i) => _UserTile(
              user: visible[i],
              currentUserId: currentUser?.id ?? '',
              canManage: isDeveloper ||
                  (currentUser?.role == 'admin' && visible[i].role == 'cashier'),
            ),
          );
        },
      ),
      floatingActionButton: isDeveloper
          ? FloatingActionButton(
              onPressed: () => _openAddUser(context, ref, isDeveloper: true),
              tooltip: context.l10n.addUser,
              child: const Icon(Icons.person_add_outlined),
            )
          : null,
    );
  }

  void _openAddUser(BuildContext context, WidgetRef ref, {required bool isDeveloper}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AddUserSheet(isDeveloper: isDeveloper),
    );
  }
}

class _UserTile extends ConsumerWidget {
  const _UserTile({
    required this.user,
    required this.currentUserId,
    required this.canManage,
  });

  final User user;
  final String currentUserId;
  final bool canManage;

  Color _roleColor(String role) => switch (role) {
        'developer' => AppColors.primary,
        'admin' => AppColors.warning,
        _ => AppColors.success,
      };

  IconData _roleIcon(String role) => switch (role) {
        'developer' => Icons.code_rounded,
        'admin' => Icons.admin_panel_settings_outlined,
        _ => Icons.person_outline_rounded,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrentUser = user.id == currentUserId;
    final isDevSeed = user.id == _devUserId;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _roleColor(user.role).withAlpha(30),
        child: Icon(_roleIcon(user.role), color: _roleColor(user.role), size: 20),
      ),
      title: Row(
        children: [
          Text(user.name, style: AppTextStyles.labelLarge),
          if (isCurrentUser) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(context.l10n.youLabel, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontSize: 10)),
            ),
          ],
        ],
      ),
      subtitle: Text(
        '@${user.username}  ·  ${user.role.toUpperCase()}',
        style: AppTextStyles.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusChip(isActive: user.isActive),
          if (canManage && !isDevSeed) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              tooltip: context.l10n.edit,
              onPressed: () => _openEdit(context),
            ),
          ],
        ],
      ),
      onTap: (canManage || isCurrentUser) ? () => _openDetail(context, ref, isDevSeed) : null,
    );
  }

  void _openEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EditUserSheet(user: user),
    );
  }

  void _openDetail(BuildContext context, WidgetRef ref, bool isDevSeed) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _UserDetailSheet(
        user: user,
        isDevSeed: isDevSeed,
        isCurrentUser: user.id == currentUserId,
        canManage: canManage,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? AppColors.successLight : AppColors.errorLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isActive ? context.l10n.activeStatus : context.l10n.inactiveStatus,
        style: AppTextStyles.bodySmall.copyWith(
          color: isActive ? AppColors.success : AppColors.error,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _UserDetailSheet extends ConsumerWidget {
  const _UserDetailSheet({
    required this.user,
    required this.isDevSeed,
    required this.isCurrentUser,
    required this.canManage,
  });
  final User user;
  final bool isDevSeed;
  final bool isCurrentUser;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(user.name, style: AppTextStyles.titleLarge),
          const SizedBox(height: 4),
          Text('@${user.username}  ·  ${user.role.toUpperCase()}', style: AppTextStyles.bodySmall),
          if (user.lastLoginAt != null) ...[
            const SizedBox(height: 4),
            Text(
              '${context.l10n.lastLogin} ${_fmt(user.lastLoginAt!)}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
          if (user.passwordChangedAt != null) ...[
            const SizedBox(height: 2),
            Text(
              '${context.l10n.passwordChangedAt} ${_fmt(user.passwordChangedAt!)}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 20),
          if (isCurrentUser) ...[
            OutlinedButton.icon(
              icon: const Icon(Icons.lock_outlined),
              label: Text(context.l10n.changeMyPassword),
              onPressed: () {
                Navigator.of(context).pop();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => _ChangeOwnPasswordSheet(userName: user.name),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
          if (canManage && !isDevSeed && !isCurrentUser) ...[
            OutlinedButton.icon(
              icon: Icon(user.isActive ? Icons.block : Icons.check_circle_outline),
              label: Text(user.isActive ? context.l10n.deactivateAccount : context.l10n.activateAccount),
              style: OutlinedButton.styleFrom(
                foregroundColor: user.isActive ? AppColors.error : AppColors.success,
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await ref.read(userActionsProvider).setActive(user.id, active: !user.isActive);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(user.isActive ? context.l10n.accountDeactivated : context.l10n.accountActivated)),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.lock_reset_outlined),
              label: Text(context.l10n.resetPassword),
              onPressed: () {
                Navigator.of(context).pop();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => _ResetPasswordSheet(userId: user.id, userName: user.name),
                );
              },
            ),
          ],
          if (isDevSeed)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                context.l10n.devSeedWarning,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
              ),
            ),
        ],
      ),
    );
  }

  static String _fmt(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}  '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}


class _AddUserSheet extends ConsumerStatefulWidget {
  const _AddUserSheet({required this.isDeveloper});
  final bool isDeveloper;

  @override
  ConsumerState<_AddUserSheet> createState() => _AddUserSheetState();
}

class _AddUserSheetState extends ConsumerState<_AddUserSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  String _role = 'cashier';
  bool _saving = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(userActionsProvider).createUser(
            name: _name.text.trim(),
            username: _username.text.trim(),
            password: _password.text,
            role: _role,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.userCreated)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.l10n.createUser, style: AppTextStyles.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration: InputDecoration(labelText: context.l10n.fullName),
                validator: (v) => v == null || v.trim().isEmpty ? context.l10n.required : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _username,
                decoration: InputDecoration(labelText: context.l10n.usernameField),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return context.l10n.required;
                  if (v.trim().length < 3) return context.l10n.minCharsUsername;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: context.l10n.passwordField,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return context.l10n.required;
                  if (v.length < 6) return context.l10n.minCharsPassword;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: InputDecoration(labelText: context.l10n.roleField),
                items: [
                  DropdownMenuItem(value: 'cashier', child: Text(context.l10n.roleCashier)),
                  DropdownMenuItem(value: 'admin', child: Text(context.l10n.roleAdmin)),
                  if (widget.isDeveloper)
                    DropdownMenuItem(value: 'developer', child: Text(context.l10n.roleDeveloper)),
                ],
                onChanged: (v) => setState(() => _role = v ?? 'cashier'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(context.l10n.createUser),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _EditUserSheet extends ConsumerStatefulWidget {
  const _EditUserSheet({required this.user});
  final User user;

  @override
  ConsumerState<_EditUserSheet> createState() => _EditUserSheetState();
}

class _EditUserSheetState extends ConsumerState<_EditUserSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _username;
  late String _role;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.name);
    _username = TextEditingController(text: widget.user.username);
    _role = widget.user.role;
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(userActionsProvider).updateUser(
            id: widget.user.id,
            name: _name.text.trim(),
            username: _username.text.trim(),
            role: _role,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.userUpdated)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(currentAuthStateProvider);
    final isDeveloper = authState is Authenticated && authState.user.role == 'developer';

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.editUser, style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: context.l10n.fullName),
              validator: (v) => v == null || v.trim().isEmpty ? context.l10n.required : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _username,
              decoration: InputDecoration(labelText: context.l10n.usernameField),
              validator: (v) => v == null || v.trim().isEmpty ? context.l10n.required : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: InputDecoration(labelText: context.l10n.roleField),
              items: [
                DropdownMenuItem(value: 'cashier', child: Text(context.l10n.roleCashier)),
                DropdownMenuItem(value: 'admin', child: Text(context.l10n.roleAdmin)),
                if (isDeveloper)
                  DropdownMenuItem(value: 'developer', child: Text(context.l10n.roleDeveloper)),
              ],
              onChanged: (v) => setState(() => _role = v ?? _role),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(context.l10n.saveChanges),
            ),
          ],
        ),
      ),
    );
  }
}


class _ChangeOwnPasswordSheet extends ConsumerStatefulWidget {
  const _ChangeOwnPasswordSheet({required this.userName});
  final String userName;

  @override
  ConsumerState<_ChangeOwnPasswordSheet> createState() => _ChangeOwnPasswordSheetState();
}

class _ChangeOwnPasswordSheetState extends ConsumerState<_ChangeOwnPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _newPass = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _newPass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(userActionsProvider).changeOwnPassword(
            currentPassword: _current.text,
            newPassword: _newPass.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.passwordChanged)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.changePasswordTitle(widget.userName), style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _current,
              obscureText: _obscureCurrent,
              decoration: InputDecoration(
                labelText: context.l10n.currentPassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
              validator: (v) => v == null || v.isEmpty ? context.l10n.required : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _newPass,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: context.l10n.newPassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return context.l10n.required;
                if (v.length < 6) return context.l10n.minCharsPassword;
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirm,
              obscureText: _obscureNew,
              decoration: InputDecoration(labelText: context.l10n.confirmNewPassword),
              validator: (v) => v != _newPass.text ? context.l10n.passwordsMustMatch : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(context.l10n.changePassword),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResetPasswordSheet extends ConsumerStatefulWidget {
  const _ResetPasswordSheet({required this.userId, required this.userName});
  final String userId;
  final String userName;

  @override
  ConsumerState<_ResetPasswordSheet> createState() => _ResetPasswordSheetState();
}

class _ResetPasswordSheetState extends ConsumerState<_ResetPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _saving = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(userActionsProvider).resetPassword(
            id: widget.userId,
            newPassword: _password.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.passwordReset)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.resetPasswordTitle(widget.userName), style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: context.l10n.newPassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return context.l10n.required;
                if (v.length < 6) return context.l10n.minCharsPassword;
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(context.l10n.resetPassword),
            ),
          ],
        ),
      ),
    );
  }
}
