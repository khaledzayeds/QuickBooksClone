// purchase_order_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/purchase_orders_provider.dart';
import '../data/models/purchase_order_model.dart';
import '../../../app/router.dart';

class PurchaseOrderListScreen extends ConsumerStatefulWidget {
  const PurchaseOrderListScreen({super.key});

  @override
  ConsumerState<PurchaseOrderListScreen> createState() =>
      _PurchaseOrderListScreenState();
}

class _PurchaseOrderListScreenState
    extends ConsumerState<PurchaseOrderListScreen> {
  PurchaseOrderStatus? _selectedStatus;
  final _queryCtrl = TextEditingController();

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
      final matchesStatus =
          _selectedStatus == null || order.status == _selectedStatus;
      return matchesText && matchesStatus;
    }).toList()..sort((a, b) => b.orderDate.compareTo(a.orderDate));
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(purchaseOrdersProvider);
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF0),
      body: Column(
        children: [
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F6F7),
              border: Border(bottom: BorderSide(color: Color(0xFFB7C3CB))),
            ),
            child: Row(
              children: [
                _ListTool(
                  icon: Icons.note_add_outlined,
                  label: l10n.newText,
                  onTap: () => context.go(AppRoutes.purchaseOrderNew),
                ),
                _ListTool(
                  icon: Icons.refresh,
                  label: 'Refresh',
                  onTap: () =>
                      ref.read(purchaseOrdersProvider.notifier).refresh(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _queryCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search by number or vendor',
                      isDense: true,
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<PurchaseOrderStatus?>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      isDense: true,
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: [
                      DropdownMenuItem(value: null, child: Text(l10n.all)),
                      DropdownMenuItem(
                        value: PurchaseOrderStatus.draft,
                        child: Text(l10n.statusDraft),
                      ),
                      DropdownMenuItem(
                        value: PurchaseOrderStatus.open,
                        child: Text(l10n.statusOpen),
                      ),
                      DropdownMenuItem(
                        value: PurchaseOrderStatus.closed,
                        child: Text(l10n.statusClosed),
                      ),
                      DropdownMenuItem(
                        value: PurchaseOrderStatus.cancelled,
                        child: Text(l10n.statusCancelled),
                      ),
                    ],
                    onChanged: (status) {
                      setState(() => _selectedStatus = status);
                      ref
                          .read(purchaseOrdersProvider.notifier)
                          .setStatusFilter(status);
                    },
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ordersAsync.when(
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
                return filtered.isEmpty
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
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ListTool extends StatelessWidget {
  const _ListTool({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 68,
          height: 62,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF1F5163)),
              const SizedBox(height: 5),
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1F5163),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
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
    final fmt = MaterialLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFB9C3CA)),
      ),
      child: Column(
        children: [
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: const Color(0xFFE8F0F4),
            child: const Row(
              children: [
                Expanded(flex: 2, child: _TableHeader('DATE')),
                Expanded(flex: 2, child: _TableHeader('TYPE')),
                Expanded(flex: 3, child: _TableHeader('NUM')),
                Expanded(flex: 4, child: _TableHeader('NAME')),
                Expanded(flex: 2, child: _TableHeader('STATUS')),
                Expanded(
                  flex: 2,
                  child: _TableHeader('AMOUNT', alignEnd: true),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final bg = index.isEven
                    ? Colors.white
                    : const Color(0xFFF4F7F9);
                return InkWell(
                  onTap: () => onOpen(order),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    color: bg,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(fmt.formatShortDate(order.orderDate)),
                        ),
                        const Expanded(flex: 2, child: Text('Purchase Order')),
                        Expanded(flex: 3, child: Text(order.orderNumber)),
                        Expanded(
                          flex: 4,
                          child: Text(
                            order.vendorName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: _StatusBadge(status: order.status),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            order.totalAmount.toStringAsFixed(2),
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
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
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader(this.text, {this.alignEnd = false});

  final String text;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: alignEnd ? TextAlign.end : TextAlign.start,
      style: const TextStyle(
        color: Color(0xFF607D8B),
        fontSize: 11,
        fontWeight: FontWeight.w800,
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
