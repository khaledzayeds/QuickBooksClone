// bank_register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/models/banking_models.dart';
import '../providers/banking_provider.dart';

class BankRegisterScreen extends ConsumerWidget {
  const BankRegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(bankAccountsProvider);
    final selectedAccountId = ref.watch(selectedBankAccountIdProvider);
    final registerAsync = ref.watch(bankRegisterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Register'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(bankAccountsProvider);
              ref.invalidate(bankRegisterProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            accountsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => _ErrorCard(message: error.toString()),
              data: (accounts) {
                if (accounts.isEmpty) {
                  return const _EmptyCard(
                    icon: Icons.account_balance_outlined,
                    title: 'No bank accounts',
                    message: 'Create an active Bank, Other Current Asset, or Credit Card account first.',
                  );
                }

                final safeSelectedId = accounts.any((account) => account.id == selectedAccountId) ? selectedAccountId : null;
                if (safeSelectedId == null && selectedAccountId != null) {
                  Future.microtask(() => ref.read(selectedBankAccountIdProvider.notifier).state = null);
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: safeSelectedId,
                            decoration: const InputDecoration(
                              labelText: 'Bank/Cash Account',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.account_balance_outlined),
                            ),
                            items: accounts
                                .where((account) => account.isActive)
                                .map(
                                  (account) => DropdownMenuItem<String>(
                                    value: account.id,
                                    child: Text('${account.displayName} — ${account.balance.toStringAsFixed(2)}'),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) => ref.read(selectedBankAccountIdProvider.notifier).state = value,
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: safeSelectedId == null ? null : () => ref.invalidate(bankRegisterProvider),
                          icon: const Icon(Icons.search),
                          label: const Text('Load'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: registerAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ErrorCard(message: error.toString()),
                data: (register) {
                  if (selectedAccountId == null || selectedAccountId.isEmpty) {
                    return const _EmptyCard(
                      icon: Icons.menu_book_outlined,
                      title: 'Select an account',
                      message: 'Choose a bank or cash account to view its register.',
                    );
                  }

                  if (register.items.isEmpty) {
                    return _EmptyCard(
                      icon: Icons.receipt_long_outlined,
                      title: 'No register activity',
                      message: 'No posted transactions were found for ${register.accountName}.',
                    );
                  }

                  return _RegisterTable(register: register);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterTable extends StatelessWidget {
  const _RegisterTable({required this.register});

  final BankRegisterResponseModel register;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    register.accountName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  'Ending: ${register.endingBalance.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1050,
                child: ListView.separated(
                  itemCount: register.items.length + 1,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (index == 0) return const _RegisterHeader();
                    final line = register.items[index - 1];
                    return _RegisterRow(line: line, dateFormat: dateFormat);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800);
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text('Date', style: style)),
          SizedBox(width: 150, child: Text('Type', style: style)),
          SizedBox(width: 140, child: Text('Reference', style: style)),
          Expanded(child: Text('Description', style: style)),
          SizedBox(width: 110, child: Text('Debit', textAlign: TextAlign.end, style: style)),
          SizedBox(width: 110, child: Text('Credit', textAlign: TextAlign.end, style: style)),
          SizedBox(width: 120, child: Text('Balance', textAlign: TextAlign.end, style: style)),
        ],
      ),
    );
  }
}

class _RegisterRow extends StatelessWidget {
  const _RegisterRow({required this.line, required this.dateFormat});

  final BankRegisterLineModel line;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(dateFormat.format(line.transactionDate))),
          SizedBox(width: 150, child: Text(line.transactionType)),
          SizedBox(width: 140, child: Text(line.referenceNumber)),
          Expanded(child: Text(line.description, overflow: TextOverflow.ellipsis)),
          SizedBox(width: 110, child: Text(line.debit == 0 ? '-' : line.debit.toStringAsFixed(2), textAlign: TextAlign.end)),
          SizedBox(width: 110, child: Text(line.credit == 0 ? '-' : line.credit.toStringAsFixed(2), textAlign: TextAlign.end)),
          SizedBox(width: 120, child: Text(line.runningBalance.toStringAsFixed(2), textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
      ),
    );
  }
}
