import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_result.dart';
import '../../../core/constants/api_enums.dart';
import '../../reports/data/models/report_models.dart';
import '../../reports/providers/reports_provider.dart';

final cashFlowHubProvider = FutureProvider.autoDispose<CashFlowHubSnapshot>((ref) async {
  final reports = ref.read(reportsRepositoryProvider);
  final today = DateTime.now();
  final fromDate = DateTime(today.year, 1, 1);

  final trialBalanceResult = await reports.getTrialBalance(
    asOfDate: today,
    includeZeroBalances: true,
  );
  final balanceSheetResult = await reports.getBalanceSheet(
    asOfDate: today,
    includeZeroBalances: true,
  );
  final profitAndLossResult = await reports.getProfitAndLoss(
    fromDate: fromDate,
    toDate: today,
    includeZeroBalances: true,
  );
  final receivablesResult = await reports.getAccountsReceivableAging(
    asOfDate: today,
  );
  final payablesResult = await reports.getAccountsPayableAging(
    asOfDate: today,
  );

  final trialBalance = _unwrap(trialBalanceResult);
  final balanceSheet = _unwrap(balanceSheetResult);
  final profitAndLoss = _unwrap(profitAndLossResult);
  final receivables = _unwrap(receivablesResult);
  final payables = _unwrap(payablesResult);

  final cashBalance = trialBalance.items
      .where((row) => row.accountType == AccountType.bank)
      .fold<double>(0, (sum, row) => sum + row.closingDebit - row.closingCredit);

  final currentIncoming = receivables.current;
  final overdueIncoming = receivables.days1To30 +
      receivables.days31To60 +
      receivables.days61To90 +
      receivables.over90;
  final currentOutgoing = payables.current;
  final overdueOutgoing = payables.days1To30 +
      payables.days31To60 +
      payables.days61To90 +
      payables.over90;
  final netAfterOpenItems = cashBalance + receivables.total - payables.total;
  final openInvoiceCount = receivables.items.fold<int>(0, (sum, row) => sum + row.openCount);
  final openBillCount = payables.items.fold<int>(0, (sum, row) => sum + row.openCount);

  return CashFlowHubSnapshot(
    asOfDate: today,
    fromDate: fromDate,
    toDate: today,
    currency: _resolveCurrency(receivables, payables),
    cashBalance: cashBalance,
    totalAssets: balanceSheet.totalAssets,
    totalLiabilities: balanceSheet.totalLiabilities,
    totalEquity: balanceSheet.totalEquity,
    expectedIncoming: receivables.total,
    overdueIncoming: overdueIncoming,
    expectedOutgoing: payables.total,
    overdueOutgoing: overdueOutgoing,
    netCashAfterOpenItems: netAfterOpenItems,
    totalIncome: profitAndLoss.totalIncome,
    totalExpenses: profitAndLoss.totalExpenses + profitAndLoss.totalCostOfGoodsSold,
    netProfit: profitAndLoss.netProfit,
    openInvoiceCount: openInvoiceCount,
    openBillCount: openBillCount,
    incomingBuckets: [
      CashFlowBucket('Current', receivables.current),
      CashFlowBucket('1-30', receivables.days1To30),
      CashFlowBucket('31-60', receivables.days31To60),
      CashFlowBucket('61-90', receivables.days61To90),
      CashFlowBucket('90+', receivables.over90),
    ],
    outgoingBuckets: [
      CashFlowBucket('Current', payables.current),
      CashFlowBucket('1-30', payables.days1To30),
      CashFlowBucket('31-60', payables.days31To60),
      CashFlowBucket('61-90', payables.days61To90),
      CashFlowBucket('90+', payables.over90),
    ],
    forecastPoints: [
      CashFlowForecastPoint('Now', cashBalance),
      CashFlowForecastPoint('Current', cashBalance + currentIncoming - currentOutgoing),
      CashFlowForecastPoint('30d', cashBalance + currentIncoming + receivables.days1To30 - currentOutgoing - payables.days1To30),
      CashFlowForecastPoint('60d', cashBalance + currentIncoming + receivables.days1To30 + receivables.days31To60 - currentOutgoing - payables.days1To30 - payables.days31To60),
      CashFlowForecastPoint('90d+', netAfterOpenItems),
    ],
    alerts: _buildAlerts(
      cashBalance: cashBalance,
      netAfterOpenItems: netAfterOpenItems,
      overdueIncoming: overdueIncoming,
      overdueOutgoing: overdueOutgoing,
      openInvoiceCount: openInvoiceCount,
      openBillCount: openBillCount,
    ),
  );
});

T _unwrap<T>(ApiResult<T> result) => result.when(
      success: (data) => data,
      failure: (error) => throw error,
    );

String _resolveCurrency(AgingReportModel receivables, AgingReportModel payables) {
  final arCurrency = receivables.items.isEmpty ? '' : receivables.items.first.currency;
  if (arCurrency.trim().isNotEmpty) return arCurrency;
  final apCurrency = payables.items.isEmpty ? '' : payables.items.first.currency;
  if (apCurrency.trim().isNotEmpty) return apCurrency;
  return 'EGP';
}

List<CashFlowAlert> _buildAlerts({
  required double cashBalance,
  required double netAfterOpenItems,
  required double overdueIncoming,
  required double overdueOutgoing,
  required int openInvoiceCount,
  required int openBillCount,
}) {
  final alerts = <CashFlowAlert>[];

  if (cashBalance < 0) {
    alerts.add(const CashFlowAlert(
      severity: CashFlowAlertSeverity.critical,
      title: 'Negative cash position',
      message: 'Bank and cash accounts are below zero. Review deposits, checks, and bank transactions.',
    ));
  }

  if (netAfterOpenItems < 0) {
    alerts.add(const CashFlowAlert(
      severity: CashFlowAlertSeverity.warning,
      title: 'Projected cash pressure',
      message: 'Open receivables minus open payables leaves a negative projected cash position.',
    ));
  }

  if (overdueIncoming > 0) {
    alerts.add(CashFlowAlert(
      severity: CashFlowAlertSeverity.info,
      title: 'Overdue customer balances',
      message: '$openInvoiceCount open invoice(s) include overdue receivables that can improve cash once collected.',
    ));
  }

  if (overdueOutgoing > 0) {
    alerts.add(CashFlowAlert(
      severity: CashFlowAlertSeverity.info,
      title: 'Vendor bills need attention',
      message: '$openBillCount open bill(s) include overdue payables. Prioritize payment planning.',
    ));
  }

  if (alerts.isEmpty) {
    alerts.add(const CashFlowAlert(
      severity: CashFlowAlertSeverity.success,
      title: 'Cash flow looks stable',
      message: 'No overdue cash-flow pressure was detected from current receivables and payables reports.',
    ));
  }

  return alerts;
}

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
}

class CashFlowBucket {
  const CashFlowBucket(this.label, this.amount);
  final String label;
  final double amount;
}

class CashFlowForecastPoint {
  const CashFlowForecastPoint(this.label, this.amount);
  final String label;
  final double amount;
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
}
