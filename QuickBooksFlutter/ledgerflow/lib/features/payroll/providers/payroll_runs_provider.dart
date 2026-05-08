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

final payrollRunJournalLinksProvider = FutureProvider.autoDispose.family<PayrollRunJournalLinks, String>((ref, id) async {
  final response = await ApiClient.instance.get<Map<String, dynamic>>('/api/payroll/runs/$id/journal-links');
  return PayrollRunJournalLinks.fromJson(response.data!);
});

final payrollSummaryReportProvider = FutureProvider.autoDispose<PayrollSummaryReport>((ref) async {
  final response = await ApiClient.instance.get<Map<String, dynamic>>('/api/payroll/reports/summary');
  return PayrollSummaryReport.fromJson(response.data!);
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
    ref.invalidate(payrollSummaryReportProvider);
  }

  Future<void> approve(String id) async {
    await ApiClient.instance.post<Map<String, dynamic>>('/api/payroll/runs/$id/approve');
    ref.invalidate(payrollRunsProvider);
    ref.invalidate(payrollRunDetailsProvider(id));
    ref.invalidate(payrollRunJournalLinksProvider(id));
    ref.invalidate(payrollSummaryReportProvider);
  }

  Future<void> post(String id) async {
    await ApiClient.instance.post<Map<String, dynamic>>('/api/payroll/runs/$id/post');
    ref.invalidate(payrollRunsProvider);
    ref.invalidate(payrollRunDetailsProvider(id));
    ref.invalidate(payrollRunJournalLinksProvider(id));
    ref.invalidate(payrollSummaryReportProvider);
  }

  Future<void> voidRun(String id) async {
    await ApiClient.instance.patch<Map<String, dynamic>>('/api/payroll/runs/$id/void');
    ref.invalidate(payrollRunsProvider);
    ref.invalidate(payrollRunDetailsProvider(id));
    ref.invalidate(payrollRunJournalLinksProvider(id));
    ref.invalidate(payrollSummaryReportProvider);
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

class PayrollRunJournalLinks {
  const PayrollRunJournalLinks({
    required this.runId,
    required this.journalEntryId,
    required this.reversalJournalEntryId,
    required this.hasOriginalJournal,
    required this.hasReversalJournal,
  });

  final String runId;
  final String? journalEntryId;
  final String? reversalJournalEntryId;
  final bool hasOriginalJournal;
  final bool hasReversalJournal;

  factory PayrollRunJournalLinks.fromJson(Map<String, dynamic> json) => PayrollRunJournalLinks(
        runId: JsonUtils.asString(json['runId']),
        journalEntryId: JsonUtils.asNullableString(json['journalEntryId']),
        reversalJournalEntryId: JsonUtils.asNullableString(json['reversalJournalEntryId']),
        hasOriginalJournal: JsonUtils.asBool(json['hasOriginalJournal']),
        hasReversalJournal: JsonUtils.asBool(json['hasReversalJournal']),
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

class PayrollSummaryReport {
  const PayrollSummaryReport({
    required this.fromDate,
    required this.toDate,
    required this.runCount,
    required this.employeeCount,
    required this.totalGrossPay,
    required this.totalDeductions,
    required this.totalNetPay,
    required this.byStatus,
    required this.byEmployee,
    required this.runs,
  });

  final DateTime? fromDate;
  final DateTime? toDate;
  final int runCount;
  final int employeeCount;
  final double totalGrossPay;
  final double totalDeductions;
  final double totalNetPay;
  final List<PayrollSummaryByStatus> byStatus;
  final List<PayrollSummaryByEmployee> byEmployee;
  final List<PayrollSummaryRun> runs;

  factory PayrollSummaryReport.fromJson(Map<String, dynamic> json) => PayrollSummaryReport(
        fromDate: _parseNullableDate(json['fromDate']),
        toDate: _parseNullableDate(json['toDate']),
        runCount: JsonUtils.asInt(json['runCount']),
        employeeCount: JsonUtils.asInt(json['employeeCount']),
        totalGrossPay: JsonUtils.asDouble(json['totalGrossPay']),
        totalDeductions: JsonUtils.asDouble(json['totalDeductions']),
        totalNetPay: JsonUtils.asDouble(json['totalNetPay']),
        byStatus: JsonUtils.asList(json['byStatus'], (row) => PayrollSummaryByStatus.fromJson(row)),
        byEmployee: JsonUtils.asList(json['byEmployee'], (row) => PayrollSummaryByEmployee.fromJson(row)),
        runs: JsonUtils.asList(json['runs'], (row) => PayrollSummaryRun.fromJson(row)),
      );
}

class PayrollSummaryByStatus {
  const PayrollSummaryByStatus({required this.status, required this.runCount, required this.grossPay, required this.deductions, required this.netPay});

  final String status;
  final int runCount;
  final double grossPay;
  final double deductions;
  final double netPay;

  factory PayrollSummaryByStatus.fromJson(Map<String, dynamic> json) => PayrollSummaryByStatus(
        status: JsonUtils.asString(json['status']),
        runCount: JsonUtils.asInt(json['runCount']),
        grossPay: JsonUtils.asDouble(json['grossPay']),
        deductions: JsonUtils.asDouble(json['deductions']),
        netPay: JsonUtils.asDouble(json['netPay']),
      );
}

class PayrollSummaryByEmployee {
  const PayrollSummaryByEmployee({required this.employeeId, required this.employeeNumber, required this.employeeName, required this.grossPay, required this.deductions, required this.netPay});

  final String employeeId;
  final String employeeNumber;
  final String employeeName;
  final double grossPay;
  final double deductions;
  final double netPay;

  factory PayrollSummaryByEmployee.fromJson(Map<String, dynamic> json) => PayrollSummaryByEmployee(
        employeeId: JsonUtils.asString(json['employeeId']),
        employeeNumber: JsonUtils.asString(json['employeeNumber']),
        employeeName: JsonUtils.asString(json['employeeName']),
        grossPay: JsonUtils.asDouble(json['grossPay']),
        deductions: JsonUtils.asDouble(json['deductions']),
        netPay: JsonUtils.asDouble(json['netPay']),
      );
}

class PayrollSummaryRun {
  const PayrollSummaryRun({
    required this.id,
    required this.runNumber,
    required this.periodStart,
    required this.periodEnd,
    required this.payDate,
    required this.status,
    required this.currency,
    required this.employeeCount,
    required this.grossPay,
    required this.deductions,
    required this.netPay,
    required this.journalEntryId,
  });

  final String id;
  final String runNumber;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime payDate;
  final String status;
  final String currency;
  final int employeeCount;
  final double grossPay;
  final double deductions;
  final double netPay;
  final String? journalEntryId;

  factory PayrollSummaryRun.fromJson(Map<String, dynamic> json) => PayrollSummaryRun(
        id: JsonUtils.asString(json['id']),
        runNumber: JsonUtils.asString(json['runNumber']),
        periodStart: _parseDate(json['periodStart']),
        periodEnd: _parseDate(json['periodEnd']),
        payDate: _parseDate(json['payDate']),
        status: JsonUtils.asString(json['status']),
        currency: JsonUtils.asString(json['currency']),
        employeeCount: JsonUtils.asInt(json['employeeCount']),
        grossPay: JsonUtils.asDouble(json['grossPay']),
        deductions: JsonUtils.asDouble(json['deductions']),
        netPay: JsonUtils.asDouble(json['netPay']),
        journalEntryId: JsonUtils.asNullableString(json['journalEntryId']),
      );
}

String _dateOnly(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
DateTime _parseDate(dynamic value) => DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
DateTime? _parseNullableDate(dynamic value) => value == null ? null : DateTime.tryParse(value.toString());
