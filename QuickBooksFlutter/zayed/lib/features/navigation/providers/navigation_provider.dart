import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_result.dart';
import '../../companies/providers/company_registry_provider.dart';
import '../data/navigation_datasource.dart';
import '../models/navigation_models.dart';

final navigationDatasourceProvider = Provider<NavigationDatasource>(
  (_) => NavigationDatasource(),
);

final navigationMenuProvider = FutureProvider<List<NavigationMenuItem>>((
  ref,
) async {
  ref.watch(activeCompanyScopeProvider);
  final result = await ref.read(navigationDatasourceProvider).getMenu();
  return switch (result) {
    Success<List<NavigationMenuItem>>(data: final menu) => menu,
    Failure<List<NavigationMenuItem>>(error: final error) => throw error,
  };
});

final currentCompanyModulesProvider = FutureProvider<CurrentCompanyModules>((
  ref,
) async {
  ref.watch(activeCompanyScopeProvider);
  final result = await ref
      .read(navigationDatasourceProvider)
      .getCurrentModules();
  return switch (result) {
    Success<CurrentCompanyModules>(data: final modules) => modules,
    Failure<CurrentCompanyModules>(error: final error) => throw error,
  };
});
