// invoices_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../app/router.dart';
import '../data/models/invoice_contracts.dart';
import '../providers/invoices_state.dart';

enum _InvoiceStatusFilter { all, open, draft, paid, voided }

class InvoicesListPage extends ConsumerStatefulWidget {
  const InvoicesListPage({super.key});

  @override
  ConsumerState<InvoicesListPage> createState() => _InvoicesListPageState();
}

class _InvoicesListPageState extends ConsumerState<InvoicesListPage> {
  final _searchCtrl = TextEditingController();
  _InvoiceStatusFilter _status = _InvoiceStatusFilter.all;
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final invoicesAsync = ref.watch(invoicesStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.invoices),
        actions: [
          IconButton(
            tooltip: l10n.retry,
            onPressed: () => ref.read(invoicesStateProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: FilledButton.icon(
              onPressed: () => context.go(AppRoutes.invoiceNew),
              icon: const Icon(Icons.add),
              label: Text(l10n.newText),
            ),
          ),
        ],
      ),
      body: invoicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.read(invoicesStateProvider.notifier).refresh(),
        ),
        data: (invoices) {
          final filtered = _filter(invoices);
          return Column(
            children: [
              _InvoiceSearchBar(
                controller: _searchCtrl,
                status: _status,
                dateRange: _dateRange,
                totalCount: invoices.length,
                visibleCount: filtered.length,
                onChanged: () => setState(() {}),
                onStatusChanged: (status) => setState(() => _status = status),
                onDateRangeChanged: (range) =>
                    setState(() => _dateRange = range),
                onReset: () {
                  setState(() {
                    _searchCtrl.clear();
                    _status = _InvoiceStatusFilter.all;
                    _dateRange = null;
                  });
                },
              ),
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyState(l10n: l10n, hasFilters: invoices.isNotEmpty)
                    : _InvoiceResultsTable(invoices: filtered),
              ),
            ],
          );
        },
      ),
    );
  }

  List<InvoiceModel> _filter(List<InvoiceModel> invoices) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered = invoices.where((invoice) {
      final matchesQuery =
          query.isEmpty ||
          invoice.invoiceNumber.toLowerCase().contains(query) ||
          invoice.customerName.toLowerCase().contains(query) ||
          invoice.totalAmount.toStringAsFixed(2).contains(query) ||
          invoice.balanceDue.toStringAsFixed(2).contains(query);
      if (!matchesQuery) return false;

      final matchesStatus = switch (_status) {
        _InvoiceStatusFilter.all => true,
        _InvoiceStatusFilter.open =>
          !invoice.isDraft && !invoice.isVoid && invoice.balanceDue > 0,
        _InvoiceStatusFilter.draft => invoice.isDraft,
        _InvoiceStatusFilter.paid => invoice.isPaid && !invoice.isVoid,
        _InvoiceStatusFilter.voided => invoice.isVoid,
      };
      if (!matchesStatus) return false;

      final range = _dateRange;
      if (range == null) return true;
      final date = DateUtils.dateOnly(invoice.invoiceDate);
      return !date.isBefore(DateUtils.dateOnly(range.start)) &&
          !date.isAfter(DateUtils.dateOnly(range.end));
    }).toList();

    filtered.sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
    return filtered;
  }
}

class _InvoiceSearchBar extends StatelessWidget {
  const _InvoiceSearchBar({
    required this.controller,
    required this.status,
    required this.dateRange,
    required this.totalCount,
    required this.visibleCount,
    required this.onChanged,
    required this.onStatusChanged,
    required this.onDateRangeChanged,
    required this.onReset,
  });

