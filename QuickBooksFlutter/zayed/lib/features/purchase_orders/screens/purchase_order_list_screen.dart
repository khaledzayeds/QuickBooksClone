// purchase_order_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/purchase_orders_provider.dart';
import '../data/models/purchase_order_model.dart';
import '../../../app/router.dart';

enum _PurchaseOrderStatusFilter { all, draft, open, closed, cancelled }

class PurchaseOrderListScreen extends ConsumerStatefulWidget {
  const PurchaseOrderListScreen({super.key});

  @override
  ConsumerState<PurchaseOrderListScreen> createState() =>
      _PurchaseOrderListScreenState();
}

class _PurchaseOrderListScreenState
    extends ConsumerState<PurchaseOrderListScreen> {
  _PurchaseOrderStatusFilter _selectedStatus = _PurchaseOrderStatusFilter.all;
  final _queryCtrl = TextEditingController();
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  PurchaseOrderStatus? _toPurchaseOrderStatus(
    _PurchaseOrderStatusFilter status,
  ) {
    return switch (status) {
      _PurchaseOrderStatusFilter.all => null,
      _PurchaseOrderStatusFilter.draft => PurchaseOrderStatus.draft,
      _PurchaseOrderStatusFilter.open => PurchaseOrderStatus.open,
      _PurchaseOrderStatusFilter.closed => PurchaseOrderStatus.closed,
      _PurchaseOrderStatusFilter.cancelled => PurchaseOrderStatus.cancelled,
    };
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(purchaseOrdersProvider);
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
                    onTap: () => context.push(AppRoutes.purchaseOrderNew),
                  ),
                  _Tool(
                    icon: Icons.refresh,
                    label: 'Refresh',
                    onTap: () => ref.read(purchaseOrdersProvider.notifier).refresh(),
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
                      'Purchase Orders',
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
                        hintText: 'Search purchase order #, vendor, amount...',
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
                    child: DropdownButtonFormField<_PurchaseOrderStatusFilter>(
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
                        DropdownMenuItem(value: _PurchaseOrderStatusFilter.all, child: Text('All')),
                        DropdownMenuItem(value: _PurchaseOrderStatusFilter.draft, child: Text('Draft')),
                        DropdownMenuItem(value: _PurchaseOrderStatusFilter.open, child: Text('Open')),
                        DropdownMenuItem(value: _PurchaseOrderStatusFilter.closed, child: Text('Closed')),
                        DropdownMenuItem(value: _PurchaseOrderStatusFilter.cancelled, child: Text('Cancelled')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedStatus = value ?? _PurchaseOrderStatusFilter.all);
                        ref.read(purchaseOrdersProvider.notifier).setStatusFilter(_toPurchaseOrderStatus(_selectedStatus));
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
                          _selectedStatus = _PurchaseOrderStatusFilter.all;
                          _queryCtrl.clear();
                        });
                        ref.read(purchaseOrdersProvider.notifier).setStatusFilter(null);
                      },
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ordersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(error.toString())),
                data: (orders) {
                  final filtered = _filter(orders);
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
                                _HeaderCell('VENDOR', flex: 4),
                                _HeaderCell('STATUS', flex: 2),
                                _HeaderCell('EXPECTED', flex: 2),
                                _HeaderCell('TOTAL', flex: 2, right: true),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final order = filtered[index];
                                final shaded = index.isEven;
                                
                                return InkWell(
                                  onTap: () => context.push(
                                    AppRoutes.purchaseOrderDetails.replaceFirst(
                                      ':id',
                                      order.id,
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
                                          _fmtDate(order.orderDate),
                                          flex: 2,
                                        ),
                                        _Cell(
                                          order.orderNumber.isEmpty
                                              ? 'Purchase Order'
                                              : order.orderNumber,
                                          flex: 2,
                                        ),
                                        _Cell(
                                          order.vendorName,
                                          flex: 4,
                                        ),
                                        _CellWidget(
                                          flex: 2,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: _StatusBadge(status: order.status),
                                          ),
                                        ),
                                        _Cell(
                                          _fmtDate(order.expectedDate),
                                          flex: 2,
                                        ),
                                        _Cell(
                                          _fmtMoney(order.totalAmount),
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
                'Purchase Orders search  •  Enter opens purchase order workspace  •  Esc Close',
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

  List<PurchaseOrderModel> _filter(List<PurchaseOrderModel> orders) {
    final query = _queryCtrl.text.trim().toLowerCase();
    return orders.where((order) {
      final matchesText =
          query.isEmpty ||
          order.orderNumber.toLowerCase().contains(query) ||
          order.vendorName.toLowerCase().contains(query);
      final matchesStatus = switch (_selectedStatus) {
        _PurchaseOrderStatusFilter.all => true,
        _PurchaseOrderStatusFilter.draft =>
          order.status == PurchaseOrderStatus.draft,
        _PurchaseOrderStatusFilter.open =>
          order.status == PurchaseOrderStatus.open,
        _PurchaseOrderStatusFilter.closed =>
          order.status == PurchaseOrderStatus.closed,
        _PurchaseOrderStatusFilter.cancelled =>
          order.status == PurchaseOrderStatus.cancelled,
      };
      if (!matchesText || !matchesStatus) return false;
      final range = _dateRange;
      if (range == null) return true;
      final date = DateUtils.dateOnly(order.orderDate);
      return !date.isBefore(DateUtils.dateOnly(range.start)) &&
          !date.isAfter(DateUtils.dateOnly(range.end));
    }).toList()..sort((a, b) => b.orderDate.compareTo(a.orderDate));
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

// ─── Status Badge ─────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final PurchaseOrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (status) {
      PurchaseOrderStatus.draft => (Colors.grey.shade200, Colors.grey.shade700),
      PurchaseOrderStatus.open => (
        Colors.green.shade100,
        Colors.green.shade800,
      ),
      PurchaseOrderStatus.closed => (
        Colors.blue.shade100,
        Colors.blue.shade800,
      ),
      PurchaseOrderStatus.cancelled => (
        Colors.red.shade100,
        Colors.red.shade800,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.localizedLabel(context),
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

String _fmtDate(DateTime value) => DateFormat('dd/MM/yyyy').format(value);

String _fmtMoney(double value) => NumberFormat('#,##0.00').format(value);
