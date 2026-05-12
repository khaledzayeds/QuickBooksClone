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
    final hasParty = initials != null && title.trim().isNotEmpty;

    return Container(
      color: const Color(0xFFF4F7F8),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasParty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PanelHeader(title: title, subtitle: subtitle),
                    if (warning != null && warning!.trim().isNotEmpty)
                      _WarningStrip(message: warning!),
                    Expanded(
                      child: DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            Container(
                              height: 34,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE1E9ED),
                                border: Border(
                                  top: BorderSide(color: Color(0xFFB8C6CE)),
                                  bottom: BorderSide(color: Color(0xFFB8C6CE)),
                                ),
                              ),
                              child: const TabBar(
                                labelPadding: EdgeInsets.zero,
                                indicatorSize: TabBarIndicatorSize.tab,
                                dividerColor: Colors.transparent,
                                tabs: [
                                  Tab(text: 'Customer'),
                                  Tab(text: 'Transaction'),
                                ],
                              ),
                            ),
                            Expanded(
                              child: TabBarView(
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  _CustomerPanel(
                                    metrics: metrics,
                                    activities: activities,
                                    notes: notes,
                                    onViewAll: onViewAll,
                                    onEditNotes: onEditNotes,
                                  ),
                                  _TransactionPanel(totals: totals),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : _EmptyPanel(title: emptyTitle, message: emptyMessage),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
      decoration: const BoxDecoration(
        color: Color(0xFF264D5B),
        border: Border(bottom: BorderSide(color: Color(0xFF183642))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: const Color(0xFFD7E6EB),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CustomerPanel extends StatelessWidget {
  const _CustomerPanel({
    required this.metrics,
    required this.activities,
    this.notes,
    this.onViewAll,
    this.onEditNotes,
  });

  final List<TransactionContextMetric> metrics;
  final List<TransactionContextActivity> activities;
  final String? notes;
  final VoidCallback? onViewAll;
  final VoidCallback? onEditNotes;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Section(
          title: 'Customer Balance Summary',
          child: Column(
            children: metrics.isEmpty
                ? const [_EmptyLine('No balance data yet.')]
                : metrics.take(4).map((metric) {
                    return _InfoRow(label: metric.label, value: metric.value);
                  }).toList(),
          ),
        ),
        _Section(
          title: 'Recent Transactions',
          trailing: TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            child: const Text('View All'),
          ),
          child: Expanded(
            child: activities.isEmpty
                ? const Center(child: _EmptyLine('No recent transactions.'))
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: activities.take(8).length,
                    itemBuilder: (context, index) {
                      final activity = activities[index];
                      return _ActivityLine(activity: activity);
                    },
                  ),
          ),
          expanded: true,
        ),
        _Section(
          title: 'Notes',
          trailing: TextButton(
            onPressed: onEditNotes,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            child: const Text('Edit'),
          ),
          child: Text(
            notes?.trim().isNotEmpty == true ? notes! : 'No notes added.',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF4E616A),
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _TransactionPanel extends StatelessWidget {
  const _TransactionPanel({this.totals});

  final TransactionTotalsUiModel? totals;

  @override
  Widget build(BuildContext context) {
    final t = totals;
    return Column(
      children: [
        _Section(
          title: 'Transaction Summary',
          child: t == null
              ? const _EmptyLine('No transaction totals yet.')
              : Column(
                  children: [
                    _InfoRow(label: 'Subtotal', value: _money(t.subtotal, t.currency)),
                    _InfoRow(label: 'Discount', value: _money(t.discountTotal, t.currency)),
                    _InfoRow(label: 'Tax', value: _money(t.taxTotal, t.currency)),
                    const Divider(height: 14),
                    _InfoRow(label: 'Total', value: _money(t.total, t.currency), strong: true),
                    _InfoRow(label: 'Paid', value: _money(t.paid, t.currency)),
                    _InfoRow(label: 'Balance Due', value: _money(t.balanceDue, t.currency), strong: true),
                  ],
                ),
        ),
        const _Section(
          title: 'Quick Actions',
          child: Column(
            children: [
              _EmptyLine('Receive Payment requires a saved invoice.'),
              SizedBox(height: 6),
              _EmptyLine('Email and refund workflows can be connected later.'),
            ],
          ),
        ),
      ],
    );
  }

  static String _money(double value, String currency) => '${value.toStringAsFixed(2)} $currency';
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.trailing,
    this.expanded = false,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFB8C6CE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 30,
            padding: const EdgeInsetsDirectional.only(start: 8, end: 4),
            decoration: const BoxDecoration(
              color: Color(0xFFE7EEF1),
              border: Border(bottom: BorderSide(color: Color(0xFFB8C6CE))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF2D4854),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: child,
          ),
        ],
      ),
    );

    return expanded ? Expanded(child: content) : content;
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: const Color(0xFF334A55),
      fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style, overflow: TextOverflow.ellipsis)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _ActivityLine extends StatelessWidget {
  const _ActivityLine({required this.activity});

  final TransactionContextActivity activity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE0E6E9))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  activity.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF263E49),
                  ),
                ),
              ),
              if (activity.amount != null)
                Text(
                  activity.amount!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF263E49),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            activity.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(color: const Color(0xFF687980)),
          ),
        ],
      ),
    );
  }
}

class _WarningStrip extends StatelessWidget {
  const _WarningStrip({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
      color: const Color(0xFFFFE7C4),
      child: Text(
        message,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF714600),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_search_outlined, size: 38, color: Color(0xFF8CA0AA)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: const Color(0xFF2D4854),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF667A84),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: const Color(0xFF667A84),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
