import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/utils/json_utils.dart';

final cashFlowHubProvider = FutureProvider.autoDispose<CashFlowHubSnapshot>((ref) async {
  final response = await ApiClient.instance.get<Map<String, dynamic>>('/api/reports/cash-flow-hub');
  return CashFlowHubSnapshot.fromJson(response.data!);
});

class CashFlowHubSnapshot {
  const CashFlowHubSnapshot({
    required this.asOfDate,
    required this.fromDate,
    required this.toDate,
    required this.currency,
    required this.cashBalance,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.totalEquity,
    required this.expectedIncoming,
    required this.overdueIncoming,
    required this.expectedOutgoing,
    required this.overdueOutgoing,
    required this.netCashAfterOpenItems,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netProfit,
    required this.openInvoiceCount,
    required this.openBillCount,
    required this.incomingBuckets,
    required this.outgoingBuckets,
    required this.forecastPoints,
    required this.alerts,
  });

  final DateTime asOfDate;
  final DateTime fromDate;
  final DateTime toDate;
  final String currency;
  final double cashBalance;
  final double totalAssets;
  final double totalLiabilities;
  final double totalEquity;
  final double expectedIncoming;
  final double overdueIncoming;
  final double expectedOutgoing;
  final double overdueOutgoing;
  final double netCashAfterOpenItems;
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final int openInvoiceCount;
  final int openBillCount;
  final List<CashFlowBucket> incomingBuckets;
  final List<CashFlowBucket> outgoingBuckets;
  final List<CashFlowForecastPoint> forecastPoints;
  final List<CashFlowAlert> alerts;

  factory CashFlowHubSnapshot.fromJson(Map<String, dynamic> json) => CashFlowHubSnapshot(
        asOfDate: _parseDate(json['asOfDate']),
        fromDate: _parseDate(json['fromDate']),
        toDate: _parseDate(json['toDate']),
        currency: JsonUtils.asString(json['currency'], defaultValue: 'EGP'),
        cashBalance: JsonUtils.asDouble(json['cashBalance']),
        totalAssets: JsonUtils.asDouble(json['totalAssets']),
        totalLiabilities: JsonUtils.asDouble(json['totalLiabilities']),
        totalEquity: JsonUtils.asDouble(json['totalEquity']),
        expectedIncoming: JsonUtils.asDouble(json['expectedIncoming']),
        overdueIncoming: JsonUtils.asDouble(json['overdueIncoming']),
        expectedOutgoing: JsonUtils.asDouble(json['expectedOutgoing']),
        overdueOutgoing: JsonUtils.asDouble(json['overdueOutgoing']),
        netCashAfterOpenItems: JsonUtils.asDouble(json['netCashAfterOpenItems']),
        totalIncome: JsonUtils.asDouble(json['totalIncome']),
        totalExpenses: JsonUtils.asDouble(json['totalExpenses']),
        netProfit: JsonUtils.asDouble(json['netProfit']),
        openInvoiceCount: JsonUtils.asInt(json['openInvoiceCount']),
        openBillCount: JsonUtils.asInt(json['openBillCount']),
        incomingBuckets: JsonUtils.asList(
          json['incomingBuckets'],
          (row) => CashFlowBucket.fromJson(row),
        ),
        outgoingBuckets: JsonUtils.asList(
          json['outgoingBuckets'],
          (row) => CashFlowBucket.fromJson(row),
        ),
        forecastPoints: JsonUtils.asList(
          json['forecastPoints'],
          (row) => CashFlowForecastPoint.fromJson(row),
        ),
        alerts: JsonUtils.asList(
          json['alerts'],
          (row) => CashFlowAlert.fromJson(row),
        ),
      );
}

class CashFlowBucket {
  const CashFlowBucket(this.label, this.amount);
  final String label;
  final double amount;

  factory CashFlowBucket.fromJson(Map<String, dynamic> json) => CashFlowBucket(
        JsonUtils.asString(json['label']),
        JsonUtils.asDouble(json['amount']),
      );
}

class CashFlowForecastPoint {
  const CashFlowForecastPoint(this.label, this.amount);
  final String label;
  final double amount;

  factory CashFlowForecastPoint.fromJson(Map<String, dynamic> json) => CashFlowForecastPoint(
        JsonUtils.asString(json['label']),
        JsonUtils.asDouble(json['amount']),
      );
}

enum CashFlowAlertSeverity { success, info, warning, critical }

class CashFlowAlert {
  const CashFlowAlert({
    required this.severity,
    required this.title,
    required this.message,
  });

  final CashFlowAlertSeverity severity;
  final String title;
  final String message;

  factory CashFlowAlert.fromJson(Map<String, dynamic> json) => CashFlowAlert(
        severity: _severity(JsonUtils.asString(json['severity'])),
        title: JsonUtils.asString(json['title']),
        message: JsonUtils.asString(json['message']),
      );
}

CashFlowAlertSeverity _severity(String value) => switch (value.toLowerCase()) {
      'success' => CashFlowAlertSeverity.success,
      'warning' => CashFlowAlertSeverity.warning,
      'critical' => CashFlowAlertSeverity.critical,
      _ => CashFlowAlertSeverity.info,
    };

DateTime _parseDate(dynamic value) => DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
