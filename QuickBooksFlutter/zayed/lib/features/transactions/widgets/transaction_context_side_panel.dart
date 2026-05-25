import 'package:flutter/material.dart';

import 'transaction_models.dart';

class TransactionContextSidePanel extends StatelessWidget {
  const TransactionContextSidePanel({
    super.key,
    required this.title,
    required this.expanded,
    required this.onToggle,
    this.subtitle,
    this.metrics = const [],
    this.activities = const [],
    this.notes,
    this.warning,
  });

  final String title;
  final String? subtitle;
  final bool expanded;
  final VoidCallback onToggle;
  final List<TransactionContextMetric> metrics;
  final List<TransactionContextActivity> activities;
  final String? notes;
  final String? warning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (!expanded) {
      return SizedBox(
        width: 42,
        child: Card(
          child: InkWell(
            onTap: onToggle,
            child: const Center(child: Icon(Icons.chevron_left)),
          ),
        ),
      );
    }

    return SizedBox(
      width: 340,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
                  IconButton(onPressed: onToggle, icon: const Icon(Icons.chevron_right), tooltip: 'Collapse'),
                ],
              ),
              if (subtitle?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
              const SizedBox(height: 12),
              if (warning?.isNotEmpty == true) ...[
                _WarningBox(text: warning!),
                const SizedBox(height: 12),
              ],
              if (metrics.isNotEmpty) ...[
                Text('Snapshot', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                ...metrics.map((metric) => _MetricTile(metric: metric)),
                const SizedBox(height: 12),
              ],
              if (activities.isNotEmpty) ...[
                Text('Recent activity', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                ...activities.map((activity) => _ActivityTile(activity: activity)),
              ] else ...[
                const _EmptyActivity(),
              ],
              const Spacer(),
              if (notes?.isNotEmpty == true) _NotesBox(notes: notes!),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});
  final TransactionContextMetric metric;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [Icon(metric.icon, color: cs.primary), const SizedBox(width: 10), Expanded(child: Text(metric.label)), Text(metric.value, style: const TextStyle(fontWeight: FontWeight.w900))]),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});
  final TransactionContextActivity activity;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(activity.title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(activity.subtitle),
      trailing: activity.amount == null
          ? null
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(activity.amount!, style: const TextStyle(fontWeight: FontWeight.w900)),
                if (activity.status != null) Text(activity.status!, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
              ],
            ),
    );
  }
}

class _WarningBox extends StatelessWidget {
  const _WarningBox({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: cs.errorContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.warning_amber_outlined, color: cs.onErrorContainer), const SizedBox(width: 8), Expanded(child: Text(text, style: TextStyle(color: cs.onErrorContainer)))]),
    );
  }
}

class _NotesBox extends StatelessWidget {
  const _NotesBox({required this.notes});
  final String notes;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Text(notes, style: TextStyle(color: cs.onSecondaryContainer)),
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity();

  @override
  Widget build(BuildContext context) {
    return const ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.history_outlined),
      title: Text('No activity loaded yet'),
      subtitle: Text('Recent transactions will appear here.'),
    );
  }
}
