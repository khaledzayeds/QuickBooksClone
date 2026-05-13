import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router.dart';
import '../../../../core/widgets/qb/qb_transaction_line_grid.dart';
import '../../../../core/widgets/qb/transaction_line_price_mode.dart';
import '../../../../core/widgets/transaction_vendor_picker.dart';
import '../../../../l10n/app_localizations.dart';
import '../../vendors/data/models/vendor_model.dart';
import '../data/models/order_line_entry.dart';
import '../data/models/purchase_order_model.dart';
import '../providers/purchase_orders_provider.dart';

class PurchaseOrderWorkspaceScreen extends ConsumerStatefulWidget {
  const PurchaseOrderWorkspaceScreen({super.key, this.id});

  final String? id;

  @override
  ConsumerState<PurchaseOrderWorkspaceScreen> createState() => _PurchaseOrderWorkspaceScreenState();
}

class _PurchaseOrderWorkspaceScreenState extends ConsumerState<PurchaseOrderWorkspaceScreen> {
  VendorModel? _vendor;
  PurchaseOrderModel? _editingOrder;
  DateTime _orderDate = DateTime.now();
  DateTime _expectedDate = DateTime.now().add(const Duration(days: 7));
  final List<TransactionLineEntry> _lines = [TransactionLineEntry()];
  bool _saving = false;
  bool _loadingExisting = false;

  bool get _isEdit => widget.id != null && widget.id!.isNotEmpty;
  bool get _readOnly => _editingOrder != null && !_editingOrder!.canEdit;
  bool get _canSaveDraft => !_readOnly && !_saving;
  bool get _canOpen => !_isEdit && !_readOnly && !_saving;
  bool get _canReceive => _editingOrder?.canReceive == true;
  double get _draftTotal => _lines.fold(0, (sum, line) => sum + line.amount);
  double get _total => _editingOrder?.totalAmount ?? _draftTotal;

  @override
  void initState() {
    super.initState();
    if (_isEdit) Future.microtask(_loadExistingOrder);
  }

