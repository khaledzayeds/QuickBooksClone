import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../companies/providers/company_registry_provider.dart';
import '../data/models/login_user_option.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscurePass = true;
  String? _errorMsg;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    final error = await ref
        .read(authProvider.notifier)
        .login(_userCtrl.text.trim(), _passCtrl.text);

    if (!mounted) return;
    if (error == null) {
      context.go(AppRoutes.dashboard);
    } else {
      setState(() {
        _loading = false;
        _errorMsg = _friendlyMessage(error);
      });
    }
  }

  Future<void> _switchCompany() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      await ref.read(authProvider.notifier).logout();
      await ref.read(companyRegistryProvider.notifier).closeActiveCompany();
      if (!mounted) return;
      context.go(AppRoutes.companies);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMsg = _texts(context).companySwitchFailed;
      });
    }
  }

  void _selectUser(LoginUserOption user) {
    _userCtrl.text = user.userName;
    _passCtrl.selection = TextSelection.collapsed(
      offset: _passCtrl.text.length,
    );
    FocusScope.of(context).nextFocus();
  }

  @override
  Widget build(BuildContext context) {
    final registry = ref.watch(companyRegistryProvider).value;
    final users = ref.watch(loginUsersProvider);
    final companyName =
        registry?.activeCompany?.name ?? _texts(context).noCompanyOpen;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final text = _texts(context);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: _LanguageToggleButton(),
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 860;
                      final intro = _LoginIntro(
                        companyName: companyName,
                        text: text,
                      );
                      final form = _LoginPanel(
                        formKey: _formKey,
                        userCtrl: _userCtrl,
                        passCtrl: _passCtrl,
                        obscurePass: _obscurePass,
                        loading: _loading,
                        errorMsg: _errorMsg,
                        users: users,
                        text: text,
                        onSubmit: _submit,
                        onSwitchCompany: _switchCompany,
                        onTogglePassword: () =>
                            setState(() => _obscurePass = !_obscurePass),
                        onSelectUser: _selectUser,
                      );

                      if (!wide) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [intro, const SizedBox(height: 18), form],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: intro),
                          const SizedBox(width: 20),
                          Expanded(flex: 4, child: form),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _friendlyMessage(String error) {
    final lower = error.toLowerCase();
    final text = _texts(context);
    if (lower.contains('invalid') ||
        lower.contains('unauthorized') ||
        lower.contains('401')) {
      return text.invalidCredentials;
    }
    if (lower.contains('connection') ||
        lower.contains('timeout') ||
        lower.contains('socket')) {
      return text.connectionUnavailable;
    }
    return text.signInFailed;
  }
}

class _LanguageToggleButton extends ConsumerWidget {
  const _LanguageToggleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isArabic = locale.languageCode == 'ar';
    final cs = Theme.of(context).colorScheme;

