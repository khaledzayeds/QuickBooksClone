// recent_transactions_widget.dart
// recent_transactions_widget.dart

import 'package:flutter/material.dart';

class RecentTransactionsWidget extends StatelessWidget {
  const RecentTransactionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Icon(
                  Icons.swap_horiz_outlined,
                  size: 40,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 12),
                Text(
                  'ستظهر آخر الحركات هنا بعد إضافة بيانات',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(alpha: 0.5),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}