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
    final text = _BackupText.of(context);

    ref.listen(backupProvider, (previous, next) {
      if (next.successMessage != null &&
          previous?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.successMessage!)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(text.title),
        actions: [
          IconButton(
            tooltip: text.refresh,
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
              Text(
                text.heading,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                text.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
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
                onBackupNow: () =>
                    _showCreateBackupDialog(context, backupNotifier),
              ),
              const SizedBox(height: 16),
              _BackupListCard(
                loading: backupState.loading,
                backups: backupState.backups,
                working: backupState.working,
                onRestore: (backup) =>
                    _showRestoreDialog(context, backupNotifier, backup),
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

  static Future<void> _showCreateBackupDialog(
    BuildContext context,
    BackupNotifier notifier,
  ) async {
    final labelController = TextEditingController();
    final reasonController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_BackupText.of(context).createBackup),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: InputDecoration(
                labelText: _BackupText.of(context).label,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: _BackupText.of(context).reason,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_BackupText.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_BackupText.of(context).create),
          ),
        ],
      ),
    );

    if (result == true) {
      await notifier.createBackup(
        label: labelController.text,
        reason: reasonController.text,
      );
    }
  }

  static Future<void> _showRestoreDialog(
    BuildContext context,
    BackupNotifier notifier,
    BackupFileModel backup,
  ) async {
    final text = _BackupText.of(context);
    final reasonController = TextEditingController(text: text.manualRestore);
    var createSafetyBackup = true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(text.restoreBackup),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text.restoreWarning),
              const SizedBox(height: 8),
              SelectableText(
                backup.fileName,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: createSafetyBackup,
                onChanged: (value) =>
                    setState(() => createSafetyBackup = value ?? true),
                title: Text(text.safetyBackup),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: text.reason,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(text.cancel),
            ),
            FilledButton.tonalIcon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.warning_amber_outlined),
              label: Text(text.restore),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await notifier.restoreBackup(
        fileName: backup.fileName,
        createSafetyBackup: createSafetyBackup,
        reason: reasonController.text,
      );
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
    final text = _BackupText.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: cs.primaryContainer,
                  child: Icon(
                    Icons.storage_outlined,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  text.runtimeDatabase,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _InfoRow(label: text.environment, value: runtime.environmentName),
            _InfoRow(label: text.provider, value: runtime.databaseProvider),
            _InfoRow(
              label: text.supportsBackupRestore,
              value: runtime.supportsBackupRestore ? text.yes : text.no,
            ),
            _InfoRow(
              label: text.liveDatabasePath,
              value: _safe(runtime.liveDatabasePath),
            ),
            _InfoRow(
              label: text.backupDirectory,
              value: _safe(runtime.backupDirectory),
            ),
          ],
        ),
      ),
    );
  }

  static String _safe(String? value) =>
      value?.isNotEmpty == true ? value! : '-';
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.working,
    required this.supported,
    required this.onBackupNow,
  });
  final bool working;
  final bool supported;
  final VoidCallback onBackupNow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final text = _BackupText.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: cs.secondaryContainer,
                  child: Icon(
                    Icons.backup_outlined,
                    color: cs.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  text.backupActions,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              text.backupActionsDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: working || !supported ? null : onBackupNow,
                  icon: working
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_alt_outlined),
                  label: Text(text.backupNow),
                ),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(text.importBackup),
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
  const _BackupListCard({
    required this.loading,
    required this.backups,
    required this.working,
    required this.onRestore,
  });
  final bool loading;
  final bool working;
  final List<BackupFileModel> backups;
  final ValueChanged<BackupFileModel> onRestore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = _BackupText.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text.availableBackups,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (backups.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(text.noBackups),
              )
            else
              ...backups.map(
                (backup) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.storage_outlined),
                  title: Text(backup.fileName, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${backup.backupKind} • ${_formatBytes(backup.sizeBytes)} • ${backup.createdAtIso}',
                  ),
                  trailing: OutlinedButton.icon(
                    onPressed: working ? null : () => onRestore(backup),
                    icon: const Icon(Icons.restore_outlined),
                    label: Text(text.restore),
                  ),
                ),
              ),
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
    final text = _BackupText.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: cs.tertiaryContainer,
                  child: Icon(
                    Icons.schedule_outlined,
                    color: cs.onTertiaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  text.backupPolicy,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: text.autoBackup,
              value: settings?.autoBackupEnabled == true
                  ? text.enabled
                  : text.disabled,
            ),
            _InfoRow(
              label: text.schedule,
              value: settings?.scheduleMode ?? '-',
            ),
            _InfoRow(
              label: text.runHour,
              value: settings?.runAtHourLocal.toString() ?? '-',
            ),
            _InfoRow(
              label: text.retentionCount,
              value: settings?.retentionCount.toString() ?? '-',
            ),
            _InfoRow(
              label: text.safetyBackupBeforeRestore,
              value: settings?.createSafetyBackupBeforeRestore == true
                  ? text.yes
                  : text.no,
            ),
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
    final text = _BackupText.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text.restoreAuditLog,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            if (audits.isEmpty)
              Text(text.noRestoreOperations)
            else
              ...audits
                  .take(8)
                  .map(
                    (audit) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.history_outlined),
                      title: Text(
                        audit.backupFileName,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${audit.restoredAtIso} • ${text.safetyBackupShort}: ${audit.createdSafetyBackup ? text.yes : text.no}',
                      ),
                    ),
                  ),
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
          SizedBox(
            width: 190,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
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
    final text = _BackupText.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: supported ? cs.primaryContainer : cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            supported
                ? Icons.check_circle_outline
                : Icons.warning_amber_outlined,
            color: supported ? cs.onPrimaryContainer : cs.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              supported ? text.supportedMessage : text.unsupportedMessage,
              style: TextStyle(
                color: supported ? cs.onPrimaryContainer : cs.onErrorContainer,
              ),
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
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: cs.onErrorContainer)),
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
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(_BackupText.of(context).retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupText {
  const _BackupText(this.ar);

  final bool ar;

  static _BackupText of(BuildContext context) =>
      _BackupText(Localizations.localeOf(context).languageCode == 'ar');

  String get title => ar ? 'إعدادات النسخ الاحتياطي' : 'Backup Settings';
  String get refresh => ar ? 'تحديث' : 'Refresh';
  String get heading =>
      ar ? 'قاعدة البيانات والنسخ الاحتياطي' : 'Database & Backup';
  String get description => ar
      ? 'إنشاء واستعراض واسترجاع نسخ احتياطية من ملف شركة SQLite. هذه الإجراءات محمية بخاصية ترخيص النسخ والاسترجاع.'
      : 'Create, list, and restore SQLite company backups. These API actions are protected by the Backup/Restore license feature.';
  String get createBackup => ar ? 'إنشاء نسخة احتياطية' : 'Create Backup';
  String get label => ar ? 'التسمية' : 'Label';
  String get reason => ar ? 'السبب' : 'Reason';
  String get cancel => ar ? 'إلغاء' : 'Cancel';
  String get create => ar ? 'إنشاء' : 'Create';
  String get manualRestore => ar ? 'استرجاع يدوي' : 'Manual restore';
  String get restoreBackup => ar ? 'استرجاع نسخة احتياطية' : 'Restore Backup';
  String get restoreWarning => ar
      ? 'سيتم استبدال قاعدة بيانات الشركة الحالية بهذا الملف:'
      : 'This will overwrite the live company database with:';
  String get safetyBackup => ar
      ? 'إنشاء نسخة أمان قبل الاسترجاع'
      : 'Create safety backup before restore';
  String get restore => ar ? 'استرجاع' : 'Restore';
  String get runtimeDatabase =>
      ar ? 'قاعدة بيانات التشغيل' : 'Runtime Database';
  String get environment => ar ? 'البيئة' : 'Environment';
  String get provider => ar ? 'المزود' : 'Provider';
  String get supportsBackupRestore =>
      ar ? 'يدعم النسخ/الاسترجاع' : 'Supports Backup/Restore';
  String get liveDatabasePath =>
      ar ? 'مسار قاعدة البيانات الحالية' : 'Live Database Path';
  String get backupDirectory =>
      ar ? 'مجلد النسخ الاحتياطي' : 'Backup Directory';
  String get yes => ar ? 'نعم' : 'Yes';
  String get no => ar ? 'لا' : 'No';
  String get backupActions => ar ? 'إجراءات النسخ الاحتياطي' : 'Backup Actions';
  String get backupActionsDescription => ar
      ? 'إنشاء نسخ احتياطية يدوية واسترجاع النسخ المحفوظة.'
      : 'Create manual backups and restore saved database backups.';
  String get backupNow => ar ? 'نسخ احتياطي الآن' : 'Backup Now';
  String get importBackup => ar ? 'استيراد نسخة' : 'Import Backup';
  String get availableBackups =>
      ar ? 'النسخ الاحتياطية المتاحة' : 'Available Backups';
  String get noBackups =>
      ar ? 'لا توجد نسخ احتياطية حتى الآن.' : 'No backups found yet.';
  String get backupPolicy => ar ? 'سياسة النسخ الاحتياطي' : 'Backup Policy';
  String get autoBackup => ar ? 'النسخ التلقائي' : 'Auto Backup';
  String get enabled => ar ? 'مفعل' : 'Enabled';
  String get disabled => ar ? 'غير مفعل' : 'Disabled';
  String get schedule => ar ? 'الجدولة' : 'Schedule';
  String get runHour => ar ? 'ساعة التشغيل' : 'Run Hour';
  String get retentionCount => ar ? 'عدد النسخ المحتفظ بها' : 'Retention Count';
  String get safetyBackupBeforeRestore =>
      ar ? 'نسخة أمان قبل الاسترجاع' : 'Safety Backup Before Restore';
  String get restoreAuditLog =>
      ar ? 'سجل عمليات الاسترجاع' : 'Restore Audit Log';
  String get noRestoreOperations => ar
      ? 'لا توجد عمليات استرجاع مسجلة حتى الآن.'
      : 'No restore operations recorded yet.';
  String get safetyBackupShort => ar ? 'نسخة أمان' : 'Safety backup';
  String get supportedMessage => ar
      ? 'النسخ والاسترجاع متاحان لمزود قاعدة البيانات الحالي.'
      : 'Backup/restore is available for this database provider.';
  String get unsupportedMessage => ar
      ? 'مزود قاعدة البيانات الحالي لا يدعم النسخ والاسترجاع حاليا.'
      : 'This database provider does not currently support backup/restore.';
  String get retry => ar ? 'إعادة المحاولة' : 'Retry';
}
