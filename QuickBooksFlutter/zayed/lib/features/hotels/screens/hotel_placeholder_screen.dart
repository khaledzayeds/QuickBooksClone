import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../navigation/providers/navigation_provider.dart';

class HotelPlaceholderScreen extends ConsumerWidget {
  const HotelPlaceholderScreen({
    super.key,
    required this.title,
    required this.moduleCode,
    this.code,
  });

  final String title;
  final String moduleCode;
  final String? code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modulesState = ref.watch(currentCompanyModulesProvider);

    return modulesState.when(
      data: (modules) {
        if (!modules.hasModule(moduleCode)) {
          return const _DisabledModuleMessage();
        }

        return _HotelPlaceholderContent(title: title, code: code);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const _DisabledModuleMessage(),
    );
  }
}

class _DisabledModuleMessage extends StatelessWidget {
  const _DisabledModuleMessage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        'هذا الموديول غير مفعل لهذه الشركة',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HotelPlaceholderContent extends StatelessWidget {
  const _HotelPlaceholderContent({required this.title, this.code});

  final String title;
  final String? code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.hotel_outlined,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (code != null) ...[
                    Text(
                      'Code: $code',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    'Hotel reservation form will be implemented here.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'سيتم تنفيذ شاشة حجز الفندق هنا.',
                    style: theme.textTheme.bodyLarge,
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
