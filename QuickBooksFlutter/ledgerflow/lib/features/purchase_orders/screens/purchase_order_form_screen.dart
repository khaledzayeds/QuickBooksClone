// purchase_order_form_screen.dart
// Premium QuickBooks-style Purchase Order form.
// Aligned with backend CreatePurchaseOrderRequest contract.
// Fully localized using AppLocalizations.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/transaction_line_table.dart';
import '../../../../core/widgets/transaction_vendor_picker.dart';
import '../../vendors/data/models/vendor_model.dart';
import '../data/models/purchase_order_model.dart';
import '../providers/purchase_orders_provider.dart';
import '../../../../app/router.dart';
import '../../../../l10n/app_localizations.dart';

class PurchaseOrderFormScreen extends ConsumerStatefulWidget {
  const PurchaseOrderFormScreen({super.key});

  @override
  ConsumerState<PurchaseOrderFormScreen> createState() =>
      _PurchaseOrderFormScreenState();
}

class _PurchaseOrderFormScreenState
    extends ConsumerState<PurchaseOrderFormScreen> {

  // ── State (Mixed Riverpod + Local State) ───────────────────────────
  VendorModel? _vendor;
  DateTime     _orderDate    = DateTime.now();
  DateTime     _expectedDate = DateTime.now().add(const Duration(days: 7));
  final List<TransactionLineEntry> _lines = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _lines.add(TransactionLineEntry());
  }

  @override
  void dispose() {
    for (final l in _lines) l.dispose();
    super.dispose();
  }

  double get _total => _lines.fold(0, (s, l) => s + l.amount);

  Future<void> _save(SaveMode mode) async {
    final l10n = AppLocalizations.of(context)!;
    if (_vendor == null) { 
      _showErr(l10n.selectVendor); 
      return; 
    }
    
    final validLines = _lines.where((l) => l.itemId != null && l.qty > 0).toList();
    if (validLines.isEmpty) { 
      _showErr(l10n.selectItem); 
      return; 
    }

    setState(() => _saving = true);
    try {
      final dto = CreatePurchaseOrderDto(
        vendorId:     _vendor!.id,
        orderDate:    _orderDate,
        expectedDate: _expectedDate,
        saveMode:     mode,
        lines: validLines.map((l) => CreatePurchaseLineDto(
          itemId:      l.itemId!,
          quantity:    l.qty,
          unitCost:    l.rate,
          description: l.descCtrl.text.trim().isEmpty ? null : l.descCtrl.text.trim(),
        )).toList(),
      );
      
      final repo   = ref.read(purchaseOrdersRepoProvider);
      final result = await repo.create(dto);
      
      result.when(
        success: (newOrder) {
          ref.read(purchaseOrdersProvider.notifier).refresh();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(mode == SaveMode.saveAsOpen
                  ? l10n.poSavedAsOpen
                  : l10n.poSavedAsDraft),
              backgroundColor: Colors.green.shade700,
            ));
            context.pushReplacement(
                AppRoutes.purchaseOrderDetails.replaceFirst(':id', newOrder.id));
          }
        },
        failure: (e) => _showErr(e.message),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showErr(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade800,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _pickDate(bool isExpected) async {
    final d = await showDatePicker(
      context: context,
      initialDate: isExpected ? _expectedDate : _orderDate,
      firstDate: DateTime(2024),
      lastDate:  DateTime(2030),
    );
    if (d == null) return;
    setState(() {
      if (isExpected) _expectedDate = d; else _orderDate = d;
    });
  }

  void _clear() {
    setState(() {
      _vendor = null;
      _orderDate = DateTime.now();
      _expectedDate = DateTime.now().add(const Duration(days: 7));
      for (final l in _lines) l.dispose();
      _lines.clear();
      _lines.add(TransactionLineEntry()); 
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final l10n   = AppLocalizations.of(context)!;
    final isWide = MediaQuery.sizeOf(context).width > 1100;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(l10n.newPurchaseOrder, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          _ActionButton(label: l10n.clear, icon: Icons.refresh_outlined, onPressed: _clear, isSecondary: true),
          const SizedBox(width: 8),
          _ActionButton(label: l10n.saveDraft, icon: Icons.save_outlined, onPressed: _saving ? null : () => _save(SaveMode.draft), isSecondary: true, isLoading: _saving),
          const SizedBox(width: 8),
          _ActionButton(label: l10n.saveAndOpen, icon: Icons.check_circle_outline, onPressed: _saving ? null : () => _save(SaveMode.saveAsOpen), isLoading: _saving),
          const SizedBox(width: 16),
        ],
      ),

      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildMainForm(theme, l10n, DateFormat('dd/MM/yyyy'))),
          if (isWide && _vendor != null) _VendorSidebar(vendor: _vendor!),
        ],
      ),
    );
  }

  Widget _buildMainForm(ThemeData theme, AppLocalizations l10n, DateFormat fmt) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.purchaseOrders.toUpperCase(), style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.blue.shade900)),
                    if (_vendor != null) _InfoBadge(label: l10n.vendor.toUpperCase(), value: _vendor!.displayName),
                  ],
                ),
                const SizedBox(height: 32),
                Wrap(
                  spacing: 24,
                  runSpacing: 20,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    SizedBox(width: 350, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _FieldLabel(l10n.vendor.toUpperCase()),
                      const SizedBox(height: 8),
                      VendorPickerField(value: _vendor, onChanged: (v) => setState(() => _vendor = v), label: l10n.vendor),
                    ])),
                    _DateField(label: l10n.poDate.toUpperCase(), value: _orderDate, fmt: fmt, onTap: () => _pickDate(false)),
                    _DateField(label: l10n.expectedDate.toUpperCase(), value: _expectedDate, fmt: fmt, onTap: () => _pickDate(true)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: TransactionLineTable(lines: _lines, onChanged: () => setState(() {}))),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _FieldLabel(l10n.memoInternal.toUpperCase()),
                const SizedBox(height: 8),
                TextField(maxLines: 3, decoration: InputDecoration(hintText: '${l10n.memoInternal}...', filled: true, fillColor: const Color(0xFFFAFAFA), border: const OutlineInputBorder())),
              ]))),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.blue.shade900, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(l10n.totalAmount.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text('${_total.toStringAsFixed(2)} ${l10n.egp}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
              ]))),
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
  @override Widget build(BuildContext context) => Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.blueGrey, letterSpacing: 0.5));
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.fmt, required this.onTap});
  final String label; final DateTime value; final DateFormat fmt; final VoidCallback onTap;
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _FieldLabel(label), const SizedBox(height: 8),
    InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: Container(width: 160, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)), child: Row(children: [Expanded(child: Text(fmt.format(value), style: const TextStyle(fontWeight: FontWeight.w600))), const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey)]))),
  ]);
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.icon, this.onPressed, this.isSecondary = false, this.isLoading = false});
  final String label; final IconData icon; final VoidCallback? onPressed; final bool isSecondary; final bool isLoading;
  @override Widget build(BuildContext context) {
    if (isSecondary) return OutlinedButton.icon(onPressed: onPressed, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), side: BorderSide(color: Colors.blue.shade800), foregroundColor: Colors.blue.shade800), icon: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(icon, size: 18), label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)));
    return FilledButton.icon(onPressed: onPressed, style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), backgroundColor: Colors.blue.shade800), icon: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(icon, size: 18), label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)));
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.label, required this.value});
  final String label; final String value;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)), child: Row(children: [Text('$label: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.blue.shade900)), Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.blue.shade800))]));
}

class _VendorSidebar extends StatelessWidget {
  const _VendorSidebar({required this.vendor});
  final VendorModel vendor;
  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n  = AppLocalizations.of(context)!;

    return Container(width: 280, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, border: Border(left: BorderSide(color: Colors.grey.shade300))), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      CircleAvatar(backgroundColor: Colors.blue.shade900, radius: 32, child: Text(vendor.initials, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900))),
      const SizedBox(height: 16), Text(vendor.displayName, textAlign: TextAlign.center, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
      const SizedBox(height: 8), Text(vendor.companyName ?? '', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
      const SizedBox(height: 32), const Divider(), const SizedBox(height: 16),
      _SidebarItem(label: l10n.currentBalance.toUpperCase(), value: '${vendor.balance.toStringAsFixed(2)} ${l10n.egp}', isBold: true, color: vendor.balance > 0 ? Colors.orange.shade900 : Colors.green.shade900),
      const SizedBox(height: 16), _SidebarItem(label: l10n.email.toUpperCase(), value: vendor.email ?? 'No email'),
      const SizedBox(height: 16), _SidebarItem(label: l10n.phone.toUpperCase(), value: vendor.phone ?? 'No phone'),
      const Spacer(), OutlinedButton(onPressed: () {}, child: Text(l10n.viewVendorProfile.toUpperCase())),
    ]));
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({required this.label, required this.value, this.isBold = false, this.color});
  final String label; final String value; final bool isBold; final Color? color;
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1)), const SizedBox(height: 4), Text(value, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.w800 : FontWeight.w600, color: color))]);
}