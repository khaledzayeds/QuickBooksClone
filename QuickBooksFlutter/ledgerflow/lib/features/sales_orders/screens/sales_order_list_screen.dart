// sales_order_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../app/router.dart';
import '../data/models/sales_order_model.dart';
import '../providers/sales_orders_provider.dart';

class SalesOrderListScreen extends ConsumerStatefulWidget {
  const SalesOrderListScreen({super.key});

  @override
  ConsumerState<SalesOrderListScreen> createState() =>
      _SalesOrderListScreenState();
}

class _SalesOrderListScreenState extends ConsumerState<SalesOrderListScreen> {
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
    final ordersAsync = ref.watch(salesOrdersProvider);
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
                    onTap: () => context.push(AppRoutes.salesOrderNew),
                  ),
                  _Tool(
                    icon: Icons.refresh,
                    label: 'Refresh',
                    onTap: () =>
                        ref.read(salesOrdersProvider.notifier).refresh(),
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
                      'Sales Orders',
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
                        hintText: 'Search order #, customer, amount...',
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
                    width: 170,
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
                        DropdownMenuItem(
                          value: 'closed',
                          child: Text('Closed'),
                        ),
                        DropdownMenuItem(
                          value: 'cancelled',
                          child: Text('Cancelled'),
                        ),
                        DropdownMenuItem(value: 'draft', child: Text('Draft')),
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
                                _HeaderCell('TYPE', flex: 2),
                                _HeaderCell('NUM', flex: 2),
                                _HeaderCell('NAME', flex: 4),
                                _HeaderCell('EXPECTED', flex: 3),
                                _HeaderCell('AMOUNT', flex: 2, right: true),
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
                                    AppRoutes.salesOrderDetails.replaceFirst(
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
                                        _Cell(_date(order.orderDate), flex: 2),
                                        _Cell(_statusText(order), flex: 2),
                                        _Cell(
                                          order.orderNumber.isEmpty
                                              ? 'Sales Order'
                                              : order.orderNumber,
                                          flex: 2,
                                        ),
                                        _Cell(
                                          order.customerName ?? '',
                                          flex: 4,
                                        ),
                                        _Cell(
                                          _date(order.expectedDate),
                                          flex: 3,
                                        ),
                                        _Cell(
                                          order.totalAmount.toStringAsFixed(2),
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
                'Sales orders search  •  Enter opens order workspace  •  Esc Close',
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

  List<SalesOrderModel> _filter(List<SalesOrderModel> orders) {
    final query = _searchCtrl.text.trim().toLowerCase();
    return orders.where((order) {
      final matchesStatus = switch (_status) {
        'open' => order.isOpen,
        'closed' => order.isClosed,
        'cancelled' => order.isCancelled,
        'draft' => !order.isOpen && !order.isClosed && !order.isCancelled,
        _ => true,
      };
      if (!matchesStatus) return false;
      
      final range = _dateRange;
      if (range != null) {
        final date = DateUtils.dateOnly(order.orderDate);
        if (date.isBefore(DateUtils.dateOnly(range.start)) ||
            date.isAfter(DateUtils.dateOnly(range.end))) {
          return false;
        }
      }

      if (query.isEmpty) return true;
      return order.orderNumber.toLowerCase().contains(query) ||
          (order.customerName ?? '').toLowerCase().contains(query) ||
          order.totalAmount.toStringAsFixed(2).contains(query);
    }).toList()..sort((a, b) => b.orderDate.compareTo(a.orderDate));
  }

  static String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  static String _statusText(SalesOrderModel order) {
    if (order.isCancelled) return 'Cancelled';
    if (order.isClosed) return 'Closed';
    if (order.isOpen) return 'Open';
    return 'Draft';
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
  });
  final String text;
  final int flex;
  final bool right;
  final bool strong;

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
          color: const Color(0xFF273F4B),
        ),
      ),
    ),
  );
}
