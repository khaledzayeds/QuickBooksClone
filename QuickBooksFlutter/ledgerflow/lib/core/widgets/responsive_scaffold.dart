// responsive_scaffold.dart

import 'package:flutter/material.dart';
import 'sidebar_menu.dart';
import 'top_bar.dart';
import 'top_menu_bar.dart';

class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({super.key, required this.child});
  final Widget child;

  static const _sidebarBreakpoint = 800.0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= _sidebarBreakpoint;

    if (isWide) {
      return Scaffold(
        body: Column(
          children: [
            const TopMenuBar(), // QuickBooks Desktop Top Menu
            Expanded(
              child: Row(
                children: [
                  const SidebarMenu(),
                  Expanded(
                    child: Column(
                      children: [
                        const TopBar(),
                        Expanded(child: child),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile: drawer
    return Scaffold(
      appBar: AppBar(
        title: const Text('LedgerFlow'),
      ),
      drawer: const Drawer(child: SidebarMenu()),
      body: child,
    );
  }
}