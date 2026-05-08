// reports_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../payroll/providers/payroll_runs_provider.dart';
import '../../time_tracking/providers/time_entries_provider.dart';
import '../data/models/report_models.dart';
import '../providers/reports_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reports = [
      _ReportMenuItem(l10n.profitAndLoss, Icons.trending_up),
      _ReportMenuItem(l10n.bankAccounts, Icons.account_balance),
      _ReportMenuItem(l10n.chartOfAccounts, Icons.balance),
      _ReportMenuItem(l10n.incomeTracker, Icons.groups_outlined),
      _ReportMenuItem(l10n.billTracker, Icons.storefront_outlined),
      _ReportMenuItem(l10n.stock, Icons.inventory_2_outlined),
      _ReportMenuItem(l10n.tax, Icons.receipt_long_outlined),
      const _ReportMenuItem('Payroll Summary', Icons.payments_outlined),
      const _ReportMenuItem('Time Tracking Summary', Icons.timer_outlined),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reports)),
      body: Row(
        children: [
          SizedBox(
            width: 280,
            child: Card(
              margin: const EdgeInsets.all(16),
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: reports.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = reports[index];
                  return ListTile(
                    selected: _selected == index,
                    leading: Icon(item.icon),
                    title: Text(item.title),
                    onTap: () => setState(() => _selected = index),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
              child: _ReportBody(index: _selected),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportMenuItem {
  const _ReportMenuItem(this.title, this.icon);
  final String title;
  final IconData icon;
}

class _ReportBody extends ConsumerWidget {
  const _ReportBody({required this.index});
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (index) {
      case 0:
        return _ProfitAndLossView(report: ref.watch(profitAndLossReportProvider));
      case 1:
        return _BalanceSheetView(report: ref.watch(balanceSheetReportProvider));
      case 2:
        return _TrialBalanceView(report: ref.watch(trialBalanceReportProvider));
      case 3:
        return _AgingView(report: ref.watch(accountsReceivableAgingReportProvider));
      case 4:
        return _AgingView(report: ref.watch(accountsPayableAgingReportProvider));
      case 5:
        return _InventoryValuationView(report: ref.watch(inventoryValuationReportProvider));
      case 6:
        return _TaxSummaryView(report: ref.watch(taxSummaryReportProvider));
      case 7:
        return _PayrollSummaryView(report: ref.watch(payrollReportHubProvider));
      case 8:
        return _TimeTrackingSummaryView(report: ref.watch(timeTrackingReportHubProvider));
      default:
        return const SizedBox.shrink();
    }
  }
}

class _ProfitAndLossView extends StatelessWidget {
  const _ProfitAndLossView({required this.report});
  final AsyncValue<ProfitAndLossReportModel> report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _AsyncReportFrame<ProfitAndLossReportModel>(
      title: l10n.profitAndLoss,
      report: report,
      builder: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryGrid(items: [
            _SummaryItem(l10n.income, data.totalIncome),
            _SummaryItem(l10n.expensesByCategory, data.totalExpenses),
            _SummaryItem(l10n.netIncome, data.netProfit),
          ]),
          const SizedBox(height: 16),
          Expanded(child: _FinancialSections(sections: data.sections)),
        ],
      ),
    );
  }
}

class _BalanceSheetView extends StatelessWidget {
  const _BalanceSheetView({required this.report});
  final AsyncValue<FinancialStatementReportModel> report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _AsyncReportFrame<FinancialStatementReportModel>(
      title: l10n.bankAccounts,
      report: report,
      builder: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryGrid(items: [
            _SummaryItem(l10n.total, data.totalAssets),
            _SummaryItem(l10n.totalAmount, data.totalLiabilities),
            _SummaryItem(l10n.currentBalance, data.totalEquity),
          ]),
          const SizedBox(height: 16),
          Expanded(child: _FinancialSections(sections: data.sections)),
        ],
      ),
    );
  }
}