  @override
  void dispose() {
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

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
            ..addAll(loadedLines.isEmpty ? [TransactionLineEntry()] : loadedLines);
        });
      },
      failure: (error) => _showError(error.message),
    );
  }

  Future<void> _save(SaveMode mode) async {
    final l10n = AppLocalizations.of(context)!;
    if (_readOnly) {
      _showError('This purchase order is ${_editingOrder!.status.label}. Financial fields are read-only.');
      return;
    }
    if (_vendor == null) {
      _showError(l10n.selectVendor);
      return;
    }
    if (_expectedDate.isBefore(_orderDate)) {
      _showError('${l10n.expectedDate} < ${l10n.poDate}');
      return;
    }

    final validLines = _lines.where((line) => line.itemId != null && line.qty > 0).toList();
    if (validLines.isEmpty) {
      _showError(l10n.selectItem);
      return;
    }

    final lines = validLines.map((line) {
      return CreatePurchaseLineDto(
        itemId: line.itemId!,
        quantity: line.qty,
        unitCost: line.rate,
        description: line.descCtrl.text.trim().isEmpty ? null : line.descCtrl.text.trim(),
      );
    }).toList();

    setState(() => _saving = true);
    try {
      final repo = ref.read(purchaseOrdersRepoProvider);
      if (_isEdit) {
        final result = await repo.update(
          widget.id!,
          UpdatePurchaseOrderDto(
            vendorId: _vendor!.id,
            orderDate: _orderDate,
            expectedDate: _expectedDate,
            lines: lines,
          ),
        );
        if (!mounted) return;
        result.when(
          success: (updated) {
            ref.read(purchaseOrdersProvider.notifier).refresh();
            ref.invalidate(purchaseOrderProvider(updated.id));
            context.go(AppRoutes.purchaseOrderDetails.replaceFirst(':id', updated.id));
          },
          failure: (error) => _showError(_friendlyErrorMessage(error.message)),
        );
        return;
      }

      final result = await repo.create(
        CreatePurchaseOrderDto(
          vendorId: _vendor!.id,
          orderDate: _orderDate,
          expectedDate: _expectedDate,
          saveMode: mode,
          lines: lines,
        ),
      );
      if (!mounted) return;
      result.when(
        success: (order) {
          ref.read(purchaseOrdersProvider.notifier).refresh();
          context.pushReplacement(AppRoutes.purchaseOrderDetails.replaceFirst(':id', order.id));
        },
        failure: (error) => _showError(_friendlyErrorMessage(error.message)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate({required bool expected}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: expected ? _expectedDate : _orderDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (expected) {
        _expectedDate = picked;
      } else {
        _orderDate = picked;
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
    for (final line in _lines) {
      line.dispose();
    }
    setState(() {
      _vendor = null;
      _editingOrder = null;
      _orderDate = DateTime.now();
      _expectedDate = DateTime.now().add(const Duration(days: 7));
      _lines
        ..clear()
        ..add(TransactionLineEntry());
    });
  }

  void _receiveInventory() {
    final order = _editingOrder;
    if (order == null || !order.canReceive) return;
    context.push('${AppRoutes.receiveInventoryNew}?poId=${order.id}');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_friendlyErrorMessage(message)),
        backgroundColor: Colors.red.shade800,
      ),
    );
  }

  String _friendlyErrorMessage(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('expected to affect 1 row') || normalized.contains('optimistic concurrency')) {
      return 'This purchase order changed after it was loaded. Reopen it before saving.';
    }
    return message;
  }

  String? get _statusBadgeText => _editingOrder?.status.label.toUpperCase();

  String? get _statusMessage {
    final order = _editingOrder;
    if (order == null) return null;
    final total = NumberFormat('#,##0.00').format(order.totalAmount);
    if (order.isDraft) return 'Draft purchase order. You can edit lines and save it as open.';
    if (order.isOpen) return 'Open purchase order. Total $total EGP. Receive inventory when goods arrive.';
    if (order.isClosed) return 'Closed purchase order. Financial fields are read-only.';
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
    final l10n = AppLocalizations.of(context)!;
    final fmt = DateFormat('dd/MM/yyyy');

    if (_loadingExisting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF0),
      body: SafeArea(
        child: Column(
          children: [
            _PoCommandBar(
              saving: _saving,
              onFind: () => context.go(AppRoutes.purchaseOrders),
              onNew: () => context.go(AppRoutes.purchaseOrderNew),
              onSaveDraft: _canSaveDraft ? () => _save(SaveMode.draft) : null,
              onSaveOpen: _canOpen ? () => _save(SaveMode.saveAsOpen) : null,
              onReceive: _canReceive ? _receiveInventory : null,
              onClear: _clear,
              onClose: () => context.go(AppRoutes.purchaseOrders),
            ),
            if (_statusMessage != null && _statusBadgeText != null)
              _PoStatusStrip(
                badgeText: _statusBadgeText!,
                message: _statusMessage!,
                color: _statusColor,
              ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(10, 8, 0, 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFB9C3CA)),
                      ),
                      child: Column(
                        children: [
                          _PoHeader(
                            l10n: l10n,
                            fmt: fmt,
                            vendor: _vendor,
                            readOnly: _readOnly,
                            orderDate: _orderDate,
                            expectedDate: _expectedDate,
                            poNumber: _editingOrder?.orderNumber ?? 'AUTO',
                            onVendorChanged: (vendor) => setState(() => _vendor = vendor),
                            onOrderDateTap: () => _pickDate(expected: false),
                            onExpectedDateTap: () => _pickDate(expected: true),
                          ),
                          _LinesHeader(
                            readOnly: _readOnly,
                            onAddLine: () => setState(() => _lines.add(TransactionLineEntry())),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                              child: QbTransactionLineGrid(
                                lines: _lines,
                                priceMode: TransactionLinePriceMode.purchase,
                                fillWidth: true,
                                compact: true,
                                showAddLineFooter: false,
                                readOnly: _readOnly,
                                onChanged: () {
                                  if (!_readOnly) setState(() {});
                                },
                              ),
                            ),
                          ),
                          _PoFooter(
                            l10n: l10n,
                            total: _total,
                            saving: _saving,
                            readOnly: _readOnly,
                            onSaveDraft: _canSaveDraft ? () => _save(SaveMode.draft) : null,
                            onSaveOpen: _canOpen ? () => _save(SaveMode.saveAsOpen) : null,
                            onClear: _clear,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _PoSidePanel(order: _editingOrder, vendor: _vendor, total: _total),
                ],
              ),
            ),
            const _PoShortcutStrip(),
          ],
        ),
      ),
    );
  }
}

