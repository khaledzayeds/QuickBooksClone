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
      subtitle:
          'Choose how this company will start: create a company, restore a backup, connect to an existing service, or open sample data.',
      icon: Icons.rocket_launch_outlined,
      route: null,
      status: 'Ready',
      kind: _WizardStepKind.startMode,
    ),
    _WizardStepData(
      title: 'Connection',
      subtitle: 'Choose local, network, hosted, or custom connection.',
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
      subtitle:
          'Configure tax behavior, default tax rates, rounding, and future tax account links.',
      icon: Icons.calculate_outlined,
      route: AppRoutes.taxSettings,
      status: 'Ready',
    ),
    _WizardStepData(
      title: 'Default Accounts',
      subtitle:
          'Seed or review chart of accounts required for posting transactions.',
      icon: Icons.account_tree_outlined,
      route: AppRoutes.chartOfAccounts,
      status: 'Ready',
      kind: _WizardStepKind.defaultAccounts,
    ),
    _WizardStepData(
      title: 'Users & Permissions',
      subtitle:
          'Review users, roles, and permissions after first admin is created.',
      icon: Icons.admin_panel_settings_outlined,
      route: AppRoutes.usersPermissions,
      status: 'Ready',
    ),
    _WizardStepData(
      title: 'Backup',
      subtitle:
          'Review database backup status and prepare backup/restore operations.',
      icon: Icons.backup_outlined,
      route: AppRoutes.backupSettings,
      status: 'Ready',
    ),
    _WizardStepData(
      title: 'Printing',
      subtitle:
          'Configure A4 invoices, thermal receipts, branding, QR, tax summary, and print behavior.',
      icon: Icons.print_outlined,
      route: AppRoutes.printingSettings,
      status: 'Ready',
    ),
    _WizardStepData(
      title: 'Finish',
      subtitle: 'Review setup status and start using Zayed.',
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
    final text = _SetupText.of(context);

    ref.listen(setupProvider, (previous, next) {
      if (next.successMessage != null &&
          previous?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.successMessage!)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(text.title),
        actions: [
          IconButton(
            tooltip: text.refreshStatus,
            onPressed: () => ref.read(setupProvider.notifier).loadStatus(),
            icon: const Icon(Icons.refresh),
          ),
          TextButton.icon(
            onPressed: () => context.go(AppRoutes.settings),
            icon: const Icon(Icons.close),
            label: Text(text.exit),
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
                    SizedBox(
                      width: 360,
                      child: _StepRail(
                        currentStep: _currentStep,
                        onStepSelected: _goToStep,
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: _StepDetails(
                        step: current,
                        index: _currentStep,
                        total: _steps.length,
                        onBack: _back,
                        onNext: _next,
                        setupState: setupState,
                        setupNotifier: ref.read(setupProvider.notifier),
                      ),
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      'Company setup',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Prepare Zayed for local, network, or hosted use. Start by choosing the company opening path.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _StepRail(
                      currentStep: _currentStep,
                      onStepSelected: _goToStep,
                      compact: true,
                    ),
                    const SizedBox(height: 24),
                    _StepDetails(
                      step: current,
                      index: _currentStep,
                      total: _steps.length,
                      onBack: _back,
                      onNext: _next,
                      setupState: setupState,
                      setupNotifier: ref.read(setupProvider.notifier),
                    ),
                  ],
                );
        },
      ),
    );
  }

  void _goToStep(int index) => setState(() => _currentStep = index);
  void _back() => setState(
    () => _currentStep = (_currentStep - 1).clamp(0, _steps.length - 1),
  );
  void _next() => setState(
    () => _currentStep = (_currentStep + 1).clamp(0, _steps.length - 1),
  );
}

