import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../data/models/license_settings_model.dart';
import '../providers/license_settings_provider.dart';

class LicenseGate extends ConsumerWidget {
  const LicenseGate({
    super.key,
    required this.feature,
    required this.child,
    this.blockedTitle,
    this.blockedDescription,
  });

  final LicenseFeature feature;
  final Widget child;
  final String? blockedTitle;
  final String? blockedDescription;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(licenseSettingsProvider);

    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final license = state.license;
    if (license.allows(feature)) return child;
    final ar = Localizations.localeOf(context).languageCode == 'ar';

    return LicenseBlockedScreen(
      title:
          blockedTitle ??
          (ar ? '${feature.label} مقفلة' : '${feature.label} is locked'),
      description: blockedDescription ?? license.denialReason(feature),
      editionLabel: license.edition.label,
      statusLabel: license.status.label,
    );
  }
}

class LicenseBlockedScreen extends StatelessWidget {
  const LicenseBlockedScreen({
    super.key,
    required this.title,
    required this.description,
    required this.editionLabel,
    required this.statusLabel,
  });

  final String title;
  final String description;
  final String editionLabel;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final text = _LicenseGateText.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(text.title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: cs.errorContainer,
                    child: Icon(
                      Icons.lock_outline,
                      color: cs.onErrorContainer,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _InfoRow(label: text.currentEdition, value: editionLabel),
                  _InfoRow(label: text.licenseStatus, value: statusLabel),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: () => context.go(AppRoutes.licenseSettings),
                        icon: const Icon(Icons.verified_user_outlined),
                        label: Text(text.openLicenseSettings),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go(AppRoutes.settings),
                        icon: const Icon(Icons.settings_outlined),
                        label: Text(text.backToSettings),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LicenseGateText {
  const _LicenseGateText(this.ar);

  final bool ar;

  static _LicenseGateText of(BuildContext context) =>
      _LicenseGateText(Localizations.localeOf(context).languageCode == 'ar');

  String get title => ar ? 'الترخيص مطلوب' : 'License Required';
  String get currentEdition => ar ? 'الإصدار الحالي' : 'Current Edition';
  String get licenseStatus => ar ? 'حالة الترخيص' : 'License Status';
  String get openLicenseSettings =>
      ar ? 'فتح إعدادات الترخيص' : 'Open License Settings';
  String get backToSettings => ar ? 'العودة للإعدادات' : 'Back to Settings';
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
