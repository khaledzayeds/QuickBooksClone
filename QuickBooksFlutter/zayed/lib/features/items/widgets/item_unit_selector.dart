import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class ItemUnitSelector extends StatefulWidget {
  const ItemUnitSelector({super.key, this.initialValue, this.onChanged});

  final String? initialValue;
  final ValueChanged<String?>? onChanged;

  @override
  State<ItemUnitSelector> createState() => _ItemUnitSelectorState();
}

class _ItemUnitSelectorState extends State<ItemUnitSelector> {
  static const _presets = [
    'pcs',
    'kg',
    'g',
    'l',
    'ml',
    'm',
    'cm',
    'box',
    'carton',
    'dozen',
    'pair',
  ];

  final _customCtrl = TextEditingController();
  String? _selected;
  bool _showCustom = false;

  @override
  void initState() {
    super.initState();
    final value = widget.initialValue;
    if (value == null || value.isEmpty) {
      _selected = null;
    } else if (_presets.contains(value)) {
      _selected = value;
    } else {
      _selected = '__custom__';
      _showCustom = true;
      _customCtrl.text = value;
    }
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = _UnitLabels.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.unit,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _UnitChip(
              label: labels.none,
              selected: _selected == null && !_showCustom,
              onTap: () {
                setState(() {
                  _selected = null;
                  _showCustom = false;
                });
                widget.onChanged?.call(null);
              },
            ),
            ..._presets.map(
              (unit) => _UnitChip(
                label: labels.unitLabel(unit),
                selected: _selected == unit,
                onTap: () {
                  setState(() {
                    _selected = unit;
                    _showCustom = false;
                  });
                  widget.onChanged?.call(unit);
                },
              ),
            ),
            _UnitChip(
              label: labels.other,
              selected: _selected == '__custom__',
              icon: Icons.edit_outlined,
              onTap: () {
                setState(() {
                  _selected = '__custom__';
                  _showCustom = true;
                });
                if (_customCtrl.text.isNotEmpty) {
                  widget.onChanged?.call(_customCtrl.text.trim());
                }
              },
            ),
          ],
        ),
        if (_showCustom) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _customCtrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: labels.customUnitHint,
              isDense: true,
              suffixIcon: _customCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.check, size: 18),
                      onPressed: () {
                        final value = _customCtrl.text.trim();
                        if (value.isNotEmpty) widget.onChanged?.call(value);
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() {});
              if (value.trim().isNotEmpty) {
                widget.onChanged?.call(value.trim());
              }
            },
            onSubmitted: (value) {
              final trimmed = value.trim();
              if (trimmed.isNotEmpty) {
                widget.onChanged?.call(trimmed);
              }
            },
          ),
        ],
      ],
    );
  }
}

class _UnitChip extends StatelessWidget {
  const _UnitChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: 0.12)
              : theme.colorScheme.surface,
          border: Border.all(
            color: selected ? primary : theme.dividerColor,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: selected ? primary : theme.hintColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: selected ? primary : theme.hintColor,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitLabels {
  const _UnitLabels(this.ar);

  final bool ar;

  static _UnitLabels of(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return _UnitLabels(locale == 'ar');
  }

  String get none => ar ? 'بدون' : 'None';
  String get other => ar ? 'أخرى...' : 'Other...';
  String get customUnitHint =>
      ar ? 'اكتب وحدة القياس...' : 'Type a unit of measure...';

  String unitLabel(String unit) {
    if (!ar) {
      return switch (unit) {
        'pcs' => 'Pieces',
        'kg' => 'Kilogram',
        'g' => 'Gram',
        'l' => 'Liter',
        'ml' => 'Milliliter',
        'm' => 'Meter',
        'cm' => 'Centimeter',
        'box' => 'Box',
        'carton' => 'Carton',
        'dozen' => 'Dozen',
        'pair' => 'Pair',
        _ => unit,
      };
    }
    return switch (unit) {
      'pcs' => 'قطعة',
      'kg' => 'كيلوجرام',
      'g' => 'جرام',
      'l' => 'لتر',
      'ml' => 'ملليلتر',
      'm' => 'متر',
      'cm' => 'سنتيمتر',
      'box' => 'علبة',
      'carton' => 'كرتونة',
      'dozen' => 'دستة',
      'pair' => 'زوج',
      _ => unit,
    };
  }
}
