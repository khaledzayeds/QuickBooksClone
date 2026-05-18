// companies_screen.dart
// Company selection screen shown after login.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../setup/providers/setup_provider.dart';

class CompaniesScreen extends ConsumerWidget {
  const CompaniesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    final setupState = ref.watch(setupProvider);
    final companyName = setupState.valueOrNull?.companyName ?? 'My Company';
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Column(
        children: [
          _TopBar(
            userName: user?.displayName ?? user?.userName ?? '',
            onLogout: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'اختر شركة للعمل عليها',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select a company to open',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _CompanyCard(
                        companyName: companyName,
                        onOpen: () => context.go(AppRoutes.dashboard),
                      ),
                      const SizedBox(height: 24),
                      _QuickActions(
                        onCompany: () => context.go(AppRoutes.companySettings),
                        onUsers: () => context.go(AppRoutes.usersPermissions),
                        onReports: () => context.go(AppRoutes.reports),
                      ),
                      const SizedBox(height: 36),
                      const _InfoBanner(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const _BottomBar(),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.userName, required this.onLogout});

  final String userName;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: const Color(0xFF1B4D0F),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
          const SizedBox(width: 10),
          const Text(
            'LedgerFlow',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          if (userName.isNotEmpty) ...[
            Text(
              userName,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(width: 12),
          ],
          TextButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_outlined, size: 16, color: Colors.white70),
            label: const Text('خروج', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  const _CompanyCard({required this.companyName, required this.onOpen});

  final String companyName;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2CA01C), Color(0xFF1B7A0F)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  companyName.isNotEmpty ? companyName[0].toUpperCase() : 'C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 30,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    companyName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: const [
                      _Badge(icon: Icons.payments_outlined, label: 'EGP'),
                      _Badge(
                        icon: Icons.cloud_done_outlined,
                        label: 'متصل · Online',
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: onOpen,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('فتح · Open'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey[600]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onCompany,
    required this.onUsers,
    required this.onReports,
  });

  final VoidCallback onCompany;
  final VoidCallback onUsers;
  final VoidCallback onReports;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final actions = [
          _ActionTile(icon: Icons.settings_outlined, title: 'إعدادات الشركة', subtitle: 'Company Settings', onTap: onCompany),
          _ActionTile(icon: Icons.people_outline, title: 'المستخدمون', subtitle: 'Users & Permissions', onTap: onUsers),
          _ActionTile(icon: Icons.bar_chart_outlined, title: 'التقارير', subtitle: 'Reports', onTap: onReports),
        ];

        if (constraints.maxWidth < 680) {
          return Column(
            children: [
              for (final action in actions) ...[action, const SizedBox(height: 12)],
            ],
          );
        }

        return Row(
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              Expanded(child: actions[i]),
              if (i != actions.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600]),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.20)),
      ),
      child: const Text(
        'بعد فتح الشركة يمكنك ضبط الضرائب، المستخدمين، والطباعة من شاشة الإعدادات.',
        style: TextStyle(fontSize: 13, height: 1.5),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      alignment: Alignment.center,
      color: Colors.white,
      child: Text(
        'LedgerFlow Desktop · Local SQLite API mode',
        style: TextStyle(color: Colors.grey[500], fontSize: 11),
      ),
    );
  }
}
