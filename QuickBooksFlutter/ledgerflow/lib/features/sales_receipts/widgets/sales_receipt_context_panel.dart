import 'package:flutter/widgets.dart';

import '../../customers/data/models/customer_model.dart';
import '../../transactions/widgets/transaction_context_sidebar.dart';
import '../../transactions/widgets/transaction_models.dart';

Widget buildSalesReceiptContextPanel({
  required CustomerModel? customer,
  required List<TransactionContextMetric> metrics,
  required List<TransactionContextActivity> activities,
  required TransactionTotalsUiModel totals,
  required bool isLoading,
  required String? warning,
  required String? referenceText,
  VoidCallback? onViewAll,
  VoidCallback? onEditNotes,
}) {
  return TransactionContextSidebar(
    title: customer?.displayName ?? '',
    subtitle: customer?.companyName ?? customer?.primaryContact,
    initials: customer?.initials,
    emptyTitle: 'Select a customer',
    emptyMessage: 'Choose a customer to see balances, credits, and recent activity.',
    metrics: metrics,
    activities: activities,
    warning: warning,
    isLoading: isLoading,
    totals: totals,
    notes: referenceText == null || referenceText.trim().isEmpty
        ? null
        : 'Ref: ${referenceText.trim()}',
    onViewAll: customer == null ? null : onViewAll,
    onEditNotes: onEditNotes,
  );
}
