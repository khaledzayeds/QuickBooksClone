import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_client.dart';
import '../data/models/customer_model.dart';
import '../providers/customers_provider.dart';

class CustomerTransactionHistoryScreen extends ConsumerStatefulWidget {
  const CustomerTransactionHistoryScreen({
    super.key,
    this.customerId,
    this.customerName,
  });

  final String? customerId;
  final String? customerName;

  @override
  ConsumerState<CustomerTransactionHistoryScreen> createState() => _CustomerTransactionHistoryScreenState();
}

class _CustomerTransactionHistoryScreenState extends ConsumerState<CustomerTransactionHistoryScreen> {
  final _currencyFmt = NumberFormat('#,##0.00');
  DateTimeRange? _range;
  String _type = 'All';
  CustomerModel? _selectedCustomer;
  bool _loading = false;
  String? _error;
  List<CustomerTransactionDto> _transactions = const [];

  static const _types = ['All', 'Receipts', 'Payments', 'Invoices', 'Credits', 'Returns'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrateInitialCustomer());
  }

  void _hydrateInitialCustomer() {
    final customers = ref.read(customersProvider).valueOrNull ?? const <CustomerModel>[];
    if (widget.customerId != null) {
      final match = customers.where((customer) => customer.id == widget.customerId).toList();
      if (match.isNotEmpty) {
        setState(() => _selectedCustomer = match.first);
      }
    }
    _fetch();
  }

  String? get _customerId => _selectedCustomer?.id ?? widget.customerId;
  String get _customerName => _selectedCustomer?.displayName ?? widget.customerName ?? 'Customer Transaction History';

  Future<void> _fetch() async {
    final id = _customerId;
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
        '/api/customers/$id/transactions',
        queryParameters: {
          if (_range != null) 'from': DateFormat('yyyy-MM-dd').format(_range!.start),
          if (_range != null) 'to': DateFormat('yyyy-MM-dd').format(_range!.end),
          if (_type != 'All') 'type': _type,
        },
      );
      final data = response.data ?? const [];
      if (!mounted) return;
      setState(() {
        _transactions = data
            .whereType<Map<String, dynamic>>()
            .map(CustomerTransactionDto.fromJson)
            .toList();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_customerName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            Text('Customer Transaction History', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Print',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Print history will be connected to the report print service.')),
              );
            },
            icon: const Icon(Icons.print_outlined),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: cs.outlineVariant),
        ),
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
                      child: customersAsync.maybeWhen(
                        data: (customers) => DropdownButtonFormField<CustomerModel>(
                          value: _selectedCustomer,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Customer',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          items: customers
                              .where((customer) => customer.isActive)
                              .map((customer) => DropdownMenuItem(value: customer, child: Text(customer.displayName)))
                              .toList(),
                          onChanged: (customer) {
                            setState(() => _selectedCustomer = customer);
                            _fetch();
                          },
                        ),
                        orElse: () => const Text('Loading customers...'),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickRange,
                      icon: const Icon(Icons.date_range_outlined, size: 18),
                      label: Text(
                        _range == null
                            ? 'Date range'
                            : '${DateFormat('dd/MM/yyyy').format(_range!.start)} - ${DateFormat('dd/MM/yyyy').format(_range!.end)}',
                      ),
                    ),
                    if (_range != null)
                      IconButton(
                        tooltip: 'Clear date range',
                        onPressed: _clearRange,
                        icon: const Icon(Icons.close),
                      ),
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

    if (_customerId == null) {
      return _EmptyState(
        icon: Icons.person_search_outlined,
        title: 'Choose a customer',
        message: 'Select a customer to view transaction history.',
      );
    }
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _EmptyState(
        icon: Icons.error_outline,
        title: 'Could not load transactions',
        message: _error!,
        action: FilledButton.icon(onPressed: _fetch, icon: const Icon(Icons.refresh), label: const Text('Retry')),
      );
    }
    if (_transactions.isEmpty) {
      return const _EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No transactions found',
        message: 'No transactions match the selected filters.',
      );
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
                Chip(
                  label: Text(txn.status),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: cs.outlineVariant),
                ),
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
    if (value.contains('receipt')) return Icons.point_of_sale_outlined;
    if (value.contains('payment')) return Icons.payments_outlined;
    if (value.contains('invoice')) return Icons.description_outlined;
    if (value.contains('credit')) return Icons.credit_score_outlined;
    if (value.contains('return')) return Icons.assignment_return_outlined;
    return Icons.receipt_long_outlined;
  }
}

class CustomerTransactionDto {
  const CustomerTransactionDto({
    required this.id,
    required this.type,
    required this.number,
    required this.date,
    required this.amount,
    required this.status,
  });

  final String id;
  final String type;
  final String number;
  final DateTime date;
  final double amount;
  final String status;

  String get title => '$type $number';

  factory CustomerTransactionDto.fromJson(Map<String, dynamic> json) => CustomerTransactionDto(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? 'Transaction',
        number: json['number']?.toString() ?? json['documentNumber']?.toString() ?? '',
        date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
        amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
        status: json['status']?.toString() ?? 'Posted',
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

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
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}
