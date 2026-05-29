// invoices_state.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../companies/providers/company_registry_provider.dart';
import '../data/datasources/invoices_api.dart';
import '../data/models/invoice_contracts.dart';
import '../data/repositories/invoices_repo.dart';

final invoicesApiProvider = Provider<InvoicesApi>(
  (ref) => InvoicesApi(ApiClient.instance),
);

final invoicesRepoProvider = Provider<InvoicesRepo>(
  (ref) => InvoicesRepo(ref.watch(invoicesApiProvider)),
);

final invoicesStateProvider =
    AsyncNotifierProvider<InvoicesState, List<InvoiceModel>>(InvoicesState.new);

class InvoicesState extends AsyncNotifier<List<InvoiceModel>> {
  @override
  Future<List<InvoiceModel>> build() {
    final activeCompanyScope = ref.watch(activeCompanyScopeProvider);
    if (activeCompanyScope == null) return Future.value(const []);
    return _fetch();
  }

  Future<List<InvoiceModel>> _fetch() async {
    final result = await ref.read(invoicesRepoProvider).getAll();
    return result.when(
      success: (data) => data,
      failure: (error) => throw error,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final invoiceDetailsStateProvider = FutureProvider.family<InvoiceModel, String>(
  (ref, id) async {
    final activeCompanyScope = ref.watch(activeCompanyScopeProvider);
    if (activeCompanyScope == null) {
      throw StateError('No active company selected.');
    }
    final result = await ref.read(invoicesRepoProvider).getById(id);
    return result.when(
      success: (data) => data,
      failure: (error) => throw error,
    );
  },
);
