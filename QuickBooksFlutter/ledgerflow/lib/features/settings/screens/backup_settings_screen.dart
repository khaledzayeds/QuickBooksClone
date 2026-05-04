import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

class BackupSettingsScreen extends ConsumerWidget {
  const BackupSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runtimeAsync = ref.watch(runtimeSettingsProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup Settings'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(runtimeSettingsProvider),
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: runtimeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(runtimeSettingsProvider),
        ),
        data: (runtime) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Database & Backup', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(
                'Review current database runtime and prepare backup/restore operations. Backup execution endpoints are the next backend step.',
                style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: cs.primaryContainer,
                            child: Icon(Icons.storage_outlined, color: cs.onPrimaryContainer),
                          ),
                          const SizedBox(width: 12),
                          Text('Runtime Database', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _InfoRow(label: 'Environment', value: runtime.environmentName),
                      _InfoRow(label: 'Provider', value: runtime.databaseProvider),
                      _InfoRow(label: 'Supports Backup/Restore', value: runtime.supportsBackupRestore ? 'Yes' : 'No'),
                      _InfoRow(label: 'Live Database Path', value: _safe(runtime.liveDatabasePath)),
                      _InfoRow(label: 'Backup Directory', value: _safe(runtime.backupDirectory)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _StatusBanner(supported: runtime.supportsBackupRestore),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: cs.secondaryContainer,
                            child: Icon(Icons.backup_outlined, color: cs.onSecondaryContainer),
                          ),
                          const SizedBox(width: 12),
                          Text('Backup Actions', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'These actions are intentionally disabled until backend endpoints are added. The UI is ready to be wired to create, list, download, and restore backup operations.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: const [
                          FilledButton.icon(
                            onPressed: null,
                            icon: Icon(Icons.save_alt_outlined),
                            label: Text('Backup Now'),
                          ),
                          OutlinedButton.icon(
                            onPressed: null,
                            icon: Icon(Icons.restore_outlined),
                            label: Text('Restore Backup'),
                          ),
                          OutlinedButton.icon(
                            onPressed: null,
                            icon: Icon(Icons.folder_open_outlined),
                            label: Text('Open Backup Folder'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: cs.tertiaryContainer,
                            child: Icon(Icons.schedule_outlined, color: cs.onTertiaryContainer),
                          ),
                          const SizedBox(width: 12),
                          Text('Backup Policy', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Daily automatic backup'),
                        subtitle: const Text('Will be enabled after backend scheduler/desktop background task is implemented.'),
                        value: false,
                        onChanged: null,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Ask before restore'),
                        subtitle: const Text('Restore operation will require confirmation and a safe rollback strategy.'),
                        value: true,
                        onChanged: null,
                      ),
                      const SizedBox(height: 8),
                      const TextField(
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'Retention Days',
                          hintText: '30',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.history_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _safe(String? value) => value?.isNotEmpty == true ? value! : '-';
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(child: SelectableText(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.supported});
  final bool supported;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: supported ? cs.primaryContainer : cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(supported ? Icons.check_circle_outline : Icons.warning_amber_outlined,
              color: supported ? cs.onPrimaryContainer : cs.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              supported
                  ? 'This database provider reports backup/restore support. Backend action endpoints still need to be wired.'
                  : 'This database provider does not currently report backup/restore support.',
              style: TextStyle(color: supported ? cs.onPrimaryContainer : cs.onErrorContainer),
            ),
          ),
        ],
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
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: cs.error, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
