import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/payroll_setup_provider.dart';

class PayrollSetupScreen extends ConsumerWidget {
  const PayrollSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setupAsync = ref.watch(payrollSetupProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(payrollSetupProvider),
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: setupAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(payrollSetupProvider),
        ),
        data: (setup) => _PayrollSetupBody(setup: setup),
      ),
    );
  }
}

class _PayrollSetupBody extends ConsumerWidget {
  const _PayrollSetupBody({required this.setup});

  final PayrollSetup setup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payroll Setup', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(
                    'Configure payroll before payroll runs. Calculations and posting will be handled by backend payroll runs.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () => _showSettingsSheet(context, ref, setup.settings),
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Settings'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1040 ? 4 : constraints.maxWidth >= 680 ? 2 : 1;
            return GridView.count(
              crossAxisCount: columns,
              childAspectRatio: columns == 1 ? 3.5 : 2.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _SummaryTile('Payroll Enabled', setup.settings.isPayrollEnabled ? 'Yes' : 'No', Icons.payments_outlined, setup.settings.isPayrollEnabled ? Colors.green : Colors.orange),
                _SummaryTile('Active Employees', setup.activeEmployeeCount.toString(), Icons.badge_outlined, cs.primary),
                _SummaryTile('Pay Schedules', setup.payScheduleCount.toString(), Icons.event_repeat_outlined, Colors.blue),
                _SummaryTile('Work Week', '${setup.settings.workWeekHours} h', Icons.schedule_outlined, Colors.deepPurple),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        _Panel(
          title: 'Employees',
          actionLabel: 'Add Employee',
          onAction: () => _showEmployeeSheet(context, ref, setup.settings),
          child: setup.employees.isEmpty
              ? const _SmallEmptyState('No payroll employees yet.')
              : Column(children: setup.employees.map((employee) => _EmployeeRow(employee: employee)).toList()),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final earnings = _Panel(
              title: 'Earning Types',
              actionLabel: 'Add Earning',
              onAction: () => _showEarningTypeSheet(context, ref),
              child: Column(children: setup.earningTypes.map((item) => _TypeRow(code: item.code, name: item.name, detail: item.isTaxable ? 'Taxable' : 'Non-taxable', isActive: item.isActive)).toList()),
            );
            final deductions = _Panel(
              title: 'Deduction Types',
              actionLabel: 'Add Deduction',
              onAction: () => _showDeductionTypeSheet(context, ref),
              child: Column(children: setup.deductionTypes.map((item) => _TypeRow(code: item.code, name: item.name, detail: item.isPreTax ? 'Pre-tax' : 'Post-tax', isActive: item.isActive)).toList()),
            );
            if (!wide) return Column(children: [earnings, const SizedBox(height: 16), deductions]);
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: earnings), const SizedBox(width: 16), Expanded(child: deductions)]);
          },
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile(this.title, this.value, this.icon, this.color);

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withValues(alpha: 0.14), child: Icon(icon, color: color)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, required this.actionLabel, required this.onAction});

  final String title;
  final Widget child;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
                OutlinedButton.icon(onPressed: onAction, icon: const Icon(Icons.add), label: Text(actionLabel)),
              ],
            ),
            const Divider(height: 26),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmployeeRow extends StatelessWidget {
  const _EmployeeRow({required this.employee});

  final PayrollEmployee employee;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Text(employee.displayName.isEmpty ? '?' : employee.displayName[0].toUpperCase())),
      title: Text(employee.displayName, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text('${employee.employeeNumber} • ${employee.paySchedule} • ${employee.currency} ${employee.defaultHourlyRate.toStringAsFixed(2)}/h'),
      trailing: Chip(label: Text(employee.isActive ? 'Active' : 'Inactive')),
    );
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({required this.code, required this.name, required this.detail, required this.isActive});

  final String code;
  final String name;
  final String detail;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Text(code.isEmpty ? '?' : code[0])),
      title: Text('$code - $name', style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(detail),
      trailing: Chip(label: Text(isActive ? 'Active' : 'Inactive')),
    );
  }
}

