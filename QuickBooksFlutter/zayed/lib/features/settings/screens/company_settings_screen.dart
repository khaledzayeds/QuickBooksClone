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

    ref.listen(companySettingsFormProvider, (previous, next) {
      if (next.saved && previous?.saved != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company settings saved successfully.')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Settings'),
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
            label: const Text('Save'),
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
                  'Company Profile',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'These details are used on invoices, receipts, reports, taxes, and setup defaults.',
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
                  title: 'Basic Information',
                  icon: Icons.business_outlined,
                  children: [
                    _AppTextField(
                      label: 'Company Name *',
                      initialValue: state.form.companyName,
                      onChanged: (value) => notifier.update(
                        (current) => current.copyWith(companyName: value),
                      ),
                    ),
                    _AppTextField(
                      label: 'Legal Name',
                      initialValue: state.form.legalName ?? '',
                      onChanged: (value) => notifier.update(
                        (current) => current.copyWith(legalName: value),
                      ),
                    ),
                    _ResponsivePair(
                      first: _AppTextField(
                        label: 'Currency',
                        initialValue: state.form.currency,
                        textCapitalization: TextCapitalization.characters,
                        onChanged: (value) => notifier.update(
                          (current) => current.copyWith(currency: value),
                        ),
                      ),
                      second: _AppTextField(
                        label: 'Country',
                        initialValue: state.form.country,
                        textCapitalization: TextCapitalization.characters,
                        onChanged: (value) => notifier.update(
                          (current) => current.copyWith(country: value),
                        ),
                      ),
                    ),
                    _ResponsivePair(
                      first: _AppTextField(
                        label: 'Time Zone',
                        initialValue: state.form.timeZoneId,
                        onChanged: (value) => notifier.update(
                          (current) => current.copyWith(timeZoneId: value),
                        ),
                      ),
                      second: DropdownButtonFormField<String>(
                        initialValue: state.form.defaultLanguage,
                        decoration: const InputDecoration(
                          labelText: 'Default Language',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem<String>(
                            value: 'ar',
                            child: Text('Arabic'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'en',
                            child: Text('English'),
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
                  title: 'Contact & Address',
                  icon: Icons.contact_phone_outlined,
                  children: [
                    _ResponsivePair(
                      first: _AppTextField(
                        label: 'Email',
                        initialValue: state.form.email ?? '',
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (value) => notifier.update(
                          (current) => current.copyWith(email: value),
                        ),
                      ),
                      second: _AppTextField(
                        label: 'Phone',
                        initialValue: state.form.phone ?? '',
                        keyboardType: TextInputType.phone,
                        onChanged: (value) => notifier.update(
                          (current) => current.copyWith(phone: value),
                        ),
                      ),
                    ),
                    _AppTextField(
                      label: 'Address Line 1',
                      initialValue: state.form.addressLine1 ?? '',
                      onChanged: (value) => notifier.update(
                        (current) => current.copyWith(addressLine1: value),
                      ),
                    ),
                    _AppTextField(
                      label: 'Address Line 2',
                      initialValue: state.form.addressLine2 ?? '',
                      onChanged: (value) => notifier.update(
                        (current) => current.copyWith(addressLine2: value),
                      ),
                    ),
                    _ResponsiveTriple(
                      first: _AppTextField(
                        label: 'City',
                        initialValue: state.form.city ?? '',
                        onChanged: (value) => notifier.update(
                          (current) => current.copyWith(city: value),
                        ),
                      ),
                      second: _AppTextField(
                        label: 'Region',
                        initialValue: state.form.region ?? '',
                        onChanged: (value) => notifier.update(
                          (current) => current.copyWith(region: value),
                        ),
                      ),
                      third: _AppTextField(
                        label: 'Postal Code',
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
                  title: 'Fiscal Year & Taxes',
                  icon: Icons.calculate_outlined,
                  children: [
                    _ResponsivePair(
                      first: _AppTextField(
                        label: 'Fiscal Year Start Month',
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
                        label: 'Fiscal Year Start Day',
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
                      title: const Text('Taxes Enabled'),
                      subtitle: const Text(
                        'Enable sales/purchase tax defaults for transactions.',
                      ),
                      value: state.form.taxesEnabled,
                      onChanged: (value) => notifier.update(
                        (current) => current.copyWith(taxesEnabled: value),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Prices Include Tax'),
                      subtitle: const Text(
                        'Use tax-inclusive prices by default.',
                      ),
                      value: state.form.pricesIncludeTax,
                      onChanged: (value) => notifier.update(
                        (current) => current.copyWith(pricesIncludeTax: value),
                      ),
                    ),
                    _ResponsivePair(
                      first: _AppTextField(
                        label: 'Default Sales Tax Rate %',
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
                        label: 'Default Purchase Tax Rate %',
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
                      label: 'Tax Registration Number',
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
                    label: const Text('Save Company Settings'),
                  ),
                ),
              ],
            ),
    );
  }
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
