import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../providers/cash_flow_hub_provider.dart';

class CashFlowHubScreen extends ConsumerWidget {
  const CashFlowHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(cashFlowHubProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Flow Hub'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(cashFlowHubProvider),
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: snapshotAsync.when(
        loading: () => const _LoadingState(),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(cashFlowHubProvider),
        ),
        data: (snapshot) => _CashFlowHubBody(snapshot: snapshot),
      ),
    );
  }
}

class _CashFlowHubBody extends StatelessWidget {
  const _CashFlowHubBody({required this.snapshot});

  final CashFlowHubSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cash Flow Command Center',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Live snapshot from Balance Sheet, Profit & Loss, AR Aging, and AP Aging reports.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Chip(
                avatar: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text('As of ${_date(snapshot.asOfDate)}'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _MetricGrid(snapshot: snapshot),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              final forecast = _Panel(
                title: 'Cash Forecast',
                subtitle: 'Projected cash after open receivables and payables.',
                child: _ForecastChart(snapshot: snapshot),
              );
              final alerts = _Panel(
                title: 'Cash Alerts',
                subtitle: 'Action items generated from open balances.',
                child: _AlertsList(alerts: snapshot.alerts),
              );

              if (!wide) {
                return Column(children: [forecast, const SizedBox(height: 16), alerts]);
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: forecast),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: alerts),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              final incoming = _Panel(
                title: 'Money Coming In',
                subtitle: '${snapshot.openInvoiceCount} open invoice(s)',
                action: TextButton.icon(
                  onPressed: () => context.go(AppRoutes.invoices),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Invoices'),
                ),
                child: _BucketBars(
                  buckets: snapshot.incomingBuckets,
                  total: snapshot.expectedIncoming,
                  currency: snapshot.currency,
                ),
              );
              final outgoing = _Panel(
                title: 'Money Going Out',
                subtitle: '${snapshot.openBillCount} open bill(s)',
                action: TextButton.icon(
                  onPressed: () => context.go(AppRoutes.purchaseBills),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Bills'),
                ),
                child: _BucketBars(
                  buckets: snapshot.outgoingBuckets,
                  total: snapshot.expectedOutgoing,
                  currency: snapshot.currency,
                ),
              );