class _StepRail extends StatelessWidget {
  const _StepRail({
    required this.currentStep,
    required this.onStepSelected,
    this.compact = false,
  });

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
          final text = _SetupText.of(context);
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
                      backgroundColor: selected
                          ? cs.primary
                          : cs.secondaryContainer,
                      child: Icon(
                        step.icon,
                        color: selected
                            ? cs.onPrimary
                            : cs.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text.stepTitle(step.title),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            text.status(step.status),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
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
    final text = _SetupText.of(context);

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
                  Text(
                    text.stepTitle(step.title),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text.stepProgress(index + 1, total, step.status),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
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
          _InitializeCompanyPanel(
            state: setupState,
            notifier: setupNotifier,
            onInitialized: onNext,
          )
        else if (step.kind == _WizardStepKind.defaultAccounts)
          _DefaultAccountsPanel(state: setupState, notifier: setupNotifier)
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text.stepSubtitle(step.title, step.subtitle),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _StatusBanner(status: step.status),
                  const SizedBox(height: 20),
                  if (step.route != null)
                    FilledButton.icon(
                      onPressed: () => context.go(step.route!),
                      icon: const Icon(Icons.open_in_new),
                      label: Text(text.openStep(step.title)),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.lock_clock_outlined),
                      label: Text(text.availableAfterSetup),
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
              label: Text(text.back),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: isLast
                  ? () => context.go(AppRoutes.dashboard)
                  : onNext,
              icon: Icon(isLast ? Icons.check : Icons.arrow_forward),
              label: Text(isLast ? text.finish : text.next),
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
    final text = _SetupText.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: state.loading
            ? Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(text.checkingStatus),
                ],
              )
            : Row(
                children: [
                  Icon(
                    status?.isInitialized == true
                        ? Icons.check_circle_outline
                        : Icons.pending_actions_outlined,
                    color: status?.isInitialized == true
                        ? cs.primary
                        : cs.secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      status?.isInitialized == true
                          ? text.initializedStatus(
                              status?.companyName,
                              status?.adminUserName,
                            )
                          : text.notInitializedStatus(
                              status?.hasCompanySettings == true,
                              status?.hasAdminUser == true,
                            ),
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
  const _InitializeCompanyPanel({
    required this.state,
    required this.notifier,
    required this.onInitialized,
  });
  final SetupState state;
  final SetupNotifier notifier;
  final VoidCallback onInitialized;

  @override
  State<_InitializeCompanyPanel> createState() =>
      _InitializeCompanyPanelState();
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
    final text = _SetupText.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: alreadyInitialized
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text.companyAlreadyInitialized,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(text.companyAlreadyInitializedDescription),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: widget.onInitialized,
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(text.continueLabel),
                  ),
                ],
              )
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text.createNewCompany,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(text.createNewCompanyDescription),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final two = constraints.maxWidth >= 760;
                        final fields = [
                          _Field(
                            controller: _companyName,
                            label: text.companyName,
                            required: true,
                          ),
                          _Field(
                            controller: _currency,
                            label: text.currency,
                            required: true,
                          ),
                          _Field(
                            controller: _country,
                            label: text.country,
                            required: true,
                          ),
                          _Field(
                            controller: _timeZone,
                            label: text.timeZone,
                            required: true,
                          ),
                          _Field(
                            controller: _language,
                            label: text.defaultLanguage,
                            required: true,
                          ),
                          _Field(
                            controller: _adminUser,
                            label: text.adminUsername,
                            required: true,
                          ),
                          _Field(
                            controller: _adminName,
                            label: text.adminDisplayName,
                            required: true,
                          ),
                          _Field(
                            controller: _adminEmail,
                            label: text.adminEmail,
                          ),
                          _Field(
                            controller: _adminSecret,
                            label: text.initialAdminSecret,
                            required: true,
                            obscure: true,
                          ),
                        ];
                        if (!two) {
                          return Column(
                            children: fields
                                .map(
                                  (f) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: f,
                                  ),
                                )
                                .toList(),
                          );
                        }
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: fields
                              .map(
                                (field) => SizedBox(
                                  width: (constraints.maxWidth - 12) / 2,
                                  child: field,
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: widget.state.submitting ? null : _submit,
                      icon: widget.state.submitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_business_outlined),
                      label: Text(text.initializeCompany),
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
    final text = _SetupText.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text.defaultChartOfAccounts,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(text.defaultAccountsDescription),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: state.submitting
                      ? null
                      : notifier.seedDefaultAccounts,
                  icon: state.submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.account_tree_outlined),
                  label: Text(text.seedDefaultAccounts),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.chartOfAccounts),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(text.openChartOfAccounts),
                ),
              ],
            ),
            if (result != null) ...[
              const SizedBox(height: 20),
              _StatusBanner(
                status: text.createdSkipped(
                  result.createdCount,
                  result.skippedCount,
                ),
              ),
              const SizedBox(height: 12),
              if (result.createdCodes.isNotEmpty)
                _CodesBox(title: text.createdCodes, codes: result.createdCodes),
              if (result.skippedCodes.isNotEmpty) ...[
                const SizedBox(height: 12),
                _CodesBox(
                  title: text.alreadyExistingCodes,
                  codes: result.skippedCodes,
                ),
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
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
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
  const _Field({
    required this.controller,
    required this.label,
    this.required = false,
    this.obscure = false,
  });
  final TextEditingController controller;
  final String label;
  final bool required;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return _SetupText.of(context).requiredField(label);
              }
              if (label.contains('Secret') && value.trim().length < 8) {
                return _SetupText.of(context).minEightCharacters;
              }
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
    final text = _SetupText.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text.startQuestion,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              text.startDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                final cards = [
                  _StartModeCard(
                    icon: Icons.add_business_outlined,
                    title: text.createNewCompany,
                    subtitle: text.createNewCompanyPath,
                    badge: text.recommended,
                    onPressed: onNext,
                  ),
                  _StartModeCard(
                    icon: Icons.restore_outlined,
                    title: text.restoreExistingBackup,
                    subtitle: text.restoreExistingBackupPath,
                    badge: text.ready,
                    onPressed: () => context.go(AppRoutes.backupSettings),
                  ),
                  _StartModeCard(
                    icon: Icons.dns_outlined,
                    title: text.connectExistingCompany,
                    subtitle: text.connectExistingCompanyPath,
                    badge: text.ready,
                    onPressed: () => context.go(AppRoutes.connectionSettings),
                  ),
                  _StartModeCard(
                    icon: Icons.school_outlined,
                    title: text.openDemoCompany,
                    subtitle: text.openDemoCompanyPath,
                    badge: text.availableSoon,
                    onPressed: null,
                  ),
                ];

                if (!wide) {
                  return Column(
                    children: cards
                        .map(
                          (card) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: card,
                          ),
                        )
                        .toList(),
                  );
                }
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
                  CircleAvatar(
                    backgroundColor: cs.secondaryContainer,
                    child: Icon(icon, color: cs.onSecondaryContainer),
                  ),
                  const Spacer(),
                  Chip(
                    label: Text(badge),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    enabled ? Icons.arrow_forward : Icons.lock_clock_outlined,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    enabled
                        ? _SetupText.of(context).select
                        : _SetupText.of(context).availableSoon,
                  ),
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
    final text = _SetupText.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ready
            ? cs.primaryContainer
            : partial
            ? cs.secondaryContainer
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            ready
                ? Icons.check_circle_outline
                : partial
                ? Icons.timelapse
                : Icons.pending_actions_outlined,
            color: ready
                ? cs.onPrimaryContainer
                : partial
                ? cs.onSecondaryContainer
                : cs.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text.statusLine(status))),
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

