import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/time_entries_provider.dart';

class EnterTimeScreen extends ConsumerWidget {
  const EnterTimeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(timeEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Time'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(timeEntriesProvider),
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEntrySheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Time Entry'),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(timeEntriesProvider),
        ),
        data: (entries) => _EnterTimeBody(entries: entries),
      ),
    );
  }
}

class _EnterTimeBody extends ConsumerWidget {
  const _EnterTimeBody({required this.entries});

  final TimeEntryList entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Time Tracking',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Backend workflow: Open → Approved → Billable → Invoiced. Frontend only displays and submits time entry actions.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1024 ? 4 : constraints.maxWidth >= 680 ? 2 : 1;
            return GridView.count(
              crossAxisCount: columns,
              childAspectRatio: columns == 1 ? 3.5 : 2.15,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: [
                _SummaryTile('Entries', entries.totalCount.toString(), Icons.list_alt_outlined, cs.primary),
                _SummaryTile('Total Hours', entries.totalHours.toStringAsFixed(2), Icons.schedule_outlined, Colors.blue),
                _SummaryTile('Billable', entries.billableHours.toStringAsFixed(2), Icons.attach_money_outlined, Colors.green),
                _SummaryTile('Non-Billable', entries.nonBillableHours.toStringAsFixed(2), Icons.money_off_outlined, Colors.orange),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        if (entries.items.isEmpty)
          const _EmptyState()
        else
          ...entries.items.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TimeEntryCard(entry: entry),
              )),
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
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.14),
              child: Icon(icon, color: color),
            ),
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

class _TimeEntryCard extends ConsumerWidget {
  const _TimeEntryCard({required this.entry});

  final TimeEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = _statusColor(context, entry.status);
    final commands = ref.read(timeEntriesCommandsProvider);
    final invoiceId = entry.invoiceId;
    final canMarkBillable = entry.status == TimeEntryStatus.approved && entry.isBillable;
    final canMarkInvoiced = entry.status == TimeEntryStatus.approved || entry.status == TimeEntryStatus.billable;

