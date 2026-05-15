// sales_return_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../invoices/data/models/invoice_model.dart';
import '../../invoices/providers/invoices_provider.dart';
import '../../transactions/widgets/transaction_workspace_shell.dart';
import '../data/models/sales_return_model.dart';
import '../providers/sales_returns_provider.dart';

class SalesReturnLineState {
  SalesReturnLineState({
    required this.invoiceLineId,
    required this.description,
    required this.originalQuantity,
    required this.unitPrice,
    this.quantity = 0,
    this.discountPercent = 0,
  });

  final String invoiceLineId;
  final String description;
  final double originalQuantity;
  final double unitPrice;
  double quantity;
  double discountPercent;

  double get amount => quantity * unitPrice * (1 - discountPercent / 100);
}

class SalesReturnFormScreen extends ConsumerStatefulWidget {
  const SalesReturnFormScreen({super.key, this.id, this.invoiceId});

  final String? id;
  final String? invoiceId;

  @override
  ConsumerState<SalesReturnFormScreen> createState() => _SalesReturnFormScreenState();
}

class _SalesReturnFormScreenState extends ConsumerState<SalesReturnFormScreen> {
  String? _invoiceId;
  DateTime _returnDate = DateTime.now();
  List<SalesReturnLineState> _lines = [];
  bool _saving = false;
  bool _prefillApplied = false;

