// payment_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/api_enums.dart' show AccountType, PaymentMethod;
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../accounts/data/models/account_model.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../invoices/data/models/invoice_model.dart';
import '../../invoices/providers/invoices_provider.dart';
import '../data/models/payment_model.dart';
import '../providers/payments_provider.dart';

class PaymentFormScreen extends ConsumerStatefulWidget {
  const PaymentFormScreen({super.key});

  static String _dateOnly(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  ConsumerState<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends ConsumerState<PaymentFormScreen> {
  String? _invoiceId;
  String? _depositAccountId;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  DateTime _paymentDate = DateTime.now();
  double _amount = 0;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoicesProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تحصيل من عميل'),
        actions: [
          AppButton(
            label: 'إلغاء',
            variant: AppButtonVariant.secondary,
            onPressed: _saving
                ? null
                : () => context.canPop()
                      ? context.pop()
                      : context.go('/sales/payments'),
          ),
          const SizedBox(width: 12),
          AppButton(
            label: 'حفظ التحصيل',
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _HeaderCard(
            invoiceId: _invoiceId,
            depositAccountId: _depositAccountId,
            paymentMethod: _paymentMethod,
            paymentDate: _paymentDate,
            amount: _amount,
            invoicesAsync: invoicesAsync,
            accountsAsync: accountsAsync,
            onInvoiceChanged: (invoice) => setState(() {
              _invoiceId = invoice?.id;
              _amount = invoice?.balanceDue ?? _amount;
            }),
            onDepositAccountChanged: (value) => setState(() => _depositAccountId = value),
            onPaymentMethodChanged: (value) => setState(() => _paymentMethod = value),
            onAmountChanged: (value) => setState(() => _amount = value),
          ),
          const SizedBox(height: 24),
          _InfoCard(invoiceId: _invoiceId, invoicesAsync: invoicesAsync),
          const SizedBox(height: 24),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _DraftPaymentAmountCard(amount: _amount),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_invoiceId == null || _invoiceId!.isEmpty) {
      _error(context, 'اختر الفاتورة أولاً');
      return;
    }
    if (_depositAccountId == null || _depositAccountId!.isEmpty) {
      _error(context, 'اختر حساب الإيداع أولاً');
      return;
    }
    if (_amount <= 0) {
      _error(context, 'قيمة التحصيل يجب أن تكون أكبر من صفر');
      return;
    }

    final dto = CreatePaymentDto(
      invoiceId: _invoiceId!,
      depositAccountId: _depositAccountId!,
      paymentDate: _paymentDate,
      amount: _amount,
      paymentMethod: _paymentMethod,
    );

    setState(() => _saving = true);
    final result = await ref.read(paymentsProvider.notifier).create(dto);
    if (!mounted) return;
    setState(() => _saving = false);

    result.when(
      success: (_) {
        ref.read(invoicesProvider.notifier).refresh();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم تسجيل التحصيل بنجاح')));
        context.go('/sales/payments');
      },
      failure: (error) => _error(context, error.message),
    );
  }

  static void _error(BuildContext context, String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.invoiceId,
    required this.depositAccountId,
    required this.paymentMethod,
    required this.paymentDate,
    required this.amount,
    required this.invoicesAsync,
    required this.accountsAsync,
    required this.onInvoiceChanged,
    required this.onDepositAccountChanged,
    required this.onPaymentMethodChanged,
    required this.onAmountChanged,
  });

  final String? invoiceId;
  final String? depositAccountId;
  final PaymentMethod paymentMethod;
  final DateTime paymentDate;
  final double amount;
  final AsyncValue<List<InvoiceModel>> invoicesAsync;
  final AsyncValue<List<AccountModel>> accountsAsync;
  final ValueChanged<InvoiceModel?> onInvoiceChanged;
  final ValueChanged<String?> onDepositAccountChanged;
  final ValueChanged<PaymentMethod> onPaymentMethodChanged;
  final ValueChanged<double> onAmountChanged;

  @override
  Widget build(BuildContext context) {
    final openInvoices = invoicesAsync.maybeWhen(
      data: (invoices) => invoices
          .where(
            (invoice) =>
                invoice.isCreditInvoice &&
                !invoice.isVoid &&
                invoice.balanceDue > 0,
          )
          .toList(),
      orElse: () => <InvoiceModel>[],
    );
    final depositAccounts = accountsAsync.maybeWhen(
      data: (accounts) => accounts
          .where(
            (account) =>
                account.isActive &&
                (account.accountType == AccountType.bank ||
                    account.accountType == AccountType.otherCurrentAsset),
          )
          .toList(),
      orElse: () => <AccountModel>[],
    );
    final selectedInvoice = openInvoices
        .where((invoice) => invoice.id == invoiceId)
        .firstOrNull;
    final safeInvoiceId = selectedInvoice?.id;
    final safeDepositId =
        depositAccounts.any((account) => account.id == depositAccountId)
        ? depositAccountId
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: safeInvoiceId,
              decoration: const InputDecoration(
                labelText: 'الفاتورة الآجلة *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.receipt_long_outlined),
              ),
              items: openInvoices
                  .map<DropdownMenuItem<String>>(
                    (InvoiceModel invoice) => DropdownMenuItem<String>(
                      value: invoice.id,
                      child: Text(
                        '${invoice.invoiceNumber} - ${invoice.customerName ?? ''} - متبقي ${invoice.balanceDue.toStringAsFixed(2)}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                final selected = openInvoices
                    .where((invoice) => invoice.id == value)
                    .firstOrNull;
                onInvoiceChanged(selected);
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: safeDepositId,
                    decoration: const InputDecoration(
                      labelText: 'حساب الإيداع *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_balance),
                    ),
                    items: depositAccounts
                        .map<DropdownMenuItem<String>>(
                          (AccountModel account) => DropdownMenuItem<String>(
                            value: account.id,
                            child: Text('${account.code} - ${account.name}'),
                          ),
                        )
                        .toList(),
                    onChanged: onDepositAccountChanged,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<PaymentMethod>(
                    initialValue: paymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'طريقة الدفع',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    items: const [
                      DropdownMenuItem<PaymentMethod>(
                        value: PaymentMethod.cash,
                        child: Text('كاش'),
                      ),
                      DropdownMenuItem<PaymentMethod>(
                        value: PaymentMethod.check,
                        child: Text('شيك'),
                      ),
                      DropdownMenuItem<PaymentMethod>(
                        value: PaymentMethod.bankTransfer,
                        child: Text('تحويل بنكي'),
                      ),
                      DropdownMenuItem<PaymentMethod>(
                        value: PaymentMethod.creditCard,
                        child: Text('بطاقة'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) onPaymentMethodChanged(value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'تاريخ التحصيل',
                    readOnly: true,
                    initialValue: PaymentFormScreen._dateOnly(paymentDate),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    key: ValueKey('payment-amount-${invoiceId ?? 'manual'}-$amount'),
                    label: 'المبلغ *',
                    initialValue: amount == 0
                        ? ''
                        : amount.toStringAsFixed(2),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (value) => onAmountChanged(double.tryParse(value) ?? 0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.invoiceId, required this.invoicesAsync});

  final String? invoiceId;
  final AsyncValue<List<InvoiceModel>> invoicesAsync;

  @override
  Widget build(BuildContext context) {
    final invoice = invoicesAsync.value
        ?.where((i) => i.id == invoiceId)
        .firstOrNull;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: invoice == null
            ? const Text('اختر فاتورة آجلة لعرض تفاصيل التحصيل.')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تفاصيل الفاتورة',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Row(label: 'العميل', value: invoice.customerName ?? '-'),
                  _Row(label: 'رقم الفاتورة', value: invoice.invoiceNumber),
                  _Row(
                    label: 'إجمالي الفاتورة',
                    value: invoice.totalAmount.toStringAsFixed(2),
                  ),
                  _Row(
                    label: 'المدفوع سابقًا',
                    value: invoice.paidAmount.toStringAsFixed(2),
                  ),
                  _Row(
                    label: 'المتبقي',
                    value: invoice.balanceDue.toStringAsFixed(2),
                  ),
                ],
              ),
      ),
    );
  }
}

class _DraftPaymentAmountCard extends StatelessWidget {
  const _DraftPaymentAmountCard({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: SizedBox(
        width: 360,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Draft payment amount', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    amount.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: cs.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Official invoice balance, customer balance, deposit, and accounting impact are recalculated by the backend after save.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}
