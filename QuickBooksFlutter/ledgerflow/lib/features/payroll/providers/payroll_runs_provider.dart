import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/utils/json_utils.dart';

final payrollRunsProvider = FutureProvider.autoDispose<PayrollRunList>((ref) async {
  final response = await ApiClient.instance.get<Map<String, dynamic>>('/api/payroll/runs');
  return PayrollRunList.fromJson(response.data!);
});

final payrollRunDetailsProvider = FutureProvider.autoDispose.family<PayrollRunDetails, String>((ref, id) async {
  final response = await ApiClient.instance.get<Map<String, dynamic>>('/api/payroll/runs/$id');
  return PayrollRunDetails.fromJson(response.data!);
});

final payrollRunCommandsProvider = Provider<PayrollRunCommands>((ref) => PayrollRunCommands(ref));

class PayrollRunCommands {
  const PayrollRunCommands(this.ref);

  final Ref ref;

  Future<void> create({
    required DateTime periodStart,
    required DateTime periodEnd,
    required DateTime payDate,
    required String paySchedule,
    required double regularHoursPerEmployee,
    required double overtimeHoursPerEmployee,
    required double taxWithholdingRate,
  }) async {
    await ApiClient.instance.post<Map<String, dynamic>>(
      '/api/payroll/runs',
      data: {
        'periodStart': _dateOnly(periodStart),
        'periodEnd': _dateOnly(periodEnd),
        'payDate': _dateOnly(payDate),
        'paySchedule': paySchedule,
        'regularHoursPerEmployee': regularHoursPerEmployee,
        'overtimeHoursPerEmployee': overtimeHoursPerEmployee,
        'taxWithholdingRate': taxWithholdingRate,
      },
    );
    ref.invalidate(payrollRunsProvider);
  }

  Future<void> approve(String id) async {
    await ApiClient.instance.post<Map<String, dynamic>>('/api/payroll/runs/$id/approve');
    ref.invalidate(payrollRunsProvider);
    ref.invalidate(payrollRunDetailsProvider(id));
  }

  Future<void> post(String id) async {
    await ApiClient.instance.post<Map<String, dynamic>>('/api/payroll/runs/$id/post');
    ref.invalidate(payrollRunsProvider);
    ref.invalidate(payrollRunDetailsProvider(id));
  }

  Future<void> voidRun(String id) async {
    await ApiClient.instance.patch<Map<String, dynamic>>('/api/payroll/runs/$id/void');
    ref.invalidate(payrollRunsProvider);
    ref.invalidate(payrollRunDetailsProvider(id));
  }
}

class PayrollRunList {
  const PayrollRunList({
    required this.items,
    required this.totalCount,
    required this.totalGrossPay,
    required this.totalDeductions,
    required this.totalNetPay,
  });

  final List<PayrollRunSummary> items;
  final int totalCount;
  final double totalGrossPay;
  final double totalDeductions;
  final double totalNetPay;

  factory PayrollRunList.fromJson(Map<String, dynamic> json) => PayrollRunList(
        items: JsonUtils.asList(json['items'], (row) => PayrollRunSummary.fromJson(row)),
        totalCount: JsonUtils.asInt(json['totalCount']),
        totalGrossPay: JsonUtils.asDouble(json['totalGrossPay']),
        totalDeductions: JsonUtils.asDouble(json['totalDeductions']),
        totalNetPay: JsonUtils.asDouble(json['totalNetPay']),
      );
}

class PayrollRunSummary {
  const PayrollRunSummary({
    required this.id,
    required this.runNumber,
    required this.periodStart,
    required this.periodEnd,
    required this.payDate,
    required this.paySchedule,
    required this.currency,
    required this.status,
    required this.journalEntryId,
    required this.employeeCount,
    required this.totalGrossPay,
    required this.totalDeductions,
    required this.totalNetPay,
  });

  final String id;
  final String runNumber;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime payDate;
  final String paySchedule;
  final String currency;
  final String status;
  final String? journalEntryId;
  final int employeeCount;
  final double totalGrossPay;
  final double totalDeductions;
  final double totalNetPay;

