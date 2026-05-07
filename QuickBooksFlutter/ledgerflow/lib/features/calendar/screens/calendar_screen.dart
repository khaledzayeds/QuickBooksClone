import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/calendar_provider.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarAsync = ref.watch(calendarProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(calendarProvider),
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: calendarAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(calendarProvider),
        ),
        data: (summary) => _CalendarBody(summary: summary),
      ),
    );
  }
}

class _CalendarBody extends StatelessWidget {
  const _CalendarBody({required this.summary});

  final CalendarSummary summary;

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDate(summary.events);
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
                  Text(
                    'Business Calendar',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Due invoices and bills from backend documents. Range: ${_date(summary.fromDate)} to ${_date(summary.toDate)}.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Chip(
              avatar: const Icon(Icons.today_outlined, size: 16),
              label: Text('Today ${_date(summary.today)}'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1024 ? 4 : constraints.maxWidth >= 680 ? 2 : 1;
            return GridView.count(
              crossAxisCount: columns,
              childAspectRatio: columns == 1 ? 3.5 : 2.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _SummaryTile('Total Events', summary.totalEvents.toString(), Icons.event_note_outlined, Colors.blue),
                _SummaryTile('Overdue', summary.overdueCount.toString(), Icons.warning_amber_outlined, Theme.of(context).colorScheme.error),
                _SummaryTile('Due Today', summary.dueTodayCount.toString(), Icons.today_outlined, Colors.orange),
                _SummaryTile('Upcoming', summary.upcomingCount.toString(), Icons.upcoming_outlined, Colors.green),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final receivable = _AmountPanel(
              title: 'Receivables Due',
              amount: summary.totalReceivableDue,
              icon: Icons.south_west_outlined,
              color: Colors.green,
            );
            final payable = _AmountPanel(
              title: 'Payables Due',
              amount: summary.totalPayableDue,
              icon: Icons.north_east_outlined,
              color: Colors.orange,
            );
            if (!wide) return Column(children: [receivable, const SizedBox(height: 12), payable]);
            return Row(children: [Expanded(child: receivable), const SizedBox(width: 12), Expanded(child: payable)]);
          },
        ),
        const SizedBox(height: 24),
        if (summary.events.isEmpty)
          const _EmptyState()
        else
          for (final entry in grouped.entries) ...[
            _DateHeader(date: entry.key, today: summary.today),
            const SizedBox(height: 8),
            for (final event in entry.value) ...[
              _EventCard(event: event),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 14),
          ],
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

class _AmountPanel extends StatelessWidget {
  const _AmountPanel({required this.title, required this.amount, required this.icon, required this.color});

  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))),
            Text(amount.toStringAsFixed(2), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date, required this.today});

  final DateTime date;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final label = normalizedDate == normalizedToday
        ? 'Today'
        : normalizedDate == normalizedToday.add(const Duration(days: 1))
            ? 'Tomorrow'
            : normalizedDate.isBefore(normalizedToday)
                ? 'Overdue - ${_date(date)}'
                : _date(date);

    return Row(
      children: [
        const Icon(Icons.calendar_month_outlined, size: 18),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(context, event.severity);
    final icon = event.sourceType == 'invoice' ? Icons.receipt_long_outlined : Icons.request_quote_outlined;

    return Card(
      child: InkWell(
        onTap: event.route.isEmpty ? null : () => context.go(event.route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w900))),
                        _SeverityChip(severity: event.severity),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(event.partyName),
                    const SizedBox(height: 4),
                    Text('Document: ${event.documentNumber} • Status: ${event.status}'),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(event.amountDue.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.w900, color: color)),
                  const SizedBox(height: 4),
                  Text('Due ${_date(event.dueDate)}'),
                ],
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  const _SeverityChip({required this.severity});

  final CalendarSeverity severity;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(context, severity);
    final label = switch (severity) {
      CalendarSeverity.overdue => 'Overdue',
      CalendarSeverity.dueToday => 'Due Today',
      CalendarSeverity.soon => 'Soon',
      CalendarSeverity.upcoming => 'Upcoming',
    };

    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
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
            Icon(Icons.event_available_outlined, size: 42, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text('No due invoices or bills in this range', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Posted invoices and purchase bills with open balances will appear here based on their due dates.'),
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
                const Text('Could not load calendar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
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

Map<DateTime, List<CalendarEvent>> _groupByDate(List<CalendarEvent> events) {
  final grouped = <DateTime, List<CalendarEvent>>{};
  for (final event in events) {
    final key = DateTime(event.dueDate.year, event.dueDate.month, event.dueDate.day);
    grouped.putIfAbsent(key, () => []).add(event);
  }
  return Map.fromEntries(grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
}

Color _severityColor(BuildContext context, CalendarSeverity severity) => switch (severity) {
      CalendarSeverity.overdue => Theme.of(context).colorScheme.error,
      CalendarSeverity.dueToday => Colors.orange,
      CalendarSeverity.soon => Colors.blue,
      CalendarSeverity.upcoming => Colors.green,
    };

String _date(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
