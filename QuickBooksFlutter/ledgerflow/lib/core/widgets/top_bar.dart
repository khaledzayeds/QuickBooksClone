// top_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';
import '../localization/locale_provider.dart';

class TopBar extends ConsumerWidget implements PreferredSizeWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final locale = ref.watch(localeProvider);
    final isArabic = locale.languageCode == 'ar';
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Search Bar Placeholder
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: l10n.search,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Actions
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          
          // Language Toggle
          TextButton.icon(
            onPressed: () => ref.read(localeProvider.notifier).toggleLocale(),
            icon: const Icon(Icons.language, size: 18),
            label: Text(isArabic ? 'English' : 'عربي'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 16),
          
          // User Profile
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary,
            radius: 18,
            child: const Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
