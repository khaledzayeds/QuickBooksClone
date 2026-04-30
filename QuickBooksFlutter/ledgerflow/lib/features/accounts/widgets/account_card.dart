// account_card.dart
// account_card.dart

import 'package:flutter/material.dart';
import '../data/models/account_model.dart';

class AccountCard extends StatelessWidget {
  const AccountCard({
    super.key,
    required this.account,
    this.onTap,
    this.onToggleActive,
  });

  final AccountModel account;
  final VoidCallback? onTap;
  final VoidCallback? onToggleActive;

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final isDebit = account.isDebitNormal;

    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            account.code,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          account.name,
          style: theme.textTheme.titleMedium?.copyWith(
            color: account.isActive ? null : theme.disabledColor,
          ),
        ),
        subtitle: Text(
          account.accountTypeName,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Balance
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${account.balance.toStringAsFixed(2)} ج.م',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: account.balance >= 0
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                  ),
                ),
                Text(
                  isDebit ? 'مدين' : 'دائن',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),

            // Toggle active
            if (onToggleActive != null)
              IconButton(
                icon: Icon(
                  account.isActive
                      ? Icons.toggle_on_outlined
                      : Icons.toggle_off_outlined,
                  color: account.isActive
                      ? theme.colorScheme.primary
                      : theme.disabledColor,
                ),
                onPressed: onToggleActive,
                tooltip: account.isActive ? 'تعطيل' : 'تفعيل',
              ),
          ],
        ),
      ),
    );
  }
}