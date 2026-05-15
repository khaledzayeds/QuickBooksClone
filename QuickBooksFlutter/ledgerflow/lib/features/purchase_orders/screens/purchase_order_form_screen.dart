// purchase_order_form_screen.dart
// Premium QuickBooks-style Purchase Order form.
// Supports new PO and draft PO editing.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/transaction_line_table.dart';
import '../../../../core/widgets/transaction_sidebar.dart';
import '../../../../core/widgets/transaction_vendor_picker.dart';
import '../../vendors/data/models/vendor_model.dart';
import '../data/models/order_line_entry.dart';
import '../data/models/purchase_order_model.dart';
import '../providers/purchase_orders_provider.dart';
import '../../../../app/router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../transactions/widgets/transaction_workspace_shell.dart';

class PurchaseOrderFormScreen extends ConsumerStatefulWidget {
  const PurchaseOrderFormScreen({super.key, this.id});

  final String? id;

  @override
  ConsumerState<PurchaseOrderFormScreen> createState() =>
      _PurchaseOrderFormScreenState();
}

class _PurchaseOrderFormScreenState
    extends ConsumerState<PurchaseOrderFormScreen> {
  VendorModel? _vendor;
  PurchaseOrderModel? _editingOrder;
  DateTime _orderDate = DateTime.now();
  DateTime _expectedDate = DateTime.now().add(const Duration(days: 7));
  final List<TransactionLineEntry> _lines = [];
  bool _saving = false;
  bool _loadingExisting = false;

  bool get _isEdit => widget.id != null && widget.id!.isNotEmpty;
  bool get _readOnly => _editingOrder != null && !_editingOrder!.canEdit;
  bool get _canSaveDraft => !_readOnly && !_saving;
  bool get _canOpen => !_isEdit && !_readOnly && !_saving;
  bool get _canReceive => _editingOrder?.canReceive == true;

  @override
  void initState() {
    super.initState();
    _lines.add(TransactionLineEntry());
    if (_isEdit) {
      Future.microtask(_loadExistingOrder);
    }
  }

  @override
  void didUpdateWidget(covariant PurchaseOrderFormScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id == widget.id) return;
    if (_isEdit) {
      Future.microtask(_loadExistingOrder);
    } else {
      _clear();
    }
  }

  @override
  void dispose() {
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  double get _draftTotal => _lines.fold(0, (s, l) => s + l.amount);

  Future<void> _loadExistingOrder() async {
    final id = widget.id;
    if (id == null || id.isEmpty) return;

    setState(() => _loadingExisting = true);
    final result = await ref.read(purchaseOrdersRepoProvider).getById(id);
    if (!mounted || widget.id != id) return;
    setState(() => _loadingExisting = false);

    result.when(
      success: (order) {
        for (final line in _lines) {
          line.dispose();
        }
        final loadedLines = order.lines.map((line) {
          final entry = TransactionLineEntry(
            itemId: line.itemId,
            itemName: line.description,
            qty: line.quantity,
            rate: line.unitCost,
          );
          entry.descCtrl.text = line.description;
          entry.qtyCtrl.text = line.quantity.toString();
          entry.rateCtrl.text = line.unitCost.toString();
          return entry;
        }).toList();

        setState(() {
          _editingOrder = order;
          _vendor = VendorModel(
            id: order.vendorId,
            displayName: order.vendorName,
            isActive: true,
            balance: 0,
            creditBalance: 0,
          );
          _orderDate = order.orderDate;
          _expectedDate = order.expectedDate;
          _lines
            ..clear()
            ..addAll(
              loadedLines.isEmpty ? [TransactionLineEntry()] : loadedLines,
            );
        });
      },
      failure: (error) => _showErr(error.message),
    );
  }

  Future<void> _save(SaveMode mode) async {
    final l10n = AppLocalizations.of(context)!;
    if (_readOnly) {
      _showErr(
        'This purchase order is already ${_editingOrder!.status.label}. Use the available toolbar actions.',
      );
      return;
    }
    if (_vendor == null) {
      _showErr(l10n.selectVendor);
      return;
    }

    if (_expectedDate.isBefore(_orderDate)) {
      _showErr('${l10n.expectedDate} < ${l10n.poDate}');
      return;
    }

    final validLines = _lines
        .where((l) => l.itemId != null && l.qty > 0)
        .toList();
    if (validLines.isEmpty) {
      _showErr(l10n.selectItem);
      return;
    }

    final lines = validLines
        .map(
          (l) => CreatePurchaseLineDto(
            itemId: l.itemId!,
            quantity: l.qty,
            unitCost: l.rate,
            description: l.descCtrl.text.trim().isEmpty
                ? null
                : l.descCtrl.text.trim(),
          ),
        )
        .toList();

    setState(() => _saving = true);
    try {
      final repo = ref.read(purchaseOrdersRepoProvider);
      if (_isEdit) {
        final dto = UpdatePurchaseOrderDto(
          vendorId: _vendor!.id,
          orderDate: _orderDate,
          expectedDate: _expectedDate,
          lines: lines,
        );
        final result = await repo.update(widget.id!, dto);
        if (!mounted) return;
        result.when(
          success: (updated) {
            ref.read(purchaseOrdersProvider.notifier).refresh();
            ref.invalidate(purchaseOrderProvider(updated.id));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Draft purchase order updated.'),
                backgroundColor: Colors.green,
              ),
            );
            context.go(
              AppRoutes.purchaseOrderDetails.replaceFirst(':id', updated.id),
            );
          },
          failure: (e) => _showErr(e.message),
        );
        return;
      }

      final dto = CreatePurchaseOrderDto(
        vendorId: _vendor!.id,
        orderDate: _orderDate,
        expectedDate: _expectedDate,
        saveMode: mode,
        lines: lines,
      );

      final result = await repo.create(dto);
      result.when(
        success: (newOrder) {
          ref.read(purchaseOrdersProvider.notifier).refresh();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  mode == SaveMode.saveAsOpen
                      ? l10n.poSavedAsOpen
                      : l10n.poSavedAsDraft,
                ),
                backgroundColor: Colors.green.shade700,
              ),
            );
            context.pushReplacement(
              AppRoutes.purchaseOrderDetails.replaceFirst(':id', newOrder.id),
            );
          }
        },
        failure: (e) => _showErr(e.message),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showErr(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_friendlyErrorMessage(msg)),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _friendlyErrorMessage(String msg) {
    final normalized = msg.toLowerCase();
    if (normalized.contains('expected to affect 1 row') ||
        normalized.contains('optimistic concurrency')) {
      return 'This purchase order changed after it was loaded. Reopen it before saving.';
    }
    return msg;
  }

  Future<void> _pickDate(bool isExpected) async {
    final d = await showDatePicker(
      context: context,
      initialDate: isExpected ? _expectedDate : _orderDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (d == null) return;
    setState(() {
      if (isExpected) {
        _expectedDate = d;
      } else {
        _orderDate = d;
        if (_expectedDate.isBefore(_orderDate)) {
          _expectedDate = _orderDate.add(const Duration(days: 7));
        }
      }
    });
  }

  void _clear() {
    if (_isEdit) {
      _loadExistingOrder();
      return;
    }
    setState(() {
      _vendor = null;
      _editingOrder = null;
      _orderDate = DateTime.now();
      _expectedDate = DateTime.now().add(const Duration(days: 7));
      _loadingExisting = false;
      for (final l in _lines) {
        l.dispose();
      }
      _lines.clear();
      _lines.add(TransactionLineEntry());
    });
  }

  void _cancel() {
    context.go(AppRoutes.purchaseOrders);
  }

  void _openAdjacentOrder(int direction) {
    final currentId = widget.id;
    if (currentId == null || currentId.isEmpty) return;
    final orders = ref
        .read(purchaseOrdersProvider)
        .maybeWhen(
          data: (items) =>
              [...items]..sort((a, b) => b.orderDate.compareTo(a.orderDate)),
          orElse: () => const <PurchaseOrderModel>[],
        );
    final index = orders.indexWhere((order) => order.id == currentId);
    final targetIndex = index + direction;
    if (index < 0 || targetIndex < 0 || targetIndex >= orders.length) return;
    context.go(
      AppRoutes.purchaseOrderDetails.replaceFirst(
        ':id',
        orders[targetIndex].id,
      ),
    );
  }

  bool _hasAdjacentOrder(int direction) {
    final currentId = widget.id;
    if (currentId == null || currentId.isEmpty) return false;
    final orders = ref
        .watch(purchaseOrdersProvider)
        .maybeWhen(
          data: (items) =>
              [...items]..sort((a, b) => b.orderDate.compareTo(a.orderDate)),
          orElse: () => const <PurchaseOrderModel>[],
        );
    final index = orders.indexWhere((order) => order.id == currentId);
    final targetIndex = index + direction;
    return index >= 0 && targetIndex >= 0 && targetIndex < orders.length;
  }

  void _receiveInventory() {
    final order = _editingOrder;
    if (order == null || !order.canReceive) return;
    context.push('${AppRoutes.receiveInventoryNew}?poId=${order.id}');
  }

  String? get _statusBadgeText {
    final order = _editingOrder;
    if (order == null) return null;
    return order.status.label.toUpperCase();
  }

  String? get _statusMessage {
    final order = _editingOrder;
    if (order == null) return null;
    final total = NumberFormat('#,##0.00').format(order.totalAmount);
    if (order.isDraft) {
      return 'Draft purchase order. You can edit lines and save it as open.';
    }
    if (order.isOpen) {
      return 'Open purchase order. Total $total EGP. Receive inventory when goods arrive.';
    }
    if (order.isClosed) {
      return 'Closed purchase order. Financial fields are read-only.';
    }
    return 'Cancelled purchase order. Financial fields are read-only.';
  }

  Color get _statusColor {
    final status = _editingOrder?.status;
    return switch (status) {
      PurchaseOrderStatus.draft => const Color(0xFF607D8B),
      PurchaseOrderStatus.open => const Color(0xFF2E7D32),
      PurchaseOrderStatus.closed => const Color(0xFF1565C0),
      PurchaseOrderStatus.cancelled => const Color(0xFFC62828),
      null => const Color(0xFF546E7A),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingExisting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final l10n = AppLocalizations.of(context)!;
    final fmt = DateFormat('dd/MM/yyyy');

    return TransactionWorkspaceShell(
      workspaceName: 'Purchase order workspace',
      saving: _saving,
      posting: false,
      isEdit: _isEdit,
      readOnly: _readOnly,
      onFind: () => context.go(AppRoutes.purchaseOrders),
      onPrevious: _hasAdjacentOrder(-1) ? () => _openAdjacentOrder(-1) : null,
      onNext: _hasAdjacentOrder(1) ? () => _openAdjacentOrder(1) : null,
      onNew: () => context.go(AppRoutes.purchaseOrderNew),
      onSaveDraft: _canSaveDraft ? () => _save(SaveMode.draft) : null,
      onSave: _canOpen ? () => _save(SaveMode.saveAsOpen) : null,
      onReceive: _canReceive ? _receiveInventory : null,
      onClear: _clear,
      onClose: _cancel,
      showReceive: true,
      statusBadgeText: _statusBadgeText,
      statusMessage: _statusMessage,
      statusColor: _statusColor,
      formContent: _buildMainForm(l10n, fmt),
      contextPanel: _PoSidePanel(vendorId: _vendor?.id),
    );
  }

  Widget _buildMainForm(AppLocalizations l10n, DateFormat fmt) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 6,
                  child: _PoTopSearchBar(
                    label: 'VENDOR',
                    child: _readOnly
                        ? _ReadonlyBox(
                            text: _vendor?.displayName ?? 'Select vendor',
                          )
                        : VendorPickerField(
                            value: _vendor,
                            onChanged: (v) => setState(() => _vendor = v),
                            label: l10n.vendor,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: _PoTopSearchBar(
                    label: 'TEMPLATE',
                    child: const _ReadonlyBox(text: 'Standard Purchase Order'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Purchase Order',
                    style: TextStyle(
                      fontSize: 34,
                      color: Color(0xFF203A49),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Wrap(
                    spacing: 18,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      _DateField(
                        label: l10n.poDate.toUpperCase(),
                        value: _orderDate,
                        fmt: fmt,
                        enabled: !_readOnly,
                        onTap: () => _pickDate(false),
                      ),
                      _DateField(
                        label: l10n.expectedDate.toUpperCase(),
                        value: _expectedDate,
                        fmt: fmt,
                        enabled: !_readOnly,
                        onTap: () => _pickDate(true),
                      ),
                      _PoNumberField(
                        label: 'P.O. #',
                        value: _editingOrder?.orderNumber ?? 'AUTO',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF9EADB6)),
              ),
              child: Column(
                children: [
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    color: const Color(0xFFE8F0F4),
                    child: Row(
                      children: [
                        const Text(
                          'Products and Services',
                          style: TextStyle(
                            color: Color(0xFF203A49),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Tab moves across cells • Enter commits row',
                          style: TextStyle(
                            color: Color(0xFF607D8B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _readOnly
                              ? null
                              : () => setState(
                                  () => _lines.add(TransactionLineEntry()),
                                ),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Line'),
                        ),
                      ],
                    ),
                  ),
                  IgnorePointer(
                    ignoring: _readOnly,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: TransactionLineTable(
                        lines: _lines,
                        onChanged: () {
                          if (_readOnly) return;
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(l10n.memoInternal.toUpperCase()),
                      const SizedBox(height: 5),
                      TextField(
                        enabled: !_readOnly,
                        minLines: 1,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Optional',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                SizedBox(
                  width: 310,
                  child: _PoTotalsBox(
                    total: _editingOrder?.totalAmount ?? _draftTotal,
                    currency: l10n.egp,
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      color: Colors.blueGrey,
      letterSpacing: 0.5,
    ),
  );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.fmt,
    required this.onTap,
    this.enabled = true,
  });
  final String label;
  final DateTime value;
  final DateFormat fmt;
  final VoidCallback onTap;
  final bool enabled;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _FieldLabel(label),
      const SizedBox(height: 8),
      InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 160,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: enabled ? Colors.white : const Color(0xFFF4F6F7),
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  fmt.format(value),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}



class _PoTopSearchBar extends StatelessWidget {
  const _PoTopSearchBar({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      color: const Color(0xFF1F5163),
      padding: const EdgeInsets.only(left: 10, right: 6),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _ReadonlyBox extends StatelessWidget {
  const _ReadonlyBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF9EADB6)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF203A49),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PoNumberField extends StatelessWidget {
  const _PoNumberField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label),
          const SizedBox(height: 8),
          _ReadonlyBox(text: value),
        ],
      ),
    );
  }
}

class _PoTotalsBox extends StatelessWidget {
  const _PoTotalsBox({required this.total, required this.currency});

  final double total;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TotalRow(
          label: 'TOTAL',
          value: '${total.toStringAsFixed(2)} $currency',
        ),
        const SizedBox(height: 8),
        Container(
          height: 31,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          color: const Color(0xFFE3F0F4),
          child: _TotalRow(
            label: 'OPEN AMOUNT',
            value: '${total.toStringAsFixed(2)} $currency',
            strong: true,
          ),
        ),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: const Color(0xFF203A49),
              fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: const Color(0xFF203A49),
            fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PoSidePanel extends StatelessWidget {
  const _PoSidePanel({this.vendorId});

  final String? vendorId;

  @override
  Widget build(BuildContext context) {
    return TransactionSidebar(vendorId: vendorId);
  }
}
