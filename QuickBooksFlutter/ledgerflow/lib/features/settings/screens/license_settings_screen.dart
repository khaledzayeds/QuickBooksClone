import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/device_fingerprint_service.dart';
import '../data/models/license_settings_model.dart';
import '../providers/license_settings_provider.dart';

class LicenseSettingsScreen extends ConsumerWidget {
  const LicenseSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(licenseSettingsProvider);
    final notifier = ref.read(licenseSettingsProvider.notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    ref.listen(licenseSettingsProvider, (previous, next) {
      if (next.saved && previous?.saved != true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('License settings saved.')));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('License Settings'),
        actions: [
          TextButton.icon(
            onPressed: state.saving ? null : notifier.reset,
            icon: const Icon(Icons.restore_outlined),
            label: const Text('Reset'),
          ),
          TextButton.icon(
            onPressed: state.saving ? null : notifier.save,
            icon: state.saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            label: const Text('Save'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text('Edition & Activation', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(
                  'Local license skeleton for Solo / Network / Hosted editions. Real serial validation and device activation will be wired to a license service later.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _ErrorBanner(message: state.errorMessage!),
                ],
                if (state.activationMessage != null) ...[
                  const SizedBox(height: 16),
                  _SuccessBanner(message: state.activationMessage!),
                ],
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 980;
                    final left = Column(
                      children: [
                        _EditionCard(state: state, notifier: notifier),
                        const SizedBox(height: 16),
                        _ActivationCard(state: state, notifier: notifier),
                        const SizedBox(height: 16),
                        _PackageActivationCard(state: state, notifier: notifier),
                        const SizedBox(height: 16),
                        _DeviceFingerprintCard(notifier: notifier),
                      ],
                    );
                    final right = Column(
                      children: [
                        _LimitsCard(state: state, notifier: notifier),
                        const SizedBox(height: 16),
                        _FeaturesCard(state: state, notifier: notifier),
                      ],
                    );

                    if (!wide) return Column(children: [left, const SizedBox(height: 16), right]);
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Expanded(child: left), const SizedBox(width: 16), Expanded(child: right)],
                    );
                  },
                ),
                const SizedBox(height: 16),
                const _ImplementationNoteCard(),
              ],
            ),
    );
  }
}

class _EditionCard extends StatelessWidget {
  const _EditionCard({required this.state, required this.notifier});
  final LicenseSettingsState state;
  final LicenseSettingsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.verified_user_outlined,
      title: 'Edition',
      children: [
        DropdownButtonFormField<LicenseEdition>(
          initialValue: state.license.edition,
          decoration: const InputDecoration(labelText: 'Edition', border: OutlineInputBorder()),
          items: LicenseEdition.values.map((edition) => DropdownMenuItem(value: edition, child: Text(edition.label))).toList(),
          onChanged: (value) {
            if (value != null) notifier.applyEdition(value);
          },
        ),
        const SizedBox(height: 12),
        _InfoText(text: state.license.edition.description),
        const SizedBox(height: 12),
        DropdownButtonFormField<LicenseStatus>(
          initialValue: state.license.status,
          decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
          items: LicenseStatus.values.map((status) => DropdownMenuItem(value: status, child: Text(status.label))).toList(),
          onChanged: (value) {
            if (value != null) notifier.update((current) => current.copyWith(status: value));
          },
        ),
      ],
    );
  }
}

