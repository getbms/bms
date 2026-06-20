import 'package:bms/core/theme/app_colors.dart';
import 'package:bms/core/theme/app_text_styles.dart';
import 'package:bms/l10n/l10n.dart';
import 'package:bms/providers/notifications_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key, this.iconColor = Colors.white});

  final Color iconColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(notificationsProvider);
    final count = alertsAsync.when(
      data: (alerts) => alerts.length,
      loading: () => 0,
      error: (_, _) => 0,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: iconColor),
          tooltip: context.l10n.alertsTooltip,
          onPressed: () => _showPanel(context, ref),
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showPanel(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _AlertsPanel(),
    );
  }
}

class _AlertsPanel extends ConsumerWidget {
  const _AlertsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(notificationsProvider);

    return DraggableScrollableSheet(
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          _PanelHandle(
            onRefresh: () => ref.invalidate(notificationsProvider),
          ),
          Expanded(
            child: alertsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (alerts) => alerts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_outline,
                              size: 48, color: AppColors.success),
                          const SizedBox(height: 12),
                          Text(context.l10n.alertsAllClear,
                              style: AppTextStyles.titleMedium),
                          const SizedBox(height: 4),
                          Text(context.l10n.alertsNone,
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      itemCount: alerts.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (_, i) => _AlertTile(alert: alerts[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelHandle extends StatelessWidget {
  const _PanelHandle({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.textDisabled,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(context.l10n.alertsPanelTitle,
                    style: AppTextStyles.titleLarge),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: context.l10n.refresh,
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});

  final AppAlert alert;

  IconData get _icon => switch (alert.type) {
        AlertType.chequeOverdue => Icons.warning_amber_rounded,
        AlertType.chequeDue => Icons.schedule_rounded,
        AlertType.lowStock => Icons.inventory_2_outlined,
        AlertType.creditExceeded => Icons.credit_card_off_outlined,
      };

  Color get _color => switch (alert.type) {
        AlertType.chequeOverdue => AppColors.error,
        AlertType.chequeDue => AppColors.warning,
        AlertType.lowStock => AppColors.warning,
        AlertType.creditExceeded => AppColors.error,
      };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: _color.withAlpha(20),
        child: Icon(_icon, color: _color, size: 18),
      ),
      title: Text(alert.title,
          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(alert.body, style: AppTextStyles.bodySmall),
      dense: true,
    );
  }
}
