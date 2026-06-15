import 'package:bms/core/router/app_router.dart';
import 'package:bms/data/models/user_model.dart';
import 'package:bms/features/auth/domain/auth_state.dart';
import 'package:bms/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _kSidebarBg = Color(0xFF111827);
const _kSidebarHover = Color(0xFF1F2937);
const _kSidebarActive = Color(0xFF1D4ED8);
const _kSidebarActiveText = Colors.white;
const _kSidebarText = Color(0xFF9CA3AF);
const _kSidebarAccent = Color(0xFF3B82F6);
const _kSidebarDivider = Color(0xFF1F2937);

const double _kExpandedWidth = 224;
const double _kCollapsedWidth = 56;
const Duration _kAnimDuration = Duration(milliseconds: 200);

class SidebarNav extends ConsumerWidget {
  const SidebarNav({
    super.key,
    required this.currentLocation,
    required this.collapsed,
    required this.onToggle,
  });

  final String currentLocation;
  final bool collapsed;
  final VoidCallback onToggle;

  static const List<_NavItemData> _navItems = [
    _NavItemData(label: 'Dashboard', icon: Icons.grid_view_rounded, route: AppRoutes.dashboard),
    _NavItemData(label: 'POS / Sales', icon: Icons.point_of_sale_rounded, route: AppRoutes.pos),
    _NavItemData(label: 'Invoices', icon: Icons.receipt_long_rounded, route: AppRoutes.invoices, minRole: _Role.admin),
    _NavItemData(label: 'Inventory', icon: Icons.inventory_2_rounded, route: AppRoutes.inventory),
    _NavItemData(label: 'Customers', icon: Icons.people_rounded, route: AppRoutes.customers),
    _NavItemData(label: 'Debtors', icon: Icons.account_balance_wallet_outlined, route: AppRoutes.debtors, minRole: _Role.admin),
    _NavItemData(label: 'Suppliers', icon: Icons.local_shipping_rounded, route: AppRoutes.suppliers, minRole: _Role.admin),
    _NavItemData(label: 'Cheques', icon: Icons.account_balance_rounded, route: AppRoutes.cheques, minRole: _Role.admin),
    _NavItemData(label: 'Petty Cash', icon: Icons.account_balance_wallet_rounded, route: AppRoutes.pettyCash, minRole: _Role.admin),
    _NavItemData(label: 'Reports', icon: Icons.bar_chart_rounded, route: AppRoutes.reports, minRole: _Role.admin),
    _NavItemData(label: 'Users', icon: Icons.manage_accounts_rounded, route: AppRoutes.users, minRole: _Role.developer),
    _NavItemData(label: 'Settings', icon: Icons.settings_rounded, route: AppRoutes.settings, minRole: _Role.admin),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(currentAuthStateProvider);
    final user = authState is Authenticated ? authState.user : null;
    final role = user?.role ?? 'cashier';

    return AnimatedContainer(
      duration: _kAnimDuration,
      curve: Curves.easeInOut,
      width: collapsed ? _kCollapsedWidth : _kExpandedWidth,
      color: _kSidebarBg,
      child: ClipRect(
        child: Column(
          children: [
            _Header(collapsed: collapsed),
            const Divider(color: _kSidebarDivider, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: _navItems
                    .where((item) => item.isVisibleFor(role))
                    .map((item) => _NavTile(
                          item: item,
                          isActive: currentLocation.startsWith(item.route),
                          collapsed: collapsed,
                          onTap: () => context.go(item.route),
                        ))
                    .toList(),
              ),
            ),
            const Divider(color: _kSidebarDivider, height: 1),
            if (user != null) _UserFooter(user: user, ref: ref, collapsed: collapsed),
            _ToggleButton(collapsed: collapsed, onToggle: onToggle),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.collapsed});
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(collapsed ? 0 : 20, 16, collapsed ? 0 : 20, 14),
      child: collapsed
          ? Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _kSidebarAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 18),
              ),
            )
          : Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _kSidebarAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BMS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        )),
                    Text('Business Manager',
                        style: TextStyle(color: _kSidebarText, fontSize: 11)),
                  ],
                ),
              ],
            ),
    );
  }
}

// ── Nav tile ──────────────────────────────────────────────────────────────────

class _NavTile extends StatefulWidget {
  const _NavTile({
    required this.item,
    required this.isActive,
    required this.collapsed,
    required this.onTap,
  });

  final _NavItemData item;
  final bool isActive;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;

    final tile = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: active
                  ? _kSidebarActive.withAlpha(40)
                  : _hovered
                      ? _kSidebarHover
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              border: active
                  ? const Border(left: BorderSide(color: _kSidebarAccent, width: 3))
                  : const Border(),
            ),
            child: widget.collapsed
                ? SizedBox(
                    height: 40,
                    child: Center(
                      child: Icon(
                        widget.item.icon,
                        size: 18,
                        color: active ? _kSidebarAccent : _kSidebarText,
                      ),
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.fromLTRB(active ? 13 : 16, 10, 12, 10),
                    child: Row(
                      children: [
                        Icon(widget.item.icon,
                            size: 18,
                            color: active ? _kSidebarAccent : _kSidebarText),
                        const SizedBox(width: 11),
                        Text(
                          widget.item.label,
                          style: TextStyle(
                            color: active ? _kSidebarActiveText : _kSidebarText,
                            fontSize: 13.5,
                            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );

    if (widget.collapsed) {
      return Tooltip(
        message: widget.item.label,
        preferBelow: false,
        waitDuration: const Duration(milliseconds: 300),
        child: tile,
      );
    }
    return tile;
  }
}

// ── User footer ───────────────────────────────────────────────────────────────

class _UserFooter extends StatelessWidget {
  const _UserFooter({required this.user, required this.ref, required this.collapsed});

  final UserModel user;
  final WidgetRef ref;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: 16,
      backgroundColor: _kSidebarAccent.withAlpha(50),
      child: Text(
        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
        style: const TextStyle(
            color: _kSidebarAccent, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );

    if (collapsed) {
      return Tooltip(
        message: '${user.name}  (${user.role})',
        preferBelow: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(child: avatar),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          avatar,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
                Text(user.role.toUpperCase(),
                    style: const TextStyle(color: _kSidebarText, fontSize: 10.5)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 16, color: _kSidebarText),
            tooltip: 'Sign out',
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}

// ── Toggle button ─────────────────────────────────────────────────────────────

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({required this.collapsed, required this.onToggle});
  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Container(
        height: 36,
        color: const Color(0xFF0D1321),
        alignment: Alignment.center,
        child: Icon(
          collapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
          color: _kSidebarText,
          size: 20,
        ),
      ),
    );
  }
}

// ── Data types ────────────────────────────────────────────────────────────────

enum _Role { cashier, admin, developer }

_Role _parseRole(String r) => switch (r) {
      'developer' => _Role.developer,
      'admin' => _Role.admin,
      _ => _Role.cashier,
    };

class _NavItemData {
  const _NavItemData({
    required this.label,
    required this.icon,
    required this.route,
    this.minRole = _Role.cashier,
  });

  final String label;
  final IconData icon;
  final String route;
  final _Role minRole;

  bool isVisibleFor(String roleStr) => _parseRole(roleStr).index >= minRole.index;
}
