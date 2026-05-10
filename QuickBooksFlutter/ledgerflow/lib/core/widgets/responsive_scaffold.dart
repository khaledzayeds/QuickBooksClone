import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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

    if (isWide) {
      return Scaffold(
        body: Column(
          children: [
            const TopMenuBar(),
            Expanded(
              child: Row(
                children: [
                  const SidebarMenu(),
                  Expanded(
                    child: Column(
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
                  ),
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
    final cs = theme.colorScheme;
    final label = routeTitle(location);

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          _NavIconButton(
            tooltip: 'Back',
            enabled: canGoBack,
            onPressed: onBack,
            icon: PhosphorIconsRegular.arrowLeft,
          ),
          const Gap(3),
          _NavIconButton(
            tooltip: 'Forward',
            enabled: canGoForward,
            onPressed: onForward,
            icon: PhosphorIconsRegular.arrowRight,
          ),
          const Gap(9),
          Icon(PhosphorIconsRegular.folderSimple, size: 15, color: cs.primary),
          const Gap(6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            location,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.65),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  const _NavIconButton({
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 25,
          height: 25,
          child: Icon(
            icon,
            size: 15,
            color: enabled ? cs.onSurfaceVariant : cs.onSurfaceVariant.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}
