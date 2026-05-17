import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/setup_models.dart';
import '../providers/setup_provider.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameCtrl = TextEditingController(text: 'LedgerFlow Company');
  final _currencyCtrl = TextEditingController(text: 'EGP');
  final _countryCtrl = TextEditingController(text: 'Egypt');
  final _timeZoneCtrl = TextEditingController(text: 'Africa/Cairo');
  final _languageCtrl = TextEditingController(text: 'ar');
  final _legalNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _adminUserCtrl = TextEditingController(text: 'admin');
  final _adminNameCtrl = TextEditingController(text: 'System Administrator');
  final _adminEmailCtrl = TextEditingController();
  final _adminSecretCtrl = TextEditingController();

  bool _saving = false;
  bool _obscureSecret = true;
  String? _errorMessage;

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _currencyCtrl.dispose();
    _countryCtrl.dispose();
    _timeZoneCtrl.dispose();
    _languageCtrl.dispose();
    _legalNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _adminUserCtrl.dispose();
    _adminNameCtrl.dispose();
    _adminEmailCtrl.dispose();
    _adminSecretCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    final request = InitializeCompanyRequest(
      companyName: _companyNameCtrl.text.trim(),
      currency: _currencyCtrl.text.trim(),
      country: _countryCtrl.text.trim(),
      timeZoneId: _timeZoneCtrl.text.trim(),
      defaultLanguage: _languageCtrl.text.trim(),
      legalName: _emptyToNull(_legalNameCtrl.text),
      email: _emptyToNull(_emailCtrl.text),
      phone: _emptyToNull(_phoneCtrl.text),
      adminUserName: _adminUserCtrl.text.trim(),
      adminDisplayName: _adminNameCtrl.text.trim(),
      adminEmail: _emptyToNull(_adminEmailCtrl.text),
      initialAdminSecret: _adminSecretCtrl.text,
    );

    try {
      final error = await ref
          .read(setupProvider.notifier)
          .initializeCompany(request);
      if (!mounted) return;

      if (error == null) {
        context.go('/login');
        return;
      }

      setState(() {
        _saving = false;
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = 'Company setup failed: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final setupState = ref.watch(setupProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: setupState.when(
              loading: () => const _SetupLoadingCard(),
              error: (error, _) => _SetupErrorCard(
                message: error.toString(),
                onRetry: () => ref.read(setupProvider.notifier).refreshStatus(),
              ),
              data: (status) {
                if (status.isInitialized) {
                  return _AlreadyInitializedCard(
                    companyName: status.companyName,
                    onContinue: () => context.go('/login'),
                  );
                }

                return Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.business_center_outlined,
                        size: 56,
                        color: cs.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Company Setup',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Create the company profile and first administrator account.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_errorMessage != null) ...[
                        _ErrorBanner(message: _errorMessage!),
                        const SizedBox(height: 16),
                      ],
                      _SectionCard(
                        title: 'Company',
                        children: [
                          _TextField(
                            controller: _companyNameCtrl,
                            label: 'Company name',
                            icon: Icons.apartment,
                            isRequired: true,
                          ),
                          _TwoColumns(
                            left: _TextField(
                              controller: _currencyCtrl,
                              label: 'Currency',
                              icon: Icons.payments_outlined,
                              isRequired: true,
                            ),
                            right: _TextField(
                              controller: _countryCtrl,
                              label: 'Country',
                              icon: Icons.public_outlined,
                              isRequired: true,
                            ),
                          ),
                          _TwoColumns(
                            left: _TextField(
                              controller: _timeZoneCtrl,
                              label: 'Time zone',
                              icon: Icons.schedule_outlined,
                              isRequired: true,
                            ),
                            right: _TextField(
                              controller: _languageCtrl,
                              label: 'Default language',
                              icon: Icons.language_outlined,
                              isRequired: true,
                            ),
                          ),
                          _TextField(
                            controller: _legalNameCtrl,
                            label: 'Legal name',
                            icon: Icons.badge_outlined,
                          ),
                          _TwoColumns(
                            left: _TextField(
                              controller: _emailCtrl,
                              label: 'Company email',
                              icon: Icons.email_outlined,
                            ),
                            right: _TextField(
                              controller: _phoneCtrl,
                              label: 'Company phone',
                              icon: Icons.phone_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'First Administrator',
                        children: [
                          _TwoColumns(
                            left: _TextField(
                              controller: _adminUserCtrl,
                              label: 'Username',
                              icon: Icons.person_outline,
                              isRequired: true,
                            ),
                            right: _TextField(
                              controller: _adminNameCtrl,
                              label: 'Display name',
                              icon: Icons.badge_outlined,
                              isRequired: true,
                            ),
                          ),
                          _TextField(
                            controller: _adminEmailCtrl,
                            label: 'Admin email',
                            icon: Icons.alternate_email,
                          ),
                          TextFormField(
                            controller: _adminSecretCtrl,
                            obscureText: _obscureSecret,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureSecret
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _obscureSecret = !_obscureSecret,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.length < 8) {
                                return 'Password must be at least 8 characters.';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _submit(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _submit,
                          icon: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: const Text('Initialize Company'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  static String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.isRequired = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: isRequired
            ? (value) => value == null || value.trim().isEmpty
                  ? '$label is required.'
                  : null
            : null,
      ),
    );
  }
}

class _TwoColumns extends StatelessWidget {
  const _TwoColumns({required this.left, required this.right});
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Column(children: [left, right]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 14),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SetupLoadingCard extends StatelessWidget {
  const _SetupLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 14),
            Text('Checking setup status...'),
          ],
        ),
      ),
    );
  }
}

class _SetupErrorCard extends StatelessWidget {
  const _SetupErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 42),
            const SizedBox(height: 12),
            Text(
              'Cannot reach the backend',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlreadyInitializedCard extends StatelessWidget {
  const _AlreadyInitializedCard({
    required this.companyName,
    required this.onContinue,
  });
  final String? companyName;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_outlined, size: 42),
            const SizedBox(height: 12),
            Text(
              companyName ?? 'Company is ready',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onContinue,
              child: const Text('Continue to Login'),
            ),
          ],
        ),
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: cs.onErrorContainer)),
          ),
        ],
      ),
    );
  }
}
