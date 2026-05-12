import 'package:flutter/widgets.dart';

import '../../customers/data/models/customer_model.dart';
import '../../transactions/widgets/transaction_context_sidebar.dart';
import '../../transactions/widgets/transaction_models.dart';

Widget buildInvoiceContextPanel({
  required CustomerModel? customer,
  required List<TransactionContextMetric> metrics,
  required List<TransactionContextActivity> activities,
  required TransactionTotalsUiModel totals,
  required bool isLoading,
  required String? warning,
  required String? memoText,
  VoidCallback? onViewAll,
  VoidCallback? onEditNotes,
}) {
  return TransactionContextSidebar(
    title: customer?.displayName ?? '',
    subtitle: customer?.companyName ?? customer?.primaryContact,
    initials: customer?.initials,
    emptyTitle: 'Select a customer',
    emptyMessage:
        'Choose a customer to see balances, credits, invoices, and recent activity.',
    metrics: metrics,
    activities: activities,
    warning: warning,
    isLoading: isLoading,
    totals: totals,
    notes: memoText == null || memoText.trim().isEmpty
        ? null
        : 'Memo: ${memoText.trim()}',
    onViewAll: customer == null ? null : onViewAll,
    onEditNotes: onEditNotes,
  );
}
