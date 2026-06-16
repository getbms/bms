import 'package:bms/data/database/daos/reports_dao.dart';
import 'package:bms/providers/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reports_provider.g.dart';

@riverpod
Future<List<DailySales>> dailySales(Ref ref, DateTime from, DateTime to) =>
    ref.read(reportsDaoProvider).getDailySales(from, to);

@riverpod
Future<List<StockValuationRow>> stockValuation(Ref ref) =>
    ref.read(reportsDaoProvider).getStockValuation();

@riverpod
Future<List<DebtorAgingRow>> debtorAging(Ref ref) =>
    ref.read(reportsDaoProvider).getDebtorAging();
