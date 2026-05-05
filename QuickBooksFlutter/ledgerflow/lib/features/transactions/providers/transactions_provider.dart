// transactions_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../data/datasources/transactions_remote_datasource.dart';
import '../data/models/transaction_model.dart';
import '../data/repositories/transactions_repository.dart';

final transactionsDatasourceProvider = Provider<TransactionsRemoteDatasource>(
  (ref) => TransactionsRemoteDatasource(ApiClient.instance),
);

final transactionsRepositoryProvider = Provider<TransactionsRepository>(
  (ref) => TransactionsRepository(ref.watch(transactionsDatasourceProvider)),
);

final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<TransactionModel>>(
      TransactionsNotifier.new,
    );

class TransactionsNotifier extends AsyncNotifier<List<TransactionModel>> {
  String _search = '';
  bool _includeVoided = false;

  @override
  Future<List<TransactionModel>> build() => _fetch();

  Future<List<TransactionModel>> _fetch() async {
    final result = await ref
        .read(transactionsRepositoryProvider)
        .getAll(search: _search, includeVoided: _includeVoided);
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

  void setIncludeVoided(bool value) {
    _includeVoided = value;
    refresh();
  }
}

final transactionDetailsProvider =
    FutureProvider.family<TransactionModel, String>((ref, id) async {
      final result = await ref.read(transactionsRepositoryProvider).getById(id);
      return result.when(
        success: (data) => data,
        failure: (error) => throw error,
      );
    });
