// payment_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
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

class PaymentFormState {
  String? invoiceId;
  String? depositAccountId;
  PaymentMethod paymentMethod = PaymentMethod.cash;
  DateTime paymentDate = DateTime.now();
  double amount = 0;
}

final paymentFormProvider = StateProvider.autoDispose<PaymentFormState>((ref) => PaymentFormState());
final paymentSavingProvider = StateProvider.autoDispose<bool>((ref) => false);

class PaymentFormScreen extends ConsumerWidget {
  const PaymentFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(paymentFormProvider);
    final saving = ref.watch(paymentSavingProvider);
    final invoicesAsync = ref.watch(invoicesProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تحصيل من عميل'),
        actions: [
          AppButton(
            label: 'إلغاء',
            variant: AppButtonVariant.secondary,
            onPressed: saving ? null : () => context.canPop() ? context.pop() : context.go('/sales/payments'),
          ),
          const SizedBox(width: 12),
          AppButton(
            label: 'حفظ التحصيل',
            loading: saving,
            onPressed: saving ? null : () => _save(context, ref),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _HeaderCard(
            form: form,
            invoicesAsync: invoicesAsync,
            accountsAsync: accountsAsync,
          ),
          const SizedBox(height: 24),
          _InfoCard(form: form, invoicesAsync: invoicesAsync),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final form = ref.read(paymentFormProvider);
    if (form.invoiceId == null || form.invoiceId!.isEmpty) {
      _error(context, 'اختر الفاتورة أولاً');
      return;
    }
    if (form.depositAccountId == null || form.depositAccountId!.isEmpty) {
      _error(context, 'اختر حساب الإيداع أولاً');
      return;
    }
    if (form.amount <= 0) {
      _error(context, 'قيمة التحصيل يجب أن تكون أكبر من صفر');
      return;
    }

    final dto = CreatePaymentDto(
      invoiceId: form.invoiceId!,
      depositAccountId: form.depositAccountId!,
      paymentDate: form.paymentDate,
      amount: form.amount,
      paymentMethod: form.paymentMethod,
    );

    ref.read(paymentSavingProvider.notifier).state = true;
    final result = await ref.read(paymentsProvider.notifier).create(dto);
    ref.read(paymentSavingProvider.notifier).state = false;

    if (!context.mounted) return;
    result.when(
      success: (_) {
        ref.read(invoicesProvider.notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل التحصيل بنجاح')));
        context.go('/sales/payments');
      },
      failure: (error) => _error(context, error.message),
    );
  }

  static void _error(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _HeaderCard extends ConsumerWidget {
  const _HeaderCard({
    required this.form,
    required this.invoicesAsync,
    required this.accountsAsync,
  });

  final PaymentFormState form;
  final AsyncValue<List<InvoiceModel>> invoicesAsync;
  final AsyncValue<List<AccountModel>> accountsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openInvoices = invoicesAsync.maybeWhen(
      data: (invoices) => invoices
          .where((invoice) => invoice.isCreditInvoice && !invoice.isVoid && invoice.balanceDue > 0)
          .toList(),
      orElse: () => <InvoiceModel>[],
    );
    final depositAccounts = accountsAsync.maybeWhen(
      data: (accounts) => accounts
          .where((account) => account.isActive && (account.accountType == AccountType.bank || account.accountType == AccountType.otherCurrentAsset))
          .toList(),
      orElse: () => <AccountModel>[],
    );
    final selectedInvoice = openInvoices.where((invoice) => invoice.id == form.invoiceId).firstOrNull;
    final safeInvoiceId = selectedInvoice?.id;
    final safeDepositId = depositAccounts.any((account) => account.id == form.depositAccountId) ? form.depositAccountId : null;

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
                  .map(
                    (invoice) => DropdownMenuItem(
                      value: invoice.id,
                      child: Text('${invoice.invoiceNumber} - ${invoice.customerName ?? ''} - متبقي ${invoice.balanceDue.toStringAsFixed(2)}'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                final selected = openInvoices.where((invoice) => invoice.id == value).firstOrNull;
                _update(ref, form
                  ..invoiceId = value
                  ..amount = selected?.balanceDue ?? form.amount);
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
                        .map((account) => DropdownMenuItem(value: account.id, child: Text('${account.code} - ${account.name}')))
                        .toList(),
                    onChanged: (value) => _update(ref, form..depositAccountId = value),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<PaymentMethod>(
                    initialValue: form.paymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'طريقة الدفع',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: PaymentMethod.cash, child: Text('كاش')),
                      DropdownMenuItem(value: PaymentMethod.check, child: Text('شيك')),
                      DropdownMenuItem(value: PaymentMethod.bankTransfer, child: Text('تحويل بنكي')),
                      DropdownMenuItem(value: PaymentMethod.creditCard, child: Text('بطاقة')),
                    ],
                    onChanged: (value) {
                      if (value != null) _update(ref, form..paymentMethod = value);
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
                    initialValue: PaymentFormScreen._dateOnly(form.paymentDate),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    key: ValueKey('amount-${form.invoiceId}-${form.amount}'),
                    label: 'المبلغ *',
                    initialValue: form.amount == 0 ? '' : form.amount.toStringAsFixed(2),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      form.amount = double.tryParse(value) ?? 0;
                      _update(ref, form);
                    },
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
  const _InfoCard({required this.form, required this.invoicesAsync});

  final PaymentFormState form;
  final AsyncValue<List<InvoiceModel>> invoicesAsync;

  @override
  Widget build(BuildContext context) {
    final invoice = invoicesAsync.value?.where((i) => i.id == form.invoiceId).firstOrNull;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: invoice == null
            ? const Text('اختر فاتورة آجلة لعرض تفاصيل التحصيل.')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('تفاصيل الفاتورة', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  _Row(label: 'العميل', value: invoice.customerName ?? '-'),
                  _Row(label: 'رقم الفاتورة', value: invoice.invoiceNumber),
                  _Row(label: 'إجمالي الفاتورة', value: invoice.totalAmount.toStringAsFixed(2)),
                  _Row(label: 'المدفوع سابقًا', value: invoice.paidAmount.toStringAsFixed(2)),
                  _Row(label: 'المتبقي', value: invoice.balanceDue.toStringAsFixed(2)),
                ],
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
          children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.w700))],
        ),
      );
}

void _update(WidgetRef ref, PaymentFormState old) {
  ref.read(paymentFormProvider.notifier).state = PaymentFormState()
    ..invoiceId = old.invoiceId
    ..depositAccountId = old.depositAccountId
    ..paymentMethod = old.paymentMethod
    ..paymentDate = old.paymentDate
    ..amount = old.amount;
}