class _PoHeader extends StatelessWidget {
  const _PoHeader({
    required this.l10n,
    required this.fmt,
    required this.vendor,
    required this.readOnly,
    required this.orderDate,
    required this.expectedDate,
    required this.poNumber,
    required this.onVendorChanged,
    required this.onOrderDateTap,
    required this.onExpectedDateTap,
  });

  final AppLocalizations l10n;
  final DateFormat fmt;
  final VendorModel? vendor;
  final bool readOnly;
  final DateTime orderDate;
  final DateTime expectedDate;
  final String poNumber;
  final ValueChanged<VendorModel?> onVendorChanged;
  final VoidCallback onOrderDateTap;
  final VoidCallback onExpectedDateTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF264D5B),
              border: Border(bottom: BorderSide(color: Color(0xFF183642))),
            ),
            child: Row(
              children: [
                const _StripLabel('VENDOR'),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: readOnly
                      ? _StaticBox(text: vendor?.displayName ?? 'Select vendor')
                      : VendorPickerField(value: vendor, onChanged: onVendorChanged, label: l10n.vendor),
                ),
                const SizedBox(width: 16),
                const _StripLabel('TEMPLATE'),
                const SizedBox(width: 8),
                const Expanded(flex: 3, child: _StaticBox(text: 'Standard Purchase Order')),
              ],
            ),
          ),
          SizedBox(
            height: 146,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 240,
                    child: Text(
                      'Purchase Order',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w300,
                        color: const Color(0xFF243E4A),
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: Column(
                      children: [
                        _HorizontalField(label: 'DATE', child: _DateBox(text: fmt.format(orderDate), enabled: !readOnly, onTap: onOrderDateTap)),
                        const SizedBox(height: 8),
                        _HorizontalField(label: 'P.O. #', child: _StaticBox(text: poNumber)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('VENDOR / SHIP FROM'),
                        const SizedBox(height: 4),
                        Container(
                          height: 96,
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFB7C3CB))),
                          child: Text(
                            vendor?.displayName ?? 'Select a vendor',
                            style: theme.textTheme.bodySmall?.copyWith(color: vendor == null ? const Color(0xFF7B8B93) : const Color(0xFF253C47), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 3,
                    child: _StackedField(
                      label: 'EXPECTED DATE',
                      child: _DateBox(text: fmt.format(expectedDate), enabled: !readOnly, onTap: onExpectedDateTap),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinesHeader extends StatelessWidget {
  const _LinesHeader({required this.readOnly, required this.onAddLine});
  final bool readOnly;
  final VoidCallback onAddLine;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFE9EFF2),
        border: Border(top: BorderSide(color: Color(0xFFB7C3CB)), bottom: BorderSide(color: Color(0xFFB7C3CB))),
      ),
      child: Row(
        children: [
          Text('Products and Services', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: const Color(0xFF233F4C), fontWeight: FontWeight.w900)),
          const SizedBox(width: 10),
          Text('Tab moves across cells • Enter commits row', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: const Color(0xFF596B74), fontWeight: FontWeight.w600)),
          const Spacer(),
          TextButton.icon(
            onPressed: readOnly ? null : onAddLine,
            icon: const Icon(Icons.add, size: 15),
            label: const Text('Add Line'),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
          ),
        ],
      ),
    );
  }
}

