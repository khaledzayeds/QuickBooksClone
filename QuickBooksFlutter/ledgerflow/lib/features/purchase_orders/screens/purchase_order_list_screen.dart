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

  // ignore: unused_field
  static const _filters = [
    (null, 'الكل | All'),
    (PurchaseOrderStatus.draft, 'مسودة | Draft'),
    (PurchaseOrderStatus.open, 'مفتوح | Open'),
    (PurchaseOrderStatus.closed, 'مغلق | Closed'),
    (PurchaseOrderStatus.cancelled, 'ملغي | Cancelled'),
  ];

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  List<PurchaseOrderModel> _filtered(List<PurchaseOrderModel> orders) {
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF0),
      appBar: AppBar(
        title: Text(l10n.purchaseOrders),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(purchaseOrdersProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: FilledButton.icon(
              onPressed: () => context.go(AppRoutes.purchaseOrderNew),
              icon: const Icon(Icons.add),
              label: Text(l10n.newText),
            ),
          ),
        ],
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: cs.error),
              const SizedBox(height: 12),
              Text(e.toString(), style: TextStyle(color: cs.error)),
              const SizedBox(height: 12),
              TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
                onPressed: () =>
                    ref.read(purchaseOrdersProvider.notifier).refresh(),
              ),
            ],
          ),
        ),
        data: (orders) {
          final filtered = _filtered(orders);
          return Column(
            children: [
              _PurchaseOrderSearchBar(
                controller: _queryCtrl,
                selectedStatus: _selectedStatus,
                dateRange: _dateRange,
                totalCount: orders.length,
                visibleCount: filtered.length,
                onChanged: () => setState(() {}),
                onStatusChanged: (status) {
                  setState(() => _selectedStatus = status);
                  ref
                      .read(purchaseOrdersProvider.notifier)
                      .setStatusFilter(_toPurchaseOrderStatus(status));
                },
                onDateRangeChanged: (range) =>
                    setState(() => _dateRange = range),
                onReset: () {
                  setState(() {
                    _queryCtrl.clear();
                    _selectedStatus = _PurchaseOrderStatusFilter.all;
                    _dateRange = null;
                  });
                  ref
                      .read(purchaseOrdersProvider.notifier)
                      .setStatusFilter(null);
                },
              ),
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyState(
                        onNew: () => context.go(AppRoutes.purchaseOrderNew),
                      )
                    : _PurchaseOrderTable(
                        orders: filtered,
                        onOpen: (order) => context.go(
                          AppRoutes.purchaseOrderDetails.replaceFirst(
                            ':id',
                            order.id,
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PurchaseOrderSearchBar extends StatelessWidget {
  const _PurchaseOrderSearchBar({
    required this.controller,
    required this.selectedStatus,
    required this.dateRange,
    required this.totalCount,
    required this.visibleCount,
    required this.onChanged,
    required this.onStatusChanged,
    required this.onDateRangeChanged,
    required this.onReset,
  });

  final TextEditingController controller;
  final _PurchaseOrderStatusFilter selectedStatus;
  final DateTimeRange? dateRange;
  final int totalCount;
  final int visibleCount;
  final VoidCallback onChanged;
  final ValueChanged<_PurchaseOrderStatusFilter> onStatusChanged;
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
                    hintText: 'Search purchase order #, vendor, amount...',
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
              SegmentedButton<_PurchaseOrderStatusFilter>(
                segments: const [
                  ButtonSegment(
                    value: _PurchaseOrderStatusFilter.all,
                    label: Text('All'),
                    icon: Icon(Icons.all_inbox_outlined),
                  ),
                  ButtonSegment(
                    value: _PurchaseOrderStatusFilter.draft,
                    label: Text('Draft'),
                    icon: Icon(Icons.drafts_outlined),
                  ),
                  ButtonSegment(
                    value: _PurchaseOrderStatusFilter.open,
                    label: Text('Open'),
                    icon: Icon(Icons.pending_actions_outlined),
                  ),
                  ButtonSegment(
                    value: _PurchaseOrderStatusFilter.closed,
                    label: Text('Closed'),
                    icon: Icon(Icons.check_circle_outline),
                  ),
                  ButtonSegment(
                    value: _PurchaseOrderStatusFilter.cancelled,
                    label: Text('Cancelled'),
                    icon: Icon(Icons.block),
                  ),
                ],
                selected: {selectedStatus},
                onSelectionChanged: (next) => onStatusChanged(next.first),
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const Spacer(),
              Text(
                '$visibleCount of $totalCount purchase orders',
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

class _PurchaseOrderTable extends StatelessWidget {
  const _PurchaseOrderTable({required this.orders, required this.onOpen});

  final List<PurchaseOrderModel> orders;
  final ValueChanged<PurchaseOrderModel> onOpen;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _PurchaseTableHeader(),
        for (var i = 0; i < orders.length; i++)
          _PurchaseOrderRow(
            order: orders[i],
            shaded: i.isOdd,
            onOpen: () => onOpen(orders[i]),
          ),
      ],
    );
  }
}

class _PurchaseTableHeader extends StatelessWidget {
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
          _HeaderCell('VENDOR', flex: 3, style: style),
          _HeaderCell('STATUS', flex: 1, style: style),
          _HeaderCell('EXPECTED', flex: 1, style: style),
          _HeaderCell('TOTAL', flex: 1, style: style, right: true),
        ],
      ),
    );
  }
}

class _PurchaseOrderRow extends StatelessWidget {
  const _PurchaseOrderRow({
    required this.order,
    required this.shaded,
    required this.onOpen,
  });

  final PurchaseOrderModel order;
  final bool shaded;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = shaded ? const Color(0xFFF4F7F8) : cs.surface;
    return Material(
      color: bg,
      child: InkWell(
        hoverColor: const Color(0xFFDCEBF0),
        onTap: onOpen,
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
              _DataCell(_fmtDate(order.orderDate), flex: 1),
              _DataCell(
                order.orderNumber.isEmpty
                    ? 'Purchase Order'
                    : order.orderNumber,
                flex: 2,
                bold: true,
              ),
              _DataCell(order.vendorName, flex: 3),
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _StatusBadge(status: order.status),
                ),
              ),
              _DataCell(_fmtDate(order.expectedDate), flex: 1),
              _DataCell(
                _fmtMoney(order.totalAmount),
                flex: 1,
                right: true,
                bold: true,
              ),
            ],
          ),
        ),
      ),
    );
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
  });

  final String text;
  final int flex;
  final bool right;
  final bool bold;

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
            color: const Color(0xFF263D47),
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
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

// ─── Empty State ──────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onNew});
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.receipt_long_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
        const SizedBox(height: 16),
        const Text(
          'لا توجد أوامر شراء | No purchase orders',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text('ابدأ بإنشاء أمر شراء جديد'),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('أمر جديد | New Order'),
          onPressed: onNew,
        ),
      ],
    ),
  );
}

String _fmtDate(DateTime value) => DateFormat('dd/MM/yyyy').format(value);

String _fmtMoney(double value) => NumberFormat('#,##0.00').format(value);
