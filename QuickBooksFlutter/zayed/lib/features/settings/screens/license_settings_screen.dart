import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/device_fingerprint_service.dart';
import '../data/models/license_settings_model.dart';
import '../data/offline_activation_service.dart';
import '../providers/license_settings_provider.dart';

class LicenseSettingsScreen extends ConsumerWidget {
  const LicenseSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(licenseSettingsProvider);
    final notifier = ref.read(licenseSettingsProvider.notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final text = _LicenseText.of(context);

    ref.listen(licenseSettingsProvider, (previous, next) {
      if (next.saved && previous?.saved != true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(text.saved)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(text.title),
        actions: [
          TextButton.icon(
            onPressed: state.saving ? null : notifier.reset,
            icon: const Icon(Icons.restore_outlined),
            label: Text(text.reset),
          ),
          TextButton.icon(
            onPressed: state.saving ? null : notifier.save,
            icon: state.saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(text.save),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
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
                        _OfflineRequestCard(license: state.license),
                        const SizedBox(height: 16),
                        _PackageActivationCard(
                          state: state,
                          notifier: notifier,
                        ),
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

                    if (!wide) {
                      return Column(
                        children: [left, const SizedBox(height: 16), right],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: left),
                        const SizedBox(width: 16),
                        Expanded(child: right),
                      ],
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
      title: _LicenseText.of(context).edition,
      children: [
        DropdownButtonFormField<LicenseEdition>(
          initialValue: state.license.edition,
          decoration: InputDecoration(
            labelText: _LicenseText.of(context).edition,
            border: OutlineInputBorder(),
          ),
          items: LicenseEdition.values
              .map(
                (edition) => DropdownMenuItem<LicenseEdition>(
                  value: edition,
                  child: Text(edition.label),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) notifier.applyEdition(value);
          },
        ),
        const SizedBox(height: 12),
        _InfoText(text: state.license.edition.description),
        const SizedBox(height: 12),
        DropdownButtonFormField<LicenseStatus>(
          initialValue: state.license.status,
          decoration: InputDecoration(
            labelText: _LicenseText.of(context).status,
            border: OutlineInputBorder(),
          ),
          items: LicenseStatus.values
              .map(
                (status) => DropdownMenuItem<LicenseStatus>(
                  value: status,
                  child: Text(status.label),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              notifier.update((current) => current.copyWith(status: value));
            }
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
      title: _LicenseText.of(context).activation,
      children: [
        _TextField(
          label: _LicenseText.of(context).licenseKey,
          value: state.license.licenseKey ?? '',
          icon: Icons.password_outlined,
          onChanged: (value) =>
              notifier.update((current) => current.copyWith(licenseKey: value)),
        ),
        const SizedBox(height: 12),
        _TextField(
          label: _LicenseText.of(context).licensedCompanyName,
          value: state.license.companyName ?? '',
          icon: Icons.business_outlined,
          onChanged: (value) => notifier.update(
            (current) => current.copyWith(companyName: value),
          ),
        ),
        const SizedBox(height: 12),
        _TextField(
          label: _LicenseText.of(context).activatedDevice,
          value: state.license.activatedDeviceId ?? '',
          icon: Icons.devices_outlined,
          onChanged: (value) => notifier.update(
            (current) => current.copyWith(activatedDeviceId: value),
          ),
        ),
        const SizedBox(height: 12),
        _TextField(
          label: _LicenseText.of(context).expiresAt,
          value: state.license.expiresAtIso ?? '',
          icon: Icons.event_outlined,
          onChanged: (value) => notifier.update(
            (current) => current.copyWith(expiresAtIso: value),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: state.saving ? null : notifier.save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_LicenseText.of(context).saveLocalLicense),
            ),
            FutureBuilder<DeviceFingerprintInfo>(
              future: DeviceFingerprintService().getOrCreate(),
              builder: (context, snapshot) {
                final canActivate =
                    snapshot.hasData &&
                    !state.saving &&
                    (state.license.licenseKey?.trim().isNotEmpty ?? false);
                return OutlinedButton.icon(
                  onPressed: canActivate
                      ? () => notifier.activateOnline(
                          serial: state.license.licenseKey!,
                          deviceFingerprint: snapshot.data!.deviceFingerprint,
                          companyName: state.license.companyName,
                        )
                      : null,
                  icon: state.saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_sync_outlined),
                  label: Text(_LicenseText.of(context).activateOnline),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        _InfoText(text: _LicenseText.of(context).activationNote),
      ],
    );
  }
}

class _OfflineRequestCard extends StatefulWidget {
  const _OfflineRequestCard({required this.license});
  final LicenseSettingsModel license;

  @override
  State<_OfflineRequestCard> createState() => _OfflineRequestCardState();
}

class _OfflineRequestCardState extends State<_OfflineRequestCard> {
  OfflineActivationRequest? _request;
  bool _loading = false;
  String? _error;

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final request = await OfflineActivationService().createRequest(
        currentLicense: widget.license,
      );
      setState(() => _request = request);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.qr_code_2_outlined,
      title: _LicenseText.of(context).offlineRequest,
      children: [
        _InfoText(text: _LicenseText.of(context).offlineRequestNote),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _loading ? null : _generate,
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.generating_tokens_outlined),
          label: Text(_LicenseText.of(context).generateRequestCode),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _ErrorBanner(message: _error!),
        ],
        if (_request != null) ...[
          const SizedBox(height: 12),
          _ReadOnlyValue(
            label: _LicenseText.of(context).requestCode,
            value: _request!.requestCode,
          ),
          const SizedBox(height: 12),
          _ReadOnlyValue(
            label: _LicenseText.of(context).createdAt,
            value: _request!.createdAtIso,
          ),
          const SizedBox(height: 12),
          _ReadOnlyValue(
            label: _LicenseText.of(context).payloadPreview,
            value: _request!.payload.entries
                .map((entry) => '${entry.key}: ${entry.value}')
                .join('\n'),
          ),
        ],
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
      title: _LicenseText.of(context).signedPackage,
      children: [
        TextFormField(
          controller: _packageController,
          minLines: 3,
          maxLines: 6,
          decoration: InputDecoration(
            labelText: _LicenseText.of(context).licensePackage,
            helperText:
                'Expected format: base64url(payloadJson).base64url(ed25519Signature)',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.code_outlined),
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
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.verified_outlined),
              label: Text(_LicenseText.of(context).applyPackage),
            );
          },
        ),
        const SizedBox(height: 10),
        _InfoText(text: _LicenseText.of(context).packageNote),
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
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(_LicenseText.of(context).preparingFingerprint),
                ],
              ),
            ),
          );
        }

        final info = snapshot.data!;
        return _SectionCard(
          icon: Icons.fingerprint_outlined,
          title: _LicenseText.of(context).thisDevice,
          children: [
            _ReadOnlyValue(
              label: _LicenseText.of(context).installationId,
              value: info.installationId,
            ),
            const SizedBox(height: 12),
            _ReadOnlyValue(
              label: _LicenseText.of(context).deviceFingerprint,
              value: info.deviceFingerprint,
            ),
            const SizedBox(height: 12),
            _ReadOnlyValue(
              label: _LicenseText.of(context).generatedAt,
              value: info.generatedAtIso,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    notifier.update(
                      (current) => current.copyWith(
                        activatedDeviceId: info.deviceFingerprint,
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _LicenseText.of(context).fingerprintCopied,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_outlined),
                  label: Text(_LicenseText.of(context).useThisDevice),
                ),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.refresh_outlined),
                  label: Text(_LicenseText.of(context).rotateForTesting),
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
      title: _LicenseText.of(context).limits,
      children: [
        _NumberField(
          label: _LicenseText.of(context).maxUsers,
          value: state.license.maxUsers,
          onChanged: (value) => notifier.update(
            (current) => current.copyWith(
              maxUsers: int.tryParse(value) ?? current.maxUsers,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _NumberField(
          label: _LicenseText.of(context).maxDevices,
          value: state.license.maxDevices,
          onChanged: (value) => notifier.update(
            (current) => current.copyWith(
              maxDevices: int.tryParse(value) ?? current.maxDevices,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _NumberField(
          label: _LicenseText.of(context).offlineGraceDays,
          value: state.license.offlineGraceDays,
          onChanged: (value) => notifier.update(
            (current) => current.copyWith(
              offlineGraceDays: int.tryParse(value) ?? current.offlineGraceDays,
            ),
          ),
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
      title: _LicenseText.of(context).allowedFeatures,
      children: [
        _SwitchRow(
          title: _LicenseText.of(context).localMode,
          value: state.license.allowLocalMode,
          onChanged: (value) => notifier.update(
            (current) => current.copyWith(allowLocalMode: value),
          ),
        ),
        _SwitchRow(
          title: _LicenseText.of(context).lanMode,
          value: state.license.allowLanMode,
          onChanged: (value) => notifier.update(
            (current) => current.copyWith(allowLanMode: value),
          ),
        ),
        _SwitchRow(
          title: _LicenseText.of(context).hostedMode,
          value: state.license.allowHostedMode,
          onChanged: (value) => notifier.update(
            (current) => current.copyWith(allowHostedMode: value),
          ),
        ),
        _SwitchRow(
          title: _LicenseText.of(context).backupRestore,
          value: state.license.allowBackupRestore,
          onChanged: (value) => notifier.update(
            (current) => current.copyWith(allowBackupRestore: value),
          ),
        ),
        _SwitchRow(
          title: _LicenseText.of(context).demoCompany,
          value: state.license.allowDemoCompany,
          onChanged: (value) => notifier.update(
            (current) => current.copyWith(allowDemoCompany: value),
          ),
        ),
        _SwitchRow(
          title: _LicenseText.of(context).advancedInventory,
          value: state.license.allowAdvancedInventory,
          onChanged: (value) => notifier.update(
            (current) => current.copyWith(allowAdvancedInventory: value),
          ),
        ),
        _SwitchRow(
          title: _LicenseText.of(context).payroll,
          value: state.license.allowPayroll,
          onChanged: (value) => notifier.update(
            (current) => current.copyWith(allowPayroll: value),
          ),
        ),
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
            CircleAvatar(
              backgroundColor: cs.secondaryContainer,
              child: Icon(Icons.info_outline, color: cs.onSecondaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _LicenseText.of(context).implementationNote,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _LicenseText.of(context).implementationNoteBody,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
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

class _LicenseText {
  const _LicenseText(this.ar);

  final bool ar;

  static _LicenseText of(BuildContext context) =>
      _LicenseText(Localizations.localeOf(context).languageCode == 'ar');

  String get saved =>
      ar ? 'تم حفظ إعدادات الترخيص.' : 'License settings saved.';
  String get title => ar ? 'ترخيص الخدمات المتصلة' : 'Online License';
  String get reset => ar ? 'إعادة ضبط' : 'Reset';
  String get save => ar ? 'حفظ' : 'Save';
  String get heading =>
      ar ? 'ترخيص الخدمات المتصلة' : 'Online Services License';
  String get description => ar
      ? 'استخدم هذه الشاشة فقط للاشتراكات المستضافة والوصول البعيد والتفعيل المتصل والخدمات المعتمدة على الاشتراك. ملف الشركة غير المتصل يظل يعمل محليا.'
      : 'Use this only for hosted subscriptions, remote access, online activation, and subscription-only services. The offline company file keeps working locally.';
  String get edition => ar ? 'الإصدار' : 'Edition';
  String get status => ar ? 'الحالة' : 'Status';
  String get activation => ar ? 'التفعيل' : 'Activation';
  String get licenseKey =>
      ar ? 'مفتاح الترخيص / السيريال' : 'License Key / Serial';
  String get licensedCompanyName =>
      ar ? 'اسم الشركة المرخصة' : 'Licensed Company Name';
  String get activatedDevice =>
      ar ? 'معرف الجهاز المفعل / البصمة' : 'Activated Device ID / Fingerprint';
  String get expiresAt => ar ? 'ينتهي في ISO' : 'Expires At ISO';
  String get saveLocalLicense =>
      ar ? 'حفظ الترخيص المحلي' : 'Save Local License';
  String get activateOnline => ar ? 'تفعيل متصل' : 'Activate Online';
  String get activationNote => ar
      ? 'التفعيل المتصل يستدعي POST /api/licenses/activate، ثم يستقبل حزمة ترخيص موقعة، يتحقق منها محليا، ويحفظها.'
      : 'Online activation calls POST /api/licenses/activate, receives a signed license package, verifies it locally, then saves it.';
  String get offlineRequest =>
      ar ? 'طلب تفعيل غير متصل' : 'Offline Activation Request';
  String get offlineRequestNote => ar
      ? 'أنشئ كود الطلب على جهاز العميل، أرسله لمالك البرنامج، ثم الصق حزمة الترخيص الموقعة العائدة أدناه.'
      : 'Generate this request code on the customer device, send it to the software owner, then paste the returned signed license package below.';
  String get generateRequestCode =>
      ar ? 'إنشاء كود الطلب' : 'Generate Request Code';
  String get requestCode => ar ? 'كود الطلب' : 'Request Code';
  String get createdAt => ar ? 'تم الإنشاء في' : 'Created At';
  String get payloadPreview => ar ? 'معاينة البيانات' : 'Payload Preview';
  String get signedPackage => ar
      ? 'حزمة الترخيص الموقعة / غير المتصلة'
      : 'Signed / Offline License Package';
  String get licensePackage => ar ? 'حزمة الترخيص' : 'License Package';
  String get applyPackage => ar ? 'تطبيق الحزمة' : 'Apply Package';
  String get packageNote => ar
      ? 'يتم التحقق من الحزمة باستخدام مفتاح Ed25519 العام المضمن قبل حفظها محليا.'
      : 'The package is verified with the embedded Ed25519 public key before it is saved locally.';
  String get preparingFingerprint =>
      ar ? 'جاري تجهيز بصمة الجهاز...' : 'Preparing device fingerprint...';
  String get thisDevice => ar ? 'هذا الجهاز' : 'This Device';
  String get installationId => ar ? 'معرف التثبيت' : 'Installation ID';
  String get deviceFingerprint => ar ? 'بصمة الجهاز' : 'Device Fingerprint';
  String get generatedAt => ar ? 'تم الإنشاء في' : 'Generated At';
  String get fingerprintCopied => ar
      ? 'تم نسخ بصمة الجهاز إلى حقل جهاز الترخيص.'
      : 'Device fingerprint copied into license device field.';
  String get useThisDevice => ar ? 'استخدام هذا الجهاز' : 'Use This Device';
  String get rotateForTesting => ar ? 'تدوير للاختبار' : 'Rotate For Testing';
  String get limits => ar ? 'الحدود' : 'Limits';
  String get maxUsers => ar ? 'أقصى عدد مستخدمين' : 'Max Users';
  String get maxDevices => ar ? 'أقصى عدد أجهزة' : 'Max Devices';
  String get offlineGraceDays =>
      ar ? 'أيام السماح دون اتصال' : 'Offline Grace Days';
  String get allowedFeatures => ar ? 'الخصائص المسموحة' : 'Allowed Features';
  String get localMode => ar ? 'الوضع المحلي' : 'Local Mode';
  String get lanMode => ar ? 'وضع الشبكة المحلية' : 'LAN / Network Mode';
  String get hostedMode => ar ? 'وضع الاستضافة' : 'Hosted Mode';
  String get backupRestore => ar ? 'النسخ والاسترجاع' : 'Backup / Restore';
  String get demoCompany => ar ? 'شركة تجريبية' : 'Demo Company';
  String get advancedInventory => ar ? 'مخزون متقدم' : 'Advanced Inventory';
  String get payroll => ar ? 'الرواتب' : 'Payroll';
  String get implementationNote => ar ? 'ملاحظة تنفيذ' : 'Implementation note';
  String get implementationNoteBody => ar
      ? 'التفعيل المتصل مخصص لخدمات الاستضافة والاشتراكات. العمل المحلي غير المتصل على ملف الشركة لا يعتمد على هذه الشاشة.'
      : 'Online activation is for hosted and subscription services. Local offline company work does not depend on this screen.';
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });
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
                CircleAvatar(
                  backgroundColor: cs.primaryContainer,
                  child: Icon(icon, color: cs.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
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
  const _TextField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onChanged,
  });
  final String label;
  final String value;
  final IconData icon;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      onChanged: onChanged,
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final int value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value.toString(),
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: '',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.numbers_outlined),
      ).copyWith(labelText: label),
      onChanged: onChanged,
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });
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
      maxLines: 5,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock_outline),
      ),
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
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
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

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: cs.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: cs.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