class _PoFooter extends StatelessWidget {
  const _PoFooter({required this.l10n, required this.total, required this.saving, required this.readOnly, this.onSaveDraft, this.onSaveOpen, required this.onClear});
  final AppLocalizations l10n;
  final double total;
  final bool saving;
  final bool readOnly;
  final VoidCallback? onSaveDraft;
  final VoidCallback? onSaveOpen;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: const BoxDecoration(color: Color(0xFFF6F8F9), border: Border(top: BorderSide(color: Color(0xFFB7C3CB)))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('VENDOR MESSAGE', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: const Color(0xFF53646D), fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Container(height: 30, alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFB7C3CB))), child: Text('Please supply the following items.', style: Theme.of(context).textTheme.bodySmall)),
              const SizedBox(height: 8),
              Text('MEMO', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: const Color(0xFF53646D), fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Container(height: 34, alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFB7C3CB))), child: Text('Optional', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF7B8B93)))),
            ]),
          ),
          const SizedBox(width: 18),
          SizedBox(
            width: 310,
            child: Column(children: [
              _TotalRow(label: 'TOTAL', value: total, currency: l10n.egp),
              Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFE7F1F4), border: Border.all(color: const Color(0xFF9DB2BC))), child: _TotalRow(label: 'OPEN AMOUNT', value: total, currency: l10n.egp, strong: true, noPadding: true)),
              const Spacer(),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                OutlinedButton(onPressed: saving || readOnly ? null : onSaveDraft, style: _smallButton(), child: Text(saving ? 'Saving...' : 'Save Draft')),
                const SizedBox(width: 6),
                OutlinedButton(onPressed: saving || readOnly ? null : onSaveOpen, style: _smallButton(), child: const Text('Save & Open')),
                const SizedBox(width: 6),
                OutlinedButton(onPressed: saving ? null : onClear, style: _smallButton(), child: const Text('Clear')),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  ButtonStyle _smallButton() => OutlinedButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)), side: const BorderSide(color: Color(0xFF8FA1AB)));
}

class _PoCommandBar extends StatelessWidget {
  const _PoCommandBar({required this.saving, required this.onFind, required this.onNew, required this.onClear, required this.onClose, this.onSaveDraft, this.onSaveOpen, this.onReceive});
  final bool saving;
  final VoidCallback onFind;
  final VoidCallback onNew;
  final VoidCallback? onSaveDraft;
  final VoidCallback? onSaveOpen;
  final VoidCallback? onReceive;
  final VoidCallback onClear;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      decoration: const BoxDecoration(color: Color(0xFFF3F6F7), border: Border(bottom: BorderSide(color: Color(0xFFB7C3CB)))),
      child: Row(children: [
        const SizedBox(width: 8),
        _Tool(icon: Icons.search, label: 'Find', onTap: saving ? null : onFind),
        _Tool(icon: Icons.note_add_outlined, label: 'New', onTap: saving ? null : onNew),
        _SaveTool(saving: saving, onSaveDraft: onSaveDraft, onSaveOpen: onSaveOpen),
        _Tool(icon: Icons.drafts_outlined, label: 'Draft', onTap: saving ? null : onSaveDraft),
        _Tool(icon: Icons.delete_outline, label: 'Clear', onTap: saving ? null : onClear),
        const _Separator(),
        const _Tool(icon: Icons.print_outlined, label: 'Print'),
        const _Tool(icon: Icons.mail_outline, label: 'Email'),
        _Tool(icon: Icons.inventory_2_outlined, label: 'Receive', onTap: saving ? null : onReceive),
        const Spacer(),
        _Tool(icon: Icons.close, label: 'Close', onTap: saving ? null : onClose),
        const SizedBox(width: 8),
      ]),
    );
  }
}

class _SaveTool extends StatelessWidget {
  const _SaveTool({required this.saving, this.onSaveDraft, this.onSaveOpen});
  final bool saving;
  final VoidCallback? onSaveDraft;
  final VoidCallback? onSaveOpen;

