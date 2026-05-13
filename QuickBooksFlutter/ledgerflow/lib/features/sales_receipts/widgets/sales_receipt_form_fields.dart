import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import '../../accounts/data/models/account_model.dart';
import '../../customers/data/models/customer_model.dart';
import '../../transactions/widgets/transaction_form_shell.dart';

class SalesReceiptFormField extends StatelessWidget {
  const SalesReceiptFormField({
    super.key,
    required this.label,
    required this.child,
    this.required = false,
  });

  final String label;
  final Widget child;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class SalesReceiptReadonlyTextField extends StatelessWidget {
  const SalesReceiptReadonlyTextField({
    super.key,
    required this.controller,
    this.hint,
    this.onTap,
    this.suffixIcon,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String? hint;
  final VoidCallback? onTap;
  final IconData? suffixIcon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return TextFormField(
      controller: controller,
      readOnly: true,
      enabled: enabled,
      onTap: enabled ? onTap : null,
      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      decoration: transactionCompactInputDecoration(
        cs,
        hint: hint,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class SalesReceiptMemoField extends StatelessWidget {
  const SalesReceiptMemoField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.enabled = true,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return TextFormField(
      controller: controller,
      enabled: enabled,
      style: theme.textTheme.bodySmall,
      decoration: transactionCompactInputDecoration(cs, hint: 'Optional'),
      onChanged: onChanged,
    );
  }
}

class SalesReceiptPaymentMethodField extends StatelessWidget {
  const SalesReceiptPaymentMethodField({
    super.key,
    required this.value,
    required this.methods,
    required this.onChanged,
    this.enabled = true,
  });

  final String value;
  final List<String> methods;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return DropdownButtonFormField<String>(
      initialValue: value,
      isDense: true,
      decoration: transactionCompactInputDecoration(cs),
      style: theme.textTheme.bodySmall,
      items: methods
          .map((method) => DropdownMenuItem(value: method, child: Text(method)))
          .toList(),
      onChanged: enabled
          ? (next) {
              if (next != null) onChanged(next);
            }
          : null,
    );
  }
}

class SalesReceiptCustomerField extends StatelessWidget {
  const SalesReceiptCustomerField({
    super.key,
    required this.controller,
    required this.customers,
    required this.selected,
    required this.onSelected,
    required this.onCleared,
    this.enabled = true,
  });

  final TextEditingController controller;
  final List<CustomerModel> customers;
  final CustomerModel? selected;
  final ValueChanged<CustomerModel> onSelected;
  final VoidCallback onCleared;
  final bool enabled;

  Iterable<CustomerModel> _matches(String pattern) {
    final q = pattern.toLowerCase().trim();
    if (q.isEmpty) return customers.take(20);
    return customers
        .where((customer) {
          return customer.displayName.toLowerCase().contains(q) ||
              (customer.companyName?.toLowerCase().contains(q) ?? false) ||
              customer.primaryContact.toLowerCase().contains(q) ||
              (customer.phone?.toLowerCase().contains(q) ?? false);
        })
        .take(25);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TypeAheadField<CustomerModel>(
      textFieldConfiguration: TextFieldConfiguration(
        controller: controller,
        enabled: enabled,
        decoration: transactionCompactInputDecoration(
          cs,
          hint: 'Select customer',
          suffixIcon: selected == null ? Icons.search : Icons.close,
        ),
      ),
      suggestionsCallback: (pattern) =>
          enabled ? _matches(pattern).toList() : const <CustomerModel>[],
      itemBuilder: (context, customer) => ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        title: Text(
          customer.displayName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(customer.companyName ?? customer.primaryContact),
      ),
      onSuggestionSelected: (customer) {
        controller.text = customer.displayName;
        onSelected(customer);
      },
      noItemsFoundBuilder: (_) => const Padding(
        padding: EdgeInsets.all(8),
        child: Text('No customers found'),
      ),
      suggestionsBoxDecoration: const SuggestionsBoxDecoration(
        elevation: 4,
        constraints: BoxConstraints(maxHeight: 300),
      ),
    );
  }
}

class SalesReceiptDepositAccountField extends StatelessWidget {
  const SalesReceiptDepositAccountField({
    super.key,
    required this.controller,
    required this.accounts,
    required this.selected,
    required this.onSelected,
    required this.onCleared,
    this.enabled = true,
  });

  final TextEditingController controller;
  final List<AccountModel> accounts;
  final AccountModel? selected;
  final ValueChanged<AccountModel> onSelected;
  final VoidCallback onCleared;
  final bool enabled;

  Iterable<AccountModel> _matches(String pattern) {
    final q = pattern.toLowerCase().trim();
    if (q.isEmpty) return accounts.take(20);
    return accounts
        .where((account) {
          return account.name.toLowerCase().contains(q) ||
              account.code.toLowerCase().contains(q) ||
              account.accountType.name.toLowerCase().contains(q);
        })
        .take(25);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TypeAheadField<AccountModel>(
      textFieldConfiguration: TextFieldConfiguration(
        controller: controller,
        enabled: enabled,
        decoration: transactionCompactInputDecoration(
          cs,
          hint: 'Select deposit account',
          suffixIcon: selected == null ? Icons.search : Icons.close,
        ),
      ),
      suggestionsCallback: (pattern) =>
          enabled ? _matches(pattern).toList() : const <AccountModel>[],
      itemBuilder: (context, account) => ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        title: Text(
          account.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${account.code} • ${account.accountType.name}'),
      ),
      onSuggestionSelected: (account) {
        controller.text = account.name;
        onSelected(account);
      },
      noItemsFoundBuilder: (_) => const Padding(
        padding: EdgeInsets.all(8),
        child: Text('No accounts found'),
      ),
      suggestionsBoxDecoration: const SuggestionsBoxDecoration(
        elevation: 4,
        constraints: BoxConstraints(maxHeight: 300),
      ),
    );
  }
}
