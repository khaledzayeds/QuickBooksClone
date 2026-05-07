import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../cash_flow/providers/cash_flow_hub_provider.dart';

class SnapshotsScreen extends ConsumerWidget {
  const SnapshotsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(cashFlowHubProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Snapshots'),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(cashFlowHubProvider),
        ),
        data: (snapshot) => _SnapshotsBody(snapshot: snapshot),
      ),
    );
  }
}

class _SnapshotsBody extends StatelessWidget {
  const _SnapshotsBody({required this.snapshot});

  final CashFlowHubSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListView(
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
                    'Company Snapshot',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'A compact financial view powered by backend reports, ready for quick daily review.',
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
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1040 ? 4 : constraints.maxWidth >= 680 ? 2 : 1;
            return GridView.count(
              crossAxisCount: columns,
              childAspectRatio: columns == 1 ? 3.4 : 2.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _SnapshotTile(
                  title: 'Cash Balance',
                  value: _money(snapshot.cashBalance, snapshot.currency),
                  icon: Icons.account_balance_wallet_outlined,
                  tone: _tone(snapshot.cashBalance),
                  route: AppRoutes.cashFlowHub,
                ),
                _SnapshotTile(
                  title: 'Receivables',
                  value: _money(snapshot.expectedIncoming, snapshot.currency),
                  subtitle: '${snapshot.openInvoiceCount} open invoice(s)',
                  icon: Icons.south_west_outlined,
                  tone: _SnapshotTone.positive,
                  route: AppRoutes.invoices,
                ),
                _SnapshotTile(
                  title: 'Payables',
                  value: _money(snapshot.expectedOutgoing, snapshot.currency),
                  subtitle: '${snapshot.openBillCount} open bill(s)',
                  icon: Icons.north_east_outlined,
                  tone: snapshot.overdueOutgoing > 0 ? _SnapshotTone.warning : _SnapshotTone.neutral,
                  route: AppRoutes.purchaseBills,
                ),
                _SnapshotTile(
                  title: 'Net Profit YTD',
                  value: _money(snapshot.netProfit, snapshot.currency),
                  icon: Icons.trending_up_outlined,
                  tone: _tone(snapshot.netProfit),
                  route: AppRoutes.reports,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 980;
            final position = _Panel(
              title: 'Financial Position',
              subtitle: 'Assets, liabilities, and equity from the Balance Sheet report.',
              child: _PositionChart(snapshot: snapshot),
            );
            final cashFlow = _Panel(
              title: 'Cash Flow Summary',
              subtitle: 'Open receivables and payables compared to current cash.',
              child: Column(
                children: [
                  _SnapshotRow('Cash', snapshot.cashBalance, snapshot.currency, _tone(snapshot.cashBalance)),
                  _SnapshotRow('Expected In', snapshot.expectedIncoming, snapshot.currency, _SnapshotTone.positive),
                  _SnapshotRow('Expected Out', snapshot.expectedOutgoing, snapshot.currency, _SnapshotTone.warning),
                  const Divider(height: 28),
                  _SnapshotRow('Projected Cash', snapshot.netCashAfterOpenItems, snapshot.currency, _tone(snapshot.netCashAfterOpenItems)),
                ],
              ),
            );

            if (!wide) {
              return Column(children: [position, const SizedBox(height: 16), cashFlow]);
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: position),
                const SizedBox(width: 16),
                Expanded(child: cashFlow),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        _Panel(
          title: 'Attention Needed',
          subtitle: 'Backend-generated alerts from current financial reports.',
          child: Column(
            children: snapshot.alerts.map((alert) => _AlertCard(alert: alert)).toList(),
          ),
        ),
        const SizedBox(height: 24),
        _Panel(
          title: 'Quick Links',
          subtitle: 'Jump to related workflows.',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => context.go(AppRoutes.cashFlowHub),
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: const Text('Cash Flow Hub'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => context.go(AppRoutes.invoices),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Invoices'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => context.go(AppRoutes.purchaseBills),
                icon: const Icon(Icons.request_quote_outlined),
                label: const Text('Bills'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => context.go(AppRoutes.reports),
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('Reports'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SnapshotTile extends StatelessWidget {
  const _SnapshotTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.tone,
    required this.route,
    this.subtitle,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final _SnapshotTone tone;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _toneColor(context, tone);

    return Card(
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(12),
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
                      Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

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
            Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ],
            const Divider(height: 28),
            child,
          ],
        ),
      ),
    );
  }
}

class _PositionChart extends StatelessWidget {
  const _PositionChart({required this.snapshot});

  final CashFlowHubSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final total = snapshot.totalAssets.abs() + snapshot.totalLiabilities.abs() + snapshot.totalEquity.abs();
    if (total == 0) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('No balance sheet values available yet.')),
      );
    }

    return SizedBox(
      height: 240,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 48,
          sections: [
            PieChartSectionData(
              value: snapshot.totalAssets.abs(),
              title: 'Assets',
              radius: 78,
              showTitle: true,
            ),
            PieChartSectionData(
              value: snapshot.totalLiabilities.abs(),
              title: 'Liabilities',
              radius: 78,
              showTitle: true,
            ),
            PieChartSectionData(
              value: snapshot.totalEquity.abs(),
              title: 'Equity',
              radius: 78,
              showTitle: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SnapshotRow extends StatelessWidget {
  const _SnapshotRow(this.label, this.value, this.currency, this.tone);

  final String label;
  final double value;
  final String currency;
  final _SnapshotTone tone;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(context, tone);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
          Text(
            _money(value, currency),
            style: TextStyle(fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});

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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: color),
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
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 42),
                const SizedBox(height: 12),
                const Text('Could not load snapshots', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
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

enum _SnapshotTone { positive, warning, negative, neutral }

_SnapshotTone _tone(double value) {
  if (value > 0) return _SnapshotTone.positive;
  if (value < 0) return _SnapshotTone.negative;
  return _SnapshotTone.neutral;
}

Color _toneColor(BuildContext context, _SnapshotTone tone) => switch (tone) {
      _SnapshotTone.positive => Colors.green,
      _SnapshotTone.warning => Colors.orange,
      _SnapshotTone.negative => Theme.of(context).colorScheme.error,
      _SnapshotTone.neutral => Theme.of(context).colorScheme.primary,
    };

String _money(double value, String currency) => '$currency ${value.toStringAsFixed(2)}';
String _date(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
