// reports_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../payroll/providers/payroll_runs_provider.dart';
import '../../time_tracking/providers/time_entries_provider.dart';
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

final payrollReportHubProvider = FutureProvider.autoDispose<PayrollSummaryReport>((ref) async {
  final response = await ApiClient.instance.get<Map<String, dynamic>>('/api/payroll/reports/summary');
  return PayrollSummaryReport.fromJson(response.data!);
});

final timeTrackingReportHubProvider = FutureProvider.autoDispose<TimeEntrySummaryReport>((ref) async {
  final response = await ApiClient.instance.get<Map<String, dynamic>>('/api/time-entries/reports/summary');
  return TimeEntrySummaryReport.fromJson(response.data!);
});

final salesSummaryReportProvider = FutureProvider.autoDispose<SalesSummaryReportModel>((ref) async {
  final response = await ApiClient.instance.get<Map<String, dynamic>>('/api/reports/sales-summary');
  return SalesSummaryReportModel.fromJson(response.data!);
});

final purchasesSummaryReportProvider = FutureProvider.autoDispose<PurchasesSummaryReportModel>((ref) async {
  final response = await ApiClient.instance.get<Map<String, dynamic>>('/api/reports/purchases-summary');
  return PurchasesSummaryReportModel.fromJson(response.data!);
});