  factory PayrollRunSummary.fromJson(Map<String, dynamic> json) => PayrollRunSummary(
        id: JsonUtils.asString(json['id']),
        runNumber: JsonUtils.asString(json['runNumber']),
        periodStart: _parseDate(json['periodStart']),
        periodEnd: _parseDate(json['periodEnd']),
        payDate: _parseDate(json['payDate']),
        paySchedule: JsonUtils.asString(json['paySchedule']),
        currency: JsonUtils.asString(json['currency']),
        status: JsonUtils.asString(json['status']),
        journalEntryId: JsonUtils.asNullableString(json['journalEntryId']),
        employeeCount: JsonUtils.asInt(json['employeeCount']),
        totalGrossPay: JsonUtils.asDouble(json['totalGrossPay']),
        totalDeductions: JsonUtils.asDouble(json['totalDeductions']),
        totalNetPay: JsonUtils.asDouble(json['totalNetPay']),
      );
}

class PayrollRunDetails {
  const PayrollRunDetails({
    required this.id,
    required this.runNumber,
    required this.periodStart,
    required this.periodEnd,
    required this.payDate,
    required this.paySchedule,
    required this.currency,
    required this.status,
    required this.journalEntryId,
    required this.regularHoursPerEmployee,
    required this.overtimeHoursPerEmployee,
    required this.taxWithholdingRate,
    required this.employeeCount,
    required this.totalGrossPay,
    required this.totalDeductions,
    required this.totalNetPay,
    required this.lines,
  });

  final String id;
  final String runNumber;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime payDate;
  final String paySchedule;
  final String currency;
  final String status;
  final String? journalEntryId;
  final double regularHoursPerEmployee;
  final double overtimeHoursPerEmployee;
  final double taxWithholdingRate;
  final int employeeCount;
  final double totalGrossPay;
  final double totalDeductions;
  final double totalNetPay;
  final List<PayrollRunLine> lines;

  factory PayrollRunDetails.fromJson(Map<String, dynamic> json) => PayrollRunDetails(
        id: JsonUtils.asString(json['id']),
        runNumber: JsonUtils.asString(json['runNumber']),
        periodStart: _parseDate(json['periodStart']),
        periodEnd: _parseDate(json['periodEnd']),
        payDate: _parseDate(json['payDate']),
        paySchedule: JsonUtils.asString(json['paySchedule']),
        currency: JsonUtils.asString(json['currency']),
        status: JsonUtils.asString(json['status']),
        journalEntryId: JsonUtils.asNullableString(json['journalEntryId']),
        regularHoursPerEmployee: JsonUtils.asDouble(json['regularHoursPerEmployee']),
        overtimeHoursPerEmployee: JsonUtils.asDouble(json['overtimeHoursPerEmployee']),
        taxWithholdingRate: JsonUtils.asDouble(json['taxWithholdingRate']),
        employeeCount: JsonUtils.asInt(json['employeeCount']),
        totalGrossPay: JsonUtils.asDouble(json['totalGrossPay']),
        totalDeductions: JsonUtils.asDouble(json['totalDeductions']),
        totalNetPay: JsonUtils.asDouble(json['totalNetPay']),
        lines: JsonUtils.asList(json['lines'], (row) => PayrollRunLine.fromJson(row)),
      );
}

class PayrollRunLine {
  const PayrollRunLine({
    required this.id,
    required this.employeeId,
    required this.employeeNumber,
    required this.employeeName,
    required this.regularHours,
    required this.overtimeHours,
    required this.hourlyRate,
    required this.grossPay,
    required this.deductions,
    required this.netPay,
  });

  final String id;
  final String employeeId;
  final String employeeNumber;
  final String employeeName;
  final double regularHours;
  final double overtimeHours;
  final double hourlyRate;
  final double grossPay;
  final double deductions;
  final double netPay;

  factory PayrollRunLine.fromJson(Map<String, dynamic> json) => PayrollRunLine(
        id: JsonUtils.asString(json['id']),
        employeeId: JsonUtils.asString(json['employeeId']),
        employeeNumber: JsonUtils.asString(json['employeeNumber']),
        employeeName: JsonUtils.asString(json['employeeName']),
        regularHours: JsonUtils.asDouble(json['regularHours']),
        overtimeHours: JsonUtils.asDouble(json['overtimeHours']),
        hourlyRate: JsonUtils.asDouble(json['hourlyRate']),
        grossPay: JsonUtils.asDouble(json['grossPay']),
        deductions: JsonUtils.asDouble(json['deductions']),
        netPay: JsonUtils.asDouble(json['netPay']),
      );
}

String _dateOnly(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
DateTime _parseDate(dynamic value) => DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
