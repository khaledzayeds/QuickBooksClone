// sales_receipts_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/sales_receipts_state.dart';
import '../data/models/sales_receipt_contracts.dart';
import '../../../app/router.dart';

class SalesReceiptsListPage extends ConsumerStatefulWidget {
  const SalesReceiptsListPage({super.key});

  @override
  ConsumerState<SalesReceiptsListPage> createState() =>
      _SalesReceiptsListPageState();
}

class _SalesReceiptsListPageState
    extends ConsumerState<SalesReceiptsListPage> {
  final _queryCtrl = TextEditingController();
  int _selectedStatus = 0; // 0: All, 1: Posted, 2: Void
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final receiptsAsync = ref.watch(salesReceiptsStateProvider);
    final l10n = AppLocalizations.of(context)!;
    
    final dateLabel = _dateRange == null
        ? 'Any date'
        : '${_fmtDate(_dateRange!.start)} - ${_fmtDate(_dateRange!.end)}';

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
                    onTap: () => context.push(AppRoutes.salesReceiptNew),
                  ),
                  _Tool(
                    icon: Icons.refresh,
                    label: 'Refresh',
                    onTap: () => ref.read(salesReceiptsStateProvider.notifier).refresh(),
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
                      'Sales Receipts',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: const Color(0xFF243E4A),
                            fontWeight: FontWeight.w300,
                          ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _queryCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.search, size: 18),
                        hintText: 'Search receipt #, customer, amount...',
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
                    child: DropdownButtonFormField<int>(
                      initialValue: _selectedStatus,
                      isDense: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('All')),
                        DropdownMenuItem(value: 1, child: Text('Posted')),
                        DropdownMenuItem(value: 2, child: Text('Void')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedStatus = value ?? 0);
                      },
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
                          _selectedStatus = 0;
                          _queryCtrl.clear();
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: receiptsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(error.toString())),
                data: (receipts) {
                  final filtered = _filter(receipts);
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
                                _HeaderCell('METHOD', flex: 2),
                                _HeaderCell('DEPOSIT TO', flex: 2),
                                _HeaderCell('STATUS', flex: 2),
                                _HeaderCell('TOTAL', flex: 2, right: true),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final receipt = filtered[index];
                                final shaded = index.isEven;
                                
                                return InkWell(
                                  onTap: () => context.push(
                                    AppRoutes.salesReceiptDetails.replaceFirst(
                                      ':id',
                                      receipt.id,
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
                                          _fmtDate(receipt.receiptDate),
                                          flex: 2,
                                        ),
                                        _Cell(
                                          receipt.receiptNumber.isEmpty
                                              ? 'Receipt'
                                              : receipt.receiptNumber,
                                          flex: 2,
                                        ),
                                        _Cell(
                                          receipt.customerName,
                                          flex: 4,
                                        ),
                                        _Cell(
                                          receipt.paymentMethod ?? '-',
                                          flex: 2,
                                        ),
                                        _Cell(
                                          receipt.depositAccountName ?? '-',
                                          flex: 2,
                                        ),
                                        _CellWidget(
                                          flex: 2,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: _StatusBadge(isVoid: receipt.isVoid),
                                          ),
                                        ),
                                        _Cell(
                                          _fmtMoney(receipt.totalAmount),
                                          flex: 2,
                                          right: true,
                                          strong: true,
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
                'Sales receipts search  •  Enter opens receipt workspace  •  Esc Close',
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

  List<SalesReceiptModel> _filter(List<SalesReceiptModel> receipts) {
    final query = _queryCtrl.text.trim().toLowerCase();
    return receipts.where((receipt) {
      if (_selectedStatus == 1 && receipt.isVoid) return false;
      if (_selectedStatus == 2 && !receipt.isVoid) return false;

      final range = _dateRange;
      if (range != null) {
        final date = DateUtils.dateOnly(receipt.receiptDate);
        if (date.isBefore(DateUtils.dateOnly(range.start)) ||
            date.isAfter(DateUtils.dateOnly(range.end))) {
          return false;
        }
      }

      if (query.isEmpty) return true;
      return receipt.receiptNumber.toLowerCase().contains(query) ||
          receipt.customerName.toLowerCase().contains(query) ||
          (receipt.paymentMethod?.toLowerCase().contains(query) ?? false) ||
          (receipt.depositAccountName?.toLowerCase().contains(query) ?? false) ||
          receipt.totalAmount.toStringAsFixed(2).contains(query);
    }).toList()..sort((a, b) => b.receiptDate.compareTo(a.receiptDate));
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

class _CellWidget extends StatelessWidget {
  const _CellWidget({
    required this.child,
    required this.flex,
  });
  final Widget child;
  final int flex;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Container(
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFFB8C6CE))),
      ),
      child: child,
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isVoid});
  final bool isVoid;

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color bg;
    final Color fg;
    
    if (isVoid) {
      label = 'Void';
      bg = Colors.red.shade100;
      fg = Colors.red.shade800;
    } else {
      label = 'Posted';
      bg = Colors.green.shade100;
      fg = Colors.green.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

String _fmtDate(DateTime value) => DateFormat('dd/MM/yyyy').format(value);

String _fmtMoney(double value) => NumberFormat('#,##0.00').format(value);
