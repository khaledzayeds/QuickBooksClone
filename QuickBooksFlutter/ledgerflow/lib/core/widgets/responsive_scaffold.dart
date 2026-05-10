import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/open_windows_provider.dart';
import 'sidebar_menu.dart';
import 'top_menu_bar.dart';

class ResponsiveScaffold extends ConsumerStatefulWidget {
  const ResponsiveScaffold({super.key, required this.child});
  final Widget child;

  static const _sidebarBreakpoint = 800.0;

  @override
  ConsumerState<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends ConsumerState<ResponsiveScaffold> {
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(openWindowsProvider.notifier).open(location);
    });
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

    final topMenu = TopMenuBar(
      canGoBack: _backStack.isNotEmpty,
      canGoForward: _forwardStack.isNotEmpty,
      onBack: _goBack,
      onForward: _goForward,
      location: _currentLocation ?? '/',
    );

    if (isWide) {
      return Scaffold(
        body: Column(
          children: [
            topMenu,
            Expanded(
              child: Row(
                children: [
                  const SidebarMenu(),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('LedgerFlow'),
        actions: const [SizedBox(width: 8)],
      ),
      drawer: const Drawer(child: SidebarMenu()),
      body: widget.child,
    );
  }
}
