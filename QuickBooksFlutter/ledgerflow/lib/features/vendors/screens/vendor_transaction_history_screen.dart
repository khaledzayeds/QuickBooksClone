import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_client.dart';
import '../../reports/printing/vendor_statement_print_service.dart';
import '../data/models/vendor_model.dart';
import '../providers/vendors_provider.dart';

class VendorTransactionHistoryScreen extends ConsumerStatefulWidget {
  const VendorTransactionHistoryScreen({super.key, this.vendorId, this.vendorName});

  final String? vendorId;
  final String? vendorName;

  @override
  ConsumerState<VendorTransactionHistoryScreen> createState() => _VendorTransactionHistoryScreenState();
}

class _VendorTransactionHistoryScreenState extends ConsumerState<VendorTransactionHistoryScreen> {
  final _currencyFmt = NumberFormat('#,##0.00');
  DateTimeRange? _range;
  String _type = 'All';
  VendorModel? _selectedVendor;
  bool _loading = false;
  String? _error;
  List<VendorTransactionDto> _transactions = const [];

  static const _types = ['All', 'Bills', 'Payments', 'Credits', 'Returns'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrateInitialVendor());
  }

  void _hydrateInitialVendor() {
    final vendors = ref.read(vendorsProvider).valueOrNull ?? const <VendorModel>[];
    if (widget.vendorId != null) {
      final match = vendors.where((vendor) => vendor.id == widget.vendorId).toList();
      if (match.isNotEmpty) {
        setState(() => _selectedVendor = match.first);
      }
    }
    _fetch();
  }

  String? get _vendorId => _selectedVendor?.id ?? widget.vendorId;
  String get _vendorName => _selectedVendor?.displayName ?? widget.vendorName ?? 'Vendor Statement';

  Future<void> _fetch() async {
    final id = _vendorId;
    if (id == null || id.trim().isEmpty) {
      setState(() {
        _transactions = const [];
        _error = null;
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiClient.instance.get<List<dynamic>>(
        '/api/vendors/$id/transactions',
        queryParameters: {
          if (_range != null) 'from': DateFormat('yyyy-MM-dd').format(_range!.start),
          if (_range != null) 'to': DateFormat('yyyy-MM-dd').format(_range!.end),
          if (_type != 'All') 'type': _type,
        },
      );
      final data = response.data ?? const [];
      if (!mounted) return;
      setState(() {
        _transactions = data.whereType<Map<String, dynamic>>().map(VendorTransactionDto.fromJson).toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _range ?? DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() => _range = picked);
    _fetch();
  }

  void _clearRange() {
    setState(() => _range = null);
    _fetch();
  }

  Future<void> _printStatement() async {
    if (_vendorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a vendor before printing.')));
      return;
    }

    final model = VendorStatementPrintModel(
      vendorName: _vendorName,
      fromDate: _range?.start,
      toDate: _range?.end,
      type: _type,
      currency: 'EGP',
      lines: _transactions
          .map((txn) => VendorStatementPrintLine(type: txn.type, number: txn.number, date: txn.date, amount: txn.amount, status: txn.status))
          .toList(),
    );

    try {
      await const VendorStatementPrintService().printStatement(model);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not print vendor statement: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final vendorsAsync = ref.watch(vendorsProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_vendorName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            Text('Vendor Statement', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
        actions: [
          IconButton(tooltip: 'Print', onPressed: _printStatement, icon: const Icon(Icons.print_outlined)),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: cs.outlineVariant)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: cs.outlineVariant)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 280,
                      child: vendorsAsync.maybeWhen(
                        data: (vendors) => DropdownButtonFormField<VendorModel>(
                          value: _selectedVendor,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Vendor', isDense: true, border: OutlineInputBorder()),
                          items: vendors.where((vendor) => vendor.isActive).map((vendor) => DropdownMenuItem(value: vendor, child: Text(vendor.displayName))).toList(),
                          onChanged: (vendor) {
                            setState(() => _selectedVendor = vendor);
                            _fetch();
                          },
                        ),
                        orElse: () => const Text('Loading vendors...'),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickRange,
                      icon: const Icon(Icons.date_range_outlined, size: 18),
                      label: Text(_range == null ? 'Date range' : '${DateFormat('dd/MM/yyyy').format(_range!.start)} - ${DateFormat('dd/MM/yyyy').format(_range!.end)}'),
                    ),
                    if (_range != null) IconButton(tooltip: 'Clear date range', onPressed: _clearRange, icon: const Icon(Icons.close)),
                    for (final type in _types)
                      ChoiceChip(
                        label: Text(type),
                        selected: _type == type,
                        onSelected: (_) {
                          setState(() => _type = type);
                          _fetch();
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildContent(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_vendorId == null) {
      return const _EmptyState(icon: Icons.storefront_outlined, title: 'Choose a vendor', message: 'Select a vendor to view statement transactions.');
    }
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _EmptyState(icon: Icons.error_outline, title: 'Could not load transactions', message: _error!, action: FilledButton.icon(onPressed: _fetch, icon: const Icon(Icons.refresh), label: const Text('Retry')));
    }
    if (_transactions.isEmpty) {
      return const _EmptyState(icon: Icons.receipt_long_outlined, title: 'No transactions found', message: 'No transactions match the selected filters.');
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: cs.outlineVariant)),
      child: ListView.separated(
        itemCount: _transactions.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: cs.outlineVariant),
        itemBuilder: (context, index) {
          final txn = _transactions[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: cs.primaryContainer.withValues(alpha: 0.55),
              child: Icon(_iconForType(txn.type), color: cs.primary, size: 20),
            ),
            title: Text(txn.title, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('${DateFormat('dd/MM/yyyy').format(txn.date)} • ${txn.type}'),
            trailing: Wrap(
              spacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(label: Text(txn.status), visualDensity: VisualDensity.compact, side: BorderSide(color: cs.outlineVariant)),
                Text('${_currencyFmt.format(txn.amount)} EGP', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900)),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _iconForType(String type) {
    final value = type.toLowerCase();
    if (value.contains('bill')) return Icons.receipt_long_outlined;
    if (value.contains('payment')) return Icons.payments_outlined;
    if (value.contains('credit')) return Icons.credit_score_outlined;
    if (value.contains('return')) return Icons.assignment_return_outlined;
    return Icons.storefront_outlined;
  }
}

class VendorTransactionDto {
  const VendorTransactionDto({required this.id, required this.type, required this.number, required this.date, required this.amount, required this.status});

  final String id;
  final String type;
  final String number;
  final DateTime date;
  final double amount;
  final String status;

  String get title => '$type $number';

  factory VendorTransactionDto.fromJson(Map<String, dynamic> json) => VendorTransactionDto(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? 'Transaction',
        number: json['number']?.toString() ?? json['documentNumber']?.toString() ?? '',
        date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
        amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
        status: json['status']?.toString() ?? 'Posted',
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.message, this.action});

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 34, backgroundColor: cs.surfaceContainerHighest, child: Icon(icon, size: 34, color: cs.outline)),
          const SizedBox(height: 14),
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}