class _SmallEmptyState extends StatelessWidget {
  const _SmallEmptyState(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Center(child: Text(message)),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 42),
                const SizedBox(height: 12),
                const Text('Could not load payroll setup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 18),
                FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _showSettingsSheet(BuildContext context, WidgetRef ref, PayrollSettings settings) async {
  final schedule = TextEditingController(text: settings.defaultPaySchedule);
  final currency = TextEditingController(text: settings.defaultCurrency);
  final hours = TextEditingController(text: settings.workWeekHours.toString());
  var enabled = settings.isPayrollEnabled;
  await _showFormSheet(
    context,
    title: 'Payroll Settings',
    fields: [
      TextFormField(controller: schedule, decoration: const InputDecoration(labelText: 'Default pay schedule'), validator: _required),
      const SizedBox(height: 12),
      TextFormField(controller: currency, decoration: const InputDecoration(labelText: 'Currency'), validator: _required),
      const SizedBox(height: 12),
      TextFormField(controller: hours, decoration: const InputDecoration(labelText: 'Work week hours'), keyboardType: TextInputType.number, validator: _required),
      StatefulBuilder(builder: (context, setState) => SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Payroll enabled'), value: enabled, onChanged: (value) => setState(() => enabled = value))),
    ],
    onSave: () => ref.read(payrollSetupCommandsProvider).updateSettings(
          defaultPaySchedule: schedule.text.trim(),
          defaultCurrency: currency.text.trim(),
          workWeekHours: int.parse(hours.text.trim()),
          isPayrollEnabled: enabled,
        ),
  );
  schedule.dispose();
  currency.dispose();
  hours.dispose();
}

Future<void> _showEmployeeSheet(BuildContext context, WidgetRef ref, PayrollSettings settings) async {
  final number = TextEditingController();
  final name = TextEditingController();
  final email = TextEditingController();
  final schedule = TextEditingController(text: settings.defaultPaySchedule);
  final rate = TextEditingController(text: '0.00');
  final currency = TextEditingController(text: settings.defaultCurrency);
  var active = true;
  await _showFormSheet(
    context,
    title: 'Add Payroll Employee',
    fields: [
      TextFormField(controller: number, decoration: const InputDecoration(labelText: 'Employee number'), validator: _required),
      const SizedBox(height: 12),
      TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Display name'), validator: _required),
      const SizedBox(height: 12),
      TextFormField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
      const SizedBox(height: 12),
      TextFormField(controller: schedule, decoration: const InputDecoration(labelText: 'Pay schedule'), validator: _required),
      const SizedBox(height: 12),
      TextFormField(controller: rate, decoration: const InputDecoration(labelText: 'Hourly rate'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _required),
      const SizedBox(height: 12),
      TextFormField(controller: currency, decoration: const InputDecoration(labelText: 'Currency'), validator: _required),
      StatefulBuilder(builder: (context, setState) => SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Active'), value: active, onChanged: (value) => setState(() => active = value))),
    ],
    onSave: () => ref.read(payrollSetupCommandsProvider).createEmployee(
          employeeNumber: number.text.trim(),
          displayName: name.text.trim(),
          email: email.text.trim().isEmpty ? null : email.text.trim(),
          paySchedule: schedule.text.trim(),
          defaultHourlyRate: double.parse(rate.text.trim()),
          currency: currency.text.trim(),
          isActive: active,
        ),
  );
  number.dispose();
  name.dispose();
  email.dispose();
  schedule.dispose();
  rate.dispose();
  currency.dispose();
}

Future<void> _showEarningTypeSheet(BuildContext context, WidgetRef ref) async {
  final code = TextEditingController();
  final name = TextEditingController();
  var taxable = true;
  await _showFormSheet(
    context,
    title: 'Add Earning Type',
    fields: [
      TextFormField(controller: code, decoration: const InputDecoration(labelText: 'Code'), validator: _required),
      const SizedBox(height: 12),
      TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Name'), validator: _required),
      StatefulBuilder(builder: (context, setState) => SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Taxable'), value: taxable, onChanged: (value) => setState(() => taxable = value))),
    ],
    onSave: () => ref.read(payrollSetupCommandsProvider).createEarningType(code: code.text.trim(), name: name.text.trim(), isTaxable: taxable, isActive: true),
  );
  code.dispose();
  name.dispose();
}

Future<void> _showDeductionTypeSheet(BuildContext context, WidgetRef ref) async {
  final code = TextEditingController();
  final name = TextEditingController();
  var preTax = false;
  await _showFormSheet(
    context,
    title: 'Add Deduction Type',
    fields: [
      TextFormField(controller: code, decoration: const InputDecoration(labelText: 'Code'), validator: _required),
      const SizedBox(height: 12),
      TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Name'), validator: _required),
      StatefulBuilder(builder: (context, setState) => SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Pre-tax'), value: preTax, onChanged: (value) => setState(() => preTax = value))),
    ],
    onSave: () => ref.read(payrollSetupCommandsProvider).createDeductionType(code: code.text.trim(), name: name.text.trim(), isPreTax: preTax, isActive: true),
  );
  code.dispose();
  name.dispose();
}

Future<void> _showFormSheet(BuildContext context, {required String title, required List<Widget> fields, required Future<void> Function() onSave}) async {
  final formKey = GlobalKey<FormState>();
  var saving = false;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.viewInsetsOf(context).bottom + 24),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 18),
                ...fields,
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: saving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setState(() => saving = true);
                              try {
                                await onSave();
                                if (context.mounted) Navigator.of(context).pop();
                              } catch (error) {
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
                                setState(() => saving = false);
                              }
                            },
                      icon: saving ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
                      label: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

String? _required(String? value) => value == null || value.trim().isEmpty ? 'Required' : null;
