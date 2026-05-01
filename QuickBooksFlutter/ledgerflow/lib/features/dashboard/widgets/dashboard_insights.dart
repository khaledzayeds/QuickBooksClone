// features/dashboard/widgets/dashboard_insights.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

class DashboardInsights extends StatelessWidget {
  const DashboardInsights({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // ── Profit & Loss Header ──────────────────
        _InsightCard(
          title: l10n.profitAndLoss,
          action: l10n.fiscalYearToDate,
          child: Column(
            children: [
              Row(
                children: [
                  _Metric(label: l10n.netIncome.toUpperCase(), value: '150.00', color: Colors.blue.shade900),
                  const SizedBox(width: 24),
                  _Metric(label: l10n.income.toUpperCase(), value: '400.00', color: const Color(0xFF2CA01C)),
                  const SizedBox(width: 24),
                  _Metric(label: l10n.expensesByCategory.split(' ')[0].toUpperCase(), value: '250.00', color: const Color(0xFF0078D4)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          const FlSpot(0, 0),
                          const FlSpot(1, 0),
                          const FlSpot(2, 0),
                          const FlSpot(3, 150),
                          const FlSpot(4, 0),
                        ],
                        isCurved: true,
                        color: Colors.blue.shade900,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _InsightCard(
                title: l10n.income,
                action: l10n.createInvoice,
                child: Column(
                  children: [
                    _ProgressBar(label: l10n.unpaid.toUpperCase(), value: 500.00, color: Colors.orange, maxValue: 1000),
                    const SizedBox(height: 12),
                    _ProgressBar(label: l10n.paid.toUpperCase(), value: 0.00, color: const Color(0xFF2CA01C), maxValue: 1000),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _InsightCard(
                title: l10n.moneyBarExpenses,
                action: l10n.createBill,
                child: SizedBox(
                  height: 150,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(color: Colors.blue.shade200, value: 40, showTitle: false),
                        PieChartSectionData(color: Colors.purple.shade200, value: 30, showTitle: false),
                        PieChartSectionData(color: Colors.teal.shade200, value: 30, showTitle: false),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.title, required this.child, this.action});
  final String title;
  final Widget child;
  final String? action;

  @override
  Widget build(BuildContext context) {
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
                Text(action!, style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.w600)),
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
  const _Metric({required this.label, required this.value, required this.color});
  final String label; final String value; final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.label, required this.value, required this.color, required this.maxValue});
  final String label; final double value; final Color color; final double maxValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey)),
            Text(value.toStringAsFixed(2), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value / maxValue,
          backgroundColor: Colors.grey.shade100,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