  @override
  Widget build(BuildContext context) {
    final enabled = !saving && (onSaveDraft != null || onSaveOpen != null);
    return PopupMenuButton<String>(
      enabled: enabled,
      tooltip: 'Save options',
      onSelected: (value) {
        if (value == 'draft') onSaveDraft?.call();
        if (value == 'open') onSaveOpen?.call();
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 'draft', enabled: onSaveDraft != null, child: const Text('Save Draft')),
        PopupMenuItem(value: 'open', enabled: onSaveOpen != null, child: const Text('Save & Open')),
      ],
      child: _ToolVisual(icon: saving ? Icons.hourglass_top : Icons.save_outlined, label: saving ? 'Saving' : 'Save', enabled: enabled, showDropDown: true),
    );
  }
}

class _PoSidePanel extends StatelessWidget {
  const _PoSidePanel({required this.order, required this.vendor, required this.total});
  final PurchaseOrderModel? order;
  final VendorModel? vendor;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 258,
      margin: const EdgeInsets.fromLTRB(8, 8, 10, 8),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFB9C3CA))),
      child: vendor == null
          ? const _EmptySidePanel()
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(padding: const EdgeInsets.all(10), color: const Color(0xFF264D5B), child: Text(vendor!.displayName, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900))),
              if (order != null) _SideWarning(text: order!.status.label.toUpperCase()),
              const _SideTabBar(),
              _SideSection(title: 'Vendor Summary', children: [
                _InfoRow(label: 'Status', value: order?.status.label ?? 'New'),
                _InfoRow(label: 'PO Total', value: '${total.toStringAsFixed(2)} EGP'),
                _InfoRow(label: 'Can Receive', value: order?.canReceive == true ? 'Yes' : 'No'),
              ]),
              const Spacer(),
              _SideSection(title: 'Notes', children: const [_MutedText('No notes added.')]),
            ]),
    );
  }
}

class _PoShortcutStrip extends StatelessWidget {
  const _PoShortcutStrip();
  @override
  Widget build(BuildContext context) => Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.centerLeft,
        decoration: const BoxDecoration(color: Color(0xFFD4DDE3), border: Border(top: BorderSide(color: Color(0xFFAFBBC4)))),
        child: Text('Purchase order workspace  •  Save Draft  •  Save & Open  •  Receive Inventory  •  Esc Close', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: const Color(0xFF33434C), fontWeight: FontWeight.w700)),
      );
}

class _PoStatusStrip extends StatelessWidget {
  const _PoStatusStrip({required this.badgeText, required this.message, required this.color});
  final String badgeText;
  final String message;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: color.withOpacity(0.10), border: Border(bottom: BorderSide(color: color.withOpacity(0.35)))),
        child: Row(children: [
          Container(height: 20, padding: const EdgeInsets.symmetric(horizontal: 10), alignment: Alignment.center, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)), child: Text(badgeText, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900))),
          const SizedBox(width: 10),
          Expanded(child: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w800))),
        ]),
      );
}

