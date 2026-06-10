// reports_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zayed/l10n/app_localizations.dart';

import '../../../app/router.dart';
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
      _ReportMenuItem(l10n.salesSummary, Icons.point_of_sale_outlined),
      _ReportMenuItem(l10n.purchasesSummary, Icons.shopping_cart_outlined),
      _ReportMenuItem(l10n.customerStatement, Icons.person_search_outlined),
      _ReportMenuItem(l10n.vendorStatement, Icons.storefront_outlined),
      _ReportMenuItem(l10n.incomeTracker, Icons.groups_outlined),
      _ReportMenuItem(l10n.billTracker, Icons.storefront_outlined),
      _ReportMenuItem(l10n.stock, Icons.inventory_2_outlined),
      _ReportMenuItem(l10n.tax, Icons.receipt_long_outlined),
      _ReportMenuItem(l10n.payrollSummary, Icons.payments_outlined),
      _ReportMenuItem(l10n.timeTrackingSummary, Icons.timer_outlined),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reports),
        actions: const [_ReportDateRangeButton(), SizedBox(width: 8)],
      ),
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

class _ReportDateRangeButton extends ConsumerWidget {
  const _ReportDateRangeButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(reportsDateRangeProvider);
    return OutlinedButton.icon(
      onPressed: () => _showDateRangeSheet(context, ref, range),
      icon: const Icon(Icons.date_range_outlined),
      label: Text('${_date(range.fromDate)} → ${_date(range.toDate)}'),
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
        return _ProfitAndLossView(
          report: ref.watch(profitAndLossReportProvider),
        );
      case 1:
        return _BalanceSheetView(report: ref.watch(balanceSheetReportProvider));
      case 2:
        return _TrialBalanceView(report: ref.watch(trialBalanceReportProvider));
      case 3:
        return _SalesSummaryView(report: ref.watch(salesSummaryReportProvider));
      case 4:
        return _PurchasesSummaryView(
          report: ref.watch(purchasesSummaryReportProvider),
        );
      case 5:
        final l10n = AppLocalizations.of(context)!;
        return _StatementLauncher(
          title: l10n.customerStatement,
          subtitle: l10n.customerStatementSubtitle,
          icon: Icons.person_search_outlined,
          route: AppRoutes.customerTransactionHistory,
          buttonText: l10n.openCustomerStatement,
          chips: [
            l10n.customerDropdown,
            l10n.dateRange,
            l10n.receiptsPaymentsInvoices,
            l10n.a4PdfPrint,
          ],
        );
      case 6:
        final l10n = AppLocalizations.of(context)!;
        return _StatementLauncher(
          title: l10n.vendorStatement,
          subtitle: l10n.vendorStatementSubtitle,
          icon: Icons.storefront_outlined,
          route: AppRoutes.vendorTransactionHistory,
          buttonText: l10n.openVendorStatement,
          chips: [
            l10n.vendorDropdown,
            l10n.dateRange,
            l10n.billsPayments,
            l10n.a4PdfPrint,
          ],
        );
      case 7:
        return _AgingView(
          report: ref.watch(accountsReceivableAgingReportProvider),
        );
      case 8:
        return _AgingView(
          report: ref.watch(accountsPayableAgingReportProvider),
        );
      case 9:
        return _InventoryValuationView(
          report: ref.watch(inventoryValuationReportProvider),
        );
      case 10:
        return _TaxSummaryView(report: ref.watch(taxSummaryReportProvider));
      case 11:
        return _PayrollSummaryView(report: ref.watch(payrollReportHubProvider));
      case 12:
        return _TimeTrackingSummaryView(
          report: ref.watch(timeTrackingReportHubProvider),
        );
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
          _SummaryGrid(
            items: [
              _SummaryItem(l10n.income, data.totalIncome),
              _SummaryItem(l10n.expensesByCategory, data.totalExpenses),
              _SummaryItem(l10n.netIncome, data.netProfit),
            ],
          ),
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
          _SummaryGrid(
            items: [
              _SummaryItem(l10n.total, data.totalAssets),
              _SummaryItem(l10n.totalAmount, data.totalLiabilities),
              _SummaryItem(l10n.currentBalance, data.totalEquity),
            ],
          ),
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
          _SummaryGrid(
            items: [
              _SummaryItem(l10n.totalAmount, data.totalDebit),
              _SummaryItem(l10n.totalPayment, data.totalCredit),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _ReportTable(
              columns: [
                l10n.chartOfAccounts,
                l10n.totalAmount,
                l10n.totalPayment,
              ],
              rows: data.items
                  .map(
                    (row) => [
                      '${row.accountCode} - ${row.accountName}',
                      row.closingDebit.toStringAsFixed(2),
                      row.closingCredit.toStringAsFixed(2),
                    ],
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesSummaryView extends StatelessWidget {
  const _SalesSummaryView({required this.report});
  final AsyncValue<SalesSummaryReportModel> report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _AsyncReportFrame<SalesSummaryReportModel>(
      title: l10n.salesSummary,
      report: report,
      builder: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryGrid(
            items: [
              _SummaryItem(l10n.invoices, data.invoiceCount.toDouble()),
              _SummaryItem(l10n.customers, data.customerCount.toDouble()),
              _SummaryItem(l10n.totalSales, data.totalAmount),
              _SummaryItem(l10n.balanceDue, data.balanceDue),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _ReportTable(
              columns: [
                l10n.invoice,
                l10n.date,
                l10n.due,
                l10n.customer,
                l10n.status,
                l10n.total,
                l10n.paid,
                l10n.balance,
              ],
              rows: data.invoices
                  .map(
                    (row) => [
                      row.invoiceNumber,
                      _date(row.invoiceDate),
                      _date(row.dueDate),
                      row.customerName,
                      _invoiceStatusLabel(context, row.status),
                      row.totalAmount.toStringAsFixed(2),
                      row.paidAmount.toStringAsFixed(2),
                      row.balanceDue.toStringAsFixed(2),
                    ],
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchasesSummaryView extends StatelessWidget {
  const _PurchasesSummaryView({required this.report});
  final AsyncValue<PurchasesSummaryReportModel> report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _AsyncReportFrame<PurchasesSummaryReportModel>(
      title: l10n.purchasesSummary,
      report: report,
      builder: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryGrid(
            items: [
              _SummaryItem(l10n.purchaseBills, data.billCount.toDouble()),
              _SummaryItem(l10n.vendors, data.vendorCount.toDouble()),
              _SummaryItem(l10n.totalPurchases, data.totalAmount),
              _SummaryItem(l10n.balanceDue, data.balanceDue),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _ReportTable(
              columns: [
                l10n.bill,
                l10n.date,
                l10n.due,
                l10n.vendor,
                l10n.status,
                l10n.total,
                l10n.paid,
                l10n.balance,
              ],
              rows: data.bills
                  .map(
                    (row) => [
                      row.billNumber,
                      _date(row.billDate),
                      _date(row.dueDate),
                      row.vendorName,
                      _purchaseBillStatusLabel(context, row.status),
                      row.totalAmount.toStringAsFixed(2),
                      row.paidAmount.toStringAsFixed(2),
                      row.balanceDue.toStringAsFixed(2),
                    ],
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatementLauncher extends StatelessWidget {
  const _StatementLauncher({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.buttonText,
    required this.chips,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final String buttonText;
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: cs.primaryContainer.withValues(alpha: 0.55),
                  child: Icon(icon, color: cs.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => context.push(route),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(buttonText),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: chips
                  .map(
                    (label) => Chip(
                      avatar: Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: cs.primary,
                      ),
                      label: Text(label),
                      side: BorderSide(color: cs.outlineVariant),
                      backgroundColor: cs.surface,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.statementLauncherHint,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
          _SummaryGrid(
            items: [
              _SummaryItem(l10n.currentBalance, data.current),
              _SummaryItem(l10n.moneyBarOverdue, data.over90),
              _SummaryItem(l10n.total, data.total),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _ReportTable(
              columns: [l10n.customer, l10n.currentBalance, l10n.total],
              rows: data.items
                  .map(
                    (row) => [
                      row.partyName,
                      row.current.toStringAsFixed(2),
                      row.total.toStringAsFixed(2),
                    ],
                  )
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
          _SummaryGrid(
            items: [_SummaryItem(l10n.total, data.totalClosingValue)],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _ReportTable(
              columns: [l10n.items, l10n.qty, l10n.unitCost, l10n.total],
              rows: data.items
                  .map(
                    (row) => [
                      row.itemName,
                      row.closingQuantity.toStringAsFixed(2),
                      row.unitCost.toStringAsFixed(2),
                      row.closingValue.toStringAsFixed(2),
                    ],
                  )
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
                  .map(
                    (row) => [
                      row.taxCodeName,
                      row.ratePercent.toStringAsFixed(2),
                      row.netTaxPayable.toStringAsFixed(2),
                    ],
                  )
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
    final l10n = AppLocalizations.of(context)!;
    return _AsyncReportFrame<PayrollSummaryReport>(
      title: l10n.payrollSummary,
      report: report,
      builder: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryGrid(
            items: [
              _SummaryItem(l10n.runs, data.runCount.toDouble()),
              _SummaryItem(l10n.employees, data.employeeCount.toDouble()),
              _SummaryItem(l10n.grossPay, data.totalGrossPay),
              _SummaryItem(l10n.netPay, data.totalNetPay),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _ReportTable(
              columns: [
                l10n.run,
                l10n.payDate,
                l10n.status,
                l10n.employees,
                l10n.gross,
                l10n.deductions,
                l10n.net,
              ],
              rows: data.runs
                  .map(
                    (run) => [
                      run.runNumber,
                      _date(run.payDate),
                      run.status,
                      run.employeeCount.toString(),
                      run.grossPay.toStringAsFixed(2),
                      run.deductions.toStringAsFixed(2),
                      run.netPay.toStringAsFixed(2),
                    ],
                  )
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
    final l10n = AppLocalizations.of(context)!;
    return _AsyncReportFrame<TimeEntrySummaryReport>(
      title: l10n.timeTrackingSummary,
      report: report,
      builder: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryGrid(
            items: [
              _SummaryItem(l10n.entries, data.entryCount.toDouble()),
              _SummaryItem(l10n.totalHours, data.totalHours),
              _SummaryItem(l10n.billableHours, data.billableHours),
              _SummaryItem(
                l10n.billableNotInvoiced,
                data.billableNotInvoicedHours,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _ReportTable(
              columns: [
                l10n.date,
                l10n.person,
                l10n.customer,
                l10n.service,
                l10n.activity,
                l10n.hours,
                l10n.status,
              ],
              rows: data.billableQueue
                  .map(
                    (row) => [
                      _date(row.workDate),
                      row.personName,
                      row.customerName,
                      row.serviceItemName,
                      row.activity,
                      row.hours.toStringAsFixed(2),
                      timeEntryStatusLabel(row.status),
                    ],
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AsyncReportFrame<T> extends StatelessWidget {
  const _AsyncReportFrame({
    required this.title,
    required this.report,
    required this.builder,
  });

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
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
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
          title: Text(
            section.title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          trailing: Text(
            section.total.toStringAsFixed(2),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
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
                      Text(
                        item.label,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.value.toStringAsFixed(2),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: columns
              .map((column) => DataColumn(label: Text(column)))
              .toList(),
          rows: rows
              .map(
                (row) => DataRow(
                  cells: row.map((cell) => DataCell(Text(cell))).toList(),
                ),
              )
              .toList(),
        ),
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

Future<void> _showDateRangeSheet(
  BuildContext context,
  WidgetRef ref,
  ReportDateRange current,
) async {
  final l10n = AppLocalizations.of(context)!;
  var fromDate = current.fromDate;
  var toDate = current.toDate;

  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.reportDateRange,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(_date(fromDate)),
              subtitle: Text(l10n.fromDate),
              trailing: TextButton(
                onPressed: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: fromDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (selected != null) setState(() => fromDate = selected);
                },
                child: Text(l10n.change),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_available_outlined),
              title: Text(_date(toDate)),
              subtitle: Text(l10n.toDate),
              trailing: TextButton(
                onPressed: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: toDate,
                    firstDate: fromDate,
                    lastDate: DateTime(2100),
                  );
                  if (selected != null) setState(() => toDate = selected);
                },
                child: Text(l10n.change),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () {
                    ref.read(reportsDateRangeProvider.notifier).state =
                        ReportDateRange(fromDate: fromDate, toDate: toDate);
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.check_outlined),
                  label: Text(l10n.apply),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

String _invoiceStatusLabel(BuildContext context, int status) {
  final l10n = AppLocalizations.of(context)!;
  return switch (status) {
    1 => l10n.statusDraft,
    2 => l10n.statusSent,
    3 => l10n.statusPartiallyPaid,
    4 => l10n.statusPaid,
    5 => l10n.statusVoid,
    6 => l10n.statusPosted,
    7 => l10n.statusReturned,
    _ => status.toString(),
  };
}

String _purchaseBillStatusLabel(BuildContext context, int status) {
  final l10n = AppLocalizations.of(context)!;
  return switch (status) {
    1 => l10n.statusDraft,
    2 => l10n.statusPosted,
    3 => l10n.statusVoid,
    4 => l10n.statusPartiallyPaid,
    5 => l10n.statusPaid,
    6 => l10n.statusReturned,
    _ => status.toString(),
  };
}

String _date(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
