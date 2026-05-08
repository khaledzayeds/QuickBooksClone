import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../data/models/setup_models.dart';
import '../providers/setup_provider.dart';

class SetupWizardScreen extends ConsumerStatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  ConsumerState<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends ConsumerState<SetupWizardScreen> {
  int _currentStep = 0;

  static const _steps = [
    _WizardStepData(
      title: 'Start Mode',
      subtitle: 'Choose how this customer will start: create a new company, restore a backup, connect to an existing server, or open a demo company.',
      icon: Icons.rocket_launch_outlined,
      route: null,
      status: 'Ready',
      kind: _WizardStepKind.startMode,
    ),
    _WizardStepData(
      title: 'Connection',
      subtitle: 'Choose Local, LAN, Hosted, or Custom API endpoint.',
      icon: Icons.language_outlined,
      route: AppRoutes.connectionSettings,
      status: 'Ready',
    ),
    _WizardStepData(
      title: 'Create Company',
      subtitle: 'Create the company profile and first administrator user.',
      icon: Icons.business_outlined,
      route: null,
      status: 'Ready',
      kind: _WizardStepKind.initializeCompany,
    ),
    _WizardStepData(
      title: 'Tax Defaults',
      subtitle: 'Configure tax behavior, default tax rates, rounding, and future tax account links.',
      icon: Icons.calculate_outlined,
      route: AppRoutes.taxSettings,
      status: 'Ready',
    ),
    _WizardStepData(
      title: 'Default Accounts',
      subtitle: 'Seed or review chart of accounts required for posting transactions.',
      icon: Icons.account_tree_outlined,
      route: AppRoutes.chartOfAccounts,
      status: 'Ready',
      kind: _WizardStepKind.defaultAccounts,
    ),
    _WizardStepData(
      title: 'Users & Permissions',
      subtitle: 'Review users, roles, and permissions after first admin is created.',
      icon: Icons.admin_panel_settings_outlined,
      route: AppRoutes.usersPermissions,
      status: 'Partial',
    ),
    _WizardStepData(
      title: 'Backup',
      subtitle: 'Review database backup status and prepare backup/restore operations.',
      icon: Icons.backup_outlined,
      route: AppRoutes.backupSettings,
      status: 'Ready',
    ),
    _WizardStepData(
      title: 'Printing',
      subtitle: 'Configure A4 invoices, thermal receipts, branding, QR, tax summary, and print behavior.',
      icon: Icons.print_outlined,
      route: AppRoutes.printingSettings,
      status: 'Ready',
    ),
    _WizardStepData(
      title: 'Finish',
      subtitle: 'Review setup status and start using LedgerFlow.',
      icon: Icons.flag_outlined,
      route: AppRoutes.dashboard,
      status: 'Ready',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = _steps[_currentStep];
    final setupState = ref.watch(setupProvider);

    ref.listen(setupProvider, (previous, next) {
      if (next.successMessage != null && previous?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.successMessage!)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Wizard'),
        actions: [
          IconButton(
            tooltip: 'Refresh setup status',
            onPressed: () => ref.read(setupProvider.notifier).loadStatus(),
            icon: const Icon(Icons.refresh),
          ),
          TextButton.icon(
            onPressed: () => context.go(AppRoutes.settings),
            icon: const Icon(Icons.close),
            label: const Text('Exit'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 980;
          return wide
              ? Row(
                  children: [
                    SizedBox(width: 360, child: _StepRail(currentStep: _currentStep, onStepSelected: _goToStep)),
                    const VerticalDivider(width: 1),
                    Expanded(child: _StepDetails(step: current, index: _currentStep, total: _steps.length, onBack: _back, onNext: _next, setupState: setupState, setupNotifier: ref.read(setupProvider.notifier))),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text('First-run setup', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text(
                      'Prepare LedgerFlow for Solo, Network, or Hosted use. Start by choosing whether the customer needs a new company, restore, existing server, or demo company.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),
                    _StepRail(currentStep: _currentStep, onStepSelected: _goToStep, compact: true),
                    const SizedBox(height: 24),
                    _StepDetails(step: current, index: _currentStep, total: _steps.length, onBack: _back, onNext: _next, setupState: setupState, setupNotifier: ref.read(setupProvider.notifier)),
                  ],
                );
        },
      ),
    );
  }

  void _goToStep(int index) => setState(() => _currentStep = index);
  void _back() => setState(() => _currentStep = (_currentStep - 1).clamp(0, _steps.length - 1));
  void _next() => setState(() => _currentStep = (_currentStep + 1).clamp(0, _steps.length - 1));
}

class _StepRail extends StatelessWidget {
  const _StepRail({required this.currentStep, required this.onStepSelected, this.compact = false});

  final int currentStep;
  final ValueChanged<int> onStepSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      child: ListView.separated(
        shrinkWrap: compact,
        physics: compact ? const NeverScrollableScrollPhysics() : null,
        padding: const EdgeInsets.all(16),
        itemCount: _SetupWizardScreenState._steps.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final step = _SetupWizardScreenState._steps[index];
          final selected = index == currentStep;
          final cs = theme.colorScheme;

          return Card(
            elevation: selected ? 2 : 0,
            color: selected ? cs.primaryContainer : null,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onStepSelected(index),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: selected ? cs.primary : cs.secondaryContainer,
                      child: Icon(step.icon, color: selected ? cs.onPrimary : cs.onSecondaryContainer),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(step.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 3),
                          Text(step.status, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    if (selected) const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StepDetails extends StatelessWidget {
  const _StepDetails({
    required this.step,
    required this.index,
    required this.total,
    required this.onBack,
    required this.onNext,
    required this.setupState,
    required this.setupNotifier,
  });

  final _WizardStepData step;
  final int index;
  final int total;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final SetupState setupState;
  final SetupNotifier setupNotifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLast = index == total - 1;

    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: cs.primaryContainer,
              child: Icon(step.icon, color: cs.onPrimaryContainer, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('Step ${index + 1} of $total • ${step.status}', style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SetupStatusCard(state: setupState),
        if (setupState.errorMessage != null) ...[
          const SizedBox(height: 12),
          _ErrorBanner(message: setupState.errorMessage!),
        ],
        const SizedBox(height: 24),
        if (step.kind == _WizardStepKind.startMode)
          _StartModePanel(onNext: onNext)
        else if (step.kind == _WizardStepKind.initializeCompany)
          _InitializeCompanyPanel(state: setupState, notifier: setupNotifier, onInitialized: onNext)
        else if (step.kind == _WizardStepKind.defaultAccounts)
          _DefaultAccountsPanel(state: setupState, notifier: setupNotifier)
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.subtitle, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  _StatusBanner(status: step.status),
                  const SizedBox(height: 20),
                  if (step.route != null)
                    FilledButton.icon(
                      onPressed: () => context.go(step.route!),
                      icon: const Icon(Icons.open_in_new),
                      label: Text('Open ${step.title}'),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.lock_clock_outlined),
                      label: const Text('This step will be implemented next'),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: index == 0 ? null : onBack,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: isLast ? () => context.go(AppRoutes.dashboard) : onNext,
              icon: Icon(isLast ? Icons.check : Icons.arrow_forward),
              label: Text(isLast ? 'Finish' : 'Next'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SetupStatusCard extends StatelessWidget {
  const _SetupStatusCard({required this.state});
  final SetupState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final status = state.status;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: state.loading
            ? const Row(children: [SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 12), Text('Checking setup status...')])
            : Row(
                children: [
                  Icon(status?.isInitialized == true ? Icons.check_circle_outline : Icons.pending_actions_outlined, color: status?.isInitialized == true ? cs.primary : cs.secondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      status?.isInitialized == true
                          ? 'Initialized: ${status?.companyName ?? '-'} • Admin: ${status?.adminUserName ?? '-'}'
                          : 'Not fully initialized yet. Company: ${status?.hasCompanySettings == true ? 'yes' : 'no'} • Admin: ${status?.hasAdminUser == true ? 'yes' : 'no'}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _InitializeCompanyPanel extends StatefulWidget {
  const _InitializeCompanyPanel({required this.state, required this.notifier, required this.onInitialized});
  final SetupState state;
  final SetupNotifier notifier;
  final VoidCallback onInitialized;

  @override
  State<_InitializeCompanyPanel> createState() => _InitializeCompanyPanelState();
}

class _InitializeCompanyPanelState extends State<_InitializeCompanyPanel> {
  final _formKey = GlobalKey<FormState>();
  final _companyName = TextEditingController(text: 'My Company');
  final _currency = TextEditingController(text: 'EGP');
  final _country = TextEditingController(text: 'Egypt');
  final _timeZone = TextEditingController(text: 'Africa/Cairo');
  final _language = TextEditingController(text: 'ar');
  final _adminUser = TextEditingController(text: 'admin');
  final _adminName = TextEditingController(text: 'Owner Administrator');
  final _adminEmail = TextEditingController();
  final _adminSecret = TextEditingController();

  @override
  void dispose() {
    _companyName.dispose();
    _currency.dispose();
    _country.dispose();
    _timeZone.dispose();
    _language.dispose();
    _adminUser.dispose();
    _adminName.dispose();
    _adminEmail.dispose();
    _adminSecret.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alreadyInitialized = widget.state.status?.isInitialized == true;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: alreadyInitialized
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Company is already initialized', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Text('You can continue to tax defaults, default accounts, users, backup, and printing.'),
                  const SizedBox(height: 16),
                  FilledButton.icon(onPressed: widget.onInitialized, icon: const Icon(Icons.arrow_forward), label: const Text('Continue')),
                ],
              )
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Create New Company', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    const Text('This creates company settings, ADMIN role, the first administrator account, and default chart of accounts.'),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final two = constraints.maxWidth >= 760;
                        final fields = [
                          _Field(controller: _companyName, label: 'Company Name', required: true),
                          _Field(controller: _currency, label: 'Currency', required: true),
                          _Field(controller: _country, label: 'Country', required: true),
                          _Field(controller: _timeZone, label: 'Time Zone', required: true),
                          _Field(controller: _language, label: 'Default Language', required: true),
                          _Field(controller: _adminUser, label: 'Admin Username', required: true),
                          _Field(controller: _adminName, label: 'Admin Display Name', required: true),
                          _Field(controller: _adminEmail, label: 'Admin Email'),
                          _Field(controller: _adminSecret, label: 'Initial Admin Secret', required: true, obscure: true),
                        ];
                        if (!two) return Column(children: fields.map((f) => Padding(padding: const EdgeInsets.only(bottom: 12), child: f)).toList());
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: fields.map((field) => SizedBox(width: (constraints.maxWidth - 12) / 2, child: field)).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: widget.state.submitting ? null : _submit,
                      icon: widget.state.submitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add_business_outlined),
                      label: const Text('Initialize Company'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final initialized = await widget.notifier.initializeCompany(
      InitializeCompanyPayload(
        companyName: _companyName.text,
        currency: _currency.text,
        country: _country.text,
        timeZoneId: _timeZone.text,
        defaultLanguage: _language.text,
        adminUserName: _adminUser.text,
        adminDisplayName: _adminName.text,
        adminEmail: _adminEmail.text.isEmpty ? null : _adminEmail.text,
        initialAdminSecret: _adminSecret.text,
      ),
    );
    if (mounted && initialized) {
      widget.onInitialized();
    }
  }
}

class _DefaultAccountsPanel extends StatelessWidget {
  const _DefaultAccountsPanel({required this.state, required this.notifier});

  final SetupState state;
  final SetupNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = state.defaultAccountsSeed;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Default Chart of Accounts', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Seed the standard QuickBooks-style accounts needed for posting sales, purchases, inventory, payments, taxes, and equity.'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: state.submitting ? null : notifier.seedDefaultAccounts,
                  icon: state.submitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.account_tree_outlined),
                  label: const Text('Seed Default Accounts'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.chartOfAccounts),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open Chart of Accounts'),
                ),
              ],
            ),
            if (result != null) ...[
              const SizedBox(height: 20),
              _StatusBanner(status: 'Created: ${result.createdCount} • Skipped: ${result.skippedCount}'),
              const SizedBox(height: 12),
              if (result.createdCodes.isNotEmpty) _CodesBox(title: 'Created Codes', codes: result.createdCodes),
              if (result.skippedCodes.isNotEmpty) ...[
                const SizedBox(height: 12),
                _CodesBox(title: 'Already Existing Codes', codes: result.skippedCodes),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _CodesBox extends StatelessWidget {
  const _CodesBox({required this.title, required this.codes});
  final String title;
  final List<String> codes;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          SelectableText(codes.join(', ')),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.label, this.required = false, this.obscure = false});
  final TextEditingController controller;
  final String label;
  final bool required;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) return '$label is required';
              if (label.contains('Secret') && value.trim().length < 8) return 'Must be at least 8 characters';
              return null;
            }
          : null,
    );
  }
}

class _StartModePanel extends StatelessWidget {
  const _StartModePanel({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How should this customer start?', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(
              'This decision controls the setup path. New Company needs a first admin. Restore and Connect should use existing company users after data is loaded.',
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                final cards = [
                  _StartModeCard(
                    icon: Icons.add_business_outlined,
                    title: 'Create New Company',
                    subtitle: 'Fresh company file, first admin, default accounts, taxes, printing, and backup policy.',
                    badge: 'Ready path',
                    onPressed: onNext,
                  ),
                  _StartModeCard(
                    icon: Icons.restore_outlined,
                    title: 'Restore Existing Backup',
                    subtitle: 'Restore a previous company backup, then login using restored users. Recovery Admin only if required.',
                    badge: 'Ready',
                    onPressed: () => context.go(AppRoutes.backupSettings),
                  ),
                  _StartModeCard(
                    icon: Icons.dns_outlined,
                    title: 'Connect To Existing Company',
                    subtitle: 'Connect this client to LAN/Hosted API and login with server-side users. No local company creation.',
                    badge: 'Connection ready',
                    onPressed: () => context.go(AppRoutes.connectionSettings),
                  ),
                  _StartModeCard(
                    icon: Icons.school_outlined,
                    title: 'Open Demo Company',
                    subtitle: 'Use sample data for training, demos, and sales presentation without affecting real accounts.',
                    badge: 'Planned demo seed',
                    onPressed: null,
                  ),
                ];

                if (!wide) return Column(children: cards.map((card) => Padding(padding: const EdgeInsets.only(bottom: 12), child: card)).toList());
                return GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 2.9,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: cards,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StartModeCard extends StatelessWidget {
  const _StartModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final enabled = onPressed != null;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: enabled ? null : cs.surfaceContainerHighest,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(backgroundColor: cs.secondaryContainer, child: Icon(icon, color: cs.onSecondaryContainer)),
                  const Spacer(),
                  Chip(label: Text(badge), visualDensity: VisualDensity.compact),
                ],
              ),
              const SizedBox(height: 12),
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(enabled ? Icons.arrow_forward : Icons.lock_clock_outlined, size: 18),
                  const SizedBox(width: 6),
                  Text(enabled ? 'Select' : 'Coming soon'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ready = status == 'Ready' || status.startsWith('Created:');
    final partial = status == 'Partial';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ready ? cs.primaryContainer : partial ? cs.secondaryContainer : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            ready ? Icons.check_circle_outline : partial ? Icons.timelapse : Icons.pending_actions_outlined,
            color: ready ? cs.onPrimaryContainer : partial ? cs.onSecondaryContainer : cs.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text('Status: $status')),
        ],
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

enum _WizardStepKind { normal, startMode, initializeCompany, defaultAccounts }

class _WizardStepData {
  const _WizardStepData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.status,
    this.kind = _WizardStepKind.normal,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? route;
  final String status;
  final _WizardStepKind kind;
}
