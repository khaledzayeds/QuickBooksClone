// reports_remote_datasource.dart

import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/utils/error_handler.dart';
import '../models/report_models.dart';

class ReportsRemoteDatasource {
  ReportsRemoteDatasource(this._client);

  final ApiClient _client;

  Future<ApiResult<TrialBalanceReportModel>> getTrialBalance({
    DateTime? asOfDate,
    bool includeZeroBalances = false,
    bool includeInactiveAccounts = false,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/reports/trial-balance',
        queryParameters: {
          if (asOfDate != null) 'asOfDate': _dateOnly(asOfDate),
          'includeZeroBalances': includeZeroBalances,
          'includeInactiveAccounts': includeInactiveAccounts,
        },
      );
      return Success(TrialBalanceReportModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<FinancialStatementReportModel>> getBalanceSheet({
    DateTime? asOfDate,
    bool includeZeroBalances = false,
    bool includeInactiveAccounts = false,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/reports/balance-sheet',
        queryParameters: {
          if (asOfDate != null) 'asOfDate': _dateOnly(asOfDate),
          'includeZeroBalances': includeZeroBalances,
          'includeInactiveAccounts': includeInactiveAccounts,
        },
      );
      return Success(FinancialStatementReportModel.fromBalanceSheetJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<ProfitAndLossReportModel>> getProfitAndLoss({
    DateTime? fromDate,
    DateTime? toDate,
    bool includeZeroBalances = false,
    bool includeInactiveAccounts = false,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/reports/profit-and-loss',
        queryParameters: {
          if (fromDate != null) 'fromDate': _dateOnly(fromDate),
          if (toDate != null) 'toDate': _dateOnly(toDate),
          'includeZeroBalances': includeZeroBalances,
          'includeInactiveAccounts': includeInactiveAccounts,
        },
      );
      return Success(ProfitAndLossReportModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<AgingReportModel>> getAccountsReceivableAging({
    DateTime? asOfDate,
    bool includeZeroBalances = false,
    bool includeInactiveCustomers = false,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/reports/accounts-receivable-aging',
        queryParameters: {
          if (asOfDate != null) 'asOfDate': _dateOnly(asOfDate),
          'includeZeroBalances': includeZeroBalances,
          'includeInactiveCustomers': includeInactiveCustomers,
        },
      );
      return Success(AgingReportModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<AgingReportModel>> getAccountsPayableAging({
    DateTime? asOfDate,
    bool includeZeroBalances = false,
    bool includeInactiveVendors = false,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/reports/accounts-payable-aging',
        queryParameters: {
          if (asOfDate != null) 'asOfDate': _dateOnly(asOfDate),
          'includeZeroBalances': includeZeroBalances,
          'includeInactiveVendors': includeInactiveVendors,
        },
      );
      return Success(AgingReportModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<InventoryValuationReportModel>> getInventoryValuation({
    DateTime? fromDate,
    DateTime? toDate,
    bool includeZeroBalances = false,
    bool includeInactiveItems = false,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/reports/inventory-valuation',
        queryParameters: {
          if (fromDate != null) 'fromDate': _dateOnly(fromDate),
          if (toDate != null) 'toDate': _dateOnly(toDate),
          'includeZeroBalances': includeZeroBalances,
          'includeInactiveItems': includeInactiveItems,
        },
      );
      return Success(InventoryValuationReportModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<TaxSummaryReportModel>> getTaxSummary({
    DateTime? fromDate,
    DateTime? toDate,
    bool includeZeroRows = false,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/reports/tax-summary',
        queryParameters: {
          if (fromDate != null) 'fromDate': _dateOnly(fromDate),
          if (toDate != null) 'toDate': _dateOnly(toDate),
          'includeZeroRows': includeZeroRows,
        },
      );
      return Success(TaxSummaryReportModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