class _SetupText {
  const _SetupText(this.ar);

  final bool ar;

  static _SetupText of(BuildContext context) =>
      _SetupText(Localizations.localeOf(context).languageCode == 'ar');

  String get title => ar ? 'معالج الإعداد' : 'Setup Wizard';
  String get refreshStatus =>
      ar ? 'تحديث حالة الإعداد' : 'Refresh setup status';
  String get exit => ar ? 'خروج' : 'Exit';
  String get ready => ar ? 'جاهز' : 'Ready';
  String get availableSoon => ar ? 'قريبا' : 'Available soon';
  String get recommended => ar ? 'موصى به' : 'Recommended';
  String get back => ar ? 'رجوع' : 'Back';
  String get next => ar ? 'التالي' : 'Next';
  String get finish => ar ? 'إنهاء' : 'Finish';
  String get continueLabel => ar ? 'متابعة' : 'Continue';
  String get select => ar ? 'اختيار' : 'Select';
  String get availableAfterSetup => ar
      ? 'يتاح بعد اكتمال خطوات الإعداد المطلوبة'
      : 'Available after the required setup is complete';
  String get checkingStatus =>
      ar ? 'جاري فحص حالة الإعداد...' : 'Checking setup status...';
  String stepProgress(int index, int total, String status) => ar
      ? 'خطوة $index من $total • ${this.status(status)}'
      : 'Step $index of $total • ${this.status(status)}';
  String openStep(String title) =>
      ar ? 'فتح ${stepTitle(title)}' : 'Open ${stepTitle(title)}';
  String statusLine(String status) =>
      ar ? 'الحالة: ${this.status(status)}' : 'Status: ${this.status(status)}';
  String status(String status) {
    if (!ar) return status;
    if (status == 'Ready') return 'جاهز';
    if (status == 'Partial') return 'جزئي';
    if (status.startsWith('Created:')) {
      return status.replaceFirst('Created:', 'تم الإنشاء:');
    }
    return status.replaceAll('Skipped:', 'تم تخطي:');
  }

