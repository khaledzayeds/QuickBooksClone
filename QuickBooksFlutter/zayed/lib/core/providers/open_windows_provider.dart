import 'package:flutter_riverpod/legacy.dart';

final openWindowsProvider =
    StateNotifierProvider<OpenWindowsNotifier, List<OpenWindowEntry>>(
      (ref) => OpenWindowsNotifier(),
    );

class OpenWindowsNotifier extends StateNotifier<List<OpenWindowEntry>> {
  OpenWindowsNotifier() : super(const []);

  static const int _maxEntries = 12;

  void open(String path) {
    final normalized = _normalize(path);
    if (normalized.isEmpty || normalized == '/login' || normalized == '/setup') {
      return;
    }

    final existing = state.where((entry) => entry.path != normalized).toList();
    state = [
      OpenWindowEntry(
        path: normalized,
        title: routeTitle(normalized),
        openedAt: DateTime.now(),
      ),
      ...existing,
    ].take(_maxEntries).toList(growable: false);
  }

  void close(String path) {
    final normalized = _normalize(path);
    state = state
        .where((entry) => entry.path != normalized)
        .toList(growable: false);
  }

  void clear() {
    state = const [];
  }
}

class OpenWindowEntry {
  const OpenWindowEntry({
    required this.path,
    required this.title,
    required this.openedAt,
  });

  final String path;
  final String title;
  final DateTime openedAt;
}

String _normalize(String path) {
  final uri = Uri.tryParse(path);
  if (uri == null) return path.trim();
  final query = uri.hasQuery ? '?${uri.query}' : '';
  return '${uri.path.isEmpty ? '/' : uri.path}$query';
}

String routeTitle(String path) {
  final cleanPath = Uri.tryParse(path)?.path ?? path;

  if (cleanPath == '/') return 'Home';
  if (cleanPath == '/company/cash-flow-hub') return 'Cash Flow Hub';
  if (cleanPath == '/company/profile' || cleanPath == '/settings/company') {
    return 'My Company';
  }
  if (cleanPath == '/company/open-windows') return 'Open Windows';
  if (cleanPath == '/company/calendar') return 'Calendar';
  if (cleanPath == '/company/snapshots') return 'Snapshots';
  if (cleanPath == '/company/time-tracking') return 'Enter Time';
  if (cleanPath == '/company/payroll') return 'Payroll';
  if (cleanPath == '/company/journal-entries') return 'Journal Entries';

  if (cleanPath.startsWith('/sales/invoices')) {
    return _detailTitle(cleanPath, 'Invoices', 'Invoice');
  }
  if (cleanPath.startsWith('/sales/payments')) {
    return _detailTitle(cleanPath, 'Payments', 'Payment');
  }
  if (cleanPath.startsWith('/sales/estimates')) {
    return _detailTitle(cleanPath, 'Estimates', 'Estimate');
  }
  if (cleanPath.startsWith('/sales/orders')) {
    return _detailTitle(cleanPath, 'Sales Orders', 'Sales Order');
  }
  if (cleanPath.startsWith('/sales/receipts')) {
    return _detailTitle(cleanPath, 'Sales Receipts', 'Sales Receipt');
  }
  if (cleanPath.startsWith('/sales/returns')) {
    return _detailTitle(cleanPath, 'Sales Returns', 'Sales Return');
  }
  if (cleanPath.startsWith('/sales/customer-credits')) {
    return _detailTitle(cleanPath, 'Customer Credits', 'Customer Credit');
  }

  if (cleanPath.startsWith('/purchases/orders')) {
    return _detailTitle(cleanPath, 'Purchase Orders', 'Purchase Order');
  }
  if (cleanPath.startsWith('/purchases/receive')) {
    return _detailTitle(cleanPath, 'Receive Inventory', 'Inventory Receipt');
  }
  if (cleanPath.startsWith('/purchases/bills')) {
    return _detailTitle(cleanPath, 'Bills', 'Bill');
  }
  if (cleanPath.startsWith('/purchases/vendor-payments')) {
    return _detailTitle(cleanPath, 'Vendor Payments', 'Vendor Payment');
  }
  if (cleanPath.startsWith('/purchases/vendor-credits')) {
    return _detailTitle(cleanPath, 'Vendor Credits', 'Vendor Credit');
  }
  if (cleanPath.startsWith('/purchases/returns')) {
    return _detailTitle(cleanPath, 'Purchase Returns', 'Purchase Return');
  }

  if (cleanPath.startsWith('/master/customers')) {
    return _detailTitle(cleanPath, 'Customers', 'Customer');
  }
  if (cleanPath.startsWith('/master/vendors')) {
    return _detailTitle(cleanPath, 'Vendors', 'Vendor');
  }
  if (cleanPath.startsWith('/master/items')) {
    return _detailTitle(cleanPath, 'Items', 'Item');
  }
  if (cleanPath.startsWith('/master/coa')) {
    return _detailTitle(cleanPath, 'Chart of Accounts', 'Account');
  }

  if (cleanPath.startsWith('/inventory/adjustments')) {
    return _detailTitle(
      cleanPath,
      'Inventory Adjustments',
      'Inventory Adjustment',
    );
  }
  if (cleanPath.startsWith('/banking/register')) return 'Bank Register';
  if (cleanPath.startsWith('/banking/transfers')) return 'Bank Transfers';
  if (cleanPath.startsWith('/banking/deposits')) return 'Make Deposits';
  if (cleanPath.startsWith('/banking/checks')) return 'Write Checks';
  if (cleanPath.startsWith('/banking/reconcile')) return 'Reconcile';
  if (cleanPath.startsWith('/reports')) return 'Reports';
  if (cleanPath.startsWith('/transactions')) {
    return _detailTitle(cleanPath, 'Transactions', 'Transaction');
  }
  if (cleanPath.startsWith('/settings')) return 'Settings';

  return cleanPath
      .split('/')
      .where((part) => part.isNotEmpty)
      .map((part) => part.replaceAll('-', ' '))
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' / ');
}

String _detailTitle(String path, String listTitle, String itemTitle) {
  final segments = path.split('/').where((part) => part.isNotEmpty).toList();
  if (segments.isEmpty) return listTitle;
  if (segments.last == 'new') return 'New $itemTitle';
  if (segments.contains('edit')) return 'Edit $itemTitle';
  if (segments.length > 2) return '$itemTitle Details';
  return listTitle;
}