    return Tooltip(
      message: isArabic ? 'Switch to English' : 'التحويل إلى العربية',
      child: OutlinedButton.icon(
        onPressed: () => ref.read(localeProvider.notifier).toggleLocale(),
        icon: const Icon(Icons.language_outlined, size: 18),
        label: Text(
          isArabic ? 'EN' : 'ع',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          side: BorderSide(color: cs.outlineVariant),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          minimumSize: const Size(62, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

class _LoginIntro extends StatelessWidget {
  const _LoginIntro({required this.companyName, required this.text});

  final String companyName;
  final _LoginTexts text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: cs.primary,
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: cs.onPrimary,
              size: 30,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Zayed',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            text.secureWorkspace,
            style: theme.textTheme.titleMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 26),
          _InfoLine(
            icon: Icons.business_outlined,
            label: text.company,
            value: companyName,
          ),
          const SizedBox(height: 12),
          _InfoLine(
            icon: Icons.verified_user_outlined,
            label: text.access,
            value: text.accessDescription,
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      children: [
        Icon(icon, color: cs.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({
    required this.formKey,
    required this.userCtrl,
    required this.passCtrl,
    required this.obscurePass,
    required this.loading,
    required this.errorMsg,
    required this.users,
    required this.text,
    required this.onSubmit,
    required this.onSwitchCompany,
    required this.onTogglePassword,
    required this.onSelectUser,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController userCtrl;
  final TextEditingController passCtrl;
  final bool obscurePass;
  final bool loading;
  final String? errorMsg;
  final AsyncValue<List<LoginUserOption>> users;
  final _LoginTexts text;
  final VoidCallback onSubmit;
  final VoidCallback onSwitchCompany;
  final VoidCallback onTogglePassword;
  final ValueChanged<LoginUserOption> onSelectUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text.signIn,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                text.chooseUserHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              _UserChooser(
                users: users,
                text: text,
                onSelectUser: onSelectUser,
              ),
              const SizedBox(height: 18),
              if (errorMsg != null) ...[
                _ErrorBanner(message: errorMsg!),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: userCtrl,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: text.username,
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? text.usernameRequired
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: passCtrl,
                obscureText: obscurePass,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => onSubmit(),
                decoration: InputDecoration(
                  labelText: text.password,
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: obscurePass
                        ? text.showPassword
                        : text.hidePassword,
                    icon: Icon(
                      obscurePass
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: onTogglePassword,
                  ),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? text.passwordRequired
                    : null,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: loading ? null : onSubmit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login_outlined),
                label: Text(text.signIn),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: loading ? null : onSwitchCompany,
                icon: const Icon(Icons.swap_horiz_outlined),
                label: Text(text.switchCompany),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserChooser extends StatelessWidget {
  const _UserChooser({
    required this.users,
    required this.text,
    required this.onSelectUser,
  });

  final AsyncValue<List<LoginUserOption>> users;
  final _LoginTexts text;
  final ValueChanged<LoginUserOption> onSelectUser;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return users.when(
      loading: () => _ChooserShell(
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(text.loadingUsers),
          ],
        ),
      ),
      error: (_, _) => _ChooserShell(
        child: Row(
          children: [
            Icon(Icons.info_outline, color: cs.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(child: Text(text.usersUnavailable)),
          ],
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return _ChooserShell(
            child: Row(
              children: [
                Icon(Icons.person_search_outlined, color: cs.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(child: Text(text.noUsersYet)),
              ],
            ),
          );
        }
        return _ChooserShell(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map(
                  (user) =>
                      _UserChoice(user: user, onTap: () => onSelectUser(user)),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _ChooserShell extends StatelessWidget {
  const _ChooserShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: child,
    );
  }
}

class _UserChoice extends StatelessWidget {
  const _UserChoice({required this.user, required this.onTap});

  final LoginUserOption user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final display = user.displayName.isEmpty ? user.userName : user.displayName;
    final initial = display.isEmpty
        ? '?'
        : display.substring(0, 1).toUpperCase();
    return ActionChip(
      avatar: CircleAvatar(
        backgroundColor: cs.primary,
        child: Text(
          initial,
          style: TextStyle(color: cs.onPrimary, fontSize: 12),
        ),
      ),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(display, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(
            user.primaryRole,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
      onPressed: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: cs.outlineVariant),
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
          Icon(Icons.error_outline, color: cs.onErrorContainer, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: cs.onErrorContainer)),
          ),
        ],
      ),
    );
  }
}

_LoginTexts _texts(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'ar'
    ? _LoginTexts.ar
    : _LoginTexts.en;

class _LoginTexts {
  const _LoginTexts({
    required this.signIn,
    required this.secureWorkspace,
    required this.company,
    required this.access,
    required this.accessDescription,
    required this.chooseUserHint,
    required this.username,
    required this.password,
    required this.usernameRequired,
    required this.passwordRequired,
    required this.showPassword,
    required this.hidePassword,
    required this.switchCompany,
    required this.loadingUsers,
    required this.usersUnavailable,
    required this.noUsersYet,
    required this.noCompanyOpen,
    required this.invalidCredentials,
    required this.connectionUnavailable,
    required this.signInFailed,
    required this.companySwitchFailed,
  });

  final String signIn;
  final String secureWorkspace;
  final String company;
  final String access;
  final String accessDescription;
  final String chooseUserHint;
  final String username;
  final String password;
  final String usernameRequired;
  final String passwordRequired;
  final String showPassword;
  final String hidePassword;
  final String switchCompany;
  final String loadingUsers;
  final String usersUnavailable;
  final String noUsersYet;
  final String noCompanyOpen;
  final String invalidCredentials;
  final String connectionUnavailable;
  final String signInFailed;
  final String companySwitchFailed;

  static const en = _LoginTexts(
    signIn: 'Sign in',
    secureWorkspace: 'Secure access to your company workspace',
    company: 'Company',
    access: 'Access',
    accessDescription: 'Users and roles are managed from settings',
    chooseUserHint:
        'Select a user to fill the username, then enter the password.',
    username: 'Username',
    password: 'Password',
    usernameRequired: 'Enter the username',
    passwordRequired: 'Enter the password',
    showPassword: 'Show password',
    hidePassword: 'Hide password',
    switchCompany: 'Switch company',
    loadingUsers: 'Loading users...',
    usersUnavailable:
        'User list is unavailable. You can still type the username.',
    noUsersYet: 'No active users are available for this company.',
    noCompanyOpen: 'No company open',
    invalidCredentials: 'The username or password is not correct.',
    connectionUnavailable:
        'Cannot reach the company service. Try again or switch company.',
    signInFailed: 'Sign in failed. Please check the details and try again.',
    companySwitchFailed: 'Could not switch company. Please try again.',
  );

  static const ar = _LoginTexts(
    signIn: 'تسجيل الدخول',
    secureWorkspace: 'دخول آمن إلى مساحة عمل الشركة',
    company: 'الشركة',
    access: 'الصلاحيات',
    accessDescription: 'إدارة المستخدمين والأدوار من الإعدادات',
    chooseUserHint: 'اختر المستخدم لملء اسم الدخول، ثم اكتب كلمة المرور.',
    username: 'اسم المستخدم',
    password: 'كلمة المرور',
    usernameRequired: 'أدخل اسم المستخدم',
    passwordRequired: 'أدخل كلمة المرور',
    showPassword: 'إظهار كلمة المرور',
    hidePassword: 'إخفاء كلمة المرور',
    switchCompany: 'تغيير الشركة',
    loadingUsers: 'جاري تحميل المستخدمين...',
    usersUnavailable:
        'قائمة المستخدمين غير متاحة. يمكنك كتابة اسم المستخدم يدوياً.',
    noUsersYet: 'لا يوجد مستخدمون نشطون لهذه الشركة.',
    noCompanyOpen: 'لا توجد شركة مفتوحة',
    invalidCredentials: 'اسم المستخدم أو كلمة المرور غير صحيحة.',
    connectionUnavailable:
        'تعذر الوصول إلى خدمة الشركة. حاول مرة أخرى أو غيّر الشركة.',
    signInFailed: 'تعذر تسجيل الدخول. راجع البيانات وحاول مرة أخرى.',
    companySwitchFailed: 'تعذر تغيير الشركة. حاول مرة أخرى.',
  );
}
