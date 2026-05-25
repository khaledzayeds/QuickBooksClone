// reports_repository.dart

import '../../../../core/api/api_result.dart';
import '../datasources/reports_remote_datasource.dart';
import '../models/report_models.dart';

class ReportsRepository {
  ReportsRepository(this._datasource);

  final ReportsRemoteDatasource _datasource;

  Future<ApiResult<TrialBalanceReportModel>> getTrialBalance({
    DateTime? asOfDate,
    bool includeZeroBalances = false,
    bool includeInactiveAccounts = false,
  }) =>
      _datasource.getTrialBalance(
        asOfDate: asOfDate,
        includeZeroBalances: includeZeroBalances,
        includeInactiveAccounts: includeInactiveAccounts,
      );

  Future<ApiResult<FinancialStatementReportModel>> getBalanceSheet({
    DateTime? asOfDate,
    bool includeZeroBalances = false,
    bool includeInactiveAccounts = false,
  }) =>
      _datasource.getBalanceSheet(
        asOfDate: asOfDate,
        includeZeroBalances: includeZeroBalances,
        includeInactiveAccounts: includeInactiveAccounts,
      );

  Future<ApiResult<ProfitAndLossReportModel>> getProfitAndLoss({
    DateTime? fromDate,
    DateTime? toDate,
    bool includeZeroBalances = false,
    bool includeInactiveAccounts = false,
  }) =>
      _datasource.getProfitAndLoss(
        fromDate: fromDate,
        toDate: toDate,
        includeZeroBalances: includeZeroBalances,
        includeInactiveAccounts: includeInactiveAccounts,
      );

  Future<ApiResult<AgingReportModel>> getAccountsReceivableAging({
    DateTime? asOfDate,
    bool includeZeroBalances = false,
    bool includeInactiveCustomers = false,
  }) =>
      _datasource.getAccountsReceivableAging(
        asOfDate: asOfDate,
        includeZeroBalances: includeZeroBalances,
        includeInactiveCustomers: includeInactiveCustomers,
      );

  Future<ApiResult<AgingReportModel>> getAccountsPayableAging({
    DateTime? asOfDate,
    bool includeZeroBalances = false,
    bool includeInactiveVendors = false,
  }) =>
      _datasource.getAccountsPayableAging(
        asOfDate: asOfDate,
        includeZeroBalances: includeZeroBalances,
        includeInactiveVendors: includeInactiveVendors,
      );

  Future<ApiResult<InventoryValuationReportModel>> getInventoryValuation({
    DateTime? fromDate,
    DateTime? toDate,
    bool includeZeroBalances = false,
    bool includeInactiveItems = false,
  }) =>
      _datasource.getInventoryValuation(
        fromDate: fromDate,
        toDate: toDate,
        includeZeroBalances: includeZeroBalances,
        includeInactiveItems: includeInactiveItems,
      );

  Future<ApiResult<TaxSummaryReportModel>> getTaxSummary({
    DateTime? fromDate,
    DateTime? toDate,
    bool includeZeroRows = false,
  }) =>
      _datasource.getTaxSummary(
        fromDate: fromDate,
        toDate: toDate,
        includeZeroRows: includeZeroRows,
      );
}