  String stepTitle(String title) => switch (title) {
    'Start Mode' => ar ? 'طريقة البدء' : title,
    'Connection' => ar ? 'الاتصال' : title,
    'Create Company' => ar ? 'إنشاء الشركة' : title,
    'Tax Defaults' => ar ? 'افتراضات الضرائب' : title,
    'Default Accounts' => ar ? 'الحسابات الافتراضية' : title,
    'Users & Permissions' => ar ? 'المستخدمون والصلاحيات' : title,
    'Backup' => ar ? 'النسخ الاحتياطي' : title,
    'Printing' => ar ? 'الطباعة' : title,
    'Finish' => ar ? 'إنهاء' : title,
    _ => title,
  };

  String stepSubtitle(String title, String fallback) {
    if (!ar) return fallback;
    return switch (title) {
      'Start Mode' =>
        'اختر كيف ستبدأ هذه الشركة: إنشاء شركة، استرجاع نسخة، الاتصال بخدمة موجودة، أو فتح بيانات تجريبية.',
      'Connection' => 'اختر اتصال محلي أو شبكة أو استضافة أو اتصال مخصص.',
      'Create Company' => 'أنشئ ملف الشركة وأول مستخدم مدير.',
      'Tax Defaults' =>
        'اضبط سلوك الضرائب والنسب الافتراضية والتقريب وروابط حسابات الضرائب لاحقا.',
      'Default Accounts' =>
        'أنشئ أو راجع شجرة الحسابات المطلوبة لترحيل المعاملات.',
      'Users & Permissions' =>
        'راجع المستخدمين والأدوار والصلاحيات بعد إنشاء أول مدير.',
      'Backup' => 'راجع حالة النسخ الاحتياطي وجهز عمليات النسخ والاسترجاع.',
      'Printing' =>
        'اضبط فواتير A4 والإيصالات الحرارية والهوية وQR وملخص الضرائب وسلوك الطباعة.',
      'Finish' => 'راجع حالة الإعداد وابدأ استخدام Zayed.',
      _ => fallback,
    };
  }

