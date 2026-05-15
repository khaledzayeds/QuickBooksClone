// invoices_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../app/router.dart';
import '../data/models/invoice_contracts.dart';
import '../providers/invoices_state.dart';

class InvoicesListPage extends ConsumerStatefulWidget {
  const InvoicesListPage({super.key});

  @override
  ConsumerState<InvoicesListPage> createState() => _InvoicesListPageState();
}

class _InvoicesListPageState extends ConsumerState<InvoicesListPage> {
  final _searchCtrl = TextEditingController();
  String _status = 'all';
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoicesStateProvider);
    final l10n = AppLocalizations.of(context)!;
    
    final dateLabel = _dateRange == null
        ? 'Any date'
        : '${_date(_dateRange!.start)} - ${_date(_dateRange!.end)}';

    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF0),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 74,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F6F7),
                border: Border(bottom: BorderSide(color: Color(0xFFB7C3CB))),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  _Tool(
                    icon: Icons.search,
                    label: 'Find',
                    onTap: () => FocusScope.of(context).nextFocus(),
                  ),
                  _Tool(
                    icon: Icons.note_add_outlined,
                    label: 'New',
                    onTap: () => context.push(AppRoutes.invoiceNew),
                  ),
                  _Tool(
                    icon: Icons.refresh,
                    label: 'Refresh',
                    onTap: () => ref.read(invoicesStateProvider.notifier).refresh(),
                  ),
                  const Spacer(),
                  _Tool(
                    icon: Icons.close,
                    label: 'Close',
                    onTap: () => context.go(AppRoutes.dashboard),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFB7C3CB))),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 190,
                    child: Text(
                      'Invoices',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: const Color(0xFF243E4A),
                            fontWeight: FontWeight.w300,
                          ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.search, size: 18),
                        hintText: 'Search invoice #, customer, amount...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 200,
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(now.year - 5),
                          lastDate: DateTime(now.year + 3),
                          initialDateRange: _dateRange,
                        );
                        setState(() => _dateRange = picked);
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: const BorderSide(color: Color(0xFF79747E)),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.centerLeft,
                      ),
                      icon: const Icon(Icons.date_range, size: 18, color: Color(0xFF49454F)),
                      label: Text(
                        dateLabel,
                        style: const TextStyle(color: Color(0xFF1D1B20)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 150,
                    child: DropdownButtonFormField<String>(
                      initialValue: _status,
                      isDense: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All')),
                        DropdownMenuItem(value: 'open', child: Text('Open')),
                        DropdownMenuItem(value: 'draft', child: Text('Draft')),
                        DropdownMenuItem(value: 'paid', child: Text('Paid')),
                        DropdownMenuItem(value: 'voided', child: Text('Voided')),
                      ],
                      onChanged: (value) =>
                          setState(() => _status = value ?? 'all'),
                    ),
                  ),
                  if (_dateRange != null) ...[
                    const SizedBox(width: 10),
                    IconButton(
                      tooltip: 'Clear filters',
                      icon: const Icon(Icons.clear, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _dateRange = null;
                          _status = 'all';
                          _searchCtrl.clear();
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: invoicesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(error.toString())),
                data: (invoices) {
                  final filtered = _filter(invoices);
                  if (filtered.isEmpty) {
                    return Center(child: Text(l10n.noRecentTransactions));
                  }

                  return Padding(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFF9EADB6)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 30,
                            color: const Color(0xFFDDE8ED),
                            child: const Row(
                              children: [
                                _HeaderCell('DATE', flex: 2),
                                _HeaderCell('NUM', flex: 2),
                                _HeaderCell('CUSTOMER', flex: 4),
                                _HeaderCell('STATUS', flex: 2),
                                _HeaderCell('DUE', flex: 2),
                                _HeaderCell('TOTAL', flex: 2, right: true),
                                _HeaderCell('BALANCE', flex: 2, right: true),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final invoice = filtered[index];
                                final shaded = index.isEven;
                                final statusColor = _statusColor(invoice);
                                
                                return InkWell(
                                  onTap: () => context.push(
                                    AppRoutes.invoiceDetails.replaceFirst(
                                      ':id',
                                      invoice.id,
                                    ),
                                  ),
                                  child: Container(
                                    height: 34,
                                    color: shaded
                                        ? const Color(0xFFDDEFF4)
                                        : Colors.white,
                                    child: Row(
                                      children: [
                                        _Cell(
                                          _date(invoice.invoiceDate),
                                          flex: 2,
                                        ),
                                        _Cell(
                                          invoice.invoiceNumber.isEmpty
                                              ? 'Invoice'
                                              : invoice.invoiceNumber,
                                          flex: 2,
                                        ),
                                        _Cell(
                                          invoice.customerName,
                                          flex: 4,
                                        ),
                                        _Cell(
                                          _statusLabel(invoice), 
                                          flex: 2,
                                          color: statusColor,
                                          strong: true,
                                        ),
                                        _Cell(
                                          _date(invoice.dueDate),
                                          flex: 2,
                                        ),
                                        _Cell(
                                          _fmtMoney(invoice.totalAmount),
                                          flex: 2,
                                          right: true,
                                        ),
                                        _Cell(
                                          _fmtMoney(invoice.balanceDue),
                                          flex: 2,
                                          right: true,
                                          strong: true,
                                          color: invoice.balanceDue > 0 ? Colors.red.shade700 : const Color(0xFF177A25),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.centerLeft,
              decoration: const BoxDecoration(
                color: Color(0xFFD4DDE3),
                border: Border(top: BorderSide(color: Color(0xFFAFBBC4))),
              ),
              child: Text(
                'Invoices search  •  Enter opens invoice workspace  •  Esc Close',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF33434C),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
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
        'all' => true,
        'open' =>
          !invoice.isDraft && !invoice.isVoid && invoice.balanceDue > 0,
        'draft' => invoice.isDraft,
        'paid' => invoice.isPaid && !invoice.isVoid,
        'voided' => invoice.isVoid,
        _ => true,
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

  static String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  static String _fmtMoney(double value) => NumberFormat('#,##0.00').format(value);

  static String _statusLabel(InvoiceModel invoice) {
    if (invoice.isVoid) return 'Void';
    if (invoice.isPaid) return 'Paid';
    if (invoice.isPartiallyPaid) return 'Partial';
    if (invoice.isDraft) return 'Draft';
    return 'Open';
  }

  static Color _statusColor(InvoiceModel invoice) {
    if (invoice.isVoid) return Colors.red.shade700;
    if (invoice.isPaid) return const Color(0xFF177A25);
    if (invoice.isPartiallyPaid) return Colors.orange.shade800;
    if (invoice.isDraft) return const Color(0xFF7D8B93);
    return const Color(0xFF177A25);
  }
}

class _Tool extends StatelessWidget {
  const _Tool({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = enabled ? const Color(0xFF234C5D) : const Color(0xFF7D8B93);
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 66,
        height: 74,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: enabled ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text, {required this.flex, this.right = false});
  final String text;
  final int flex;
  final bool right;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        text,
        textAlign: right ? TextAlign.end : TextAlign.start,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF53656E),
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _Cell extends StatelessWidget {
  const _Cell(
    this.text, {
    required this.flex,
    this.right = false,
    this.strong = false,
    this.color,
  });
  final String text;
  final int flex;
  final bool right;
  final bool strong;
  final Color? color;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Container(
      height: double.infinity,
      alignment: right ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFFB8C6CE))),
      ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
          color: color ?? const Color(0xFF273F4B),
        ),
      ),
    ),
  );
}
