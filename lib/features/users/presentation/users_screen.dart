import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/database/app_database.dart';
import '../../../features/auth/domain/auth_state.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/users_provider.dart';

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
        title: const Text('User Management'),
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (users) {
          // Admins can only see cashiers; developers see all
          final visible = isDeveloper
              ? users
              : users.where((u) => u.role == 'cashier').toList();

          if (visible.isEmpty) {
            return const Center(
              child: Text('No users found.', style: AppTextStyles.bodySmall),
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
              tooltip: 'Add User',
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
              child: Text('You', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontSize: 10)),
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
              tooltip: 'Edit',
              onPressed: () => _openEdit(context),
            ),
          ],
        ],
      ),
      onTap: canManage ? () => _openDetail(context, ref, isDevSeed) : null,
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
      builder: (_) => _UserDetailSheet(user: user, isDevSeed: isDevSeed),
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
        isActive ? 'Active' : 'Inactive',
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
  const _UserDetailSheet({required this.user, required this.isDevSeed});
  final User user;
  final bool isDevSeed;

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
          const SizedBox(height: 20),
          if (!isDevSeed) ...[
            OutlinedButton.icon(
              icon: Icon(user.isActive ? Icons.block : Icons.check_circle_outline),
              label: Text(user.isActive ? 'Deactivate Account' : 'Activate Account'),
              style: OutlinedButton.styleFrom(
                foregroundColor: user.isActive ? AppColors.error : AppColors.success,
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await ref.read(userActionsProvider).setActive(user.id, active: !user.isActive);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(user.isActive ? 'Account deactivated.' : 'Account activated.')),
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
              label: const Text('Reset Password'),
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
          ] else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Developer seed account - cannot be deactivated or deleted.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
              ),
            ),
        ],
      ),
    );
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User created.')));
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
              const Text('Create User', style: AppTextStyles.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full Name *', isDense: true),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _username,
                decoration: const InputDecoration(labelText: 'Username *', isDense: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.trim().length < 3) return 'Min 3 characters';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password *',
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length < 6) return 'Min 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Role *', isDense: true),
                items: [
                  const DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
                  const DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  if (widget.isDeveloper)
                    const DropdownMenuItem(value: 'developer', child: Text('Developer')),
                ],
                onChanged: (v) => setState(() => _role = v ?? 'cashier'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Create User'),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User updated.')));
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
            const Text('Edit User', style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Full Name *', isDense: true),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _username,
              decoration: const InputDecoration(labelText: 'Username *', isDense: true),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: const InputDecoration(labelText: 'Role *', isDense: true),
              items: [
                const DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
                const DropdownMenuItem(value: 'admin', child: Text('Admin')),
                if (isDeveloper)
                  const DropdownMenuItem(value: 'developer', child: Text('Developer')),
              ],
              onChanged: (v) => setState(() => _role = v ?? _role),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Changes'),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset.')));
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
            Text('Reset Password - ${widget.userName}', style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'New Password *',
                isDense: true,
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v.length < 6) return 'Min 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Reset Password'),
            ),
          ],
        ),
      ),
    );
  }
}
