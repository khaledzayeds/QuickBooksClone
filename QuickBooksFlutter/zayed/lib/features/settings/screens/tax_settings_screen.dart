import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/company_settings_form_provider.dart';

class TaxSettingsScreen extends ConsumerWidget {
  const TaxSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(companySettingsFormProvider);
    final notifier = ref.read(companySettingsFormProvider.notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final text = _TaxSettingsText.of(context);

    ref.listen(companySettingsFormProvider, (previous, next) {
      if (next.saved && previous?.saved != true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(text.saved)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(text.title),
        actions: [
          TextButton.icon(
            onPressed: state.saving ? null : notifier.save,
            icon: state.saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(text.save),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  text.defaults,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  text.defaultsDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _ErrorBanner(message: state.errorMessage!),
                ],
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: cs.primaryContainer,
                              child: Icon(
                                Icons.calculate_outlined,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              text.generalBehavior,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(text.enableTaxes),
                          subtitle: Text(text.enableTaxesDescription),
                          value: state.form.taxesEnabled,
                          onChanged: (value) => notifier.update(
                            (current) => current.copyWith(taxesEnabled: value),
                          ),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(text.pricesIncludeTax),
                          subtitle: Text(text.pricesIncludeTaxDescription),
                          value: state.form.pricesIncludeTax,
                          onChanged: (value) => notifier.update(
                            (current) =>
                                current.copyWith(pricesIncludeTax: value),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          initialValue: state.form.taxRoundingMode,
                          decoration: InputDecoration(
                            labelText: text.roundingMode,
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.rounded_corner_outlined),
                          ),
                          items: [
                            DropdownMenuItem<int>(
                              value: 1,
                              child: Text(text.roundNormally),
                            ),
                            DropdownMenuItem<int>(
                              value: 2,
                              child: Text(text.roundDown),
                            ),
                            DropdownMenuItem<int>(
                              value: 3,
                              child: Text(text.roundUp),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              notifier.update(
                                (current) =>
                                    current.copyWith(taxRoundingMode: value),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: cs.secondaryContainer,
                              child: Icon(
                                Icons.percent_outlined,
                                color: cs.onSecondaryContainer,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              text.defaultRates,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final fields = [
                              _RateField(
                                label: text.defaultSalesTax,
                                value: state.form.defaultSalesTaxRate,
                                onChanged: (value) => notifier.update(
                                  (current) => current.copyWith(
                                    defaultSalesTaxRate:
                                        double.tryParse(value) ?? 0,
                                  ),
                                ),
                              ),
                              _RateField(
                                label: text.defaultPurchaseTax,
                                value: state.form.defaultPurchaseTaxRate,
                                onChanged: (value) => notifier.update(
                                  (current) => current.copyWith(
                                    defaultPurchaseTaxRate:
                                        double.tryParse(value) ?? 0,
                                  ),
                                ),
                              ),
                            ];
                            if (constraints.maxWidth < 720) {
                              return Column(
                                children: [
                                  fields[0],
                                  const SizedBox(height: 16),
                                  fields[1],
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(child: fields[0]),
                                const SizedBox(width: 16),
                                Expanded(child: fields[1]),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: state.form.taxRegistrationNumber ?? '',
                          decoration: InputDecoration(
                            labelText: text.taxRegistration,
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          onChanged: (value) => notifier.update(
                            (current) =>
                                current.copyWith(taxRegistrationNumber: value),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: cs.tertiaryContainer,
                              child: Icon(
                                Icons.account_balance_outlined,
                                color: cs.onTertiaryContainer,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              text.advancedLinks,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          text.advancedDescription,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ReadOnlyLink(
                          label: text.defaultSalesTaxCode,
                          value: state.form.defaultSalesTaxCodeId,
                        ),
                        const SizedBox(height: 12),
                        _ReadOnlyLink(
                          label: text.defaultPurchaseTaxCode,
                          value: state.form.defaultPurchaseTaxCodeId,
                        ),
                        const SizedBox(height: 12),
                        _ReadOnlyLink(
                          label: text.salesTaxPayable,
                          value: state.form.defaultSalesTaxPayableAccountId,
                        ),
                        const SizedBox(height: 12),
                        _ReadOnlyLink(
                          label: text.purchaseTaxReceivable,
                          value:
                              state.form.defaultPurchaseTaxReceivableAccountId,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: FilledButton.icon(
                    onPressed: state.saving ? null : notifier.save,
                    icon: state.saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(text.saveTaxSettings),
                  ),
                ),
              ],
            ),
    );
  }
}

class _RateField extends StatelessWidget {
  const _RateField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value.toString(),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.percent_outlined),
      ).copyWith(labelText: label),
      onChanged: onChanged,
    );
  }
}

class _ReadOnlyLink extends StatelessWidget {
  const _ReadOnlyLink({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      initialValue: value?.isNotEmpty == true
          ? value!
          : _TaxSettingsText.of(context).notLinked,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.link_outlined),
      ).copyWith(labelText: label),
    );
  }
}

class _TaxSettingsText {
  const _TaxSettingsText(this.ar);

  final bool ar;

  static _TaxSettingsText of(BuildContext context) =>
      _TaxSettingsText(Localizations.localeOf(context).languageCode == 'ar');

  String get saved =>
      ar ? 'تم حفظ إعدادات الضرائب بنجاح.' : 'Tax settings saved successfully.';
  String get title => ar ? 'إعدادات الضرائب' : 'Tax Settings';
  String get save => ar ? 'حفظ' : 'Save';
  String get defaults => ar ? 'افتراضات الضرائب' : 'Tax Defaults';
  String get defaultsDescription => ar
      ? 'اضبط سلوك ضريبة البيع والشراء الافتراضي المستخدم في المعاملات. يمكن ربط أكواد وحسابات الضرائب لاحقا.'
      : 'Configure default sales/purchase tax behavior used by transactions. Advanced tax codes and tax accounts can be linked later.';
  String get generalBehavior =>
      ar ? 'سلوك الضرائب العام' : 'General Tax Behavior';
  String get enableTaxes => ar ? 'تفعيل الضرائب' : 'Enable Taxes';
  String get enableTaxesDescription => ar
      ? 'إظهار حقول احتساب الضريبة الافتراضية داخل المعاملات.'
      : 'Turn on default tax calculation fields in transactions.';
  String get pricesIncludeTax =>
      ar ? 'الأسعار تشمل الضريبة' : 'Prices Include Tax';
  String get pricesIncludeTaxDescription => ar
      ? 'اعتبار الأسعار المدخلة شاملة للضريبة افتراضيا.'
      : 'Treat entered prices as tax-inclusive by default.';
  String get roundingMode => ar ? 'طريقة تقريب الضريبة' : 'Tax Rounding Mode';
  String get roundNormally => ar ? 'تقريب عادي' : 'Round normally';
  String get roundDown => ar ? 'تقريب لأسفل' : 'Round down';
  String get roundUp => ar ? 'تقريب لأعلى' : 'Round up';
  String get defaultRates => ar ? 'النسب الافتراضية' : 'Default Rates';
  String get defaultSalesTax =>
      ar ? 'نسبة ضريبة المبيعات الافتراضية %' : 'Default Sales Tax Rate %';
  String get defaultPurchaseTax =>
      ar ? 'نسبة ضريبة المشتريات الافتراضية %' : 'Default Purchase Tax Rate %';
  String get taxRegistration =>
      ar ? 'رقم التسجيل الضريبي' : 'Tax Registration Number';
  String get advancedLinks => ar ? 'الروابط المتقدمة' : 'Advanced Links';
  String get advancedDescription => ar
      ? 'ربط أكواد وحسابات الضرائب مدعوم في بيانات الخادم. سيتم إكمال محددات الاختيار بعد تثبيت تجربة أكواد الضرائب والحسابات.'
      : 'Tax code and tax account linking is supported by the backend payload. Dedicated selectors will be completed after Tax Codes and Accounts lookup UX is finalized.';
  String get defaultSalesTaxCode =>
      ar ? 'كود ضريبة المبيعات الافتراضي' : 'Default Sales Tax Code';
  String get defaultPurchaseTaxCode =>
      ar ? 'كود ضريبة المشتريات الافتراضي' : 'Default Purchase Tax Code';
  String get salesTaxPayable =>
      ar ? 'حساب ضريبة المبيعات المستحقة' : 'Sales Tax Payable Account';
  String get purchaseTaxReceivable =>
      ar ? 'حساب ضريبة المشتريات المستردة' : 'Purchase Tax Receivable Account';
  String get saveTaxSettings =>
      ar ? 'حفظ إعدادات الضرائب' : 'Save Tax Settings';
  String get notLinked => ar ? 'غير مربوط بعد' : 'Not linked yet';
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: cs.onErrorContainer)),
          ),
        ],
      ),
    );
  }
}