    return Card(
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
                  child: Icon(Icons.timer_outlined, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.activity, style: const TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text('${entry.personName} • ${_date(entry.workDate)}'),
                      if ((entry.customerName ?? '').isNotEmpty || (entry.serviceItemName ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text([
                          if ((entry.customerName ?? '').isNotEmpty) entry.customerName!,
                          if ((entry.serviceItemName ?? '').isNotEmpty) entry.serviceItemName!,
                        ].join(' • ')),
                      ],
                      if (invoiceId != null && invoiceId.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Invoice link: $invoiceId', style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                      if ((entry.notes ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(entry.notes!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${entry.hours.toStringAsFixed(2)} h', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    _StatusChip(status: entry.status),
                    const SizedBox(height: 6),
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(entry.isBillable ? 'Billable time' : 'Non-billable'),
                    ),
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
                  onPressed: entry.status == TimeEntryStatus.open ? () => _run(context, () => commands.approve(entry.id)) : null,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Approve'),
                ),
                OutlinedButton.icon(
                  onPressed: canMarkBillable ? () => _run(context, () => commands.markBillable(entry.id)) : null,
                  icon: const Icon(Icons.attach_money_outlined),
                  label: const Text('Mark Billable'),
                ),
                OutlinedButton.icon(
                  onPressed: canMarkInvoiced ? () => _showMarkInvoicedSheet(context, ref, entry) : null,
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Mark Invoiced'),
                ),
                OutlinedButton.icon(
                  onPressed: entry.status == TimeEntryStatus.invoiced || entry.status == TimeEntryStatus.voided
                      ? null
                      : () => _run(context, () => commands.voidEntry(entry.id)),
                  icon: const Icon(Icons.block_outlined),
                  label: const Text('Void'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final TimeEntryStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, status);
    final label = switch (status) {
      TimeEntryStatus.open => 'Open',
      TimeEntryStatus.approved => 'Approved',
      TimeEntryStatus.billable => 'Billable',
      TimeEntryStatus.invoiced => 'Invoiced',
      TimeEntryStatus.voided => 'Void',
    };

    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.timer_outlined, size: 42, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text('No time entries yet', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Create billable or non-billable time entries and manage their approval status.'),
          ],
        ),
      ),
    );
  }
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
                const Text('Could not load time entries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
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

Future<void> _showEntrySheet(BuildContext context, WidgetRef ref) async {
  final formKey = GlobalKey<FormState>();
  final personController = TextEditingController();
  final hoursController = TextEditingController();
  final activityController = TextEditingController();
  final notesController = TextEditingController();
  var workDate = DateTime.now();
  var isBillable = true;
  var saving = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New Time Entry', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 18),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: Text(_date(workDate)),
                    subtitle: const Text('Work date'),
                    trailing: TextButton(
                      onPressed: () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: workDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (selected != null) setState(() => workDate = selected);
                      },
                      child: const Text('Change'),
                    ),
                  ),
                  TextFormField(
                    controller: personController,
                    decoration: const InputDecoration(labelText: 'Person name'),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: hoursController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Hours'),
                    validator: (value) {
                      final parsed = double.tryParse(value ?? '');
                      if (parsed == null || parsed <= 0 || parsed > 24) return 'Enter hours between 0 and 24';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: activityController,
                    decoration: const InputDecoration(labelText: 'Activity'),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(labelText: 'Notes'),
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Billable'),
                    value: isBillable,
                    onChanged: (value) => setState(() => isBillable = value),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Customer and service item are optional at draft entry time, but backend requires them before moving billable time to Billable/Invoiced.',
                  ),
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
                                  await ref.read(timeEntriesCommandsProvider).create(
                                        workDate: workDate,
                                        personName: personController.text.trim(),
                                        hours: double.parse(hoursController.text.trim()),
                                        activity: activityController.text.trim(),
                                        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                                        isBillable: isBillable,
                                      );
                                  if (context.mounted) Navigator.of(context).pop();
                                } catch (error) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
                                  }
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
        );
      },
    ),
  );

  personController.dispose();
  hoursController.dispose();
  activityController.dispose();
  notesController.dispose();
}

Future<void> _showMarkInvoicedSheet(BuildContext context, WidgetRef ref, TimeEntry entry) async {
  final invoiceController = TextEditingController(text: entry.invoiceId ?? '');
  var saving = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mark Time Entry Invoiced', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text('${entry.activity} • ${entry.hours.toStringAsFixed(2)} h'),
            const SizedBox(height: 16),
            TextField(
              controller: invoiceController,
              decoration: const InputDecoration(
                labelText: 'Invoice ID (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text('If an invoice ID is provided, the backend validates that the invoice exists before linking it.'),
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
                          setState(() => saving = true);
                          try {
                            final invoiceId = invoiceController.text.trim();
                            await ref.read(timeEntriesCommandsProvider).markInvoiced(
                                  entry.id,
                                  invoiceId: invoiceId.isEmpty ? null : invoiceId,
                                );
                            if (context.mounted) Navigator.of(context).pop();
                          } catch (error) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
                            }
                            setState(() => saving = false);
                          }
                        },
                  icon: saving ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.receipt_long_outlined),
                  label: const Text('Mark Invoiced'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  invoiceController.dispose();
}

Future<void> _run(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

Color _statusColor(BuildContext context, TimeEntryStatus status) => switch (status) {
      TimeEntryStatus.open => Colors.blue,
      TimeEntryStatus.approved => Colors.green,
      TimeEntryStatus.billable => Colors.teal,
      TimeEntryStatus.invoiced => Colors.deepPurple,
      TimeEntryStatus.voided => Theme.of(context).colorScheme.error,
    };

String _date(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