  final TextEditingController controller;
  final _InvoiceStatusFilter status;
  final DateTimeRange? dateRange;
  final int totalCount;
  final int visibleCount;
  final VoidCallback onChanged;
  final ValueChanged<_InvoiceStatusFilter> onStatusChanged;
  final ValueChanged<DateTimeRange?> onDateRangeChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateLabel = dateRange == null
        ? 'Any date'
        : '${_fmtDate(dateRange!.start)} - ${_fmtDate(dateRange!.end)}';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: controller,
                  onChanged: (_) => onChanged(),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search invoice #, customer, amount...',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(now.year - 5),
                    lastDate: DateTime(now.year + 3),
                    initialDateRange: dateRange,
                  );
                  onDateRangeChanged(picked);
                },
                icon: const Icon(Icons.date_range_outlined, size: 18),
                label: Text(dateLabel),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Reset filters',
                onPressed: onReset,
                icon: const Icon(Icons.filter_alt_off_outlined),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SegmentedButton<_InvoiceStatusFilter>(
                segments: const [
                  ButtonSegment(
                    value: _InvoiceStatusFilter.all,
                    label: Text('All'),
                    icon: Icon(Icons.all_inbox_outlined),
                  ),
                  ButtonSegment(
                    value: _InvoiceStatusFilter.open,
                    label: Text('Open'),
                    icon: Icon(Icons.pending_actions_outlined),
                  ),
                  ButtonSegment(
                    value: _InvoiceStatusFilter.draft,
                    label: Text('Draft'),
                    icon: Icon(Icons.drafts_outlined),
                  ),
                  ButtonSegment(
                    value: _InvoiceStatusFilter.paid,
                    label: Text('Paid'),
                    icon: Icon(Icons.check_circle_outline),
                  ),
                  ButtonSegment(
                    value: _InvoiceStatusFilter.voided,
                    label: Text('Void'),
                    icon: Icon(Icons.block),
                  ),
                ],
                selected: {status},
                onSelectionChanged: (next) => onStatusChanged(next.first),
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const Spacer(),
              Text(
                '$visibleCount of $totalCount invoices',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvoiceResultsTable extends StatelessWidget {
  const _InvoiceResultsTable({required this.invoices});

  final List<InvoiceModel> invoices;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _TableHeader(),
        for (var i = 0; i < invoices.length; i++)
          _InvoiceRow(invoice: invoices[i], shaded: i.isOdd),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = TextStyle(
      color: cs.onSurfaceVariant,
      fontSize: 11,
      fontWeight: FontWeight.w900,
    );
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          _HeaderCell('DATE', flex: 1, style: style),
          _HeaderCell('NUM', flex: 2, style: style),
          _HeaderCell('CUSTOMER', flex: 3, style: style),
          _HeaderCell('STATUS', flex: 1, style: style),
          _HeaderCell('DUE', flex: 1, style: style),
          _HeaderCell('TOTAL', flex: 1, style: style, right: true),
          _HeaderCell('BALANCE', flex: 1, style: style, right: true),
        ],
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({required this.invoice, required this.shaded});

  final InvoiceModel invoice;
  final bool shaded;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = shaded ? const Color(0xFFF4F7F8) : cs.surface;
    final statusColor = _statusColor(cs);
    return Material(
      color: bg,
      child: InkWell(
        hoverColor: const Color(0xFFDCEBF0),
        onTap: () => context.go(
          AppRoutes.invoiceDetails.replaceFirst(':id', invoice.id),
        ),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: cs.outlineVariant),
              right: BorderSide(color: cs.outlineVariant),
              bottom: BorderSide(color: cs.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              _DataCell(_fmtDate(invoice.invoiceDate), flex: 1),
              _DataCell(
                invoice.invoiceNumber.isEmpty
                    ? 'Invoice'
                    : invoice.invoiceNumber,
                flex: 2,
                bold: true,
              ),
              _DataCell(invoice.customerName, flex: 3),
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _StatusPill(label: _statusLabel, color: statusColor),
                ),
              ),
              _DataCell(_fmtDate(invoice.dueDate), flex: 1),
              _DataCell(_fmtMoney(invoice.totalAmount), flex: 1, right: true),
              _DataCell(
                _fmtMoney(invoice.balanceDue),
                flex: 1,
                right: true,
                color: invoice.balanceDue > 0 ? cs.error : cs.primary,
                bold: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _statusLabel {
    if (invoice.isVoid) return 'Void';
    if (invoice.isPaid) return 'Paid';
    if (invoice.isPartiallyPaid) return 'Partial';
    if (invoice.isDraft) return 'Draft';
    return 'Open';
  }

  Color _statusColor(ColorScheme cs) {
    if (invoice.isVoid) return cs.error;
    if (invoice.isPaid) return cs.primary;
    if (invoice.isPartiallyPaid) return Colors.orange.shade800;
    if (invoice.isDraft) return cs.tertiary;
    return const Color(0xFF177A25);
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(
    this.text, {
    required this.flex,
    required this.style,
    this.right = false,
  });

  final String text;
  final int flex;
  final TextStyle style;
  final bool right;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          text,
          textAlign: right ? TextAlign.right : TextAlign.left,
          style: style,
        ),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  const _DataCell(
    this.text, {
    required this.flex,
    this.right = false,
    this.bold = false,
    this.color,
  });

  final String text;
  final int flex;
  final bool right;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: right ? TextAlign.right : TextAlign.left,
          style: TextStyle(
            color: color,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n, required this.hasFilters});

  final AppLocalizations l10n;
  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 56),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'No invoices match your filters' : l10n.invoices,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Reset the filters or refine the search.'
                  : l10n.creditSale,
              textAlign: TextAlign.center,
            ),
            if (!hasFilters) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.go(AppRoutes.invoiceNew),
                icon: const Icon(Icons.add),
                label: Text(l10n.createInvoice),
              ),
            ],
          ],
        ),
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
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

String _fmtDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

String _fmtMoney(double value) => NumberFormat('#,##0.00').format(value);
