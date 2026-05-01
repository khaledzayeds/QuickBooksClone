// features/dashboard/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';
import '../widgets/dashboard_flowchart.dart';
import '../widgets/dashboard_insights.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(40),
        child: Container(
          color: Colors.white,
          alignment: Alignment.bottomLeft,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            indicator: const BoxDecoration(
              color: Color(0xFF0078D4), // QuickBooks Tab Blue
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: cs.onSurface.withValues(alpha: 0.7),
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: [
              Tab(text: l10n.homePage),
              Tab(text: l10n.insights),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DashboardFlowchart(),
          const DashboardInsights(),
        ],
      ),
    );
  }
}