import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../providers/payroll_runs_provider.dart';
import '../providers/payroll_setup_provider.dart';

class PayrollRunsSection extends ConsumerWidget {
  const PayrollRunsSection({super.key, required this.setup});

  final PayrollSetup setup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runsAsync = ref.watch(payrollRunsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Payroll Runs',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: setup.employees.isEmpty ? null : () => _showCreateRunSheet(context, ref, setup),
                  icon: const Icon(Icons.playlist_add_outlined),
                  label: const Text('Create Run'),
                ),
              ],
            ),
            const Divider(height: 26),
            runsAsync.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
              error: (error, _) => _InlineError(
                message: error.toString(),
                onRetry: () => ref.invalidate(payrollRunsProvider),
              ),
              data: (runs) => _RunsBody(runs: runs),
            ),
          ],
        ),
      ),
    );
  }
}

class _RunsBody extends StatelessWidget {
  const _RunsBody({required this.runs});

  final PayrollRunList runs;

  @override
  Widget build(BuildContext context) {
    if (runs.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(child: Text('No payroll runs yet. Create a run after adding active employees.')),
      );
    }

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900 ? 4 : constraints.maxWidth >= 560 ? 2 : 1;
            return GridView.count(
              crossAxisCount: columns,
              childAspectRatio: columns == 1 ? 3.4 : 2.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _RunMetric('Runs', runs.totalCount.toString(), Icons.payments_outlined, Colors.blue),
                _RunMetric('Gross', runs.totalGrossPay.toStringAsFixed(2), Icons.trending_up_outlined, Colors.green),
                _RunMetric('Deductions', runs.totalDeductions.toStringAsFixed(2), Icons.remove_circle_outline, Colors.orange),
                _RunMetric('Net Pay', runs.totalNetPay.toStringAsFixed(2), Icons.account_balance_wallet_outlined, Colors.deepPurple),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        ...runs.items.map((run) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PayrollRunTile(run: run),
            )),
      ],
    );
  }
}

