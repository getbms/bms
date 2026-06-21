import 'package:bms/core/router/app_router.dart';
import 'package:bms/core/theme/app_colors.dart';
import 'package:bms/l10n/l10n.dart';
import 'package:bms/licensing/license_model.dart';
import 'package:bms/licensing/license_provider.dart';
import 'package:bms/shared/widgets/notification_bell.dart';
import 'package:bms/shared/widgets/sidebar_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppScaffold extends ConsumerStatefulWidget {
  const AppScaffold({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends ConsumerState<AppScaffold> {
  bool _collapsed = true;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final isWide   = MediaQuery.sizeOf(context).width >= 700;
    final licStatus = ref.watch(licenseStatusProvider);

    final nav = Row(
      children: [
        if (isWide)
          SidebarNav(
            currentLocation: location,
            collapsed: _collapsed,
            onToggle: () => setState(() => _collapsed = !_collapsed),
          ),
        Expanded(child: ClipRect(child: widget.child)),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          if (licStatus == LicenseStatus.grace)
            _GraceBanner(
              remaining: ref.watch(licenseProvider).value
                  ?.gracePeriodRemaining,
            ),
          Expanded(child: nav),
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

class _GraceBanner extends StatelessWidget {
  const _GraceBanner({this.remaining});
  final Duration? remaining;

  @override
  Widget build(BuildContext context) {
    final days = remaining == null ? 0 : remaining!.inDays;
    return Container(
      width: double.infinity,
      color: const Color(0xFF78350F),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFFBBF24), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'License validation overdue. $days day${days == 1 ? '' : 's'} remaining before the app locks. '
              'Connect to the internet to renew.',
              style: const TextStyle(
                  color: Color(0xFFFDE68A), fontSize: 12),
            ),
          ),
        ],
      ),
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
