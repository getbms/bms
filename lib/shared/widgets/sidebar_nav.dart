import 'package:bms/core/router/app_router.dart';
import 'package:bms/data/models/user_model.dart';
import 'package:bms/features/auth/domain/auth_state.dart';
import 'package:bms/l10n/l10n.dart';
import 'package:bms/licensing/license_provider.dart';
import 'package:bms/providers/auth_provider.dart';
import 'package:bms/shared/widgets/notification_bell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  static List<_NavSection> _buildSections(BuildContext context) => [
    _NavSection(label: context.l10n.navMain, items: [
      _NavItemData(label: context.l10n.navDashboard, icon: Icons.grid_view_rounded, route: AppRoutes.dashboard),
    ]),
    _NavSection(label: context.l10n.navSales, items: [
      _NavItemData(label: context.l10n.navPosSales, icon: Icons.point_of_sale_rounded, route: AppRoutes.pos),
      _NavItemData(label: context.l10n.navQuickSales, icon: Icons.flash_on_rounded, route: AppRoutes.quickSales, minRole: _Role.admin),
      _NavItemData(label: context.l10n.navInvoices, icon: Icons.receipt_long_rounded, route: AppRoutes.invoices, minRole: _Role.admin),
    ]),
    _NavSection(label: context.l10n.navStock, items: [
      _NavItemData(label: context.l10n.navInventory, icon: Icons.inventory_2_rounded, route: AppRoutes.inventory),
      _NavItemData(label: context.l10n.navGrn, icon: Icons.move_to_inbox_rounded, route: AppRoutes.grn, minRole: _Role.admin, requiredFeature: 'grn'),
    ]),
    _NavSection(label: context.l10n.navContacts, items: [
      _NavItemData(label: context.l10n.navCustomers, icon: Icons.people_rounded, route: AppRoutes.customers),
      _NavItemData(label: context.l10n.navDebtors, icon: Icons.account_balance_wallet_outlined, route: AppRoutes.debtors, minRole: _Role.admin, requiredFeature: 'debtors'),
      _NavItemData(label: context.l10n.navSuppliers, icon: Icons.local_shipping_rounded, route: AppRoutes.suppliers, minRole: _Role.admin),
    ]),
    _NavSection(label: context.l10n.navFinance, items: [
      _NavItemData(label: context.l10n.navCheques, icon: Icons.account_balance_rounded, route: AppRoutes.cheques, minRole: _Role.admin, requiredFeature: 'cheques'),
      _NavItemData(label: context.l10n.navPettyCash, icon: Icons.account_balance_wallet_rounded, route: AppRoutes.pettyCash, minRole: _Role.admin, requiredFeature: 'petty_cash'),
    ]),
    _NavSection(label: context.l10n.navAdmin, items: [
      _NavItemData(label: context.l10n.navReports, icon: Icons.bar_chart_rounded, route: AppRoutes.reports, minRole: _Role.admin, requiredFeature: 'reports'),
      _NavItemData(label: context.l10n.navUsers, icon: Icons.manage_accounts_rounded, route: AppRoutes.users, minRole: _Role.developer, requiredFeature: 'users'),
      _NavItemData(label: context.l10n.navSettings, icon: Icons.settings_rounded, route: AppRoutes.settings, minRole: _Role.admin),
    ]),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(currentAuthStateProvider);
    final user = authState is Authenticated ? authState.user : null;
    final role = user?.role ?? 'cashier';
    final features = ref.watch(allowedFeaturesProvider);

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
                children: [
                  for (final section in _buildSections(context)) ...[
                    // Only show section if at least one item is visible
                    if (section.items.any(
                        (i) => i.isVisibleFor(role) && i.isFeatureAllowed(features))) ...[
                      if (!collapsed)
                        _SectionLabel(label: section.label)
                      else
                        const SizedBox(height: 4),
                      for (final item in section.items)
                        if (item.isVisibleFor(role) && item.isFeatureAllowed(features))
                          _NavTile(
                            item: item,
                            isActive: currentLocation.startsWith(item.route),
                            collapsed: collapsed,
                            onTap: () => context.go(item.route),
                          ),
                      if (collapsed)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: Divider(color: Color(0xFF1F2937), height: 1),
                        ),
                    ],
                  ],
                ],
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


class _Header extends StatelessWidget {
  const _Header({required this.collapsed});
  final bool collapsed;

  static Widget get _logoMark => SvgPicture.asset(
        'assets/images/bms_logo.svg',
        width: 32,
        height: 32,
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 120;
        return Padding(
          padding: EdgeInsets.fromLTRB(narrow ? 0 : 20, 16, narrow ? 0 : 20, 14),
          child: narrow
              ? Center(child: _logoMark)
              : Row(
                  children: [
                    _logoMark,
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
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
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: _kSidebarText, fontSize: 11)),
                        ],
                      ),
                    ),
                    const NotificationBell(iconColor: _kSidebarText),
                  ],
                ),
        );
      },
    );
  }
}


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
            child: LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 120;
                  if (narrow) {
                    return SizedBox(
                      height: 40,
                      child: Center(
                        child: Icon(
                          widget.item.icon,
                          size: 18,
                          color: active ? _kSidebarAccent : _kSidebarText,
                        ),
                      ),
                    );
                  }
                  return Padding(
                    padding: EdgeInsets.fromLTRB(active ? 13 : 16, 10, 12, 10),
                    child: Row(
                      children: [
                        Icon(widget.item.icon,
                            size: 18,
                            color: active ? _kSidebarAccent : _kSidebarText),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            widget.item.label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: active ? _kSidebarActiveText : _kSidebarText,
                              fontSize: 13.5,
                              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 120;
        if (narrow) {
          return Tooltip(
            message: '${user.name}  (${user.role})',
            preferBelow: false,
            child: InkWell(
              onTap: () => ref.read(authStateProvider.notifier).logout(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(child: avatar),
              ),
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
                tooltip: context.l10n.signOut,
                onPressed: () => ref.read(authStateProvider.notifier).logout(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
        );
      },
    );
  }
}


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


enum _Role { cashier, admin, developer }

_Role _parseRole(String r) => switch (r) {
      'developer' => _Role.developer,
      'admin' => _Role.admin,
      _ => _Role.cashier,
    };

class _NavSection {
  const _NavSection({required this.label, required this.items});
  final String label;
  final List<_NavItemData> items;
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF4B5563),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.label,
    required this.icon,
    required this.route,
    this.minRole = _Role.cashier,
    this.requiredFeature,
  });

  final String label;
  final IconData icon;
  final String route;
  final _Role minRole;
  final String? requiredFeature;

  bool isVisibleFor(String roleStr) =>
      _parseRole(roleStr).index >= minRole.index;

  bool isFeatureAllowed(Set<String> features) =>
      requiredFeature == null || features.contains(requiredFeature!);
}
