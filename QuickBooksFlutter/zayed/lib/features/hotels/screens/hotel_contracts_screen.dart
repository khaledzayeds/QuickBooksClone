import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/hotel_contracts_models.dart';
import '../data/hotel_master_data_models.dart';
import '../providers/hotel_contracts_provider.dart';
import '../providers/hotel_master_data_provider.dart';

enum HotelContractsTab { contracts, allotments }

class HotelContractsScreen extends ConsumerStatefulWidget {
  const HotelContractsScreen({
    super.key,
    this.initialTab = HotelContractsTab.contracts,
    this.overAllotment = false,
    this.agentAllotment = false,
  });

  final HotelContractsTab initialTab;
  final bool overAllotment;
  final bool agentAllotment;

  @override
  ConsumerState<HotelContractsScreen> createState() =>
      _HotelContractsScreenState();
}

class _HotelContractsScreenState extends ConsumerState<HotelContractsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
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
              border: Border(bottom: BorderSide(color: cs.outlineVariant)),
            ),
            child: Row(
              children: [
                const Icon(Icons.assignment_outlined),
                const SizedBox(width: 10),
                Text(
                  'Contracts & Allotment / العقود والحصص',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.description_outlined), text: 'Contracts'),
              Tab(icon: Icon(Icons.hotel_class_outlined), text: 'Allotment'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ContractsPane(onAdd: _editContract, onEdit: _editContract),
                _AllotmentsPane(
                  overAllotment: widget.overAllotment,
                  agentAllotment: widget.agentAllotment,
                  onAdd: _editAllotment,
                  onEdit: _editAllotment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _refresh() {
    ref.invalidate(hotelContractsProvider);
    ref.invalidate(hotelAllotmentsProvider);
  }

  Future<void> _editContract([HotelContractModel? item]) async {
    final result = await showDialog<HotelContractModel>(
      context: context,
      builder: (_) => _ContractDialog(item: item),
    );
    if (result == null) return;
    final save = await ref
        .read(hotelContractsDatasourceProvider)
        .saveContract(result);
    if (!mounted) return;
    save.when(
      success: (_) => ref.invalidate(hotelContractsProvider),
      failure: (error) => _showError(error.toString()),
    );
  }

  Future<void> _editAllotment([HotelAllotmentModel? item]) async {
    final result = await showDialog<HotelAllotmentModel>(
      context: context,
      builder: (_) => _AllotmentDialog(
        item: item,
        overAllotment: widget.overAllotment,
        agentAllotment: widget.agentAllotment,
      ),
    );
    if (result == null) return;
    final save = await ref
        .read(hotelContractsDatasourceProvider)
        .saveAllotment(result);
    if (!mounted) return;
    save.when(
      success: (_) => ref.invalidate(hotelAllotmentsProvider),
      failure: (error) => _showError(error.toString()),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ContractsPane extends ConsumerWidget {
  const _ContractsPane({required this.onAdd, required this.onEdit});

  final VoidCallback onAdd;
  final ValueChanged<HotelContractModel> onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hotelContractsProvider);
    return _PaneShell(
      title: 'Hotel Contracts / عقود الفنادق',
      actionLabel: 'Add Contract',
      onAdd: onAdd,
      child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (items) => items.isEmpty
            ? const Center(child: Text('Create a hotel contract first.'))
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _Tile(
                    active: item.isActive,
                    title: '${item.contractNumber} - ${item.hotelName}',
                    subtitle:
                        '${_fmt(item.startDate)} to ${_fmt(item.endDate)} - ${item.currency} - ${item.rates.length} rates',
                    onEdit: () => onEdit(item),
                  );
                },
              ),
      ),
    );
  }
}

class _AllotmentsPane extends ConsumerWidget {
  const _AllotmentsPane({
    required this.onAdd,
    required this.onEdit,
    required this.overAllotment,
    required this.agentAllotment,
  });

  final VoidCallback onAdd;
  final ValueChanged<HotelAllotmentModel> onEdit;
  final bool overAllotment;
  final bool agentAllotment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hotelAllotmentsProvider);
    return _PaneShell(
      title: overAllotment
          ? 'Over Allotment / زيادة الحصص'
          : 'Allotment / الحصص',
      actionLabel: 'Add Allotment',
      onAdd: onAdd,
      child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (items) {
          final filtered = items
              .where((item) => item.isOverAllotment == overAllotment)
              .where(
                (item) => agentAllotment
                    ? item.allotmentType == 'agent'
                    : item.allotmentType == 'hotel',
              )
              .toList();
          if (filtered.isEmpty) {
            return const Center(child: Text('No allotment rows yet.'));
          }
          return ListView.separated(
            itemCount: filtered.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = filtered[index];
              return _Tile(
                active: item.isActive,
                title: '${item.contractNumber} - ${item.hotelName}',
                subtitle:
                    '${item.rooms} rooms - ${_fmt(item.startDate)} to ${_fmt(item.endDate)}',
                onEdit: () => onEdit(item),
              );
            },
          );
        },
      ),
    );
  }
}