              if (!wide) {
                return Column(children: [incoming, const SizedBox(height: 16), outgoing]);
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: incoming),
                  const SizedBox(width: 16),
                  Expanded(child: outgoing),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _QuickActions(),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.snapshot});
  final CashFlowHubSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100 ? 4 : constraints.maxWidth >= 720 ? 2 : 1;
        final cards = [
          _MetricCard(
            title: 'Cash Balance',
            value: _money(snapshot.cashBalance, snapshot.currency),
            icon: Icons.account_balance_wallet_outlined,
            tone: _toneFor(snapshot.cashBalance),
          ),
          _MetricCard(
            title: 'Expected Incoming',
            value: _money(snapshot.expectedIncoming, snapshot.currency),
            subtitle: 'Overdue ${_money(snapshot.overdueIncoming, snapshot.currency)}',
            icon: Icons.south_west_outlined,
            tone: _MetricTone.positive,
          ),
          _MetricCard(
            title: 'Expected Outgoing',
            value: _money(snapshot.expectedOutgoing, snapshot.currency),
            subtitle: 'Overdue ${_money(snapshot.overdueOutgoing, snapshot.currency)}',
            icon: Icons.north_east_outlined,
            tone: snapshot.overdueOutgoing > 0 ? _MetricTone.warning : _MetricTone.neutral,
          ),
          _MetricCard(
            title: 'Projected Cash',
            value: _money(snapshot.netCashAfterOpenItems, snapshot.currency),
            icon: Icons.insights_outlined,
            tone: _toneFor(snapshot.netCashAfterOpenItems),
          ),
          _MetricCard(
            title: 'Net Profit YTD',
            value: _money(snapshot.netProfit, snapshot.currency),
            subtitle: '${_date(snapshot.fromDate)} - ${_date(snapshot.toDate)}',
            icon: Icons.trending_up_outlined,
            tone: _toneFor(snapshot.netProfit),
          ),
          _MetricCard(
            title: 'Total Assets',
            value: _money(snapshot.totalAssets, snapshot.currency),
            icon: Icons.domain_outlined,
            tone: _MetricTone.neutral,
          ),
          _MetricCard(
            title: 'Liabilities',
            value: _money(snapshot.totalLiabilities, snapshot.currency),
            icon: Icons.receipt_long_outlined,
            tone: snapshot.totalLiabilities > 0 ? _MetricTone.warning : _MetricTone.neutral,
          ),
          _MetricCard(
            title: 'Equity',
            value: _money(snapshot.totalEquity, snapshot.currency),
            icon: Icons.account_balance_outlined,
            tone: _MetricTone.neutral,
          ),
        ];

        return GridView.count(
          crossAxisCount: columns,
          childAspectRatio: columns == 1 ? 3.6 : 2.4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: cards,
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.tone,
    this.subtitle,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final _MetricTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _toneColor(context, tone);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.14),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForecastChart extends StatelessWidget {
  const _ForecastChart({required this.snapshot});
  final CashFlowHubSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    if (snapshot.forecastPoints.every((point) => point.amount == 0)) {
      return const _EmptyBox(message: 'No cash-flow activity yet. Create invoices, bills, payments, or bank transactions to populate the forecast.');
    }

    final values = snapshot.forecastPoints.map((point) => point.amount).toList();
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final padding = math.max((maxValue - minValue).abs() * 0.2, 100.0);

    return SizedBox(
      height: 280,
      child: LineChart(
        LineChartData(
          minY: minValue - padding,
          maxY: maxValue + padding,
          gridData: FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 58,
                getTitlesWidget: (value, meta) => Text(
                  _compact(value),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
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
              spots: [
                for (var i = 0; i < snapshot.forecastPoints.length; i++)
                  FlSpot(i.toDouble(), snapshot.forecastPoints[i].amount),
              ],
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

class _BucketBars extends StatelessWidget {
  const _BucketBars({required this.buckets, required this.total, required this.currency});

  final List<CashFlowBucket> buckets;
  final double total;
  final String currency;

  @override
  Widget build(BuildContext context) {
    if (total == 0) {
      return const _EmptyBox(message: 'No open balances in this report.');
    }

    final maxValue = buckets.map((bucket) => bucket.amount).fold<double>(0, math.max);

    return Column(
      children: [
        for (final bucket in buckets) ...[
          Row(
            children: [
              SizedBox(width: 70, child: Text(bucket.label)),
              Expanded(
                child: LinearProgressIndicator(
                  value: maxValue <= 0 ? 0 : bucket.amount / maxValue,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                child: Text(
                  _money(bucket.amount, currency),
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _AlertsList extends StatelessWidget {
  const _AlertsList({required this.alerts});
  final List<CashFlowAlert> alerts;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final alert in alerts) ...[
          _AlertTile(alert: alert),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});
  final CashFlowAlert alert;

  @override
  Widget build(BuildContext context) {
    final color = switch (alert.severity) {
      CashFlowAlertSeverity.success => Colors.green,
      CashFlowAlertSeverity.info => Colors.blue,
      CashFlowAlertSeverity.warning => Colors.orange,
      CashFlowAlertSeverity.critical => Theme.of(context).colorScheme.error,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.08),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_alertIcon(alert.severity), color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(alert.message),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionSpec('Create Invoice', Icons.add_card_outlined, AppRoutes.invoiceNew),
      _ActionSpec('Receive Payment', Icons.payments_outlined, AppRoutes.paymentNew),
      _ActionSpec('Enter Bill', Icons.receipt_long_outlined, AppRoutes.purchaseBillNew),
      _ActionSpec('Pay Bills', Icons.outbox_outlined, AppRoutes.vendorPayments),
      _ActionSpec('Make Deposit', Icons.south_west_outlined, AppRoutes.bankingDeposits),
      _ActionSpec('Bank Register', Icons.account_balance_outlined, AppRoutes.bankingRegister),
    ];

    return _Panel(
      title: 'Cash Flow Actions',
      subtitle: 'Jump directly to cash-impacting workflows.',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final action in actions)
            FilledButton.tonalIcon(
              onPressed: () => context.go(action.path),
              icon: Icon(action.icon),
              label: Text(action.title),
            ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.subtitle, this.action});

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ],
                  ),
                ),
                if (action != null) action!,
              ],
            ),
            const Divider(height: 28),
            child,
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading cash flow reports...'),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 42, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 12),
                const Text('Could not load Cash Flow Hub', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(message, textAlign: TextAlign.center),
    );
  }
}

class _ActionSpec {
  const _ActionSpec(this.title, this.icon, this.path);
  final String title;
  final IconData icon;
  final String path;
}

enum _MetricTone { positive, warning, negative, neutral }

_MetricTone _toneFor(double value) {
  if (value > 0) return _MetricTone.positive;
  if (value < 0) return _MetricTone.negative;
  return _MetricTone.neutral;
}

Color _toneColor(BuildContext context, _MetricTone tone) => switch (tone) {
      _MetricTone.positive => Colors.green,
      _MetricTone.warning => Colors.orange,
      _MetricTone.negative => Theme.of(context).colorScheme.error,
      _MetricTone.neutral => Theme.of(context).colorScheme.primary,
    };

IconData _alertIcon(CashFlowAlertSeverity severity) => switch (severity) {
      CashFlowAlertSeverity.success => Icons.check_circle_outline,
      CashFlowAlertSeverity.info => Icons.info_outline,
      CashFlowAlertSeverity.warning => Icons.warning_amber_outlined,
      CashFlowAlertSeverity.critical => Icons.error_outline,
    };

String _money(double value, String currency) => '$currency ${value.toStringAsFixed(2)}';
String _compact(double value) {
  final abs = value.abs();
  if (abs >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (abs >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return value.toStringAsFixed(0);
}

String _date(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
