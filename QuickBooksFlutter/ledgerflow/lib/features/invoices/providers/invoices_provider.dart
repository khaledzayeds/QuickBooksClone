// invoices_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../data/datasources/invoices_remote_datasource.dart';
import '../data/models/invoice_model.dart';
import '../data/repositories/invoices_repository.dart';

final invoicesDatasourceProvider = Provider<InvoicesRemoteDatasource>(
  (ref) => InvoicesRemoteDatasource(ApiClient.instance),
);

final salesReceiptsDatasourceProvider = Provider<InvoicesRemoteDatasource>(
  (ref) => InvoicesRemoteDatasource(ApiClient.instance, salesReceiptMode: true),
);

final invoicesRepositoryProvider = Provider<InvoicesRepository>(
  (ref) => InvoicesRepository(ref.watch(invoicesDatasourceProvider)),
);

final salesReceiptsRepositoryProvider = Provider<InvoicesRepository>(
  (ref) => InvoicesRepository(ref.watch(salesReceiptsDatasourceProvider)),
);

final invoicesProvider = AsyncNotifierProvider<InvoicesNotifier, List<InvoiceModel>>(
  InvoicesNotifier.new,
);

class InvoicesNotifier extends AsyncNotifier<List<InvoiceModel>> {
  String _search = '';
  String? _customerId;
  bool _includeVoid = false;

  @override
  Future<List<InvoiceModel>> build() => _fetch();

  Future<List<InvoiceModel>> _fetch() async {
    final result = await ref.read(invoicesRepositoryProvider).getInvoices(
          search: _search,
          customerId: _customerId,
          includeVoid: _includeVoid,
        );
    return result.when(
      success: (data) => data,
      failure: (error) => throw error,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  void setSearch(String value) {
    _search = value;
    refresh();
  }

  void setCustomer(String? value) {
    _customerId = value;
    refresh();
  }

  void setIncludeVoid(bool value) {
    _includeVoid = value;
    refresh();
  }

  Future<ApiResult<InvoiceModel>> createInvoice(Map<String, dynamic> body) async {
    final result = await ref.read(invoicesRepositoryProvider).createInvoice(body);
    if (result.isSuccess) refresh();
    return result;
  }

  Future<ApiResult<InvoiceModel>> postInvoice(String id) async {
    final result = await ref.read(invoicesRepositoryProvider).postInvoice(id);
    if (result.isSuccess) refresh();
    return result;
  }

  Future<ApiResult<InvoiceModel>> voidInvoice(String id) async {
    final result = await ref.read(invoicesRepositoryProvider).voidInvoice(id);
    if (result.isSuccess) refresh();
    return result;
  }
}

final salesReceiptsProvider = AsyncNotifierProvider<SalesReceiptsNotifier, List<InvoiceModel>>(
  SalesReceiptsNotifier.new,
);

class SalesReceiptsNotifier extends AsyncNotifier<List<InvoiceModel>> {
  String _search = '';
  String? _customerId;
  bool _includeVoid = false;

  @override
  Future<List<InvoiceModel>> build() => _fetch();

  Future<List<InvoiceModel>> _fetch() async {
    final result = await ref.read(salesReceiptsRepositoryProvider).getInvoices(
          search: _search,
          customerId: _customerId,
          includeVoid: _includeVoid,
        );
    return result.when(
      success: (data) => data,
      failure: (error) => throw error,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  void setSearch(String value) {
    _search = value;
    refresh();
  }

  void setCustomer(String? value) {
    _customerId = value;
    refresh();
  }

  void setIncludeVoid(bool value) {
    _includeVoid = value;
    refresh();
  }

  Future<ApiResult<InvoiceModel>> createSalesReceipt(Map<String, dynamic> body) async {
    final result = await ref.read(salesReceiptsRepositoryProvider).createInvoice(body);
    if (result.isSuccess) refresh();
    return result;
  }

  Future<ApiResult<InvoiceModel>> voidSalesReceipt(String id) async {
    final result = await ref.read(salesReceiptsRepositoryProvider).voidInvoice(id);
    if (result.isSuccess) refresh();
    return result;
  }
}

final invoiceDetailProvider = FutureProvider.family<InvoiceModel, String>((ref, id) async {
  final result = await ref.read(invoicesRepositoryProvider).getInvoice(id);
  return result.when(
    success: (data) => data,
    failure: (error) => throw error,
  );
});

final salesReceiptDetailProvider = FutureProvider.family<InvoiceModel, String>((ref, id) async {
  final result = await ref.read(salesReceiptsRepositoryProvider).getInvoice(id);
  return result.when(
    success: (data) => data,
    failure: (error) => throw error,
  );
});