  String initializedStatus(String? companyName, String? adminUserName) => ar
      ? 'تم التهيئة: ${companyName ?? '-'} • المدير: ${adminUserName ?? '-'}'
      : 'Initialized: ${companyName ?? '-'} • Admin: ${adminUserName ?? '-'}';
  String notInitializedStatus(bool hasCompany, bool hasAdmin) => ar
      ? 'لم تكتمل التهيئة بعد. الشركة: ${hasCompany ? 'نعم' : 'لا'} • المدير: ${hasAdmin ? 'نعم' : 'لا'}'
      : 'Not fully initialized yet. Company: ${hasCompany ? 'yes' : 'no'} • Admin: ${hasAdmin ? 'yes' : 'no'}';
  String get companyAlreadyInitialized =>
      ar ? 'تمت تهيئة الشركة بالفعل' : 'Company is already initialized';
  String get companyAlreadyInitializedDescription => ar
      ? 'يمكنك المتابعة إلى افتراضات الضرائب والحسابات الافتراضية والمستخدمين والنسخ الاحتياطي والطباعة.'
      : 'You can continue to tax defaults, default accounts, users, backup, and printing.';
  String get createNewCompany => ar ? 'إنشاء شركة جديدة' : 'Create New Company';
  String get createNewCompanyDescription => ar
      ? 'ينشئ إعدادات الشركة وأول حساب مدير والأدوار والصلاحيات وشجرة الحسابات الافتراضية.'
      : 'This creates company settings, the first administrator account, roles, permissions, and the default chart of accounts.';
  String get companyName => ar ? 'اسم الشركة' : 'Company Name';
  String get currency => ar ? 'العملة' : 'Currency';
  String get country => ar ? 'الدولة' : 'Country';
  String get timeZone => ar ? 'المنطقة الزمنية' : 'Time Zone';
  String get defaultLanguage => ar ? 'اللغة الافتراضية' : 'Default Language';
  String get adminUsername => ar ? 'اسم مستخدم المدير' : 'Admin Username';
  String get adminDisplayName =>
      ar ? 'اسم المدير الظاهر' : 'Admin Display Name';
  String get adminEmail => ar ? 'بريد المدير' : 'Admin Email';
  String get initialAdminSecret =>
      ar ? 'كلمة سر المدير الأولية' : 'Initial Admin Secret';
  String get initializeCompany => ar ? 'تهيئة الشركة' : 'Initialize Company';
  String get defaultChartOfAccounts =>
      ar ? 'شجرة الحسابات الافتراضية' : 'Default Chart of Accounts';
  String get defaultAccountsDescription => ar
      ? 'أنشئ حسابات Zayed القياسية المطلوبة لترحيل المبيعات والمشتريات والمخزون والمدفوعات والضرائب وحقوق الملكية.'
      : 'Seed the standard Zayed-style accounts needed for posting sales, purchases, inventory, payments, taxes, and equity.';
  String get seedDefaultAccounts =>
      ar ? 'إنشاء الحسابات الافتراضية' : 'Seed Default Accounts';
  String get openChartOfAccounts =>
      ar ? 'فتح شجرة الحسابات' : 'Open Chart of Accounts';
  String createdSkipped(int created, int skipped) => ar
      ? 'تم الإنشاء: $created • تم تخطي: $skipped'
      : 'Created: $created • Skipped: $skipped';
  String get createdCodes => ar ? 'الأكواد المنشأة' : 'Created Codes';
  String get alreadyExistingCodes =>
      ar ? 'أكواد موجودة بالفعل' : 'Already Existing Codes';
  String requiredField(String label) =>
      ar ? '$label مطلوب' : '$label is required';
  String get minEightCharacters =>
      ar ? 'يجب ألا يقل عن 8 أحرف' : 'Must be at least 8 characters';
  String get startQuestion =>
      ar ? 'كيف تبدأ هذه الشركة؟' : 'How should this company start?';
  String get startDescription => ar
      ? 'اختر المسار المناسب لبيانات الشركة. الشركة الجديدة تنشئ أول مدير؛ الشركات المسترجعة أو المتصلة تستخدم مستخدميها الحاليين.'
      : 'Choose the path that matches the company data. A new company creates the first administrator; restored or connected companies use their existing users.';
  String get createNewCompanyPath => ar
      ? 'ملف شركة جديد، أول مدير، حسابات افتراضية، ضرائب، طباعة، وسياسة نسخ احتياطي.'
      : 'Fresh company file, first administrator, default accounts, taxes, printing, and backup policy.';
  String get restoreExistingBackup =>
      ar ? 'استرجاع نسخة احتياطية موجودة' : 'Restore Existing Backup';
  String get restoreExistingBackupPath => ar
      ? 'استرجع نسخة شركة سابقة، ثم سجل الدخول بالمستخدمين المسترجعين.'
      : 'Restore a previous company backup, then sign in using the restored users.';
  String get connectExistingCompany =>
      ar ? 'الاتصال بشركة موجودة' : 'Connect To Existing Company';
  String get connectExistingCompanyPath => ar
      ? 'صل هذا الجهاز بشركة على الشبكة أو الاستضافة وسجل الدخول بمستخدمي الشركة.'
      : 'Connect this device to a network or hosted company and sign in with company users.';
  String get openDemoCompany => ar ? 'فتح شركة تجريبية' : 'Open Demo Company';
  String get openDemoCompanyPath => ar
      ? 'استخدم بيانات عينة للتدريب والعروض دون التأثير على الحسابات الحقيقية.'
      : 'Use sample data for training and presentations without affecting real accounts.';
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
