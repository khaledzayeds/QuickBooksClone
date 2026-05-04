import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';

class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  int _currentStep = 0;

  static const _steps = [
    _WizardStepData(
      title: 'Connection',
      subtitle: 'Choose Local, LAN, Hosted, or Custom API endpoint.',
      icon: Icons.language_outlined,
      route: AppRoutes.connectionSettings,
      status: 'Ready',
    ),
    _WizardStepData(
      title: 'Company Profile',
      subtitle: 'Set company name, contacts, address, currency, language, and fiscal year.',
      icon: Icons.business_outlined,
      route: AppRoutes.companySettings,
      status: 'Ready',
    ),
    _WizardStepData(
      title: 'Tax Defaults',
      subtitle: 'Configure tax behavior, default tax rates, and tax accounts.',
      icon: Icons.calculate_outlined,
      route: null,
      status: 'Coming Soon',
    ),
    _WizardStepData(
      title: 'Default Accounts',
      subtitle: 'Seed or review chart of accounts required for posting transactions.',
      icon: Icons.account_tree_outlined,
      route: AppRoutes.chartOfAccounts,
      status: 'Partial',
    ),
    _WizardStepData(
      title: 'Users & Permissions',
      subtitle: 'Create admin user, users, roles, permissions, and access rules.',
      icon: Icons.admin_panel_settings_outlined,
      route: null,
      status: 'Coming Soon',
    ),
    _WizardStepData(
      title: 'Backup & Printing',
      subtitle: 'Choose backup folder, document templates, thermal printer, and logo.',
      icon: Icons.print_outlined,
      route: null,
      status: 'Coming Soon',
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Wizard'),
        actions: [
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
                    Expanded(child: _StepDetails(step: current, index: _currentStep, total: _steps.length, onBack: _back, onNext: _next)),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text('First-run setup', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text(
                      'Prepare LedgerFlow for Solo, Network, or Hosted use. Each step can be opened now or completed later from Settings.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),
                    _StepRail(currentStep: _currentStep, onStepSelected: _goToStep, compact: true),
                    const SizedBox(height: 24),
                    _StepDetails(step: current, index: _currentStep, total: _steps.length, onBack: _back, onNext: _next),
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
  });

  final _WizardStepData step;
  final int index;
  final int total;
  final VoidCallback onBack;
  final VoidCallback onNext;

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
        const SizedBox(height: 24),
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

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ready = status == 'Ready';
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

class _WizardStepData {
  const _WizardStepData({required this.title, required this.subtitle, required this.icon, required this.route, required this.status});

  final String title;
  final String subtitle;
  final IconData icon;
  final String? route;
  final String status;
}
