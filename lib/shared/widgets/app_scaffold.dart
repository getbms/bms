import 'package:bms/core/router/app_router.dart';
import 'package:bms/core/theme/app_colors.dart';
import 'package:bms/l10n/l10n.dart';
import 'package:bms/shared/widgets/notification_bell.dart';
import 'package:bms/shared/widgets/sidebar_nav.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key, required this.child});

  final Widget child;

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  bool _collapsed = true;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final isWide = MediaQuery.sizeOf(context).width >= 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          if (isWide)
            SidebarNav(
              currentLocation: location,
              collapsed: _collapsed,
              onToggle: () => setState(() => _collapsed = !_collapsed),
            ),
          Expanded(child: ClipRect(child: widget.child)),
        ],
      ),
      bottomNavigationBar: isWide ? null : _BottomNav(currentLocation: location),
      floatingActionButton: isWide
          ? null
          : const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: NotificationBell(iconColor: AppColors.primary),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndTop,
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentLocation});

  final String currentLocation;

  static List<({String label, IconData icon, String route})> _buildItems(
          BuildContext context) =>
      [
        (label: context.l10n.navDashboard, icon: Icons.grid_view_rounded, route: AppRoutes.dashboard),
        (label: context.l10n.navPos, icon: Icons.point_of_sale_rounded, route: AppRoutes.pos),
        (label: context.l10n.navInventory, icon: Icons.inventory_2_rounded, route: AppRoutes.inventory),
        (label: context.l10n.navCustomers, icon: Icons.people_rounded, route: AppRoutes.customers),
        (label: context.l10n.navMore, icon: Icons.menu_rounded, route: AppRoutes.reports),
      ];

  @override
  Widget build(BuildContext context) {
    final items = _buildItems(context);
    final currentIndex = items.indexWhere((i) => currentLocation.startsWith(i.route));

    return NavigationBar(
      selectedIndex: currentIndex < 0 ? 0 : currentIndex,
      onDestinationSelected: (i) => context.go(items[i].route),
      destinations: items
          .map((i) => NavigationDestination(icon: Icon(i.icon), label: i.label))
          .toList(),
    );
  }
}
