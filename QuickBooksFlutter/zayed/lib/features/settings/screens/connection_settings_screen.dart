import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../providers/connection_settings_provider.dart';

class ConnectionSettingsScreen extends ConsumerWidget {
  const ConnectionSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(connectionSettingsProvider);
    final notifier = ref.read(connectionSettingsProvider.notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final text = _ConnectionText.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(text.title),
        actions: [
          TextButton.icon(
            onPressed: state.loading ? null : () => notifier.load(),
            icon: const Icon(Icons.refresh),
            label: Text(text.reload),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            '${AppConstants.appDisplayName} ${text.runtime}',
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
          const SizedBox(height: 24),
          if (state.loading)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 16),
                    Text(text.loading),
                  ],
                ),
              ),
            )
          else ...[
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
                          child: Icon(
                            Icons.computer_outlined,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                text.internalApi,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                text.internalApiDescription,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _RuntimeRow(
                      label: text.mode,
                      value: AppConstants.appEdition,
                    ),
                    _RuntimeRow(
                      label: text.endpoint,
                      value: state.settings.baseUrl,
                    ),
                    _RuntimeRow(
                      label: text.companyDbName,
                      value: AppConstants.defaultCompanyDatabaseFileName,
                    ),
                    _RuntimeRow(
                      label: text.companyFileExtension,
                      value: AppConstants.companyFileExtension,
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
                    Text(
                      text.runtimeCheck,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      text.runtimeCheckDescription,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: state.testing ? null : () => notifier.test(),
                      icon: state.testing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.health_and_safety_outlined),
                      label: Text(text.checkLocalRuntime),
                    ),
                    if (state.testResult != null) ...[
                      const SizedBox(height: 16),
                      _ResultBanner(result: state.testResult!),
                    ],
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _ErrorBanner(message: state.errorMessage!),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConnectionText {
  const _ConnectionText(this.ar);

  final bool ar;

  static _ConnectionText of(BuildContext context) =>
      _ConnectionText(Localizations.localeOf(context).languageCode == 'ar');

  String get title => ar ? 'تشغيل محلي' : 'Local Runtime';
  String get reload => ar ? 'إعادة تحميل' : 'Reload';
  String get runtime => ar ? 'التشغيل' : 'Runtime';
  String get description => ar
      ? 'هذه النسخة غير المتصلة تستخدم واجهة API المحلية الداخلية دائما. إعدادات LAN والاستضافة والنهايات المخصصة مخفية عمدا في هذا الإصدار.'
      : 'This offline edition always uses the internal local API. LAN, hosted, and custom endpoints are intentionally hidden in this build.';
  String get loading => ar
      ? 'جاري تحميل إعدادات التشغيل المحلي...'
      : 'Loading local runtime settings...';
  String get internalApi =>
      ar ? 'واجهة API المحلية الداخلية' : 'Internal Local API';
  String get internalApiDescription => ar
      ? 'تدار بواسطة Zayed. لا يحتاج المستخدم لضبط أو تشغيل خادم يدويا.'
      : 'Managed by Zayed. Users should not configure or start a server manually.';
  String get mode => ar ? 'الوضع' : 'Mode';
  String get endpoint => ar ? 'نقطة الاتصال' : 'Endpoint';
  String get companyDbName =>
      ar ? 'اسم قاعدة بيانات الشركة' : 'Company DB name';
  String get companyFileExtension =>
      ar ? 'امتداد ملف الشركة' : 'Company file extension';
  String get runtimeCheck => ar ? 'فحص التشغيل' : 'Runtime Check';
  String get runtimeCheckDescription => ar
      ? 'يفحص واجهة API المحلية الداخلية عن طريق استدعاء /api/settings/runtime.'
      : 'Checks the internal local API by calling /api/settings/runtime.';
  String get checkLocalRuntime =>
      ar ? 'فحص التشغيل المحلي' : 'Check Local Runtime';
}

class _RuntimeRow extends StatelessWidget {
  const _RuntimeRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(child: SelectableText(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.result});

  final dynamic result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final success = result.success == true;
    final bg = success
        ? Colors.green.withValues(alpha: 0.12)
        : Colors.orange.withValues(alpha: 0.12);
    final fg = success ? Colors.green.shade800 : Colors.orange.shade900;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            success ? Icons.check_circle_outline : Icons.warning_amber_outlined,
            color: fg,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              result.message.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
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
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade800),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.red.shade800,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
