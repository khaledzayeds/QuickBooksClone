// features/dashboard/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';
import '../../../app/router.dart';
import '../../runtime/providers/runtime_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runtime = ref.watch(runtimeProvider);
    final cs      = Theme.of(context).colorScheme;
    final l10n    = AppLocalizations.of(context)!;
    final now     = DateTime.now();
    final greeting = _greeting(now.hour);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
        children: [
          // ── Header & Status ─────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(now),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
              _RuntimeStatusIndicator(runtime: runtime),
            ],
          ),
          const SizedBox(height: 32),

          // ── The Money Bar (Summary) ──────────────
          const _MoneyBar(),
          const SizedBox(height: 24),

          // ── Main Dashboard Grid ──────────────────
          LayoutBuilder(builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 900;
            
            if (isDesktop) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        const _ProfitAndLossChart(),
                        const SizedBox(height: 24),
                        const _ExpensesPieChart(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        const _BankAccountsWidget(),
                        const SizedBox(height: 24),
                        _QuickActions(),
                      ],
                    ),
                  ),
                ],
              );
            }

            // Tablet/Mobile
            return Column(
              children: [
                const _ProfitAndLossChart(),
                const SizedBox(height: 24),
                const _ExpensesPieChart(),
                const SizedBox(height: 24),
                const _BankAccountsWidget(),
                const SizedBox(height: 24),
                _QuickActions(),
              ],
            );
          }),
        ],
      ),
    );
  }

  String _greeting(int hour) {
    if (hour < 12) return 'صباح الخير 🌤';
    if (hour < 17) return 'مساء الخير 🌿';
    return 'مساء الخير 🌙';
  }

  String _formatDate(DateTime d) {
    const months = [
      '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    const days = [
      '', 'الاثنين', 'الثلاثاء', 'الأربعاء',
      'الخميس', 'الجمعة', 'السبت', 'الأحد'
    ];
    return '${days[d.weekday]}، ${d.day} ${months[d.month]} ${d.year}';
  }
}

// ─── Runtime Status ───────────────────────────────
class _RuntimeStatusIndicator extends StatelessWidget {
  const _RuntimeStatusIndicator({required this.runtime});
  final AsyncValue runtime;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return runtime.when(
      loading: () => const SizedBox(
        width: 16, height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, _) => _Chip('غير متصل', cs.error, Icons.wifi_off_rounded),
      data: (r) => r == null
          ? _Chip('غير متصل', cs.error, Icons.wifi_off_rounded)
          : _Chip('متصل', Colors.green.shade600, Icons.circle),
    );
  }

  Widget _Chip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ─── Money Bar (QuickBooks Style Summary) ─────────
class _MoneyBar extends StatelessWidget {
  const _MoneyBar();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        final items = [
          _MoneyBarItem(
            title: l10n.moneyBarUnpaid,
            amount: 'SAR 12,450',
            subtitle: '3 ${l10n.moneyBarOverdue}',
            color: Colors.orange.shade700,
            flex: 2,
          ),
          _MoneyBarItem(
            title: l10n.moneyBarPaid,
            amount: 'SAR 45,200',
            subtitle: '12 invoices',
            color: const Color(0xFF2CA01C), // QuickBooks Green
            flex: 2,
          ),
          _MoneyBarItem(
            title: l10n.moneyBarExpenses,
            amount: 'SAR 8,320',
            subtitle: 'This month',
            color: Colors.blue.shade700,
            flex: 1,
            hideDivider: true,
          ),
        ];

        if (isMobile) {
          return Column(
            children: items.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: e,
            )).toList(),
          );
        }

        return Row(
          children: items.map((e) => Expanded(flex: e.flex, child: e)).toList(),
        );
      }),
    );
  }
}

class _MoneyBarItem extends StatelessWidget {
  const _MoneyBarItem({
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.color,
    required this.flex,
    this.hideDivider = false,
  });

