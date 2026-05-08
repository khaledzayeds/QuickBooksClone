import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/open_windows_provider.dart';

class OpenWindowsScreen extends ConsumerWidget {
  const OpenWindowsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final windows = ref.watch(openWindowsProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Windows'),
        actions: [
          TextButton.icon(
            onPressed: windows.isEmpty
                ? null
                : () => ref.read(openWindowsProvider.notifier).clear(),
            icon: const Icon(Icons.close_fullscreen_outlined, size: 18),
            label: const Text('Close All'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: windows.isEmpty
          ? const _EmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemBuilder: (context, index) {
                final entry = windows[index];
                final isCurrent = GoRouterState.of(context).uri.toString() == entry.path;

                return Card(
                  elevation: isCurrent ? 1 : 0,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCurrent ? cs.primaryContainer : cs.surfaceContainerHighest,
                      child: Icon(
                        isCurrent ? Icons.radio_button_checked : Icons.window_outlined,
                        color: isCurrent ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                      ),
                    ),
                    title: Text(
                      entry.title,
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(entry.path),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          tooltip: 'Open',
                          onPressed: isCurrent ? null : () => context.go(entry.path),
                          icon: const Icon(Icons.open_in_new),
                        ),
                        IconButton(
                          tooltip: 'Close from list',
                          onPressed: () => ref.read(openWindowsProvider.notifier).close(entry.path),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    onTap: isCurrent ? null : () => context.go(entry.path),
                  ),
                );
              },
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemCount: windows.length,
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: cs.primaryContainer,
                  child: Icon(Icons.window_outlined, size: 34, color: cs.onPrimaryContainer),
                ),
                const SizedBox(height: 18),
                Text(
                  'No open windows yet',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  'Navigate through the application and recently opened work areas will appear here for quick switching.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Go to Dashboard'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
