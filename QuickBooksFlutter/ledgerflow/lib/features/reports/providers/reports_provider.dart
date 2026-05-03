// reports_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../data/datasources/reports_remote_datasource.dart';
import '../data/models/report_models.dart';
import '../data/repositories/reports_repository.dart';

final reportsDatasourceProvider = Provider<ReportsRemoteDatasource>(
  (ref) => ReportsRemoteDatasource(ApiClient.instance),
);

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepository(ref.watch(reportsDatasourceProvider)),
);

final trialBalanceReportProvider = FutureProvider.autoDispose<TrialBalanceReportModel>((ref) async {
  final result = await ref.read(reportsRepositoryProvider).getTrialBalance();
  return result.when(success: (data) => data, failure: (error) => throw error);
});

final balanceSheetReportProvider = FutureProvider.autoDispose<FinancialStatementReportModel>((ref) async {
  final result = await ref.read(reportsRepositoryProvider).getBalanceSheet();
  return result.when(success: (data) => data, failure: (error) => throw error);
});

final profitAndLossReportProvider = FutureProvider.autoDispose<ProfitAndLossReportModel>((ref) async {
  final result = await ref.read(reportsRepositoryProvider).getProfitAndLoss();
  return result.when(success: (data) => data, failure: (error) => throw error);
});

final accountsReceivableAgingReportProvider = FutureProvider.autoDispose<AgingReportModel>((ref) async {
  final result = await ref.read(reportsRepositoryProvider).getAccountsReceivableAging();
  return result.when(success: (data) => data, failure: (error) => throw error);
});

final accountsPayableAgingReportProvider = FutureProvider.autoDispose<AgingReportModel>((ref) async {
  final result = await ref.read(reportsRepositoryProvider).getAccountsPayableAging();
  return result.when(success: (data) => data, failure: (error) => throw error);
});

final inventoryValuationReportProvider = FutureProvider.autoDispose<InventoryValuationReportModel>((ref) async {
  final result = await ref.read(reportsRepositoryProvider).getInventoryValuation();
  return result.when(success: (data) => data, failure: (error) => throw error);
});

final taxSummaryReportProvider = FutureProvider.autoDispose<TaxSummaryReportModel>((ref) async {
  final result = await ref.read(reportsRepositoryProvider).getTaxSummary();
  return result.when(success: (data) => data, failure: (error) => throw error);
});