  bool get _isExisting => (widget.id ?? '').isNotEmpty;
  double get _draftTotal => _lines.fold(0, (sum, line) => sum + line.amount);

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoicesProvider);
    final invoices = invoicesAsync.maybeWhen(
      data: _returnableInvoices,
      orElse: () => <InvoiceModel>[],
    );

    if (_isExisting) {
      final docAsync = ref.watch(salesReturnDetailsProvider(widget.id!));
      return docAsync.when(
        loading: () => _workspaceShell(
          readOnly: true,
          isExisting: true,
          formContent: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => _workspaceShell(
          readOnly: true,
          isExisting: true,
          formContent: Center(child: Text(error.toString(), textAlign: TextAlign.center)),
        ),
        data: (doc) => _buildWorkspace(invoices: invoices, doc: doc),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _applyInvoicePrefill(invoices);
    });

    return _buildWorkspace(invoices: invoices);
  }

  Widget _buildWorkspace({required List<InvoiceModel> invoices, SalesReturnModel? doc}) {
    final isExisting = doc != null;
    final readOnly = isExisting;
    final lines = isExisting ? _linesFromDoc(doc) : _lines;
    final total = isExisting ? doc.totalAmount : _draftTotal;
    final selectedInvoice = invoices.where((invoice) => invoice.id == _invoiceId).firstOrNull;

    return _workspaceShell(
      isExisting: isExisting,
      readOnly: readOnly,
      statusBadgeText: isExisting ? _statusLabel(doc) : null,
      statusMessage: isExisting
          ? _statusMessage(doc)
          : 'New sales return. Choose an invoice, enter returned quantities, then save.',
      statusColor: isExisting ? _statusColor(doc, context) : null,
      onSave: isExisting || _saving ? null : _save,
      onVoid: doc != null && !doc.isVoid ? () => _voidReturn(doc) : null,
      contextPanel: _ContextPanel(
        doc: doc,
        selectedInvoice: selectedInvoice,
        total: total,
        lineCount: lines.length,
      ),
      formContent: Column(
        children: [
          _HeaderPanel(
            doc: doc,
            invoices: invoices,
            selectedInvoice: selectedInvoice,
            invoiceId: _invoiceId,
            returnDate: isExisting ? doc.returnDate : _returnDate,
            readOnly: readOnly,
            onInvoiceChanged: _selectInvoice,
            onOpenInvoice: doc == null
                ? null
                : () => context.push(AppRoutes.invoiceDetails.replaceFirst(':id', doc.invoiceId)),
          ),
          Expanded(
            child: _LinesPanel(
              lines: lines,
              readOnly: readOnly,
              onQuantityChanged: (index, quantity) {
                if (!readOnly) setState(() => _lines[index].quantity = quantity);
              },
            ),
          ),
          _FooterPanel(total: total),
        ],
      ),
    );
  }

  Widget _workspaceShell({
    required Widget formContent,
    Widget? contextPanel,
    bool isExisting = false,
    bool readOnly = false,
    VoidCallback? onSave,
    VoidCallback? onVoid,
    String? statusBadgeText,
    String? statusMessage,
    Color? statusColor,
  }) {
    return TransactionWorkspaceShell(
      workspaceName: 'Sales return workspace',
      saving: _saving,
      posting: false,
      isEdit: isExisting,
      readOnly: readOnly,
      statusBadgeText: statusBadgeText,
      statusMessage: statusMessage,
      statusColor: statusColor,
      onFind: _close,
      onNew: _goNew,
      onSave: onSave,
      onVoid: onVoid,
      onClear: isExisting ? _goNew : _clearDraft,
      onClose: _close,
      showPagination: false,
      showSaveDraft: false,
      showSaveAndPrint: false,
      showPrint: false,
      showEmail: false,
      showEditNotes: false,
      showPayment: false,
      showRefund: false,
      showReceive: false,
      showVoid: isExisting,
      showClear: true,
      formContent: formContent,
      contextPanel: contextPanel,
    );
  }

  void _selectInvoice(InvoiceModel? invoice) {
    setState(() {
      if (invoice == null) {
        _invoiceId = null;
        _lines = [];
        return;
      }
      _invoiceId = invoice.id;
      _returnDate = DateTime.now();
      _lines = invoice.lines
          .map(
            (line) => SalesReturnLineState(
              invoiceLineId: line.id,
              description: line.description.isEmpty ? line.itemId : line.description,
              originalQuantity: line.quantity,
              unitPrice: line.unitPrice,
              discountPercent: line.discountPercent,
            ),
          )
          .toList();
    });
  }

  List<InvoiceModel> _returnableInvoices(List<InvoiceModel> invoices) => invoices
      .where(
        (invoice) =>
            invoice.isCreditInvoice &&
            !invoice.isVoid &&
            invoice.lines.isNotEmpty &&
            invoice.postedTransactionId != null,
      )
      .toList();

  void _applyInvoicePrefill(List<InvoiceModel> invoices) {
    if (_prefillApplied || (widget.invoiceId ?? '').isEmpty) return;
    final invoice = invoices.where((item) => item.id == widget.invoiceId).firstOrNull;
    if (invoice == null) return;
    _prefillApplied = true;
    _selectInvoice(invoice);
  }

  List<SalesReturnLineState> _linesFromDoc(SalesReturnModel doc) => doc.lines
      .map(
        (line) => SalesReturnLineState(
          invoiceLineId: line.invoiceLineId,
          description: line.description.isEmpty ? line.itemId : line.description,
          originalQuantity: 0,
          quantity: line.quantity,
          unitPrice: line.unitPrice,
          discountPercent: line.discountPercent,
        ),
      )
      .toList();

  void _clearDraft() {
    setState(() {
      _invoiceId = null;
      _returnDate = DateTime.now();
      _lines = [];
      _prefillApplied = false;
    });
  }

  void _goNew() => context.go(AppRoutes.salesReturnNew);
  void _close() => context.go(AppRoutes.salesReturns);

  Future<void> _save() async {
    if (_invoiceId == null || _invoiceId!.isEmpty) {
      _showError(context, 'اختر الفاتورة أولاً');
      return;
    }

    final validLines = _lines.where((line) => line.quantity > 0).toList();
    if (validLines.isEmpty) {
      _showError(context, 'حدد كمية مرتجعة لسطر واحد على الأقل');
      return;
    }
    for (final line in validLines) {
      if (line.quantity > line.originalQuantity) {
        _showError(context, 'كمية المرتجع لا يمكن أن تتجاوز كمية الفاتورة');
        return;
      }
    }

    final dto = CreateSalesReturnDto(
      invoiceId: _invoiceId!,
      returnDate: _returnDate,
      lines: validLines
          .map(
            (line) => CreateSalesReturnLineDto(
              invoiceLineId: line.invoiceLineId,
              quantity: line.quantity,
              unitPrice: line.unitPrice,
              discountPercent: line.discountPercent,
            ),
          )
          .toList(),
    );

    setState(() => _saving = true);
    final result = await ref.read(salesReturnsProvider.notifier).create(dto);
    if (!mounted) return;
    setState(() => _saving = false);

    result.when(
      success: (saved) {
        ref.read(invoicesProvider.notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ مرتجع البيع وترحيله بنجاح')),
        );
        context.go(AppRoutes.salesReturnDetails.replaceFirst(':id', saved.id));
      },
      failure: (error) => _showError(context, error.message),
    );
  }

  Future<void> _voidReturn(SalesReturnModel doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Void ${_returnNumber(doc)}?'),
        content: const Text('This reverses the sales return when allowed.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Void')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    final result = await ref.read(salesReturnsProvider.notifier).voidReturn(doc.id);
    if (!mounted) return;
    setState(() => _saving = false);

    result.when(
      success: (_) {
        ref.invalidate(salesReturnDetailsProvider(doc.id));
        ref.read(invoicesProvider.notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sales return ${_returnNumber(doc)} voided.')),
        );
      },
      failure: (error) => _showError(context, error.message),
    );
  }

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static String _returnNumber(SalesReturnModel doc) =>
      doc.returnNumber.isEmpty ? 'Sales Return' : doc.returnNumber;

  static String _statusLabel(SalesReturnModel doc) {
    if (doc.isVoid || doc.status == 3) return 'VOID';
    if (doc.status == 1) return 'DRAFT';
    return 'POSTED';
  }

  static String _statusMessage(SalesReturnModel doc) {
    if (doc.isVoid || doc.status == 3) return 'This sales return is void and financial fields are locked.';
    if (doc.status == 1) return 'This sales return is saved as draft. Financial fields are locked until update support is added.';
    return 'This sales return is posted. Financial fields are read-only.';
  }

  static Color _statusColor(SalesReturnModel doc, BuildContext context) {
    if (doc.isVoid || doc.status == 3) return Theme.of(context).colorScheme.error;
    if (doc.status == 1) return const Color(0xFF6D7880);
    return const Color(0xFF2E7D32);
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}

