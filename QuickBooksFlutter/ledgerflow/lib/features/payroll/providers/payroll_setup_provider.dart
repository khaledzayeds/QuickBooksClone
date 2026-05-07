import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/utils/json_utils.dart';

final payrollSetupProvider = FutureProvider.autoDispose<PayrollSetup>((ref) async {
  final response = await ApiClient.instance.get<Map<String, dynamic>>('/api/payroll/setup');
  return PayrollSetup.fromJson(response.data!);
});

final payrollSetupCommandsProvider = Provider<PayrollSetupCommands>((ref) => PayrollSetupCommands(ref));

class PayrollSetupCommands {
  const PayrollSetupCommands(this.ref);

  final Ref ref;

  Future<void> updateSettings({
    required String defaultPaySchedule,
    required String defaultCurrency,
    required int workWeekHours,
    required bool isPayrollEnabled,
  }) async {
    await ApiClient.instance.put<Map<String, dynamic>>(
      '/api/payroll/setup/settings',
      data: {
        'defaultPaySchedule': defaultPaySchedule,
        'defaultCurrency': defaultCurrency,
        'workWeekHours': workWeekHours,
        'isPayrollEnabled': isPayrollEnabled,
      },
    );
    ref.invalidate(payrollSetupProvider);
  }

  Future<void> createEmployee({
    required String employeeNumber,
    required String displayName,
    String? email,
    required String paySchedule,
    required double defaultHourlyRate,
    required String currency,
    required bool isActive,
  }) async {
    await ApiClient.instance.post<Map<String, dynamic>>(
      '/api/payroll/setup/employees',
      data: {
        'employeeNumber': employeeNumber,
        'displayName': displayName,
        'email': email,
        'paySchedule': paySchedule,
        'defaultHourlyRate': defaultHourlyRate,
        'currency': currency,
        'isActive': isActive,
      },
    );
    ref.invalidate(payrollSetupProvider);
  }

  Future<void> createEarningType({
    required String code,
    required String name,
    required bool isTaxable,
    required bool isActive,
  }) async {
    await ApiClient.instance.post<Map<String, dynamic>>(
      '/api/payroll/setup/earning-types',
      data: {'code': code, 'name': name, 'isTaxable': isTaxable, 'isActive': isActive},
    );
    ref.invalidate(payrollSetupProvider);
  }

  Future<void> createDeductionType({
    required String code,
    required String name,
    required bool isPreTax,
    required bool isActive,
  }) async {
    await ApiClient.instance.post<Map<String, dynamic>>(
      '/api/payroll/setup/deduction-types',
      data: {'code': code, 'name': name, 'isPreTax': isPreTax, 'isActive': isActive},
    );
    ref.invalidate(payrollSetupProvider);
  }
}

class PayrollSetup {
  const PayrollSetup({
    required this.settings,
    required this.employees,
    required this.earningTypes,
    required this.deductionTypes,
    required this.activeEmployeeCount,
    required this.payScheduleCount,
  });

  final PayrollSettings settings;
  final List<PayrollEmployee> employees;
  final List<PayrollEarningType> earningTypes;
  final List<PayrollDeductionType> deductionTypes;
  final int activeEmployeeCount;
  final int payScheduleCount;

  factory PayrollSetup.fromJson(Map<String, dynamic> json) => PayrollSetup(
        settings: PayrollSettings.fromJson(json['settings'] as Map<String, dynamic>),
        employees: JsonUtils.asList(json['employees'], (row) => PayrollEmployee.fromJson(row)),
        earningTypes: JsonUtils.asList(json['earningTypes'], (row) => PayrollEarningType.fromJson(row)),
        deductionTypes: JsonUtils.asList(json['deductionTypes'], (row) => PayrollDeductionType.fromJson(row)),
        activeEmployeeCount: JsonUtils.asInt(json['activeEmployeeCount']),
        payScheduleCount: JsonUtils.asInt(json['payScheduleCount']),
      );
}

class PayrollSettings {
  const PayrollSettings({
    required this.id,
    required this.defaultPaySchedule,
    required this.defaultCurrency,
    required this.workWeekHours,
    required this.isPayrollEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String defaultPaySchedule;
  final String defaultCurrency;
  final int workWeekHours;
  final bool isPayrollEnabled;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory PayrollSettings.fromJson(Map<String, dynamic> json) => PayrollSettings(
        id: JsonUtils.asString(json['id']),
        defaultPaySchedule: JsonUtils.asString(json['defaultPaySchedule']),
        defaultCurrency: JsonUtils.asString(json['defaultCurrency']),
        workWeekHours: JsonUtils.asInt(json['workWeekHours']),
        isPayrollEnabled: JsonUtils.asBool(json['isPayrollEnabled']),
        createdAt: _parseDate(json['createdAt']),
        updatedAt: json['updatedAt'] == null ? null : _parseDate(json['updatedAt']),
      );
}

class PayrollEmployee {
  const PayrollEmployee({
    required this.id,
    required this.employeeNumber,
    required this.displayName,
    required this.email,
    required this.paySchedule,
    required this.defaultHourlyRate,
    required this.currency,
    required this.isActive,
  });

  final String id;
  final String employeeNumber;
  final String displayName;
  final String? email;
  final String paySchedule;
  final double defaultHourlyRate;
  final String currency;
  final bool isActive;

  factory PayrollEmployee.fromJson(Map<String, dynamic> json) => PayrollEmployee(
        id: JsonUtils.asString(json['id']),
        employeeNumber: JsonUtils.asString(json['employeeNumber']),
        displayName: JsonUtils.asString(json['displayName']),
        email: JsonUtils.asNullableString(json['email']),
        paySchedule: JsonUtils.asString(json['paySchedule']),
        defaultHourlyRate: JsonUtils.asDouble(json['defaultHourlyRate']),
        currency: JsonUtils.asString(json['currency']),
        isActive: JsonUtils.asBool(json['isActive']),
      );
}

class PayrollEarningType {
  const PayrollEarningType({required this.id, required this.code, required this.name, required this.isTaxable, required this.isActive});

  final String id;
  final String code;
  final String name;
  final bool isTaxable;
  final bool isActive;

  factory PayrollEarningType.fromJson(Map<String, dynamic> json) => PayrollEarningType(
        id: JsonUtils.asString(json['id']),
        code: JsonUtils.asString(json['code']),
        name: JsonUtils.asString(json['name']),
        isTaxable: JsonUtils.asBool(json['isTaxable']),
        isActive: JsonUtils.asBool(json['isActive']),
      );
}

class PayrollDeductionType {
  const PayrollDeductionType({required this.id, required this.code, required this.name, required this.isPreTax, required this.isActive});

  final String id;
  final String code;
  final String name;
  final bool isPreTax;
  final bool isActive;

  factory PayrollDeductionType.fromJson(Map<String, dynamic> json) => PayrollDeductionType(
        id: JsonUtils.asString(json['id']),
        code: JsonUtils.asString(json['code']),
        name: JsonUtils.asString(json['name']),
        isPreTax: JsonUtils.asBool(json['isPreTax']),
        isActive: JsonUtils.asBool(json['isActive']),
      );
}

DateTime _parseDate(dynamic value) => DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