class _RunMetric extends StatelessWidget {
  const _RunMetric(this.title, this.value, this.icon, this.color);

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withValues(alpha: 0.14), child: Icon(icon, color: color)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayrollRunTile extends ConsumerWidget {
  const _PayrollRunTile({required this.run});

  final PayrollRunSummary run;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commands = ref.read(payrollRunCommandsProvider);
    final color = _statusColor(context, run.status);
    final journalEntryId = run.journalEntryId;
    final hasJournalEntry = journalEntryId != null && journalEntryId.isNotEmpty;

    return Card(
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showRunDetailsDialog(context, run.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Icon(Icons.payments_outlined, color: color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(run.runNumber, style: const TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text('${_date(run.periodStart)} to ${_date(run.periodEnd)} • Pay ${_date(run.payDate)}'),
                        const SizedBox(height: 4),
                        Text('${run.paySchedule} • ${run.employeeCount} employee(s)'),
                        if (hasJournalEntry) ...[
                          const SizedBox(height: 4),
                          Text('Journal Entry: $journalEntryId'),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _StatusChip(status: run.status),
                      const SizedBox(height: 8),
                      Text('${run.currency} ${run.totalNetPay.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900)),
                      Text('Gross ${run.totalGrossPay.toStringAsFixed(2)}'),
                    ],
                  ),
                ],
              ),
              const Divider(height: 22),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showRunDetailsDialog(context, run.id),
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Details'),
                  ),
                  OutlinedButton.icon(
                    onPressed: run.status == 'Draft' ? () => _run(context, () => commands.approve(run.id)) : null,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Approve'),
                  ),
                  OutlinedButton.icon(
                    onPressed: run.status == 'Approved' ? () => _run(context, () => commands.post(run.id)) : null,
                    icon: const Icon(Icons.post_add_outlined),
                    label: const Text('Post'),
                  ),
                  OutlinedButton.icon(
                    onPressed: hasJournalEntry ? () => _openJournalEntry(context, journalEntryId) : null,
                    icon: const Icon(Icons.article_outlined),
                    label: const Text('Open Journal'),
                  ),
                  OutlinedButton.icon(
                    onPressed: run.status == 'Draft' || run.status == 'Approved' ? () => _run(context, () => commands.voidRun(run.id)) : null,
                    icon: const Icon(Icons.block_outlined),
                    label: const Text('Void'),
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

class _PayrollRunDetailsDialog extends ConsumerWidget {
  const _PayrollRunDetailsDialog({required this.runId});

  final String runId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(payrollRunDetailsProvider(runId));
    return AlertDialog(
      title: const Text('Payroll Run Details'),
      content: SizedBox(
        width: 900,
        child: detailsAsync.when(
          loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
          error: (error, _) => _InlineError(
            message: error.toString(),
            onRetry: () => ref.invalidate(payrollRunDetailsProvider(runId)),
          ),
          data: (details) => _PayrollRunDetailsView(details: details),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
      ],
    );
  }
}

class _PayrollRunDetailsView extends StatelessWidget {
  const _PayrollRunDetailsView({required this.details});

  final PayrollRunDetails details;

  @override
  Widget build(BuildContext context) {
    final journalEntryId = details.journalEntryId;
    final hasJournalEntry = journalEntryId != null && journalEntryId.isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(label: 'Run', value: details.runNumber),
              _InfoChip(label: 'Status', value: details.status),
              _InfoChip(label: 'Period', value: '${_date(details.periodStart)} → ${_date(details.periodEnd)}'),
              _InfoChip(label: 'Pay Date', value: _date(details.payDate)),
              _InfoChip(label: 'Tax Rate', value: '${(details.taxWithholdingRate * 100).toStringAsFixed(2)}%'),
              if (hasJournalEntry)
                ActionChip(
                  avatar: const Icon(Icons.article_outlined, size: 18),
                  label: Text('Open Journal: $journalEntryId'),
                  onPressed: () => _openJournalEntry(context, journalEntryId, closeDialog: true),
                ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 720 ? 4 : 2;
              return GridView.count(
                crossAxisCount: columns,
                childAspectRatio: 2.3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _RunMetric('Employees', details.employeeCount.toString(), Icons.people_outline, Colors.blue),
                  _RunMetric('Gross', '${details.currency} ${details.totalGrossPay.toStringAsFixed(2)}', Icons.trending_up_outlined, Colors.green),
                  _RunMetric('Deductions', '${details.currency} ${details.totalDeductions.toStringAsFixed(2)}', Icons.remove_circle_outline, Colors.orange),
                  _RunMetric('Net Pay', '${details.currency} ${details.totalNetPay.toStringAsFixed(2)}', Icons.account_balance_wallet_outlined, Colors.deepPurple),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Text('Employee Lines', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Employee')),
                DataColumn(label: Text('Regular')),
                DataColumn(label: Text('OT')),
                DataColumn(label: Text('Rate')),
                DataColumn(label: Text('Gross')),
                DataColumn(label: Text('Deductions')),
                DataColumn(label: Text('Net')),
              ],
              rows: details.lines
                  .map(
                    (line) => DataRow(
                      cells: [
                        DataCell(Text('${line.employeeNumber} - ${line.employeeName}')),
                        DataCell(Text(line.regularHours.toStringAsFixed(2))),
                        DataCell(Text(line.overtimeHours.toStringAsFixed(2))),
                        DataCell(Text(line.hourlyRate.toStringAsFixed(2))),
                        DataCell(Text(line.grossPay.toStringAsFixed(2))),
                        DataCell(Text(line.deductions.toStringAsFixed(2))),
                        DataCell(Text(line.netPay.toStringAsFixed(2))),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Chip(label: Text('$label: $value'));
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, status);
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(status),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
        ],
      ),
    );
  }
}

Future<void> _showCreateRunSheet(BuildContext context, WidgetRef ref, PayrollSetup setup) async {
  final formKey = GlobalKey<FormState>();
  final schedule = TextEditingController(text: setup.settings.defaultPaySchedule);
  final regularHours = TextEditingController(text: setup.settings.workWeekHours.toString());
  final overtimeHours = TextEditingController(text: '0');
  final taxRate = TextEditingController(text: '0.10');
  final today = DateTime.now();
  var periodStart = DateTime(today.year, today.month, 1);
  var periodEnd = DateTime(today.year, today.month + 1, 0);
  var payDate = DateTime(today.year, today.month + 1, 5);
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
                Text('Create Payroll Run', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 18),
                _DatePickerTile(label: 'Period start', date: periodStart, onPick: (date) => setState(() => periodStart = date)),
                _DatePickerTile(label: 'Period end', date: periodEnd, onPick: (date) => setState(() => periodEnd = date)),
                _DatePickerTile(label: 'Pay date', date: payDate, onPick: (date) => setState(() => payDate = date)),
                TextFormField(controller: schedule, decoration: const InputDecoration(labelText: 'Pay schedule'), validator: _required),
                const SizedBox(height: 12),
                TextFormField(controller: regularHours, decoration: const InputDecoration(labelText: 'Regular hours per employee'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _numberRequired),
                const SizedBox(height: 12),
                TextFormField(controller: overtimeHours, decoration: const InputDecoration(labelText: 'Overtime hours per employee'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _numberRequired),
                const SizedBox(height: 12),
                TextFormField(controller: taxRate, decoration: const InputDecoration(labelText: 'Tax withholding rate, e.g. 0.10'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _numberRequired),
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
                                await ref.read(payrollRunCommandsProvider).create(
                                      periodStart: periodStart,
                                      periodEnd: periodEnd,
                                      payDate: payDate,
                                      paySchedule: schedule.text.trim(),
                                      regularHoursPerEmployee: double.parse(regularHours.text.trim()),
                                      overtimeHoursPerEmployee: double.parse(overtimeHours.text.trim()),
                                      taxWithholdingRate: double.parse(taxRate.text.trim()),
                                    );
                                if (context.mounted) Navigator.of(context).pop();
                              } catch (error) {
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
                                setState(() => saving = false);
                              }
                            },
                      icon: saving ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
                      label: const Text('Create'),
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

  schedule.dispose();
  regularHours.dispose();
  overtimeHours.dispose();
  taxRate.dispose();
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({required this.label, required this.date, required this.onPick});

  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_today_outlined),
      title: Text(_date(date)),
      subtitle: Text(label),
      trailing: TextButton(
        onPressed: () async {
          final selected = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2100));
          if (selected != null) onPick(selected);
        },
        child: const Text('Change'),
      ),
    );
  }
}

Future<void> _showRunDetailsDialog(BuildContext context, String runId) async {
  await showDialog<void>(
    context: context,
    builder: (_) => _PayrollRunDetailsDialog(runId: runId),
  );
}

Future<void> _run(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
  } catch (error) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
  }
}

void _openJournalEntry(BuildContext context, String journalEntryId, {bool closeDialog = false}) {
  final router = GoRouter.of(context);
  if (closeDialog) Navigator.of(context).pop();
  router.go(AppRoutes.journalEntryDetails.replaceFirst(':id', journalEntryId));
}

Color _statusColor(BuildContext context, String status) => switch (status) {
      'Draft' => Colors.blue,
      'Approved' => Colors.green,
      'Posted' => Colors.deepPurple,
      'Void' => Theme.of(context).colorScheme.error,
      _ => Theme.of(context).colorScheme.primary,
    };

String? _required(String? value) => value == null || value.trim().isEmpty ? 'Required' : null;
String? _numberRequired(String? value) => double.tryParse(value ?? '') == null ? 'Enter a valid number' : null;
String _date(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
