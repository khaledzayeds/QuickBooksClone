import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../companies/providers/company_registry_provider.dart';
import '../data/models/setup_models.dart';
import '../providers/setup_provider.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameCtrl = TextEditingController(text: 'LedgerFlow Company');
  final _currencyCtrl = TextEditingController(text: 'EGP');
  final _countryCtrl = TextEditingController(text: 'Egypt');
  final _timeZoneCtrl = TextEditingController(text: 'Africa/Cairo');
  final _languageCtrl = TextEditingController(text: 'ar');
  final _legalNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _fiscalMonthCtrl = TextEditingController(text: '1');
  final _fiscalDayCtrl = TextEditingController(text: '1');
  final _salesTaxRateCtrl = TextEditingController(text: '14');
  final _purchaseTaxRateCtrl = TextEditingController(text: '14');
  final _warehouseCtrl = TextEditingController(text: 'Main Warehouse');
  final _adminUserCtrl = TextEditingController(text: 'admin');
  final _adminNameCtrl = TextEditingController(text: 'System Administrator');
  final _adminEmailCtrl = TextEditingController();
  final _adminSecretCtrl = TextEditingController();
  final _confirmSecretCtrl = TextEditingController();

  int _step = 0;
  bool _saving = false;
  bool _obscureSecret = true;
  bool _taxesEnabled = true;
  bool _pricesIncludeTax = false;
  bool _inventoryEnabled = true;
  bool _servicesEnabled = true;
  String? _errorMessage;

  static const _steps = [
    'Company profile',
    'Fiscal year',
    'Tax & features',
    'Admin account',
    'Finish',
  ];

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _currencyCtrl.dispose();
    _countryCtrl.dispose();
    _timeZoneCtrl.dispose();
    _languageCtrl.dispose();
    _legalNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _fiscalMonthCtrl.dispose();
    _fiscalDayCtrl.dispose();
    _salesTaxRateCtrl.dispose();
    _purchaseTaxRateCtrl.dispose();
    _warehouseCtrl.dispose();
    _adminUserCtrl.dispose();
    _adminNameCtrl.dispose();
    _adminEmailCtrl.dispose();
    _adminSecretCtrl.dispose();
    _confirmSecretCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    final request = InitializeCompanyRequest(
      companyName: _companyNameCtrl.text.trim(),
      currency: _currencyCtrl.text.trim(),
      country: _countryCtrl.text.trim(),
      timeZoneId: _timeZoneCtrl.text.trim(),
      defaultLanguage: _languageCtrl.text.trim(),
      legalName: _emptyToNull(_legalNameCtrl.text),
      email: _emptyToNull(_emailCtrl.text),
      phone: _emptyToNull(_phoneCtrl.text),
      fiscalYearStartMonth: _intValue(_fiscalMonthCtrl.text, fallback: 1),
      fiscalYearStartDay: _intValue(_fiscalDayCtrl.text, fallback: 1),
      taxesEnabled: _taxesEnabled,
      pricesIncludeTax: _pricesIncludeTax,
      defaultSalesTaxRate: _doubleValue(_salesTaxRateCtrl.text),
      defaultPurchaseTaxRate: _doubleValue(_purchaseTaxRateCtrl.text),
      inventoryEnabled: _inventoryEnabled,
      defaultWarehouseName: _inventoryEnabled
          ? _emptyToNull(_warehouseCtrl.text)
          : null,
      servicesEnabled: _servicesEnabled,
      adminUserName: _adminUserCtrl.text.trim(),
      adminDisplayName: _adminNameCtrl.text.trim(),
      adminEmail: _emptyToNull(_adminEmailCtrl.text),
      initialAdminSecret: _adminSecretCtrl.text,
    );

    try {
      final error = await ref
          .read(setupProvider.notifier)
          .initializeCompany(request);
      if (!mounted) return;

      if (error == null) {
        final refreshError = await ref
            .read(setupProvider.notifier)
            .refreshStatus();
        if (!mounted) return;

        final setup = ref.read(setupProvider).value;
        if (refreshError == null && setup?.isInitialized == true) {
          context.go(AppRoutes.login);
          return;
        }

        setState(() {
          _saving = false;
          _errorMessage =
              refreshError?.message ??
              'Setup completed, but LedgerFlow could not confirm initialization status.';
        });
        return;
      }

      setState(() {
        _saving = false;
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = 'Company setup failed: $error';
      });
    }
  }

  void _next() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _errorMessage = null;
      if (_step < _steps.length - 1) {
        _step += 1;
      }
    });
  }

  void _back() {
    setState(() {
      _errorMessage = null;
      if (_step > 0) {
        _step -= 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final registryState = ref.watch(companyRegistryProvider);
    final activeCompany = registryState.value?.activeCompany;
    if (activeCompany == null) {
      return _ChooseCompanyFileScreen(
        onChoose: () => context.go(AppRoutes.companies),
      );
    }

    final setupState = ref.watch(setupProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: setupState.when(
              loading: () => const _SetupLoadingCard(),
              error: (error, _) => _SetupErrorCard(
                message: error.toString(),
                onChooseCompany: () => context.go(AppRoutes.companies),
                onRetry: () => ref.read(setupProvider.notifier).refreshStatus(),
              ),
              data: (status) {
                if (status.isInitialized) {
                  return _AlreadyInitializedCard(
                    companyName: status.companyName,
                    onContinue: () => context.go(AppRoutes.login),
                  );
                }

                return Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.business_center_outlined,
                            size: 42,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Company Setup',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: cs.primary,
                                      ),
                                ),
                                Text(
                                  activeCompany.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _saving
                                ? null
                                : () => context.go(AppRoutes.companies),
                            icon: const Icon(Icons.folder_open_outlined),
                            label: const Text('Choose Company File'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (_errorMessage != null) ...[
                        _ErrorBanner(message: _errorMessage!),
                        const SizedBox(height: 14),
                      ],
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 820;
                          final sidebar = _StepRail(
                            steps: _steps,
                            currentStep: _step,
                            onStepSelected: _saving
                                ? null
                                : (step) {
                                    if (!(_formKey.currentState?.validate() ??
                                        false)) {
                                      return;
                                    }
                                    setState(() => _step = step);
                                  },
                          );
                          final content = _WizardPanel(
                            title: _steps[_step],
                            child: _buildStep(context),
                          );

                          if (!wide) {
                            return Column(
                              children: [
                                sidebar,
                                const SizedBox(height: 14),
                                content,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: 230, child: sidebar),
                              const SizedBox(width: 16),
                              Expanded(child: content),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: _saving || _step == 0 ? null : _back,
                            child: const Text('Back'),
                          ),
                          const Spacer(),
                          if (_step < _steps.length - 1)
                            FilledButton(
                              onPressed: _saving ? null : _next,
                              child: const Text('Next'),
                            )
                          else
                            FilledButton.icon(
                              onPressed: _saving ? null : _submit,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.check_circle_outline),
                              label: const Text('Finish Setup'),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    return switch (_step) {
      0 => _CompanyProfileStep(
        companyNameCtrl: _companyNameCtrl,
        legalNameCtrl: _legalNameCtrl,
        countryCtrl: _countryCtrl,
        currencyCtrl: _currencyCtrl,
        timeZoneCtrl: _timeZoneCtrl,
        languageCtrl: _languageCtrl,
        emailCtrl: _emailCtrl,
        phoneCtrl: _phoneCtrl,
      ),
      1 => _FiscalYearStep(
        fiscalMonthCtrl: _fiscalMonthCtrl,
        fiscalDayCtrl: _fiscalDayCtrl,
      ),
      2 => _TaxFeaturesStep(
        taxesEnabled: _taxesEnabled,
        pricesIncludeTax: _pricesIncludeTax,
        inventoryEnabled: _inventoryEnabled,
        servicesEnabled: _servicesEnabled,
        salesTaxRateCtrl: _salesTaxRateCtrl,
        purchaseTaxRateCtrl: _purchaseTaxRateCtrl,
        warehouseCtrl: _warehouseCtrl,
        onTaxesChanged: (value) => setState(() => _taxesEnabled = value),
        onPricesIncludeTaxChanged: (value) =>
            setState(() => _pricesIncludeTax = value),
        onInventoryChanged: (value) =>
            setState(() => _inventoryEnabled = value),
        onServicesChanged: (value) => setState(() => _servicesEnabled = value),
      ),
      3 => _AdminStep(
        adminUserCtrl: _adminUserCtrl,
        adminNameCtrl: _adminNameCtrl,
        adminEmailCtrl: _adminEmailCtrl,
        adminSecretCtrl: _adminSecretCtrl,
        confirmSecretCtrl: _confirmSecretCtrl,
        obscureSecret: _obscureSecret,
        onToggleSecret: () => setState(() => _obscureSecret = !_obscureSecret),
      ),
      _ => _ReviewStep(
        companyName: _companyNameCtrl.text.trim(),
        currency: _currencyCtrl.text.trim(),
        fiscalYear:
            '${_fiscalMonthCtrl.text.trim()}/${_fiscalDayCtrl.text.trim()}',
        taxesEnabled: _taxesEnabled,
        inventoryEnabled: _inventoryEnabled,
        servicesEnabled: _servicesEnabled,
        adminUser: _adminUserCtrl.text.trim(),
      ),
    };
  }

  static String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int _intValue(String value, {required int fallback}) =>
      int.tryParse(value.trim()) ?? fallback;

  static double _doubleValue(String value) =>
      double.tryParse(value.trim()) ?? 0;
}

class _CompanyProfileStep extends StatelessWidget {
  const _CompanyProfileStep({
    required this.companyNameCtrl,
    required this.legalNameCtrl,
    required this.countryCtrl,
    required this.currencyCtrl,
    required this.timeZoneCtrl,
    required this.languageCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
  });

  final TextEditingController companyNameCtrl;
  final TextEditingController legalNameCtrl;
  final TextEditingController countryCtrl;
  final TextEditingController currencyCtrl;
  final TextEditingController timeZoneCtrl;
  final TextEditingController languageCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TextField(
          controller: companyNameCtrl,
          label: 'Company name',
          icon: Icons.apartment,
          isRequired: true,
        ),
        _TextField(
          controller: legalNameCtrl,
          label: 'Legal name',
          icon: Icons.badge_outlined,
        ),
        _TwoColumns(
          left: _TextField(
            controller: countryCtrl,
            label: 'Country',
            icon: Icons.public_outlined,
            isRequired: true,
          ),
          right: _TextField(
            controller: currencyCtrl,
            label: 'Currency',
            icon: Icons.payments_outlined,
            isRequired: true,
          ),
        ),
        _TwoColumns(
          left: _TextField(
            controller: timeZoneCtrl,
            label: 'Time zone',
            icon: Icons.schedule_outlined,
            isRequired: true,
          ),
          right: _TextField(
            controller: languageCtrl,
            label: 'Default language',
            icon: Icons.language_outlined,
            isRequired: true,
          ),
        ),
        _TwoColumns(
          left: _TextField(
            controller: emailCtrl,
            label: 'Company email',
            icon: Icons.email_outlined,
          ),
          right: _TextField(
            controller: phoneCtrl,
            label: 'Company phone',
            icon: Icons.phone_outlined,
          ),
        ),
      ],
    );
  }
}

class _FiscalYearStep extends StatelessWidget {
  const _FiscalYearStep({
    required this.fiscalMonthCtrl,
    required this.fiscalDayCtrl,
  });

  final TextEditingController fiscalMonthCtrl;
  final TextEditingController fiscalDayCtrl;

  @override
  Widget build(BuildContext context) {
    return _TwoColumns(
      left: _TextField(
        controller: fiscalMonthCtrl,
        label: 'Fiscal year start month',
        icon: Icons.calendar_month_outlined,
        isRequired: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (value) => _validateRange(value, 'Month', 1, 12),
      ),
      right: _TextField(
        controller: fiscalDayCtrl,
        label: 'Fiscal year start day',
        icon: Icons.event_outlined,
        isRequired: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (value) => _validateRange(value, 'Day', 1, 31),
      ),
    );
  }
}

class _TaxFeaturesStep extends StatelessWidget {
  const _TaxFeaturesStep({
    required this.taxesEnabled,
    required this.pricesIncludeTax,
    required this.inventoryEnabled,
    required this.servicesEnabled,
    required this.salesTaxRateCtrl,
    required this.purchaseTaxRateCtrl,
    required this.warehouseCtrl,
    required this.onTaxesChanged,
    required this.onPricesIncludeTaxChanged,
    required this.onInventoryChanged,
    required this.onServicesChanged,
  });

  final bool taxesEnabled;
  final bool pricesIncludeTax;
  final bool inventoryEnabled;
  final bool servicesEnabled;
  final TextEditingController salesTaxRateCtrl;
  final TextEditingController purchaseTaxRateCtrl;
  final TextEditingController warehouseCtrl;
  final ValueChanged<bool> onTaxesChanged;
  final ValueChanged<bool> onPricesIncludeTaxChanged;
  final ValueChanged<bool> onInventoryChanged;
  final ValueChanged<bool> onServicesChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: taxesEnabled,
          onChanged: onTaxesChanged,
          title: const Text('Taxes enabled'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: pricesIncludeTax,
          onChanged: taxesEnabled ? onPricesIncludeTaxChanged : null,
          title: const Text('Prices include tax'),
        ),
        _TwoColumns(
          left: _TextField(
            controller: salesTaxRateCtrl,
            label: 'Default sales tax rate',
            icon: Icons.percent_outlined,
            enabled: taxesEnabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: taxesEnabled
                ? (value) => _validateDecimalRange(value, 'Sales tax', 0, 100)
                : null,
          ),
          right: _TextField(
            controller: purchaseTaxRateCtrl,
            label: 'Default purchase tax rate',
            icon: Icons.percent_outlined,
            enabled: taxesEnabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: taxesEnabled
                ? (value) =>
                      _validateDecimalRange(value, 'Purchase tax', 0, 100)
                : null,
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: inventoryEnabled,
          onChanged: onInventoryChanged,
          title: const Text('Inventory enabled'),
        ),
        _TextField(
          controller: warehouseCtrl,
          label: 'Default warehouse name',
          icon: Icons.warehouse_outlined,
          enabled: inventoryEnabled,
          isRequired: inventoryEnabled,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: servicesEnabled,
          onChanged: onServicesChanged,
          title: const Text('Services enabled'),
        ),
      ],
    );
  }
}

class _AdminStep extends StatelessWidget {
  const _AdminStep({
    required this.adminUserCtrl,
    required this.adminNameCtrl,
    required this.adminEmailCtrl,
    required this.adminSecretCtrl,
    required this.confirmSecretCtrl,
    required this.obscureSecret,
    required this.onToggleSecret,
  });

  final TextEditingController adminUserCtrl;
  final TextEditingController adminNameCtrl;
  final TextEditingController adminEmailCtrl;
  final TextEditingController adminSecretCtrl;
  final TextEditingController confirmSecretCtrl;
  final bool obscureSecret;
  final VoidCallback onToggleSecret;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TwoColumns(
          left: _TextField(
            controller: adminUserCtrl,
            label: 'Username',
            icon: Icons.person_outline,
            isRequired: true,
          ),
          right: _TextField(
            controller: adminNameCtrl,
            label: 'Display name',
            icon: Icons.badge_outlined,
            isRequired: true,
          ),
        ),
        _TextField(
          controller: adminEmailCtrl,
          label: 'Admin email',
          icon: Icons.alternate_email,
        ),
        TextFormField(
          controller: adminSecretCtrl,
          obscureText: obscureSecret,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(
                obscureSecret
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: onToggleSecret,
            ),
          ),
          validator: (value) {
            if (value == null || value.length < 8) {
              return 'Password must be at least 8 characters.';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: confirmSecretCtrl,
          obscureText: obscureSecret,
          decoration: const InputDecoration(
            labelText: 'Confirm password',
            prefixIcon: Icon(Icons.lock_reset_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value != adminSecretCtrl.text) {
              return 'Passwords do not match.';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.companyName,
    required this.currency,
    required this.fiscalYear,
    required this.taxesEnabled,
    required this.inventoryEnabled,
    required this.servicesEnabled,
    required this.adminUser,
  });

  final String companyName;
  final String currency;
  final String fiscalYear;
  final bool taxesEnabled;
  final bool inventoryEnabled;
  final bool servicesEnabled;
  final String adminUser;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ReviewRow(label: 'Company', value: companyName),
        _ReviewRow(label: 'Currency', value: currency),
        _ReviewRow(label: 'Fiscal year starts', value: fiscalYear),
        _ReviewRow(label: 'Taxes', value: taxesEnabled ? 'Enabled' : 'Off'),
        _ReviewRow(
          label: 'Inventory',
          value: inventoryEnabled ? 'Enabled' : 'Off',
        ),
        _ReviewRow(
          label: 'Services',
          value: servicesEnabled ? 'Enabled' : 'Off',
        ),
        _ReviewRow(label: 'Admin user', value: adminUser),
      ],
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.isRequired = false,
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isRequired;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator:
            validator ??
            (isRequired
                ? (value) => value == null || value.trim().isEmpty
                      ? '$label is required.'
                      : null
                : null),
      ),
    );
  }
}