class _PaneShell extends StatelessWidget {
  const _PaneShell({
    required this.title,
    required this.actionLabel,
    required this.onAdd,
    required this.child,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAdd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                label: Text(actionLabel),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.active,
    required this.title,
    required this.subtitle,
    required this.onEdit,
  });

  final bool active;
  final String title;
  final String subtitle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: ListTile(
        leading: Icon(
          active ? Icons.check_circle_outline : Icons.pause_circle_outline,
          color: active ? cs.primary : cs.outline,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: IconButton(
          tooltip: 'Edit',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
      ),
    );
  }
}

class _ContractDialog extends ConsumerStatefulWidget {
  const _ContractDialog({this.item});

  final HotelContractModel? item;

  @override
  ConsumerState<_ContractDialog> createState() => _ContractDialogState();
}

class _ContractDialogState extends ConsumerState<_ContractDialog> {
  late final _number = TextEditingController(
    text:
        widget.item?.contractNumber ??
        'HC-${DateTime.now().millisecondsSinceEpoch}',
  );
  late final _currency = TextEditingController(
    text: widget.item?.currency ?? 'SAR',
  );
  late final _notes = TextEditingController(text: widget.item?.notes ?? '');
  late final _rate = TextEditingController(
    text: widget.item?.rates.firstOrNull?.rate.toStringAsFixed(2) ?? '0',
  );
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(days: 30));
  String? _hotelId;
  String? _agentId;
  String? _roomTypeId;
  String? _mealPlanId;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item != null) {
      _start = item.startDate;
      _end = item.endDate;
      _hotelId = item.hotelId;
      _agentId = item.agentId;
      _roomTypeId = item.rates.firstOrNull?.roomTypeId;
      _mealPlanId = item.rates.firstOrNull?.mealPlanId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hotels =
        ref.watch(hotelPropertiesProvider).value ??
        const <HotelPropertyModel>[];
    final agents =
        ref.watch(hotelAgentsProvider).value ?? const <HotelAgentModel>[];
    final rooms =
        ref.watch(hotelRoomTypesProvider).value ?? const <HotelRoomTypeModel>[];
    final meals =
        ref.watch(hotelMealPlansProvider).value ?? const <HotelMealPlanModel>[];
    _hotelId ??= hotels.firstOrNull?.id;
    _roomTypeId ??= rooms.firstOrNull?.id;
    _mealPlanId ??= meals.firstOrNull?.id;

    return _DialogShell(
      title: widget.item == null ? 'Add Contract' : 'Edit Contract',
      children: [
        _field(_number, 'Contract number'),
        _dropdown(
          'Hotel',
          _hotelId,
          hotels.map((x) => MapEntry(x.id, x.name)),
          (v) => setState(() => _hotelId = v),
        ),
        _dropdown(
          'Agent',
          _agentId,
          agents.map((x) => MapEntry(x.id, x.name)),
          (v) => setState(() => _agentId = v),
          allowEmpty: true,
        ),
        _dateRow(context, 'Start', _start, (v) => setState(() => _start = v)),
        _dateRow(context, 'End', _end, (v) => setState(() => _end = v)),
        _field(_currency, 'Currency'),
        const Divider(),
        _dropdown(
          'Room type',
          _roomTypeId,
          rooms.map((x) => MapEntry(x.id, x.name)),
          (v) => setState(() => _roomTypeId = v),
        ),
        _dropdown(
          'Meal plan',
          _mealPlanId,
          meals.map((x) => MapEntry(x.id, x.name)),
          (v) => setState(() => _mealPlanId = v),
        ),
        _field(_rate, 'Rate', keyboardType: TextInputType.number),
        _field(_notes, 'Notes', lines: 2),
      ],
      onSubmit: () {
        if (_hotelId == null ||
            _roomTypeId == null ||
            _mealPlanId == null ||
            _number.text.trim().isEmpty) {
          return;
        }
        Navigator.of(context).pop(
          HotelContractModel(
            id: widget.item?.id ?? '',
            contractNumber: _number.text.trim(),
            hotelId: _hotelId!,
            hotelName: '',
            agentId: _agentId,
            agentName: null,
            startDate: _start,
            endDate: _end,
            currency: _currency.text.trim().isEmpty
                ? 'SAR'
                : _currency.text.trim(),
            notes: _notes.text.trim(),
            isActive: widget.item?.isActive ?? true,
            rates: [
              HotelContractRateModel(
                id: widget.item?.rates.firstOrNull?.id ?? '',
                roomTypeId: _roomTypeId!,
                roomTypeName: '',
                mealPlanId: _mealPlanId!,
                mealPlanName: '',
                rate: double.tryParse(_rate.text.trim()) ?? 0,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AllotmentDialog extends ConsumerStatefulWidget {
  const _AllotmentDialog({
    this.item,
    required this.overAllotment,
    required this.agentAllotment,
  });

  final HotelAllotmentModel? item;
  final bool overAllotment;
  final bool agentAllotment;

  @override
  ConsumerState<_AllotmentDialog> createState() => _AllotmentDialogState();
}

class _AllotmentDialogState extends ConsumerState<_AllotmentDialog> {
  late final _rooms = TextEditingController(
    text: (widget.item?.rooms ?? 1).toString(),
  );
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(days: 30));
  String? _contractId;
  String? _hotelId;
  String? _agentId;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item != null) {
      _start = item.startDate;
      _end = item.endDate;
      _contractId = item.contractId;
      _hotelId = item.hotelId;
      _agentId = item.agentId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final contracts =
        ref.watch(hotelContractsProvider).value ?? const <HotelContractModel>[];
    final hotels =
        ref.watch(hotelPropertiesProvider).value ??
        const <HotelPropertyModel>[];
    final agents =
        ref.watch(hotelAgentsProvider).value ?? const <HotelAgentModel>[];
    _contractId ??= contracts.firstOrNull?.id;
    _hotelId ??= contracts.firstOrNull?.hotelId ?? hotels.firstOrNull?.id;
    _agentId ??= contracts.firstOrNull?.agentId;

    return _DialogShell(
      title: widget.overAllotment ? 'Over Allotment' : 'Allotment',
      children: [
        _dropdown(
          'Contract',
          _contractId,
          contracts.map((x) => MapEntry(x.id, x.contractNumber)),
          (v) {
            final contract = contracts.where((x) => x.id == v).firstOrNull;
            setState(() {
              _contractId = v;
              _hotelId = contract?.hotelId ?? _hotelId;
              _agentId = contract?.agentId ?? _agentId;
            });
          },
        ),
        _dropdown(
          'Hotel',
          _hotelId,
          hotels.map((x) => MapEntry(x.id, x.name)),
          (v) => setState(() => _hotelId = v),
        ),
        _dropdown(
          'Agent',
          _agentId,
          agents.map((x) => MapEntry(x.id, x.name)),
          (v) => setState(() => _agentId = v),
          allowEmpty: true,
        ),
        _dateRow(context, 'Start', _start, (v) => setState(() => _start = v)),
        _dateRow(context, 'End', _end, (v) => setState(() => _end = v)),
        _field(_rooms, 'Rooms', keyboardType: TextInputType.number),
      ],
      onSubmit: () {
        if (_contractId == null || _hotelId == null) return;
        Navigator.of(context).pop(
          HotelAllotmentModel(
            id: widget.item?.id ?? '',
            contractId: _contractId!,
            contractNumber: '',
            hotelId: _hotelId!,
            hotelName: '',
            agentId: _agentId,
            agentName: null,
            startDate: _start,
            endDate: _end,
            rooms: int.tryParse(_rooms.text.trim()) ?? 1,
            allotmentType: widget.agentAllotment ? 'agent' : 'hotel',
            isOverAllotment: widget.overAllotment,
            isActive: widget.item?.isActive ?? true,
          ),
        );
      },
    );
  }
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
        width: 480,
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

Widget _dropdown(
  String label,
  String? value,
  Iterable<MapEntry<String, String>> entries,
  ValueChanged<String?> onChanged, {
  bool allowEmpty = false,
}) {
  final items = entries.toList();
  final safeValue = items.any((item) => item.key == value) ? value : null;
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      initialValue: safeValue,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        if (allowEmpty)
          const DropdownMenuItem<String>(value: null, child: Text('None')),
        ...items.map(
          (item) => DropdownMenuItem(value: item.key, child: Text(item.value)),
        ),
      ],
      onChanged: onChanged,
    ),
  );
}

Widget _dateRow(
  BuildContext context,
  String label,
  DateTime value,
  ValueChanged<DateTime> onChanged,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2040),
          initialDate: value,
        );
        if (picked != null) onChanged(picked);
      },
      icon: const Icon(Icons.calendar_today_outlined),
      label: Text('$label: ${_fmt(value)}'),
    ),
  );
}

String _fmt(DateTime value) => value.toIso8601String().substring(0, 10);
