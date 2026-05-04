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

    ref.listen(companySettingsFormProvider, (previous, next) {
      if (next.saved && previous?.saved != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tax settings saved successfully.')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tax Settings'),
        actions: [
          TextButton.icon(
            onPressed: state.saving ? null : notifier.save,
            icon: state.saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
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
                Text('Tax Defaults', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(
                  'Configure default sales/purchase tax behavior used by transactions. Advanced tax codes and tax accounts can be linked later.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
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
                              child: Icon(Icons.calculate_outlined, color: cs.onPrimaryContainer),
                            ),
                            const SizedBox(width: 12),
                            Text('General Tax Behavior', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Enable Taxes'),
                          subtitle: const Text('Turn on default tax calculation fields in transactions.'),
                          value: state.form.taxesEnabled,
                          onChanged: (value) => notifier.update((current) => current.copyWith(taxesEnabled: value)),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Prices Include Tax'),
                          subtitle: const Text('Treat entered prices as tax-inclusive by default.'),
                          value: state.form.pricesIncludeTax,
                          onChanged: (value) => notifier.update((current) => current.copyWith(pricesIncludeTax: value)),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          initialValue: state.form.taxRoundingMode,
                          decoration: const InputDecoration(
                            labelText: 'Tax Rounding Mode',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.rounded_corner_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('Round normally')),
                            DropdownMenuItem(value: 2, child: Text('Round down')),
                            DropdownMenuItem(value: 3, child: Text('Round up')),
                          ],
                          onChanged: (value) {
                            if (value != null) notifier.update((current) => current.copyWith(taxRoundingMode: value));
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
                              child: Icon(Icons.percent_outlined, color: cs.onSecondaryContainer),
                            ),
                            const SizedBox(width: 12),
                            Text('Default Rates', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final fields = [
                              _RateField(
                                label: 'Default Sales Tax Rate %',
                                value: state.form.defaultSalesTaxRate,
                                onChanged: (value) => notifier.update(
                                  (current) => current.copyWith(defaultSalesTaxRate: double.tryParse(value) ?? 0),
                                ),
                              ),
                              _RateField(
                                label: 'Default Purchase Tax Rate %',
                                value: state.form.defaultPurchaseTaxRate,
                                onChanged: (value) => notifier.update(
                                  (current) => current.copyWith(defaultPurchaseTaxRate: double.tryParse(value) ?? 0),
                                ),
                              ),
                            ];
                            if (constraints.maxWidth < 720) {
                              return Column(children: [fields[0], const SizedBox(height: 16), fields[1]]);
                            }
                            return Row(children: [Expanded(child: fields[0]), const SizedBox(width: 16), Expanded(child: fields[1])]);
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: state.form.taxRegistrationNumber ?? '',
                          decoration: const InputDecoration(
                            labelText: 'Tax Registration Number',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          onChanged: (value) => notifier.update((current) => current.copyWith(taxRegistrationNumber: value)),
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
                              child: Icon(Icons.account_balance_outlined, color: cs.onTertiaryContainer),
                            ),
                            const SizedBox(width: 12),
                            Text('Advanced Links', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tax code and tax account linking is supported by the backend payload. Dedicated selectors will be completed after Tax Codes and Accounts lookup UX is finalized.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
                        _ReadOnlyLink(label: 'Default Sales Tax Code', value: state.form.defaultSalesTaxCodeId),
                        const SizedBox(height: 12),
                        _ReadOnlyLink(label: 'Default Purchase Tax Code', value: state.form.defaultPurchaseTaxCodeId),
                        const SizedBox(height: 12),
                        _ReadOnlyLink(label: 'Sales Tax Payable Account', value: state.form.defaultSalesTaxPayableAccountId),
                        const SizedBox(height: 12),
                        _ReadOnlyLink(label: 'Purchase Tax Receivable Account', value: state.form.defaultPurchaseTaxReceivableAccountId),
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
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_outlined),
                    label: const Text('Save Tax Settings'),
                  ),
                ),
              ],
            ),
    );
  }
}

class _RateField extends StatelessWidget {
  const _RateField({required this.label, required this.value, required this.onChanged});

  final String label;
  final double value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value.toString(),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.percent_outlined)).copyWith(labelText: label),
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
      initialValue: value?.isNotEmpty == true ? value! : 'Not linked yet',
      decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.link_outlined)).copyWith(labelText: label),
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
      decoration: BoxDecoration(color: cs.errorContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: TextStyle(color: cs.onErrorContainer))),
        ],
      ),
    );
  }
}
