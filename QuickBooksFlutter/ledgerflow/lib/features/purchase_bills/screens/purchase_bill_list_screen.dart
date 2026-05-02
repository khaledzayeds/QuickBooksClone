// purchase_bill_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';
import '../../../app/router.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../providers/purchase_bills_provider.dart';

class PurchaseBillListScreen extends ConsumerWidget {
  const PurchaseBillListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(purchaseBillsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.purchaseBills),
        actions: [
          IconButton(
            onPressed: () => ref.read(purchaseBillsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: billsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (bills) {
          if (bills.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.receipt_outlined,
              message: l10n.noRecentTransactions,
              onAction: () => context.push(AppRoutes.purchaseBillNew),
              actionLabel: l10n.enterBills,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bills.length,
            itemBuilder: (context, i) {
              final bill = bills[i];
              return Card(
                child: ListTile(
                  title: Text(bill.billNumber),
                  subtitle: Text(bill.vendorName),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${bill.totalAmount.toStringAsFixed(2)} ${l10n.egp}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        bill.balanceDue == 0 ? l10n.paid : l10n.unpaid,
                        style: TextStyle(
                          fontSize: 12,
                          color: bill.balanceDue == 0 ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Navigate to details
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.purchaseBillNew),
        label: Text(l10n.enterBills),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
