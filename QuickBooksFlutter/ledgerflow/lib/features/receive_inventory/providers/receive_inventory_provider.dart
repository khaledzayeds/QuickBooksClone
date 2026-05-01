import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/receive_inventory_remote_datasource.dart';
import '../data/models/receive_inventory_model.dart';
import '../data/repositories/receive_inventory_repository.dart';

final receiveInventoryDatasourceProvider = Provider(
  (_) => ReceiveInventoryRemoteDatasource(),
);

final receiveInventoryRepoProvider = Provider(
  (ref) => ReceiveInventoryRepository(
    ref.read(receiveInventoryDatasourceProvider),
  ),
);

final receiveInventoryListProvider = FutureProvider(
  (ref) async {
    final result = await ref.read(receiveInventoryRepoProvider).getAll();
    return result.when(
      success: (data) => data,
      failure: (error) => throw error,
    );
  },
);

final receiveInventoryDetailsProvider =
    FutureProvider.family<ReceiveInventoryModel, String>((ref, id) async {
  final result = await ref.read(receiveInventoryRepoProvider).getById(id);
  return result.when(
    success: (data) => data,
    failure: (error) => throw error,
  );
});
