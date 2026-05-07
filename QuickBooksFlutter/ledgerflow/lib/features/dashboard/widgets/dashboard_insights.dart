// features/dashboard/widgets/dashboard_insights.dart

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../app/router.dart';
import '../../cash_flow/providers/cash_flow_hub_provider.dart';

class DashboardInsights extends ConsumerWidget {
  const DashboardInsights({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final snapshotAsync = ref.watch(cashFlowHubProvider);

    return snapshotAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
        message: error.toString(),
        onRetry: () => ref.invalidate(cashFlowHubProvider),
      ),
      data: (snapshot) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _InsightCard(
            title: l10n.profitAndLoss,
            action: l10n.fiscalYearToDate,
            child: Column(
              children: [
                Wrap(
                  spacing: 24,
                  runSpacing: 16,
                  children: [
                    _Metric(label: l10n.netIncome.toUpperCase(), value: _money(snapshot.netProfit, snapshot.currency), tone: _tone(snapshot.netProfit)),
                    _Metric(label: l10n.income.toUpperCase(), value: _money(snapshot.totalIncome, snapshot.currency), tone: _MetricTone.positive),
                    _Metric(label: l10n.expensesByCategory.split(' ').first.toUpperCase(), value: _money(snapshot.totalExpenses, snapshot.currency), tone: _MetricTone.warning),
                    _Metric(label: 'CASH', value: _money(snapshot.cashBalance, snapshot.currency), tone: _tone(snapshot.cashBalance)),
                  ],
                ),
                const SizedBox(height: 24),
                _CashForecastChart(snapshot: snapshot),
              ],
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 860;
              final incomeCard = _InsightCard(
                title: l10n.income,
                action: l10n.createInvoice,
                onActionTap: () => context.go(AppRoutes.invoiceNew),
                child: Column(
                  children: [
                    _ProgressBar(label: l10n.unpaid.toUpperCase(), value: snapshot.expectedIncoming, maxValue: math.max(snapshot.expectedIncoming, snapshot.expectedOutgoing), currency: snapshot.currency, tone: _MetricTone.positive),
                    const SizedBox(height: 12),
                    _ProgressBar(label: 'OVERDUE', value: snapshot.overdueIncoming, maxValue: math.max(snapshot.expectedIncoming, 1), currency: snapshot.currency, tone: snapshot.overdueIncoming > 0 ? _MetricTone.warning : _MetricTone.neutral),
                  ],
                ),
              );
              final expensesCard = _InsightCard(
                title: l10n.moneyBarExpenses,
                action: l10n.createBill,
                onActionTap: () => context.go(AppRoutes.purchaseBillNew),
                child: Column(
                  children: [
                    _ProgressBar(label: 'OPEN BILLS', value: snapshot.expectedOutgoing, maxValue: math.max(snapshot.expectedIncoming, snapshot.expectedOutgoing), currency: snapshot.currency, tone: _MetricTone.warning),
                    const SizedBox(height: 12),
                    _ProgressBar(label: 'OVERDUE', value: snapshot.overdueOutgoing, maxValue: math.max(snapshot.expectedOutgoing, 1), currency: snapshot.currency, tone: snapshot.overdueOutgoing > 0 ? _MetricTone.negative : _MetricTone.neutral),
                  ],
                ),
              );

              if (!wide) {
                return Column(children: [incomeCard, const SizedBox(height: 24), expensesCard]);
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: incomeCard),
                  const SizedBox(width: 24),
                  Expanded(child: expensesCard),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _InsightCard(
            title: 'Cash Flow Alerts',
            action: 'Open Hub',
            onActionTap: () => context.go(AppRoutes.cashFlowHub),
            child: Column(
              children: snapshot.alerts
                  .take(3)
                  .map((alert) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AlertSummary(alert: alert),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.title, required this.child, this.action, this.onActionTap});

  final String title;
  final Widget child;
  final String? action;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              if (action != null)
                InkWell(
                  onTap: onActionTap,
                  child: Text(action!, style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const Divider(height: 32),
          child,
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.tone});

  final String label;
  final String value;
  final _MetricTone tone;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(context, tone);
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.label, required this.value, required this.maxValue, required this.currency, required this.tone});

  final String label;
  final double value;
  final double maxValue;
  final String currency;
  final _MetricTone tone;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(context, tone);
    final normalized = maxValue <= 0 ? 0.0 : math.min(value / maxValue, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey)),
            Text(_money(value, currency), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: normalized,
          backgroundColor: Colors.grey.shade100,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

class _CashForecastChart extends StatelessWidget {
  const _CashForecastChart({required this.snapshot});

  final CashFlowHubSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    if (snapshot.forecastPoints.every((point) => point.amount == 0)) {
      return const SizedBox(height: 180, child: Center(child: Text('No cash-flow activity yet.')));
    }

    final values = snapshot.forecastPoints.map((point) => point.amount).toList();
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final padding = math.max((maxValue - minValue).abs() * 0.2, 100.0);

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: minValue - padding,
          maxY: maxValue + padding,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 54, getTitlesWidget: (value, meta) => Text(_compact(value), style: const TextStyle(fontSize: 10))),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= snapshot.forecastPoints.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(snapshot.forecastPoints[index].label, style: const TextStyle(fontSize: 11)),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [for (var i = 0; i < snapshot.forecastPoints.length; i++) FlSpot(i.toDouble(), snapshot.forecastPoints[i].amount)],
              isCurved: true,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertSummary extends StatelessWidget {
  const _AlertSummary({required this.alert});

  final CashFlowAlert alert;

  @override
  Widget build(BuildContext context) {
    final color = switch (alert.severity) {
      CashFlowAlertSeverity.success => Colors.green,
      CashFlowAlertSeverity.info => Colors.blue,
      CashFlowAlertSeverity.warning => Colors.orange,
      CashFlowAlertSeverity.critical => Theme.of(context).colorScheme.error,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(alert.title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(alert.message, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 12),
              const Text('Could not load insights', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}

enum _MetricTone { positive, warning, negative, neutral }

_MetricTone _tone(double value) {
  if (value > 0) return _MetricTone.positive;
  if (value < 0) return _MetricTone.negative;
  return _MetricTone.neutral;
}

Color _toneColor(BuildContext context, _MetricTone tone) => switch (tone) {
      _MetricTone.positive => Colors.green,
      _MetricTone.warning => Colors.orange,
      _MetricTone.negative => Theme.of(context).colorScheme.error,
      _MetricTone.neutral => Colors.blueGrey,
    };

String _money(double value, String currency) => '$currency ${value.toStringAsFixed(2)}';

String _compact(double value) {
  final abs = value.abs();
  if (abs >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (abs >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return value.toStringAsFixed(0);
}
