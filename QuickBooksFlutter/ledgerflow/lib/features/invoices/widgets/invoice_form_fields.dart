import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../customers/data/models/customer_model.dart';
import '../../transactions/widgets/transaction_form_shell.dart';

class InvoiceFormField extends StatelessWidget {
  const InvoiceFormField({
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

class InvoiceReadonlyTextField extends StatelessWidget {
  const InvoiceReadonlyTextField({
    super.key,
    required this.controller,
    this.hint,
    this.onTap,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String? hint;
  final VoidCallback? onTap;
  final IconData? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      decoration: transactionCompactInputDecoration(
        cs,
        hint: hint,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class InvoiceMemoField extends StatelessWidget {
  const InvoiceMemoField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return TextFormField(
      controller: controller,
      style: theme.textTheme.bodySmall,
      decoration: transactionCompactInputDecoration(cs, hint: 'Optional'),
      onChanged: onChanged,
    );
  }
}

class InvoiceTermsField extends StatelessWidget {
  const InvoiceTermsField({
    super.key,
    required this.value,
    required this.terms,
    required this.onChanged,
  });

  final String value;
  final List<String> terms;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return DropdownButtonFormField<String>(
      initialValue: value,
      isDense: true,
      isExpanded: true,
      decoration: transactionCompactInputDecoration(cs),
      style: theme.textTheme.bodySmall,
      items: terms
          .map((term) => DropdownMenuItem(value: term, child: Text(term)))
          .toList(),
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }
}

class InvoiceCustomerField extends StatelessWidget {
  const InvoiceCustomerField({
    super.key,
    required this.controller,
    required this.customers,
    required this.selected,
    required this.onSelected,
    required this.onCleared,
  });

  final TextEditingController controller;
  final List<CustomerModel> customers;
  final CustomerModel? selected;
  final ValueChanged<CustomerModel> onSelected;
  final VoidCallback onCleared;

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
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return TypeAheadField<CustomerModel>(
      textFieldConfiguration: TextFieldConfiguration(
        controller: controller,
        decoration: transactionCompactInputDecoration(
          cs,
          hint: l10n.selectCustomer,
          suffixIcon: selected == null ? Icons.search : Icons.close,
        ),
      ),
      suggestionsCallback: (pattern) => _matches(pattern).toList(),
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