class _TwoColumns extends StatelessWidget {
  const _TwoColumns({required this.left, required this.right});
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Column(children: [left, right]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 14),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _StepRail extends StatelessWidget {
  const _StepRail({
    required this.steps,
    required this.currentStep,
    required this.onStepSelected,
  });

  final List<String> steps;
  final int currentStep;
  final ValueChanged<int>? onStepSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Setup Progress',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: (currentStep + 1) / steps.length),
            const SizedBox(height: 12),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onStepSelected == null
                      ? null
                      : () => onStepSelected!(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: i == currentStep
                          ? cs.primaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          i < currentStep
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 18,
                          color: i == currentStep ? cs.primary : cs.outline,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            steps[i],
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: i == currentStep
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WizardPanel extends StatelessWidget {
  const _WizardPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChooseCompanyFileScreen extends StatelessWidget {
  const _ChooseCompanyFileScreen({required this.onChoose});

  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.folder_open_outlined, size: 44),
                const SizedBox(height: 12),
                Text(
                  'Choose a company file',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onChoose,
                  icon: const Icon(Icons.business_outlined),
                  label: const Text('Choose Company File'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupLoadingCard extends StatelessWidget {
  const _SetupLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 14),
            Text('Checking setup status...'),
          ],
        ),
      ),
    );
  }
}

