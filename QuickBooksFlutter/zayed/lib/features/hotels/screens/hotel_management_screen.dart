import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../navigation/providers/navigation_provider.dart';
import '../data/hotel_master_data_models.dart';
import '../providers/hotel_master_data_provider.dart';

enum HotelManagementTab { properties, agents, roomTypes, mealPlans }

class HotelManagementScreen extends ConsumerStatefulWidget {
  const HotelManagementScreen({
    super.key,
    this.initialTab = HotelManagementTab.properties,
  });

  final HotelManagementTab initialTab;

  @override
  ConsumerState<HotelManagementScreen> createState() =>
      _HotelManagementScreenState();
}

class _HotelManagementScreenState extends ConsumerState<HotelManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: HotelManagementTab.values.length,
      vsync: this,
      initialIndex: widget.initialTab.index,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modules = ref.watch(currentCompanyModulesProvider);
    return modules.when(
      data: (value) {
        if (!value.hasModule('hotels')) {
          return const _DisabledHotelModule();
        }
        return _buildContent(context);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const _DisabledHotelModule(),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(bottom: BorderSide(color: cs.outlineVariant)),
            ),
            child: Row(
              children: [
                const Icon(Icons.hotel_outlined),
                const SizedBox(width: 10),
                Text(
                  'Hotel Center / مركز الفنادق',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _refreshAll,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            isScrollable: false,
            tabs: const [
              Tab(icon: Icon(Icons.hotel_outlined), text: 'Hotels'),
              Tab(icon: Icon(Icons.groups_outlined), text: 'Agents'),
              Tab(icon: Icon(Icons.meeting_room_outlined), text: 'Room Types'),
              Tab(icon: Icon(Icons.restaurant_menu_outlined), text: 'Meals'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _RecordsPane<HotelPropertyModel>(
                  title: 'Hotels / الفنادق',
                  emptyMessage: 'Add the hotels you sell or contract with.',
                  state: ref.watch(hotelPropertiesProvider),
                  onAdd: () => _editProperty(),
                  onEdit: _editProperty,
                  onToggle: (item) => _setActive(
                    '/api/hotels/master-data/properties',
                    item,
                    HotelPropertyModel.fromJson,
                    () => ref.invalidate(hotelPropertiesProvider),
                  ),
                ),
                _RecordsPane<HotelAgentModel>(
                  title: 'Agents / الوكلاء',
                  emptyMessage: 'Add tourism agents and B2B partners.',
                  state: ref.watch(hotelAgentsProvider),
                  onAdd: () => _editAgent(),
                  onEdit: _editAgent,
                  onToggle: (item) => _setActive(
                    '/api/hotels/master-data/agents',
                    item,
                    HotelAgentModel.fromJson,
                    () => ref.invalidate(hotelAgentsProvider),
                  ),
                ),
                _RecordsPane<HotelRoomTypeModel>(
                  title: 'Room Types / أنواع الغرف',
                  emptyMessage: 'Define room categories before contracts.',
                  state: ref.watch(hotelRoomTypesProvider),
                  onAdd: () => _editRoomType(),
                  onEdit: _editRoomType,
                  onToggle: (item) => _setActive(
                    '/api/hotels/master-data/room-types',
                    item,
                    HotelRoomTypeModel.fromJson,
                    () => ref.invalidate(hotelRoomTypesProvider),
                  ),
                ),
                _RecordsPane<HotelMealPlanModel>(
                  title: 'Meal Plans / خطط الوجبات',
                  emptyMessage: 'Define RO, BB, HB, FB and custom plans.',
                  state: ref.watch(hotelMealPlansProvider),
                  onAdd: () => _editMealPlan(),
                  onEdit: _editMealPlan,
                  onToggle: (item) => _setActive(
                    '/api/hotels/master-data/meal-plans',
                    item,
                    HotelMealPlanModel.fromJson,
                    () => ref.invalidate(hotelMealPlansProvider),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _refreshAll() {
    ref.invalidate(hotelPropertiesProvider);
    ref.invalidate(hotelAgentsProvider);
    ref.invalidate(hotelRoomTypesProvider);
    ref.invalidate(hotelMealPlansProvider);
  }

  Future<void> _setActive<T extends HotelMasterDataRecord>(
    String endpoint,
    T item,
    T Function(Map<String, dynamic>) fromJson,
    VoidCallback refresh,
  ) async {
    final result = await ref
        .read(hotelMasterDataDatasourceProvider)
        .setActive(endpoint, item.id, !item.isActive, fromJson);
    if (!mounted) return;
    result.when(
      success: (_) => refresh(),
      failure: (error) => _showError(error.toString()),
    );
  }

  Future<void> _editProperty([HotelPropertyModel? item]) async {
    final result = await showDialog<HotelPropertyModel>(
      context: context,
      builder: (_) => _PropertyDialog(item: item),
    );
    if (result == null) return;
    await _save(result, () => ref.invalidate(hotelPropertiesProvider));
  }

  Future<void> _editAgent([HotelAgentModel? item]) async {
    final result = await showDialog<HotelAgentModel>(
      context: context,
      builder: (_) => _AgentDialog(item: item),
    );
    if (result == null) return;
    await _save(result, () => ref.invalidate(hotelAgentsProvider));
  }

  Future<void> _editRoomType([HotelRoomTypeModel? item]) async {
    final result = await showDialog<HotelRoomTypeModel>(
      context: context,
      builder: (_) => _RoomTypeDialog(item: item),
    );
    if (result == null) return;
    await _save(result, () => ref.invalidate(hotelRoomTypesProvider));
  }

  Future<void> _editMealPlan([HotelMealPlanModel? item]) async {
    final result = await showDialog<HotelMealPlanModel>(
      context: context,
      builder: (_) => _MealPlanDialog(item: item),
    );
    if (result == null) return;
    await _save(result, () => ref.invalidate(hotelMealPlansProvider));
  }

  Future<void> _save<T extends HotelMasterDataRecord>(
    T record,
    VoidCallback refresh,
  ) async {
    final result = await saveHotelRecord(ref, record);
    if (!mounted) return;
    result.when(
      success: (_) => refresh(),
      failure: (error) => _showError(error.toString()),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _RecordsPane<T extends HotelMasterDataRecord> extends StatelessWidget {
  const _RecordsPane({
    required this.title,
    required this.emptyMessage,
    required this.state,
    required this.onAdd,
    required this.onEdit,
    required this.onToggle,
  });

  final String title;
  final String emptyMessage;
  final AsyncValue<List<T>> state;
  final VoidCallback onAdd;
  final ValueChanged<T> onEdit;
  final ValueChanged<T> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(error.toString())),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      emptyMessage,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Material(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      child: ListTile(
                        leading: Icon(
                          item.isActive
                              ? Icons.check_circle_outline
                              : Icons.pause_circle_outline,
                          color: item.isActive ? cs.primary : cs.outline,
                        ),
                        title: Text(item.title),
                        subtitle: item.subtitle.isEmpty
                            ? null
                            : Text(item.subtitle),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              onPressed: () => onEdit(item),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: item.isActive
                                  ? 'Deactivate'
                                  : 'Activate',
                              onPressed: () => onToggle(item),
                              icon: Icon(
                                item.isActive
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DisabledHotelModule extends StatelessWidget {
  const _DisabledHotelModule();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('هذا الموديول غير مفعل لهذه الشركة'));
  }
}

class _PropertyDialog extends StatefulWidget {
  const _PropertyDialog({this.item});
  final HotelPropertyModel? item;

  @override
  State<_PropertyDialog> createState() => _PropertyDialogState();
}

class _PropertyDialogState extends State<_PropertyDialog> {
  late final _name = TextEditingController(text: widget.item?.name ?? '');
  late final _country = TextEditingController(
    text: widget.item?.country ?? 'Saudi Arabia',
  );
  late final _city = TextEditingController(text: widget.item?.city ?? 'Makkah');
  late final _phone = TextEditingController(text: widget.item?.phone ?? '');
  late final _email = TextEditingController(text: widget.item?.email ?? '');
  late final _address = TextEditingController(text: widget.item?.address ?? '');

  @override
  Widget build(BuildContext context) => _DialogShell(
    title: widget.item == null ? 'Add Hotel' : 'Edit Hotel',
    children: [
      _field(_name, 'Hotel name / اسم الفندق'),
      _field(_city, 'City / المدينة'),
      _field(_country, 'Country / الدولة'),
      _field(_phone, 'Phone / الهاتف'),
      _field(_email, 'Email / البريد'),
      _field(_address, 'Address / العنوان', lines: 2),
    ],
    onSubmit: () {
      if (_name.text.trim().isEmpty || _city.text.trim().isEmpty) return;
      Navigator.of(context).pop(
        HotelPropertyModel(
          id: widget.item?.id ?? '',
          name: _name.text.trim(),
          country: _country.text.trim(),
          city: _city.text.trim(),
          phone: _phone.text.trim(),
          email: _email.text.trim(),
          address: _address.text.trim(),
          isActive: widget.item?.isActive ?? true,
        ),
      );
    },
  );
}

class _AgentDialog extends StatefulWidget {
  const _AgentDialog({this.item});
  final HotelAgentModel? item;

  @override
  State<_AgentDialog> createState() => _AgentDialogState();
}

class _AgentDialogState extends State<_AgentDialog> {
  late final _name = TextEditingController(text: widget.item?.name ?? '');
  late final _contact = TextEditingController(
    text: widget.item?.contactName ?? '',
  );
  late final _phone = TextEditingController(text: widget.item?.phone ?? '');
  late final _email = TextEditingController(text: widget.item?.email ?? '');
  late final _currency = TextEditingController(
    text: widget.item?.currency ?? 'SAR',
  );

  @override
  Widget build(BuildContext context) => _DialogShell(
    title: widget.item == null ? 'Add Agent' : 'Edit Agent',
    children: [
      _field(_name, 'Agent name / اسم الوكيل'),
      _field(_contact, 'Contact / المسؤول'),
      _field(_phone, 'Phone / الهاتف'),
      _field(_email, 'Email / البريد'),
      _field(_currency, 'Currency / العملة'),
    ],
    onSubmit: () {
      if (_name.text.trim().isEmpty) return;
      Navigator.of(context).pop(
        HotelAgentModel(
          id: widget.item?.id ?? '',
          name: _name.text.trim(),
          contactName: _contact.text.trim(),
          phone: _phone.text.trim(),
          email: _email.text.trim(),
          currency: _currency.text.trim().isEmpty
              ? 'SAR'
              : _currency.text.trim(),
          isActive: widget.item?.isActive ?? true,
        ),
      );
    },
  );
}

class _RoomTypeDialog extends StatefulWidget {
  const _RoomTypeDialog({this.item});
  final HotelRoomTypeModel? item;

  @override
  State<_RoomTypeDialog> createState() => _RoomTypeDialogState();
}

class _RoomTypeDialogState extends State<_RoomTypeDialog> {
  late final _code = TextEditingController(text: widget.item?.code ?? '');
  late final _name = TextEditingController(text: widget.item?.name ?? '');
  late final _capacity = TextEditingController(
    text: (widget.item?.capacity ?? 2).toString(),
  );
  late final _description = TextEditingController(
    text: widget.item?.description ?? '',
  );

  @override
  Widget build(BuildContext context) => _DialogShell(
    title: widget.item == null ? 'Add Room Type' : 'Edit Room Type',
    children: [
      _field(_code, 'Code / الكود'),
      _field(_name, 'Name / الاسم'),
      _field(_capacity, 'Capacity / السعة', keyboardType: TextInputType.number),
      _field(_description, 'Description / الوصف', lines: 2),
    ],
    onSubmit: () {
      if (_code.text.trim().isEmpty || _name.text.trim().isEmpty) return;
      Navigator.of(context).pop(
        HotelRoomTypeModel(
          id: widget.item?.id ?? '',
          code: _code.text.trim(),
          name: _name.text.trim(),
          capacity: int.tryParse(_capacity.text.trim()) ?? 1,
          description: _description.text.trim(),
          isActive: widget.item?.isActive ?? true,
        ),
      );
    },
  );
}

class _MealPlanDialog extends StatefulWidget {
  const _MealPlanDialog({this.item});
  final HotelMealPlanModel? item;

  @override
  State<_MealPlanDialog> createState() => _MealPlanDialogState();
}

class _MealPlanDialogState extends State<_MealPlanDialog> {
  late final _code = TextEditingController(text: widget.item?.code ?? '');
  late final _name = TextEditingController(text: widget.item?.name ?? '');
  late final _description = TextEditingController(
    text: widget.item?.description ?? '',
  );

  @override
  Widget build(BuildContext context) => _DialogShell(
    title: widget.item == null ? 'Add Meal Plan' : 'Edit Meal Plan',
    children: [
      _field(_code, 'Code / الكود'),
      _field(_name, 'Name / الاسم'),
      _field(_description, 'Description / الوصف', lines: 2),
    ],
    onSubmit: () {
      if (_code.text.trim().isEmpty || _name.text.trim().isEmpty) return;
      Navigator.of(context).pop(
        HotelMealPlanModel(
          id: widget.item?.id ?? '',
          code: _code.text.trim(),
          name: _name.text.trim(),
          description: _description.text.trim(),
          isActive: widget.item?.isActive ?? true,
        ),
      );
    },
  );
}

class _DialogShell extends StatelessWidget {
  const _DialogShell({
    required this.title,
    required this.children,
    required this.onSubmit,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: onSubmit, child: const Text('Save')),
      ],
    );
  }
}

Widget _field(
  TextEditingController controller,
  String label, {
  int lines = 1,
  TextInputType? keyboardType,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      maxLines: lines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );
}
