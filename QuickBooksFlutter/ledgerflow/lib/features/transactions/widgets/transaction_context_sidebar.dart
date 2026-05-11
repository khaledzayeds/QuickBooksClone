import 'package:flutter/material.dart';

import 'transaction_models.dart';

class TransactionContextSidebar extends StatelessWidget {
  const TransactionContextSidebar({
    super.key,
    required this.title,
    required this.emptyTitle,
    required this.emptyMessage,
    this.subtitle,
    this.initials,
    this.metrics = const [],
    this.activities = const [],
    this.notes,
    this.warning,
    this.isLoading = false,
    this.totals,
    this.onViewAll,
    this.onEditNotes,
  });

  final String title;
  final String emptyTitle;
  final String emptyMessage;
  final String? subtitle;
  final String? initials;
  final List<TransactionContextMetric> metrics;
  final List<TransactionContextActivity> activities;
  final String? notes;
  final String? warning;
  final bool isLoading;
  final TransactionTotalsUiModel? totals;
  final VoidCallback? onViewAll;
  final VoidCallback? onEditNotes;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasParty = initials != null && title.trim().isNotEmpty;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(left: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.7))),
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasParty
              ? SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PartyCard(title: title, subtitle: subtitle, initials: initials!),
                      if (warning != null && warning!.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _WarningCard(message: warning!),
                      ],
                      if (metrics.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _MetricsCard(metrics: metrics),
                      ],
                      if (totals != null) ...[
                        const SizedBox(height: 12),
                        _SummaryCard(totals: totals!),
                      ],
                      const SizedBox(height: 12),
                      DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            Material(
                              color: cs.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                              child: TabBar(
                                indicatorSize: TabBarIndicatorSize.tab,
                                dividerColor: Colors.transparent,
                                tabs: const [
                                  Tab(text: 'Transactions'),
                                  Tab(text: 'Notes'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 320,
                              child: TabBarView(
                                physics: const ClampingScrollPhysics(),
                                children: [
                                  _ActivityCard(activities: activities, onViewAll: onViewAll),
                                  _NotesCard(notes: notes, onEditNotes: onEditNotes),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  child: _EmptyCard(title: emptyTitle, message: emptyMessage),
                ),
    );
  }
}

class _PartyCard extends StatelessWidget {
  const _PartyCard({required this.title, required this.initials, this.subtitle});

  final String title;
  final String initials;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      elevation: 0,
      color: cs.primaryContainer.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: cs.primary.withValues(alpha: 0.14))),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: cs.primary,
              child: Text(initials, style: TextStyle(fontWeight: FontWeight.w900, color: cs.onPrimary, fontSize: 18)),
            ),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(subtitle!, textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({required this.metrics});

  final List<TransactionContextMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: cs.outlineVariant)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: metrics
              .map((metric) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        CircleAvatar(radius: 17, backgroundColor: cs.primaryContainer.withValues(alpha: 0.45), child: Icon(metric.icon, size: 18, color: cs.primary)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(metric.label, style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant))),
                        Text(metric.value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.totals});

  final TransactionTotalsUiModel totals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: cs.outlineVariant)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Summary', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: cs.primary)),
            const Divider(height: 22),
            _TotalRow('Subtotal', totals.subtotal, totals.currency),
            _TotalRow('Discount', totals.discountTotal, totals.currency),
            _TotalRow('Tax', totals.taxTotal, totals.currency),
            const Divider(height: 18),
            _TotalRow('Total', totals.total, totals.currency, strong: true),
          ],
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(this.label, this.value, this.currency, {this.strong = false});

  final String label;
  final double value;
  final String currency;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: strong ? FontWeight.w900 : FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [Expanded(child: Text(label, style: style)), Text('${value.toStringAsFixed(2)} $currency', style: style)]),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activities, this.onViewAll});

  final List<TransactionContextActivity> activities;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: cs.outlineVariant)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text('Recent Transactions', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900))), TextButton(onPressed: onViewAll, child: const Text('View All'))]),
          if (activities.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('No recent transactions found.', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant))))
          else
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: activities.take(6).map((activity) => ListTile(contentPadding: EdgeInsets.zero, dense: true, title: Text(activity.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(activity.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis), trailing: activity.amount == null ? null : Text(activity.amount!, style: const TextStyle(fontWeight: FontWeight.w900)))).toList(),
              ),
            ),
        ]),
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({this.notes, this.onEditNotes});

  final String? notes;
  final VoidCallback? onEditNotes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: cs.outlineVariant)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text('Notes', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900))), TextButton(onPressed: onEditNotes, child: const Text('Edit'))]),
          Expanded(
            child: SingleChildScrollView(
              child: Text(notes?.trim().isNotEmpty == true ? notes! : 'No notes added.', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.errorContainer.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(14), border: Border.all(color: cs.error.withValues(alpha: 0.18))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.warning_amber_outlined, color: cs.error, size: 20), const SizedBox(width: 8), Expanded(child: Text(message, style: TextStyle(color: cs.onErrorContainer, fontWeight: FontWeight.w600)))]),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return SizedBox(
      height: 360,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(radius: 34, backgroundColor: cs.surfaceContainerHighest, child: Icon(Icons.info_outline, size: 34, color: cs.outline)),
          const SizedBox(height: 16),
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant))),
        ]),
      ),
    );
  }
}