class _StripLabel extends StatelessWidget { const _StripLabel(this.text); final String text; @override Widget build(BuildContext context) => Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 0.4)); }
class _FieldLabel extends StatelessWidget { const _FieldLabel(this.text); final String text; @override Widget build(BuildContext context) => Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: const Color(0xFF53656E), fontWeight: FontWeight.w900)); }
class _StaticBox extends StatelessWidget { const _StaticBox({required this.text}); final String text; @override Widget build(BuildContext context) => Container(height: 30, alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFB7C3CB))), child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall)); }
class _DateBox extends StatelessWidget { const _DateBox({required this.text, required this.enabled, required this.onTap}); final String text; final bool enabled; final VoidCallback onTap; @override Widget build(BuildContext context) => InkWell(onTap: enabled ? onTap : null, child: Container(height: 34, alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFB7C3CB))), child: Row(children: [Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)), const Icon(Icons.calendar_today_outlined, size: 15)]))); }
class _HorizontalField extends StatelessWidget { const _HorizontalField({required this.label, required this.child}); final String label; final Widget child; @override Widget build(BuildContext context) => Row(children: [SizedBox(width: 82, child: _FieldLabel(label)), Expanded(child: child)]); }
class _StackedField extends StatelessWidget { const _StackedField({required this.label, required this.child}); final String label; final Widget child; @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_FieldLabel(label), const SizedBox(height: 4), child]); }
class _TotalRow extends StatelessWidget { const _TotalRow({required this.label, required this.value, required this.currency, this.strong = false, this.noPadding = false}); final String label; final double value; final String currency; final bool strong; final bool noPadding; @override Widget build(BuildContext context) => Padding(padding: EdgeInsets.symmetric(vertical: noPadding ? 0 : 3), child: Row(children: [Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: strong ? FontWeight.w900 : FontWeight.w700))), Text('${value.toStringAsFixed(2)} $currency', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: strong ? FontWeight.w900 : FontWeight.w700))])); }
class _Tool extends StatelessWidget { const _Tool({required this.icon, required this.label, this.onTap}); final IconData icon; final String label; final VoidCallback? onTap; @override Widget build(BuildContext context) => InkWell(onTap: onTap, child: _ToolVisual(icon: icon, label: label, enabled: onTap != null)); }
class _ToolVisual extends StatelessWidget { const _ToolVisual({required this.icon, required this.label, required this.enabled, this.showDropDown = false}); final IconData icon; final String label; final bool enabled; final bool showDropDown; @override Widget build(BuildContext context) { final color = enabled ? const Color(0xFF234C5D) : const Color(0xFF7D8B93); return SizedBox(width: 64, height: 74, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 22, color: color), const SizedBox(height: 5), Row(mainAxisAlignment: MainAxisAlignment.center, children: [Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: enabled ? FontWeight.w900 : FontWeight.w700))), if (showDropDown) Icon(Icons.arrow_drop_down, size: 14, color: color)]),])); } }
class _Separator extends StatelessWidget { const _Separator(); @override Widget build(BuildContext context) => Container(width: 1, height: 52, margin: const EdgeInsets.symmetric(horizontal: 6), color: const Color(0xFFC7D0D6)); }
class _SideWarning extends StatelessWidget { const _SideWarning({required this.text}); final String text; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(8), color: const Color(0xFFFFE7C4), child: Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: const Color(0xFF714600), fontWeight: FontWeight.w900))); }
class _SideTabBar extends StatelessWidget { const _SideTabBar(); @override Widget build(BuildContext context) => Container(height: 34, alignment: Alignment.center, color: const Color(0xFFE1E9ED), child: Text('Vendor     Transaction', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900, color: const Color(0xFF2D4854)))); }
class _SideSection extends StatelessWidget { const _SideSection({required this.title, required this.children}); final String title; final List<Widget> children; @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.fromLTRB(8, 8, 8, 0), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFB8C6CE))), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Container(height: 30, padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerLeft, color: const Color(0xFFE7EEF1), child: Text(title, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900, color: const Color(0xFF2D4854)))), Padding(padding: const EdgeInsets.all(8), child: Column(children: children))])); }
class _InfoRow extends StatelessWidget { const _InfoRow({required this.label, required this.value}); final String label; final String value; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall)), Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800))])); }
class _MutedText extends StatelessWidget { const _MutedText(this.text); final String text; @override Widget build(BuildContext context) => Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF667A84), fontWeight: FontWeight.w600)); }
class _EmptySidePanel extends StatelessWidget { const _EmptySidePanel(); @override Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.storefront_outlined, size: 38, color: Color(0xFF8CA0AA)), const SizedBox(height: 12), Text('Select a vendor', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: const Color(0xFF2D4854), fontWeight: FontWeight.w900)), const SizedBox(height: 6), Text('Choose a vendor to see open purchase orders and receiving status.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF667A84)))])); }
