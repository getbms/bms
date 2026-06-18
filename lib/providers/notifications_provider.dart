import 'package:bms/data/database/app_database.dart';
import 'package:bms/providers/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AlertType { chequeOverdue, chequeDue, lowStock, creditExceeded }

class AppAlert {
  const AppAlert({
    required this.type,
    required this.title,
    required this.body,
  });

  final AlertType type;
  final String title;
  final String body;
}

final notificationsProvider = FutureProvider.autoDispose<List<AppAlert>>((ref) async {
  final chequesDao = ref.watch(chequesDaoProvider);
  final inventoryDao = ref.watch(inventoryDaoProvider);
  final customersDao = ref.watch(customersDaoProvider);

  final (overdue, dueSoon, lowStock, debtors) = await (
    chequesDao.getOverdueCheques(),
    chequesDao.getDueWithinDays(7),
    inventoryDao.getLowStockProducts(),
    customersDao.getDebtors(),
  ).wait;

  final alerts = <AppAlert>[];

  for (final Cheque c in overdue) {
    alerts.add(AppAlert(
      type: AlertType.chequeOverdue,
      title: 'Cheque Overdue',
      body: '${c.partyName} · ${c.dueDate.day}/${c.dueDate.month}/${c.dueDate.year}',
    ));
  }

  for (final Cheque c in dueSoon) {
    alerts.add(AppAlert(
      type: AlertType.chequeDue,
      title: 'Cheque Due in 7 Days',
      body: '${c.partyName} · ${c.dueDate.day}/${c.dueDate.month}/${c.dueDate.year}',
    ));
  }

  for (final Product p in lowStock) {
    alerts.add(AppAlert(
      type: AlertType.lowStock,
      title: 'Low Stock',
      body: p.name,
    ));
  }

  for (final Customer c in debtors) {
    if (c.creditLimit > 0 && c.balance > c.creditLimit) {
      alerts.add(AppAlert(
        type: AlertType.creditExceeded,
        title: 'Credit Limit Exceeded',
        body: c.name,
      ));
    }
  }

  return alerts;
});
