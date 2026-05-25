// reports_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

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

final reportsDateRangeProvider = StateProvider<ReportDateRange>((ref) {
  final today = DateTime.now();
  return ReportDateRange(
    fromDate: DateTime(today.year, today.month, 1),
    toDate: today,
  );
});

final trialBalanceReportProvider =
    FutureProvider.autoDispose<TrialBalanceReportModel>((ref) async {
      final range = ref.watch(reportsDateRangeProvider);
      final result = await ref
          .read(reportsRepositoryProvider)
          .getTrialBalance(asOfDate: range.toDate);
      return result.when(
        success: (data) => data,
        failure: (error) => throw error,
      );
    });

final balanceSheetReportProvider =
    FutureProvider.autoDispose<FinancialStatementReportModel>((ref) async {
      final range = ref.watch(reportsDateRangeProvider);
      final result = await ref
          .read(reportsRepositoryProvider)
          .getBalanceSheet(asOfDate: range.toDate);
      return result.when(
        success: (data) => data,
        failure: (error) => throw error,
      );
    });

final profitAndLossReportProvider =
    FutureProvider.autoDispose<ProfitAndLossReportModel>((ref) async {
      final range = ref.watch(reportsDateRangeProvider);
      final result = await ref
          .read(reportsRepositoryProvider)
          .getProfitAndLoss(fromDate: range.fromDate, toDate: range.toDate);
      return result.when(
        success: (data) => data,
        failure: (error) => throw error,
      );
    });

final accountsReceivableAgingReportProvider =
    FutureProvider.autoDispose<AgingReportModel>((ref) async {
      final range = ref.watch(reportsDateRangeProvider);
      final result = await ref
          .read(reportsRepositoryProvider)
          .getAccountsReceivableAging(asOfDate: range.toDate);
      return result.when(
        success: (data) => data,
        failure: (error) => throw error,
      );
    });

final accountsPayableAgingReportProvider =
    FutureProvider.autoDispose<AgingReportModel>((ref) async {
      final range = ref.watch(reportsDateRangeProvider);
      final result = await ref
          .read(reportsRepositoryProvider)
          .getAccountsPayableAging(asOfDate: range.toDate);
      return result.when(
        success: (data) => data,
        failure: (error) => throw error,
      );
    });

final inventoryValuationReportProvider =
    FutureProvider.autoDispose<InventoryValuationReportModel>((ref) async {
      final range = ref.watch(reportsDateRangeProvider);
      final result = await ref
          .read(reportsRepositoryProvider)
          .getInventoryValuation(
            fromDate: range.fromDate,
            toDate: range.toDate,
          );
      return result.when(
        success: (data) => data,
        failure: (error) => throw error,
      );
    });

final taxSummaryReportProvider =
    FutureProvider.autoDispose<TaxSummaryReportModel>((ref) async {
      final range = ref.watch(reportsDateRangeProvider);
      final result = await ref
          .read(reportsRepositoryProvider)
          .getTaxSummary(fromDate: range.fromDate, toDate: range.toDate);
      return result.when(
        success: (data) => data,
        failure: (error) => throw error,
      );
    });

final payrollReportHubProvider =
    FutureProvider.autoDispose<PayrollSummaryReport>((ref) async {
      final range = ref.watch(reportsDateRangeProvider);
      final response = await ApiClient.instance.get<Map<String, dynamic>>(
        '/api/payroll/reports/summary',
        queryParameters: range.queryParameters,
      );
      return PayrollSummaryReport.fromJson(response.data!);
    });

final timeTrackingReportHubProvider =
    FutureProvider.autoDispose<TimeEntrySummaryReport>((ref) async {
      final range = ref.watch(reportsDateRangeProvider);
      final response = await ApiClient.instance.get<Map<String, dynamic>>(
        '/api/time-entries/reports/summary',
        queryParameters: range.queryParameters,
      );
      return TimeEntrySummaryReport.fromJson(response.data!);
    });

final salesSummaryReportProvider =
    FutureProvider.autoDispose<SalesSummaryReportModel>((ref) async {
      final range = ref.watch(reportsDateRangeProvider);
      final response = await ApiClient.instance.get<Map<String, dynamic>>(
        '/api/reports/sales-summary',
        queryParameters: range.queryParameters,
      );
      return SalesSummaryReportModel.fromJson(response.data!);
    });

final purchasesSummaryReportProvider =
    FutureProvider.autoDispose<PurchasesSummaryReportModel>((ref) async {
      final range = ref.watch(reportsDateRangeProvider);
      final response = await ApiClient.instance.get<Map<String, dynamic>>(
        '/api/reports/purchases-summary',
        queryParameters: range.queryParameters,
      );
      return PurchasesSummaryReportModel.fromJson(response.data!);
    });

class ReportDateRange {
  const ReportDateRange({required this.fromDate, required this.toDate});

  final DateTime fromDate;
  final DateTime toDate;

  Map<String, dynamic> get queryParameters => {
    'fromDate': _dateOnly(fromDate),
    'toDate': _dateOnly(toDate),
  };

  ReportDateRange copyWith({DateTime? fromDate, DateTime? toDate}) =>
      ReportDateRange(
        fromDate: fromDate ?? this.fromDate,
        toDate: toDate ?? this.toDate,
      );
}

String _dateOnly(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
