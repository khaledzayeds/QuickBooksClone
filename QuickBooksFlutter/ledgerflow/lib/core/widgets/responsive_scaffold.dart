import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'sidebar_menu.dart';
import 'top_bar.dart';
import 'top_menu_bar.dart';

class ResponsiveScaffold extends StatefulWidget {
  const ResponsiveScaffold({super.key, required this.child});
  final Widget child;

  static const _sidebarBreakpoint = 800.0;

  @override
  State<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold> {
  final _backStack = <String>[];
  final _forwardStack = <String>[];
  String? _currentLocation;
  bool _navigatingHistory = false;

  void _trackLocation(String location) {
    if (_currentLocation == location) return;

    if (_currentLocation != null && !_navigatingHistory) {
      _backStack.add(_currentLocation!);
      _forwardStack.clear();
    }

    _currentLocation = location;
    _navigatingHistory = false;
  }

  void _goBack() {
    if (_backStack.isEmpty || _currentLocation == null) return;
    final previous = _backStack.removeLast();
    _forwardStack.add(_currentLocation!);
    _navigatingHistory = true;
    context.go(previous);
  }

  void _goForward() {
    if (_forwardStack.isEmpty || _currentLocation == null) return;
    final next = _forwardStack.removeLast();
    _backStack.add(_currentLocation!);
    _navigatingHistory = true;
    context.go(next);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= ResponsiveScaffold._sidebarBreakpoint;
    _trackLocation(GoRouterState.of(context).uri.toString());

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
                        _WorkspaceNavigationBar(
                          canGoBack: _backStack.isNotEmpty,
                          canGoForward: _forwardStack.isNotEmpty,
                          onBack: _goBack,
                          onForward: _goForward,
                          location: _currentLocation ?? '/',
                        ),
                        Expanded(child: widget.child),
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
      appBar: AppBar(title: const Text('LedgerFlow')),
      drawer: const Drawer(child: SidebarMenu()),
      body: Column(
        children: [
          _WorkspaceNavigationBar(
            canGoBack: _backStack.isNotEmpty,
            canGoForward: _forwardStack.isNotEmpty,
            onBack: _goBack,
            onForward: _goForward,
            location: _currentLocation ?? '/',
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

class _WorkspaceNavigationBar extends StatelessWidget {
  const _WorkspaceNavigationBar({
    required this.canGoBack,
    required this.canGoForward,
    required this.onBack,
    required this.onForward,
    required this.location,
  });

  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final String location;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = location == '/' ? 'Home' : location.replaceFirst('/', '');

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            tooltip: 'Back',
            onPressed: canGoBack ? onBack : null,
            icon: const Icon(Icons.arrow_back, size: 18),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            tooltip: 'Forward',
            onPressed: canGoForward ? onForward : null,
            icon: const Icon(Icons.arrow_forward, size: 18),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.folder_open_outlined,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
