import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/backup_models.dart';
import '../providers/backup_provider.dart';
import '../providers/settings_provider.dart';

class BackupSettingsScreen extends ConsumerWidget {
  const BackupSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runtimeAsync = ref.watch(runtimeSettingsProvider);
    final backupState = ref.watch(backupProvider);
    final backupNotifier = ref.read(backupProvider.notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    ref.listen(backupProvider, (previous, next) {
      if (next.successMessage != null && previous?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.successMessage!)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup Settings'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(runtimeSettingsProvider);
              backupNotifier.load();
            },
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
                'Create, list, and restore SQLite company backups. These API actions are protected by the Backup/Restore license feature.',
                style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              if (backupState.errorMessage != null) ...[
                const SizedBox(height: 16),
                _ErrorBanner(message: backupState.errorMessage!),
              ],
              const SizedBox(height: 24),
              _RuntimeCard(runtime: runtime),
              const SizedBox(height: 16),
              _StatusBanner(supported: runtime.supportsBackupRestore),
              const SizedBox(height: 16),
              _ActionCard(
                working: backupState.working,
                supported: runtime.supportsBackupRestore,
                onBackupNow: () => _showCreateBackupDialog(context, backupNotifier),
              ),
              const SizedBox(height: 16),
              _BackupListCard(
                loading: backupState.loading,
                backups: backupState.backups,
                working: backupState.working,
                onRestore: (backup) => _showRestoreDialog(context, backupNotifier, backup),
              ),
              const SizedBox(height: 16),
              _PolicyCard(settings: backupState.settings),
              const SizedBox(height: 16),
              _RestoreAuditCard(audits: backupState.audits),
            ],
          );
        },
      ),
    );
  }

  static Future<void> _showCreateBackupDialog(BuildContext context, BackupNotifier notifier) async {
    final labelController = TextEditingController();
    final reasonController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: labelController, decoration: const InputDecoration(labelText: 'Label', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: reasonController, decoration: const InputDecoration(labelText: 'Reason', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
        ],
      ),
    );

    if (result == true) {
      await notifier.createBackup(label: labelController.text, reason: reasonController.text);
    }
  }

  static Future<void> _showRestoreDialog(BuildContext context, BackupNotifier notifier, BackupFileModel backup) async {
    final reasonController = TextEditingController(text: 'Manual restore');
    var createSafetyBackup = true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Restore Backup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('This will overwrite the live company database with:'),
              const SizedBox(height: 8),
              SelectableText(backup.fileName, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: createSafetyBackup,
                onChanged: (value) => setState(() => createSafetyBackup = value ?? true),
                title: const Text('Create safety backup before restore'),
              ),
              const SizedBox(height: 12),
              TextField(controller: reasonController, decoration: const InputDecoration(labelText: 'Reason', border: OutlineInputBorder())),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton.tonalIcon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.warning_amber_outlined),
              label: const Text('Restore'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await notifier.restoreBackup(fileName: backup.fileName, createSafetyBackup: createSafetyBackup, reason: reasonController.text);
    }
  }
}

class _RuntimeCard extends StatelessWidget {
  const _RuntimeCard({required this.runtime});
  final dynamic runtime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: cs.primaryContainer, child: Icon(Icons.storage_outlined, color: cs.onPrimaryContainer)),
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
    );
  }

  static String _safe(String? value) => value?.isNotEmpty == true ? value! : '-';
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.working, required this.supported, required this.onBackupNow});
  final bool working;
  final bool supported;
  final VoidCallback onBackupNow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: cs.secondaryContainer, child: Icon(Icons.backup_outlined, color: cs.onSecondaryContainer)),
                const SizedBox(width: 12),
                Text('Backup Actions', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 12),
            Text('Create manual backups and restore saved database backups.', style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: working || !supported ? null : onBackupNow,
                  icon: working ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_alt_outlined),
                  label: const Text('Backup Now'),
                ),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Import Backup'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupListCard extends StatelessWidget {
  const _BackupListCard({required this.loading, required this.backups, required this.working, required this.onRestore});
  final bool loading;
  final bool working;
  final List<BackupFileModel> backups;
  final ValueChanged<BackupFileModel> onRestore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available Backups', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            if (loading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (backups.isEmpty)
              const Padding(padding: EdgeInsets.all(16), child: Text('No backups found yet.'))
            else
              ...backups.map((backup) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.storage_outlined),
                    title: Text(backup.fileName, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${backup.backupKind} • ${_formatBytes(backup.sizeBytes)} • ${backup.createdAtIso}'),
                    trailing: OutlinedButton.icon(
                      onPressed: working ? null : () => onRestore(backup),
                      icon: const Icon(Icons.restore_outlined),
                      label: const Text('Restore'),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({required this.settings});
  final DatabaseMaintenanceSettingsModel? settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: cs.tertiaryContainer, child: Icon(Icons.schedule_outlined, color: cs.onTertiaryContainer)),
                const SizedBox(width: 12),
                Text('Backup Policy', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(label: 'Auto Backup', value: settings?.autoBackupEnabled == true ? 'Enabled' : 'Disabled'),
            _InfoRow(label: 'Schedule', value: settings?.scheduleMode ?? '-'),
            _InfoRow(label: 'Run Hour', value: settings?.runAtHourLocal.toString() ?? '-'),
            _InfoRow(label: 'Retention Count', value: settings?.retentionCount.toString() ?? '-'),
            _InfoRow(label: 'Safety Backup Before Restore', value: settings?.createSafetyBackupBeforeRestore == true ? 'Yes' : 'No'),
          ],
        ),
      ),
    );
  }
}

class _RestoreAuditCard extends StatelessWidget {
  const _RestoreAuditCard({required this.audits});
  final List<RestoreAuditModel> audits;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Restore Audit Log', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            if (audits.isEmpty)
              const Text('No restore operations recorded yet.')
            else
              ...audits.take(8).map((audit) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history_outlined),
                    title: Text(audit.backupFileName, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${audit.restoredAtIso} • Safety backup: ${audit.createdSafetyBackup ? 'Yes' : 'No'}'),
                  )),
          ],
        ),
      ),
    );
  }
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
          SizedBox(width: 190, child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
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
      decoration: BoxDecoration(color: supported ? cs.primaryContainer : cs.errorContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(supported ? Icons.check_circle_outline : Icons.warning_amber_outlined, color: supported ? cs.onPrimaryContainer : cs.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              supported ? 'Backup/restore is available for this database provider.' : 'This database provider does not currently support backup/restore.',
              style: TextStyle(color: supported ? cs.onPrimaryContainer : cs.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.errorContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: TextStyle(color: cs.onErrorContainer))),
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