class _TrialBalanceView extends StatelessWidget {
  const _TrialBalanceView({required this.report});
  final AsyncValue<TrialBalanceReportModel> report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _AsyncReportFrame<TrialBalanceReportModel>(
      title: l10n.chartOfAccounts,
      report: report,
      builder: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryGrid(items: [
            _SummaryItem(l10n.totalAmount, data.totalDebit),
            _SummaryItem(l10n.totalPayment, data.totalCredit),
          ]),
          const SizedBox(height: 16),
          Expanded(
            child: _ReportTable(
              columns: [l10n.chartOfAccounts, l10n.totalAmount, l10n.totalPayment],
              rows: data.items
                  .map((row) => [
                        '${row.accountCode} - ${row.accountName}',
                        row.closingDebit.toStringAsFixed(2),
                        row.closingCredit.toStringAsFixed(2),
                      ])
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgingView extends StatelessWidget {
  const _AgingView({required this.report});
  final AsyncValue<AgingReportModel> report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _AsyncReportFrame<AgingReportModel>(
      title: l10n.currentBalance,
      report: report,
      builder: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryGrid(items: [
            _SummaryItem(l10n.currentBalance, data.current),
            _SummaryItem(l10n.moneyBarOverdue, data.over90),
            _SummaryItem(l10n.total, data.total),
          ]),
          const SizedBox(height: 16),
          Expanded(
            child: _ReportTable(
              columns: [l10n.customer, l10n.currentBalance, l10n.total],
              rows: data.items
                  .map((row) => [row.partyName, row.current.toStringAsFixed(2), row.total.toStringAsFixed(2)])
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryValuationView extends StatelessWidget {
  const _InventoryValuationView({required this.report});
  final AsyncValue<InventoryValuationReportModel> report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _AsyncReportFrame<InventoryValuationReportModel>(
      title: l10n.stock,
      report: report,
      builder: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryGrid(items: [_SummaryItem(l10n.total, data.totalClosingValue)]),
          const SizedBox(height: 16),
          Expanded(
            child: _ReportTable(
              columns: [l10n.items, l10n.qty, l10n.unitCost, l10n.total],
              rows: data.items
                  .map((row) => [row.itemName, row.closingQuantity.toStringAsFixed(2), row.unitCost.toStringAsFixed(2), row.closingValue.toStringAsFixed(2)])
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaxSummaryView extends StatelessWidget {
  const _TaxSummaryView({required this.report});
  final AsyncValue<TaxSummaryReportModel> report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _AsyncReportFrame<TaxSummaryReportModel>(
      title: l10n.tax,
      report: report,
      builder: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryGrid(items: [_SummaryItem(l10n.total, data.netTaxPayable)]),
          const SizedBox(height: 16),
          Expanded(
            child: _ReportTable(
              columns: [l10n.description, l10n.rate, l10n.total],
              rows: data.items
                  .map((row) => [row.taxCodeName, row.ratePercent.toStringAsFixed(2), row.netTaxPayable.toStringAsFixed(2)])
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PayrollSummaryView extends StatelessWidget {
  const _PayrollSummaryView({required this.report});
  final AsyncValue<PayrollSummaryReport> report;

  @override
  Widget build(BuildContext context) {
    return _AsyncReportFrame<PayrollSummaryReport>(
      title: 'Payroll Summary',
      report: report,
      builder: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryGrid(items: [
            _SummaryItem('Runs', data.runCount.toDouble()),
            _SummaryItem('Employees', data.employeeCount.toDouble()),
            _SummaryItem('Gross Pay', data.totalGrossPay),
            _SummaryItem('Net Pay', data.totalNetPay),
          ]),
          const SizedBox(height: 16),
          Expanded(
            child: _ReportTable(
              columns: const ['Run', 'Pay Date', 'Status', 'Employees', 'Gross', 'Deductions', 'Net'],
              rows: data.runs
                  .map((run) => [
                        run.runNumber,
                        _date(run.payDate),
                        run.status,
                        run.employeeCount.toString(),
                        run.grossPay.toStringAsFixed(2),
                        run.deductions.toStringAsFixed(2),
                        run.netPay.toStringAsFixed(2),
                      ])
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeTrackingSummaryView extends StatelessWidget {
  const _TimeTrackingSummaryView({required this.report});
  final AsyncValue<TimeEntrySummaryReport> report;

  @override
  Widget build(BuildContext context) {
    return _AsyncReportFrame<TimeEntrySummaryReport>(
      title: 'Time Tracking Summary',
      report: report,
      builder: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryGrid(items: [
            _SummaryItem('Entries', data.entryCount.toDouble()),
            _SummaryItem('Total Hours', data.totalHours),
            _SummaryItem('Billable Hours', data.billableHours),
            _SummaryItem('Billable Not Invoiced', data.billableNotInvoicedHours),
          ]),
          const SizedBox(height: 16),
          Expanded(
            child: _ReportTable(
              columns: const ['Date', 'Person', 'Customer', 'Service', 'Activity', 'Hours', 'Status'],
              rows: data.billableQueue
                  .map((row) => [
                        _date(row.workDate),
                        row.personName,
                        row.customerName,
                        row.serviceItemName,
                        row.activity,
                        row.hours.toStringAsFixed(2),
                        timeEntryStatusLabel(row.status),
                      ])
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AsyncReportFrame<T> extends StatelessWidget {
  const _AsyncReportFrame({required this.title, required this.report, required this.builder});

  final String title;
  final AsyncValue<T> report;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            Expanded(
              child: report.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ErrorState(message: error.toString()),
                data: builder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinancialSections extends StatelessWidget {
  const _FinancialSections({required this.sections});
  final List<FinancialSectionModel> sections;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: sections.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final section = sections[index];
        return ExpansionTile(
          initiallyExpanded: true,
          title: Text(section.title, style: const TextStyle(fontWeight: FontWeight.w800)),
          trailing: Text(section.total.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w900)),
          children: section.items
              .map(
                (item) => ListTile(
                  dense: true,
                  title: Text('${item.accountCode} - ${item.accountName}'),
                  trailing: Text(item.amount.toStringAsFixed(2)),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SummaryItem {
  const _SummaryItem(this.label, this.value);
  final String label;
  final double value;
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.items});
  final List<_SummaryItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items
          .map(
            (item) => SizedBox(
              width: 220,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.label, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 8),
                      Text(item.value.toStringAsFixed(2), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ReportTable extends StatelessWidget {
  const _ReportTable({required this.columns, required this.rows});
  final List<String> columns;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: DataTable(
        columns: columns.map((column) => DataColumn(label: Text(column))).toList(),
        rows: rows.map((row) => DataRow(cells: row.map((cell) => DataCell(Text(cell))).toList())).toList(),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

String _date(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
