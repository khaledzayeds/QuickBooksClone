import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/company_settings_form_provider.dart';

class CompanySettingsScreen extends ConsumerWidget {
  const CompanySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(companySettingsFormProvider);
    final notifier = ref.read(companySettingsFormProvider.notifier);
    final theme = Theme.of(context);
    final text = _CompanySettingsText.of(context);

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
                  text.profile,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  text.profileDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _ErrorBanner(message: state.errorMessage!),
                ],
                const SizedBox(height: 24),
                _SectionCard(
                  title: text.basicInfo,
                  icon: Icons.business_outlined,
                  children: [
                    _AppTextField(
                      label: text.companyName,
                      initialValue: state.form.companyName,
                      onChanged: (value) => notifier.update(
                        (current) => current.copyWith(companyName: value),
                      ),
                    ),
                    _AppTextField(
                      label: text.legalName,
                      initialValue: state.form.legalName ?? '',
                      onChanged: (value) => notifier.update(
                        (current) => current.copyWith(legalName: value),
                      ),
                    ),
                    _ResponsivePair(
                      first: _AppTextField(
                        label: text.currency,
                        initialValue: state.form.currency,
                        textCapitalization: TextCapitalization.characters,
                        onChanged: (value) => notifier.update(
                          (current) => current.copyWith(currency: value),
                        ),
                      ),
                      second: _AppTextField(
                        label: text.country,
                        initialValue: state.form.country,
                        textCapitalization: TextCapitalization.characters,
                        onChanged: (value) => notifier.update(
                          (current) => current.copyWith(country: value),
                        ),
                      ),
                    ),
                    _ResponsivePair(
                      first: _AppTextField(
                        label: text.timeZone,
                        initialValue: state.form.timeZoneId,
                        onChanged: (value) => notifier.update(
                          (current) => current.copyWith(timeZoneId: value),
                        ),
                      ),
                      second: DropdownButtonFormField<String>(
                        initialValue: state.form.defaultLanguage,
                        decoration: InputDecoration(
                          labelText: text.defaultLanguage,
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: 'ar',
                            child: Text(text.arabic),
                          ),
                          DropdownMenuItem<String>(
                            value: 'en',
                            child: Text(text.english),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            notifier.update(
                              (current) =>
                                  current.copyWith(defaultLanguage: value),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: text.contactAddress,
                  icon: Icons.contact_phone_outlined,
                  children: [
                    _ResponsivePair(
                      first: _AppTextField(
                        label: text.email,
                        initialValue: state.form.email ?? '',
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (value) => notifier.update(
                          (current) => current.copyWith(email: value),
                        ),
                      ),
                      second: _AppTextField(
                        label: text.phone,
                        initialValue: state.form.phone ?? '',
                        keyboardType: TextInputType.phone,
                        onChanged: (value) => notifier.update(
                          (current) => current.copyWith(phone: value),
                        ),
                      ),
                    ),
                    _AppTextField(
                      label: text.addressLine1,
                      initialValue: state.form.addressLine1 ?? '',
                      onChanged: (value) => notifier.update(
                        (current) => current.copyWith(addressLine1: value),
                      ),
                    ),
                    _AppTextField(
                      label: text.addressLine2,
                      initialValue: state.form.addressLine2 ?? '',
                      onChanged: (value) => notifier.update(
                        (current) => current.copyWith(addressLine2: value),
                      ),
                    ),
                    _ResponsiveTriple(
                      first: _AppTextField(
                        label: text.city,
                        initialValue: state.form.city ?? '',
                        onChanged: (value) => notifier.update(
                          (current) => current.copyWith(city: value),
                        ),
                      ),
                      second: _AppTextField(
                        label: text.region,
                        initialValue: state.form.region ?? '',
                        onChanged: (value) => notifier.update(
                          (current) => current.copyWith(region: value),
                        ),
                      ),
                      third: _AppTextField(
                        label: text.postalCode,
                        initialValue: state.form.postalCode ?? '',
                        onChanged: (value) => notifier.update(
                          (current) => current.copyWith(postalCode: value),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: text.fiscalTaxes,
                  icon: Icons.calculate_outlined,
                  children: [
                    _ResponsivePair(
                      first: _AppTextField(
                        label: text.fiscalMonth,
                        initialValue: state.form.fiscalYearStartMonth
                            .toString(),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => notifier.update(
                          (current) => current.copyWith(
                            fiscalYearStartMonth: int.tryParse(value) ?? 1,
                          ),
                        ),
                      ),
                      second: _AppTextField(
                        label: text.fiscalDay,
                        initialValue: state.form.fiscalYearStartDay.toString(),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => notifier.update(
                          (current) => current.copyWith(
                            fiscalYearStartDay: int.tryParse(value) ?? 1,
                          ),
                        ),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(text.taxesEnabled),
                      subtitle: Text(text.taxesEnabledDescription),
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
                        (current) => current.copyWith(pricesIncludeTax: value),
                      ),
                    ),
                    _ResponsivePair(
                      first: _AppTextField(
                        label: text.defaultSalesTax,
                        initialValue: state.form.defaultSalesTaxRate.toString(),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (value) => notifier.update(
                          (current) => current.copyWith(
                            defaultSalesTaxRate: double.tryParse(value) ?? 0,
                          ),
                        ),
                      ),
                      second: _AppTextField(
                        label: text.defaultPurchaseTax,
                        initialValue: state.form.defaultPurchaseTaxRate
                            .toString(),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (value) => notifier.update(
                          (current) => current.copyWith(
                            defaultPurchaseTaxRate: double.tryParse(value) ?? 0,
                          ),
                        ),
                      ),
                    ),
                    _AppTextField(
                      label: text.taxRegistration,
                      initialValue: state.form.taxRegistrationNumber ?? '',
                      onChanged: (value) => notifier.update(
                        (current) =>
                            current.copyWith(taxRegistrationNumber: value),
                      ),
                    ),
                  ],
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
                    label: Text(text.saveCompanySettings),
                  ),
                ),
              ],
            ),
    );
  }
}

class _CompanySettingsText {
  const _CompanySettingsText(this.ar);

  final bool ar;

  static _CompanySettingsText of(BuildContext context) => _CompanySettingsText(
    Localizations.localeOf(context).languageCode == 'ar',
  );

  String get saved => ar
      ? 'تم حفظ إعدادات الشركة بنجاح.'
      : 'Company settings saved successfully.';
  String get title => ar ? 'إعدادات الشركة' : 'Company Settings';
  String get save => ar ? 'حفظ' : 'Save';
  String get profile => ar ? 'ملف الشركة' : 'Company Profile';
  String get profileDescription => ar
      ? 'تستخدم هذه البيانات في الفواتير والإيصالات والتقارير والضرائب وإعدادات البداية.'
      : 'These details are used on invoices, receipts, reports, taxes, and setup defaults.';
  String get basicInfo => ar ? 'البيانات الأساسية' : 'Basic Information';
  String get companyName => ar ? 'اسم الشركة *' : 'Company Name *';
  String get legalName => ar ? 'الاسم القانوني' : 'Legal Name';
  String get currency => ar ? 'العملة' : 'Currency';
  String get country => ar ? 'الدولة' : 'Country';
  String get timeZone => ar ? 'المنطقة الزمنية' : 'Time Zone';
  String get defaultLanguage => ar ? 'اللغة الافتراضية' : 'Default Language';
  String get arabic => ar ? 'العربية' : 'Arabic';
  String get english => ar ? 'الإنجليزية' : 'English';
  String get contactAddress =>
      ar ? 'بيانات التواصل والعنوان' : 'Contact & Address';
  String get email => ar ? 'البريد الإلكتروني' : 'Email';
  String get phone => ar ? 'الهاتف' : 'Phone';
  String get addressLine1 => ar ? 'العنوان 1' : 'Address Line 1';
  String get addressLine2 => ar ? 'العنوان 2' : 'Address Line 2';
  String get city => ar ? 'المدينة' : 'City';
  String get region => ar ? 'المنطقة' : 'Region';
  String get postalCode => ar ? 'الرمز البريدي' : 'Postal Code';
  String get fiscalTaxes =>
      ar ? 'السنة المالية والضرائب' : 'Fiscal Year & Taxes';
  String get fiscalMonth =>
      ar ? 'شهر بداية السنة المالية' : 'Fiscal Year Start Month';
  String get fiscalDay =>
      ar ? 'يوم بداية السنة المالية' : 'Fiscal Year Start Day';
  String get taxesEnabled => ar ? 'تفعيل الضرائب' : 'Taxes Enabled';
  String get taxesEnabledDescription => ar
      ? 'تفعيل افتراضات ضريبة البيع والشراء في المعاملات.'
      : 'Enable sales/purchase tax defaults for transactions.';
  String get pricesIncludeTax =>
      ar ? 'الأسعار تشمل الضريبة' : 'Prices Include Tax';
  String get pricesIncludeTaxDescription => ar
      ? 'استخدام الأسعار الشاملة للضريبة كإعداد افتراضي.'
      : 'Use tax-inclusive prices by default.';
  String get defaultSalesTax =>
      ar ? 'نسبة ضريبة المبيعات الافتراضية %' : 'Default Sales Tax Rate %';
  String get defaultPurchaseTax =>
      ar ? 'نسبة ضريبة المشتريات الافتراضية %' : 'Default Purchase Tax Rate %';
  String get taxRegistration =>
      ar ? 'رقم التسجيل الضريبي' : 'Tax Registration Number';
  String get saveCompanySettings =>
      ar ? 'حفظ إعدادات الشركة' : 'Save Company Settings';
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final spacedChildren = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i != children.length - 1) {
        spacedChildren.add(const SizedBox(height: 16));
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: cs.primaryContainer,
                  child: Icon(icon, color: cs.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...spacedChildren,
          ],
        ),
      ),
    );
  }
}

class _AppTextField extends StatelessWidget {
  const _AppTextField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }
}

class _ResponsivePair extends StatelessWidget {
  const _ResponsivePair({required this.first, required this.second});
  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(children: [first, const SizedBox(height: 16), second]);
        }
        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: 16),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _ResponsiveTriple extends StatelessWidget {
  const _ResponsiveTriple({
    required this.first,
    required this.second,
    required this.third,
  });
  final Widget first;
  final Widget second;
  final Widget third;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            children: [
              first,
              const SizedBox(height: 16),
              second,
              const SizedBox(height: 16),
              third,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: 16),
            Expanded(child: second),
            const SizedBox(width: 16),
            Expanded(child: third),
          ],
        );
      },
    );
  }
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