  final String title;
  final String amount;
  final String subtitle;
  final Color color;
  final int flex;
  final bool hideDivider;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: hideDivider ? null : BorderDirectional(
          // For LTR, right border. For RTL, left border.
          end: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Text(amount, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

// ─── Dashboard Card Wrapper ───────────────────────
class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ─── Profit and Loss Chart ────────────────────────
class _ProfitAndLossChart extends StatelessWidget {
  const _ProfitAndLossChart();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = const Color(0xFF2CA01C); // Income Green
    final secondary = Colors.grey.shade400;  // Expenses Grey

    return _DashboardCard(
      title: l10n.profitAndLoss,
      child: SizedBox(
        height: 250,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 60000,
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                    if (value.toInt() < 0 || value.toInt() >= months.length) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(months[value.toInt()], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const SizedBox();
                    return Text('${(value / 1000).toInt()}k', style: const TextStyle(fontSize: 12, color: Colors.grey));
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 15000,
              getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            barGroups: [
              _makeGroupData(0, 35000, 20000, primary, secondary),
              _makeGroupData(1, 42000, 22000, primary, secondary),
              _makeGroupData(2, 38000, 25000, primary, secondary),
              _makeGroupData(3, 45000, 24000, primary, secondary),
              _makeGroupData(4, 52000, 30000, primary, secondary),
              _makeGroupData(5, 48000, 28000, primary, secondary),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y1, double y2, Color c1, Color c2) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: y1, color: c1, width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
        BarChartRodData(toY: y2, color: c2, width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
      ],
      barsSpace: 4,
    );
  }
}

// ─── Expenses Pie Chart ───────────────────────────
class _ExpensesPieChart extends StatelessWidget {
  const _ExpensesPieChart();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _DashboardCard(
      title: l10n.expensesByCategory,
      child: SizedBox(
        height: 250,
        child: Row(
          children: [
            Expanded(
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: [
                    PieChartSectionData(color: Colors.blue.shade400, value: 40, title: '40%', radius: 40, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    PieChartSectionData(color: Colors.orange.shade400, value: 30, title: '30%', radius: 40, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    PieChartSectionData(color: Colors.purple.shade400, value: 15, title: '15%', radius: 40, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    PieChartSectionData(color: Colors.teal.shade400, value: 15, title: '15%', radius: 40, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendItem(color: Colors.blue.shade400, text: 'Cost of Goods'),
                const SizedBox(height: 12),
                _LegendItem(color: Colors.orange.shade400, text: 'Payroll'),
                const SizedBox(height: 12),
                _LegendItem(color: Colors.purple.shade400, text: 'Rent & Utilities'),
                const SizedBox(height: 12),
                _LegendItem(color: Colors.teal.shade400, text: 'Marketing'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

// ─── Bank Accounts Widget ─────────────────────────
class _BankAccountsWidget extends StatelessWidget {
  const _BankAccountsWidget();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return _DashboardCard(
      title: l10n.bankAccounts,
      child: Column(
        children: [
          _BankRow('Cash on Hand', 'SAR 12,500.00', Icons.payments_outlined),
          Divider(color: cs.outlineVariant.withValues(alpha: 0.3), height: 32),
          _BankRow('Al Rajhi Checking', 'SAR 84,230.50', Icons.account_balance_outlined),
          Divider(color: cs.outlineVariant.withValues(alpha: 0.3), height: 32),
          _BankRow('SNB Savings', 'SAR 150,000.00', Icons.savings_outlined),
        ],
      ),
    );
  }

  Widget _BankRow(String name, String balance, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 20, color: Colors.grey.shade700),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('Updated 2h ago', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
        Text(balance, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}

// ─── Quick Actions ────────────────────────────────
class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final actions = <_ActionData>[
      _ActionData(label: '${l10n.invoices} (${l10n.newText})', icon: Icons.add_circle_outline_rounded, color: Colors.blue, path: AppRoutes.invoiceNew),
      _ActionData(label: '${l10n.purchaseOrders} (${l10n.newText})', icon: Icons.shopping_bag_outlined, color: Colors.orange, path: AppRoutes.purchaseOrderNew),
      _ActionData(label: '${l10n.customers} (${l10n.newText})', icon: Icons.person_add_outlined, color: Colors.green, path: AppRoutes.customerNew),
      _ActionData(label: '${l10n.receiveInventory} (${l10n.newText})', icon: Icons.inventory_2_outlined, color: Colors.purple, path: AppRoutes.receiveInventoryNew),
    ];

    return _DashboardCard(
      title: 'إجراءات سريعة', // Quick Actions (will l10n later if needed)
      child: Column(
        children: actions.map((a) => _ActionTile(data: a)).toList(),
      ),
    );
  }
}

class _ActionData {
  const _ActionData({required this.label, required this.icon, required this.color, required this.path});
  final String label;
  final IconData icon;
  final Color color;
  final String path;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.data});
  final _ActionData data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => context.go(data.path),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: data.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(data.icon, size: 16, color: data.color),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(data.label, style: Theme.of(context).textTheme.bodyMedium)),
            Icon(Icons.chevron_right_rounded, size: 18, color: cs.onSurface.withValues(alpha: 0.3)), // Chevron adjusted for RTL natively
          ],
        ),
      ),
    );
  }
}