class _HeaderPanel extends StatelessWidget {
  const _HeaderPanel({
    required this.doc,
    required this.invoices,
    required this.selectedInvoice,
    required this.invoiceId,
    required this.returnDate,
    required this.readOnly,
    required this.onInvoiceChanged,
    this.onOpenInvoice,
  });

  final SalesReturnModel? doc;
  final List<InvoiceModel> invoices;
  final InvoiceModel? selectedInvoice;
  final String? invoiceId;
  final DateTime returnDate;
  final bool readOnly;
  final ValueChanged<InvoiceModel?> onInvoiceChanged;
  final VoidCallback? onOpenInvoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFB),
        border: Border(bottom: BorderSide(color: Color(0xFFCAD5DC))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            doc == null ? 'Sales Return / مرتجع بيع جديد' : _SalesReturnFormScreenState._returnNumber(doc!),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF243E4A),
                  fontWeight: FontWeight.w300,
                ),
          ),
          const SizedBox(height: 14),
          if (readOnly && doc != null)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ReadBox(label: 'Customer', value: doc!.customerName ?? doc!.customerId),
                _ReadBox(label: 'Invoice', value: doc!.invoiceNumber ?? doc!.invoiceId, onTap: onOpenInvoice),
                _ReadBox(label: 'Return date', value: _dateDisplay(doc!.returnDate)),
                _ReadBox(label: 'Return #', value: _SalesReturnFormScreenState._returnNumber(doc!)),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedInvoice?.id,
                    decoration: const InputDecoration(
                      labelText: 'الفاتورة *',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: Icon(Icons.receipt_long_outlined),
                    ),
                    items: invoices
                        .map(
                          (invoice) => DropdownMenuItem<String>(
                            value: invoice.id,
                            child: Text(
                              '${invoice.invoiceNumber} - ${invoice.customerName ?? ''} - ${invoice.totalAmount.toStringAsFixed(2)}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => onInvoiceChanged(invoices.where((item) => item.id == value).firstOrNull),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 180,
                  child: TextFormField(
                    readOnly: true,
                    initialValue: _SalesReturnFormScreenState._dateOnly(returnDate),
                    decoration: const InputDecoration(
                      labelText: 'تاريخ المرتجع',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LinesPanel extends StatelessWidget {
  const _LinesPanel({required this.lines, required this.readOnly, required this.onQuantityChanged});

  final List<SalesReturnLineState> lines;
  final bool readOnly;
  final void Function(int index, double quantity) onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const Center(child: Text('اختر فاتورة لعرض سطورها.'));
    return Column(
      children: [
        Container(
          height: 30,
          color: const Color(0xFFDDE8ED),
          child: const Row(
            children: [
              _Head('ITEM / DESCRIPTION', flex: 4),
              _Head('INVOICE QTY', flex: 2, right: true),
              _Head('RETURN QTY', flex: 2, right: true),
              _Head('RATE', flex: 2, right: true),
              _Head('DISC %', flex: 2, right: true),
              _Head('AMOUNT', flex: 2, right: true),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: lines.length,
            itemBuilder: (context, index) => _LineRow(
              index: index,
              line: lines[index],
              readOnly: readOnly,
              shaded: index.isEven,
              onQuantityChanged: onQuantityChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({
    required this.index,
    required this.line,
    required this.readOnly,
    required this.shaded,
    required this.onQuantityChanged,
  });

  final int index;
  final SalesReturnLineState line;
  final bool readOnly;
  final bool shaded;
  final void Function(int index, double quantity) onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: shaded ? const Color(0xFFEAF4F7) : Colors.white,
      child: Row(
        children: [
          _Cell(line.description, flex: 4),
          _Cell(line.originalQuantity <= 0 ? '-' : line.originalQuantity.toStringAsFixed(2), flex: 2, right: true),
          Expanded(
            flex: 2,
            child: Container(
              height: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: const BoxDecoration(border: Border(right: BorderSide(color: Color(0xFFB8C6CE)))),
              child: readOnly
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: Text(line.quantity.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w800)),
                    )
                  : TextFormField(
                      key: ValueKey(line.invoiceLineId),
                      initialValue: line.quantity == 0 ? '' : line.quantity.toString(),
                      textAlign: TextAlign.end,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      onChanged: (value) => onQuantityChanged(index, double.tryParse(value) ?? 0),
                    ),
            ),
          ),
          _Cell(line.unitPrice.toStringAsFixed(2), flex: 2, right: true),
          _Cell(line.discountPercent.toStringAsFixed(2), flex: 2, right: true),
          _Cell(line.amount.toStringAsFixed(2), flex: 2, right: true, strong: true),
        ],
      ),
    );
  }
}

class _FooterPanel extends StatelessWidget {
  const _FooterPanel({required this.total});
  final double total;

  @override
  Widget build(BuildContext context) => Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFB),
          border: Border(top: BorderSide(color: Color(0xFFCAD5DC))),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Official totals, stock impact, customer credit, and accounting posting are recalculated by the backend after save.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 20),
            const Text('Return Total', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(width: 12),
            Text(
              total.toStringAsFixed(2),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      );
}

class _ContextPanel extends StatelessWidget {
  const _ContextPanel({required this.doc, required this.selectedInvoice, required this.total, required this.lineCount});

  final SalesReturnModel? doc;
  final InvoiceModel? selectedInvoice;
  final double total;
  final int lineCount;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 42, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Sales Return', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            _ContextLine(label: 'Customer', value: doc?.customerName ?? selectedInvoice?.customerName ?? 'Not selected'),
            _ContextLine(label: 'Invoice', value: doc?.invoiceNumber ?? selectedInvoice?.invoiceNumber ?? 'Not selected'),
            _ContextLine(label: 'Status', value: doc == null ? 'New' : _SalesReturnFormScreenState._statusLabel(doc!)),
            _ContextLine(label: 'Lines', value: lineCount.toString()),
            _ContextLine(label: 'Total', value: total.toStringAsFixed(2)),
            const Divider(height: 28),
            const Text('Return policy', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text(
              'Sales returns stay linked to the original invoice. Saved records open here in the same workspace and financial fields stay locked.',
              style: TextStyle(fontSize: 12, height: 1.35),
            ),
          ],
        ),
      );
}

class _ReadBox extends StatelessWidget {
  const _ReadBox({required this.label, required this.value, this.onTap});
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = InputDecorator(
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
      child: Text(
        value,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: onTap == null ? const Color(0xFF273F4B) : Theme.of(context).colorScheme.primary,
          decoration: onTap == null ? null : TextDecoration.underline,
        ),
      ),
    );
    return SizedBox(width: 220, child: onTap == null ? child : InkWell(onTap: onTap, child: child));
  }
}

class _Head extends StatelessWidget {
  const _Head(this.text, {required this.flex, this.right = false});
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
  const _Cell(this.text, {required this.flex, this.right = false, this.strong = false});
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
          decoration: const BoxDecoration(border: Border(right: BorderSide(color: Color(0xFFB8C6CE)))),
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

class _ContextLine extends StatelessWidget {
  const _ContextLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF667A84), fontWeight: FontWeight.w700)),
            const Spacer(),
            Flexible(
              child: Text(value, textAlign: TextAlign.end, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      );
}

String _dateDisplay(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year.toString().padLeft(4, '0')}';
