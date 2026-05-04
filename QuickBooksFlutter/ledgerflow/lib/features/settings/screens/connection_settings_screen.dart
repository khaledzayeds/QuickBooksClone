import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/connection_settings_model.dart';
import '../data/models/license_settings_model.dart';
import '../providers/connection_settings_provider.dart';
import '../providers/license_settings_provider.dart';

class ConnectionSettingsScreen extends ConsumerStatefulWidget {
  const ConnectionSettingsScreen({super.key});

  @override
  ConsumerState<ConnectionSettingsScreen> createState() => _ConnectionSettingsScreenState();
}

class _ConnectionSettingsScreenState extends ConsumerState<ConnectionSettingsScreen> {
  late final TextEditingController _lanHostController;
  late final TextEditingController _hostedUrlController;
  late final TextEditingController _customUrlController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(connectionSettingsProvider).settings;
    _lanHostController = TextEditingController(text: settings.lanHost ?? ConnectionSettingsModel.defaultLanHost);
    _hostedUrlController = TextEditingController(text: settings.hostedUrl ?? ConnectionSettingsModel.defaultHostedUrl);
    _customUrlController = TextEditingController(text: settings.customUrl ?? settings.baseUrl);
  }

  @override
  void dispose() {
    _lanHostController.dispose();
    _hostedUrlController.dispose();
    _customUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(connectionSettingsProvider);
    final licenseState = ref.watch(licenseSettingsProvider);
    final license = licenseState.license;
    final notifier = ref.read(connectionSettingsProvider.notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    ref.listen(connectionSettingsProvider, (previous, next) {
      final prevSettings = previous?.settings;
      final nextSettings = next.settings;
      if (prevSettings?.lanHost != nextSettings.lanHost && _lanHostController.text != (nextSettings.lanHost ?? '')) {
        _lanHostController.text = nextSettings.lanHost ?? '';
      }
      if (prevSettings?.hostedUrl != nextSettings.hostedUrl && _hostedUrlController.text != (nextSettings.hostedUrl ?? '')) {
        _hostedUrlController.text = nextSettings.hostedUrl ?? '';
      }
      if (prevSettings?.customUrl != nextSettings.customUrl && _customUrlController.text != (nextSettings.customUrl ?? '')) {
        _customUrlController.text = nextSettings.customUrl ?? '';
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Settings'),
        actions: [
          TextButton.icon(
            onPressed: state.saving ? null : () => notifier.save(),
            icon: state.saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            label: const Text('Save'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'API Connection',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose where LedgerFlow should connect. Available profiles are controlled by the current license edition: ${license.edition.label}.',
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          if (state.loading || licenseState.loading)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Row(
                  children: [
                    SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 16),
                    Text('Loading connection settings...'),
                  ],
                ),
              ),
            )
          else ...[
            _LicenseConnectionBanner(license: license),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Connection Profile', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: ConnectionProfileType.values
                          .map(
                            (type) {
                              final enabled = _isProfileAllowed(type, license);
                              return ChoiceChip(
                                label: Text(enabled ? type.label : '${type.label} 🔒'),
                                selected: state.settings.profileType == type,
                                onSelected: enabled ? (_) => notifier.setProfileType(type) : null,
                              );
                            },
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    _ProfileLockNotice(profileType: state.settings.profileType, license: license),
                    const SizedBox(height: 20),
                    _ProfileFields(
                      profileType: state.settings.profileType,
                      lanHostController: _lanHostController,
                      hostedUrlController: _hostedUrlController,
                      customUrlController: _customUrlController,
                      onLanChanged: notifier.setLanHost,
                      onHostedChanged: notifier.setHostedUrl,
                      onCustomChanged: notifier.setCustomUrl,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _CurrentEndpointCard(baseUrl: state.settings.baseUrl),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Connection Test', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text(
                      'Tests the selected endpoint by calling /api/settings/runtime.',
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: state.testing ? null : () => notifier.test(),
                          icon: state.testing
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.network_check_outlined),
                          label: const Text('Test Connection'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: state.loading ? null : () => notifier.load(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reload'),
                        ),
                      ],
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

  static bool _isProfileAllowed(ConnectionProfileType type, LicenseSettingsModel license) {
    return switch (type) {
      ConnectionProfileType.local => license.allows(LicenseFeature.localMode),
      ConnectionProfileType.lan => license.allows(LicenseFeature.lanMode),
      ConnectionProfileType.hosted => license.allows(LicenseFeature.hostedMode),
      ConnectionProfileType.custom => license.allows(LicenseFeature.localMode) || license.allows(LicenseFeature.lanMode) || license.allows(LicenseFeature.hostedMode),
    };
  }
}

class _LicenseConnectionBanner extends StatelessWidget {
  const _LicenseConnectionBanner({required this.license});
  final LicenseSettingsModel license;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final allowed = [
      if (license.allows(LicenseFeature.localMode)) 'Local',
      if (license.allows(LicenseFeature.lanMode)) 'LAN',
      if (license.allows(LicenseFeature.hostedMode)) 'Hosted',
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.verified_user_outlined, color: cs.onSecondaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'License: ${license.edition.label} • Allowed connection modes: ${allowed.isEmpty ? 'None' : allowed.join(', ')}',
              style: TextStyle(color: cs.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileLockNotice extends StatelessWidget {
  const _ProfileLockNotice({required this.profileType, required this.license});

  final ConnectionProfileType profileType;
  final LicenseSettingsModel license;

  @override
  Widget build(BuildContext context) {
    final reason = switch (profileType) {
      ConnectionProfileType.local => license.allows(LicenseFeature.localMode) ? null : license.denialReason(LicenseFeature.localMode),
      ConnectionProfileType.lan => license.allows(LicenseFeature.lanMode) ? null : license.denialReason(LicenseFeature.lanMode),
      ConnectionProfileType.hosted => license.allows(LicenseFeature.hostedMode) ? null : license.denialReason(LicenseFeature.hostedMode),
      ConnectionProfileType.custom => null,
    };

    if (reason == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.errorContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: cs.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(child: Text(reason, style: TextStyle(color: cs.onErrorContainer))),
        ],
      ),
    );
  }
}

class _ProfileFields extends StatelessWidget {
  const _ProfileFields({
    required this.profileType,
    required this.lanHostController,
    required this.hostedUrlController,
    required this.customUrlController,
    required this.onLanChanged,
    required this.onHostedChanged,
    required this.onCustomChanged,
  });

  final ConnectionProfileType profileType;
  final TextEditingController lanHostController;
  final TextEditingController hostedUrlController;
  final TextEditingController customUrlController;
  final ValueChanged<String> onLanChanged;
  final ValueChanged<String> onHostedChanged;
  final ValueChanged<String> onCustomChanged;

  @override
  Widget build(BuildContext context) {
    return switch (profileType) {
      ConnectionProfileType.local => const _InfoBox(
          icon: Icons.computer_outlined,
          title: 'Local API',
          message: 'The app connects to http://localhost:5000. Use this when the API runs on the same machine.',
        ),
      ConnectionProfileType.lan => TextField(
          controller: lanHostController,
          decoration: const InputDecoration(
            labelText: 'LAN Host',
            helperText: 'Example: 192.168.1.20:5000 or http://192.168.1.20:5000',
            prefixIcon: Icon(Icons.router_outlined),
            border: OutlineInputBorder(),
          ),
          onChanged: onLanChanged,
        ),
      ConnectionProfileType.hosted => TextField(
          controller: hostedUrlController,
          decoration: const InputDecoration(
            labelText: 'Hosted URL',
            helperText: 'Example: https://api.yourdomain.com',
            prefixIcon: Icon(Icons.cloud_outlined),
            border: OutlineInputBorder(),
          ),
          onChanged: onHostedChanged,
        ),
      ConnectionProfileType.custom => TextField(
          controller: customUrlController,
          decoration: const InputDecoration(
            labelText: 'Custom Base URL',
            helperText: 'Use for testing tunnels, custom ports, or special deployments.',
            prefixIcon: Icon(Icons.tune_outlined),
            border: OutlineInputBorder(),
          ),
          onChanged: onCustomChanged,
        ),
    };
  }
}

class _CurrentEndpointCard extends StatelessWidget {
  const _CurrentEndpointCard({required this.baseUrl});
  final String baseUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: cs.primaryContainer,
              child: Icon(Icons.link_outlined, color: cs.onPrimaryContainer),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Base URL', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  SelectableText(baseUrl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(message),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.result});
  final ConnectionTestResult result;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result.success ? cs.primaryContainer : cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(result.success ? Icons.check_circle_outline : Icons.error_outline,
              color: result.success ? cs.onPrimaryContainer : cs.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              result.message,
              style: TextStyle(color: result.success ? cs.onPrimaryContainer : cs.onErrorContainer),
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
          Expanded(child: Text(message, style: TextStyle(color: cs.onErrorContainer))),
        ],
      ),
    );
  }
}