class _ActivationCard extends StatelessWidget {
  const _ActivationCard({required this.state, required this.notifier});
  final LicenseSettingsState state;
  final LicenseSettingsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.key_outlined,
      title: 'Activation',
      children: [
        _TextField(
          label: 'License Key / Serial',
          value: state.license.licenseKey ?? '',
          icon: Icons.password_outlined,
          onChanged: (value) => notifier.update((current) => current.copyWith(licenseKey: value)),
        ),
        const SizedBox(height: 12),
        _TextField(
          label: 'Licensed Company Name',
          value: state.license.companyName ?? '',
          icon: Icons.business_outlined,
          onChanged: (value) => notifier.update((current) => current.copyWith(companyName: value)),
        ),
        const SizedBox(height: 12),
        _TextField(
          label: 'Activated Device ID / Fingerprint',
          value: state.license.activatedDeviceId ?? '',
          icon: Icons.devices_outlined,
          onChanged: (value) => notifier.update((current) => current.copyWith(activatedDeviceId: value)),
        ),
        const SizedBox(height: 12),
        _TextField(
          label: 'Expires At ISO',
          value: state.license.expiresAtIso ?? '',
          icon: Icons.event_outlined,
          onChanged: (value) => notifier.update((current) => current.copyWith(expiresAtIso: value)),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: state.saving ? null : notifier.save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Local License'),
            ),
            const OutlinedButton.icon(
              onPressed: null,
              icon: Icon(Icons.cloud_sync_outlined),
              label: Text('Activate Online'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PackageActivationCard extends StatefulWidget {
  const _PackageActivationCard({required this.state, required this.notifier});
  final LicenseSettingsState state;
  final LicenseSettingsNotifier notifier;

  @override
  State<_PackageActivationCard> createState() => _PackageActivationCardState();
}

class _PackageActivationCardState extends State<_PackageActivationCard> {
  late final TextEditingController _packageController;

  @override
  void initState() {
    super.initState();
    _packageController = TextEditingController();
  }

  @override
  void dispose() {
    _packageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.offline_bolt_outlined,
      title: 'Signed / Offline License Package',
      children: [
        TextFormField(
          controller: _packageController,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'License Package',
            helperText: 'Expected development format: base64url(payloadJson).base64url(signature)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.code_outlined),
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<DeviceFingerprintInfo>(
          future: DeviceFingerprintService().getOrCreate(),
          builder: (context, snapshot) {
            final canApply = snapshot.hasData && !widget.state.saving;
            return FilledButton.icon(
              onPressed: canApply
                  ? () => widget.notifier.applyPackage(
                        package: _packageController.text,
                        deviceFingerprint: snapshot.data!.deviceFingerprint,
                      )
                  : null,
              icon: widget.state.saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.verified_outlined),
              label: const Text('Apply Package'),
            );
          },
        ),
        const SizedBox(height: 10),
        const _InfoText(
          text: 'This currently decodes and maps the package, but production cryptographic signature verification is still pending.',
        ),
      ],
    );
  }
}

class _DeviceFingerprintCard extends StatelessWidget {
  const _DeviceFingerprintCard({required this.notifier});
  final LicenseSettingsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DeviceFingerprintInfo>(
      future: DeviceFingerprintService().getOrCreate(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 12),
                  Text('Preparing device fingerprint...'),
                ],
              ),
            ),
          );
        }

        final info = snapshot.data!;
        return _SectionCard(
          icon: Icons.fingerprint_outlined,
          title: 'This Device',
          children: [
            _ReadOnlyValue(label: 'Installation ID', value: info.installationId),
            const SizedBox(height: 12),
            _ReadOnlyValue(label: 'Device Fingerprint', value: info.deviceFingerprint),
            const SizedBox(height: 12),
            _ReadOnlyValue(label: 'Generated At', value: info.generatedAtIso),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    notifier.update((current) => current.copyWith(activatedDeviceId: info.deviceFingerprint));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Device fingerprint copied into license device field.')));
                  },
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Use This Device'),
                ),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('Rotate For Testing'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _LimitsCard extends StatelessWidget {
  const _LimitsCard({required this.state, required this.notifier});
  final LicenseSettingsState state;
  final LicenseSettingsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.speed_outlined,
      title: 'Limits',
      children: [
        _NumberField(
          label: 'Max Users',
          value: state.license.maxUsers,
          onChanged: (value) => notifier.update((current) => current.copyWith(maxUsers: int.tryParse(value) ?? current.maxUsers)),
        ),
        const SizedBox(height: 12),
        _NumberField(
          label: 'Max Devices',
          value: state.license.maxDevices,
          onChanged: (value) => notifier.update((current) => current.copyWith(maxDevices: int.tryParse(value) ?? current.maxDevices)),
        ),
        const SizedBox(height: 12),
        _NumberField(
          label: 'Offline Grace Days',
          value: state.license.offlineGraceDays,
          onChanged: (value) => notifier.update((current) => current.copyWith(offlineGraceDays: int.tryParse(value) ?? current.offlineGraceDays)),
        ),
      ],
    );
  }
}

class _FeaturesCard extends StatelessWidget {
  const _FeaturesCard({required this.state, required this.notifier});
  final LicenseSettingsState state;
  final LicenseSettingsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.toggle_on_outlined,
      title: 'Allowed Features',
      children: [
        _SwitchRow(title: 'Local Mode', value: state.license.allowLocalMode, onChanged: (value) => notifier.update((current) => current.copyWith(allowLocalMode: value))),
        _SwitchRow(title: 'LAN / Network Mode', value: state.license.allowLanMode, onChanged: (value) => notifier.update((current) => current.copyWith(allowLanMode: value))),
        _SwitchRow(title: 'Hosted Mode', value: state.license.allowHostedMode, onChanged: (value) => notifier.update((current) => current.copyWith(allowHostedMode: value))),
        _SwitchRow(title: 'Backup / Restore', value: state.license.allowBackupRestore, onChanged: (value) => notifier.update((current) => current.copyWith(allowBackupRestore: value))),
        _SwitchRow(title: 'Demo Company', value: state.license.allowDemoCompany, onChanged: (value) => notifier.update((current) => current.copyWith(allowDemoCompany: value))),
        _SwitchRow(title: 'Advanced Inventory', value: state.license.allowAdvancedInventory, onChanged: (value) => notifier.update((current) => current.copyWith(allowAdvancedInventory: value))),
        _SwitchRow(title: 'Payroll', value: state.license.allowPayroll, onChanged: (value) => notifier.update((current) => current.copyWith(allowPayroll: value))),
      ],
    );
  }
}

class _ImplementationNoteCard extends StatelessWidget {
  const _ImplementationNoteCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(backgroundColor: cs.secondaryContainer, child: Icon(Icons.info_outline, color: cs.onSecondaryContainer)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Implementation note', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(
                    'This is a local skeleton to test editions and feature flags. Production activation still needs real public-key signature verification, online/offline activation endpoints, renewal rules, and backend verification.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.icon, required this.title, required this.children});
  final IconData icon;
  final String title;
  final List<Widget> children;

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
                CircleAvatar(backgroundColor: cs.primaryContainer, child: Icon(icon, color: cs.onPrimaryContainer)),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({required this.label, required this.value, required this.icon, required this.onChanged});
  final String label;
  final String value;
  final IconData icon;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), prefixIcon: Icon(icon)),
      onChanged: onChanged,
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.label, required this.value, required this.onChanged});
  final String label;
  final int value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value.toString(),
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(labelText: '', border: OutlineInputBorder(), prefixIcon: Icon(Icons.numbers_outlined)).copyWith(labelText: label),
      onChanged: onChanged,
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.title, required this.value, required this.onChanged});
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _ReadOnlyValue extends StatelessWidget {
  const _ReadOnlyValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      initialValue: value,
      minLines: 1,
      maxLines: 3,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.lock_outline)),
    );
  }
}

class _InfoText extends StatelessWidget {
  const _InfoText({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
      child: Text(text),
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

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: cs.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: TextStyle(color: cs.onPrimaryContainer))),
        ],
      ),
    );
  }
}