class _SetupErrorCard extends StatelessWidget {
  const _SetupErrorCard({
    required this.message,
    required this.onRetry,
    required this.onChooseCompany,
  });
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onChooseCompany;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 42),
            const SizedBox(height: 12),
            Text(
              'Cannot confirm setup status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: onChooseCompany,
                  icon: const Icon(Icons.folder_open_outlined),
                  label: const Text('Choose Company File'),
                ),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlreadyInitializedCard extends StatelessWidget {
  const _AlreadyInitializedCard({
    required this.companyName,
    required this.onContinue,
  });
  final String? companyName;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_outlined, size: 42),
            const SizedBox(height: 12),
            Text(
              companyName ?? 'Company is ready',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onContinue,
              child: const Text('Continue to Login'),
            ),
          ],
        ),
      ),
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: cs.onErrorContainer)),
          ),
        ],
      ),
    );
  }
}

String? _validateRange(String? value, String label, int min, int max) {
  final number = int.tryParse(value?.trim() ?? '');
  if (number == null || number < min || number > max) {
    return '$label must be between $min and $max.';
  }
  return null;
}

String? _validateDecimalRange(String? value, String label, num min, num max) {
  final number = double.tryParse(value?.trim() ?? '');
  if (number == null || number < min || number > max) {
    return '$label must be between $min and $max.';
  }
  return null;
}
