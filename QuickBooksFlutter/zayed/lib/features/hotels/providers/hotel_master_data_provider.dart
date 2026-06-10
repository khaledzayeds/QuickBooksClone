import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_result.dart';
import '../../companies/providers/company_registry_provider.dart';
import '../data/hotel_master_data_datasource.dart';
import '../data/hotel_master_data_models.dart';

final hotelMasterDataDatasourceProvider = Provider<HotelMasterDataDatasource>(
  (_) => HotelMasterDataDatasource(),
);

final hotelPropertiesProvider = FutureProvider<List<HotelPropertyModel>>((
  ref,
) async {
  ref.watch(activeCompanyScopeProvider);
  final result = await ref
      .read(hotelMasterDataDatasourceProvider)
      .getProperties();
  return result.when(success: (data) => data, failure: (error) => throw error);
});

final hotelRoomTypesProvider = FutureProvider<List<HotelRoomTypeModel>>((
  ref,
) async {
  ref.watch(activeCompanyScopeProvider);
  final result = await ref
      .read(hotelMasterDataDatasourceProvider)
      .getRoomTypes();
  return result.when(success: (data) => data, failure: (error) => throw error);
});

final hotelMealPlansProvider = FutureProvider<List<HotelMealPlanModel>>((
  ref,
) async {
  ref.watch(activeCompanyScopeProvider);
  final result = await ref
      .read(hotelMasterDataDatasourceProvider)
      .getMealPlans();
  return result.when(success: (data) => data, failure: (error) => throw error);
});

final hotelAgentsProvider = FutureProvider<List<HotelAgentModel>>((ref) async {
  ref.watch(activeCompanyScopeProvider);
  final result = await ref.read(hotelMasterDataDatasourceProvider).getAgents();
  return result.when(success: (data) => data, failure: (error) => throw error);
});

Future<ApiResult<T>> saveHotelRecord<T extends HotelMasterDataRecord>(
  WidgetRef ref,
  T record,
) {
  final datasource = ref.read(hotelMasterDataDatasourceProvider);
  return switch (record) {
    HotelPropertyModel item =>
      datasource.saveProperty(item) as Future<ApiResult<T>>,
    HotelRoomTypeModel item =>
      datasource.saveRoomType(item) as Future<ApiResult<T>>,
    HotelMealPlanModel item =>
      datasource.saveMealPlan(item) as Future<ApiResult<T>>,
    HotelAgentModel item => datasource.saveAgent(item) as Future<ApiResult<T>>,
    _ => throw ArgumentError('Unsupported hotel record type.'),
  };
}
