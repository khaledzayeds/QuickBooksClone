// item_unit_selector.dart
// item_unit_selector.dart

import 'package:flutter/material.dart';

class ItemUnitSelector extends StatefulWidget {
  const ItemUnitSelector({
    super.key,
    this.initialValue,
    this.onChanged,
  });

  final String?                initialValue;
  final ValueChanged<String?>? onChanged;

  @override
  State<ItemUnitSelector> createState() => _ItemUnitSelectorState();
}

class _ItemUnitSelectorState extends State<ItemUnitSelector> {
  static const _presets = [
    'قطعة',
    'كيلوجرام',
    'جرام',
    'لتر',
    'مللي لتر',
    'متر',
    'سنتيمتر',
    'علبة',
    'كرتون',
    'دستة',
    'زوج',
  ];

  final _customCtrl = TextEditingController();
  String? _selected;
  bool    _showCustom = false;

  @override
  void initState() {
    super.initState();
    final v = widget.initialValue;
    if (v == null || v.isEmpty) {
      _selected = null;
    } else if (_presets.contains(v)) {
      _selected = v;
    } else {
      // قيمة مخصصة من الـ API
      _selected   = '__custom__';
      _showCustom = true;
      _customCtrl.text = v;
    }
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Label ─────────────────────────────────
        Text(
          'وحدة القياس',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.7),
              ),
        ),
        const SizedBox(height: 6),

        // ── Preset Chips ──────────────────────────
        Wrap(
          spacing:    8,
          runSpacing: 8,
          children: [
            // فارغ
            _UnitChip(
              label:    'بدون',
              selected: _selected == null && !_showCustom,
              onTap: () {
                setState(() {
                  _selected   = null;
                  _showCustom = false;
                });
                widget.onChanged?.call(null);
              },
            ),

            // Presets
            ..._presets.map((unit) => _UnitChip(
                  label:    unit,
                  selected: _selected == unit,
                  onTap: () {
                    setState(() {
                      _selected   = unit;
                      _showCustom = false;
                    });
                    widget.onChanged?.call(unit);
                  },
                )),

            // مخصص
            _UnitChip(
              label:    'أخرى...',
              selected: _selected == '__custom__',
              icon:     Icons.edit_outlined,
              onTap: () {
                setState(() {
                  _selected   = '__custom__';
                  _showCustom = true;
                });
                if (_customCtrl.text.isNotEmpty) {
                  widget.onChanged?.call(_customCtrl.text.trim());
                }
              },
            ),
          ],
        ),

        // ── Custom Input ──────────────────────────
        if (_showCustom) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _customCtrl,
            autofocus:  true,
            decoration: InputDecoration(
              hintText: 'اكتب وحدة القياس...',
              isDense:  true,
              suffixIcon: _customCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.check, size: 18),
                      onPressed: () {
                        final v = _customCtrl.text.trim();
                        if (v.isNotEmpty) widget.onChanged?.call(v);
                      },
                    )
                  : null,
            ),
            onChanged: (v) {
              setState(() {});
              if (v.trim().isNotEmpty) {
                widget.onChanged?.call(v.trim());
              }
            },
            onSubmitted: (v) {
              final trimmed = v.trim();
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

// ─── Chip Widget ──────────────────────────────────
class _UnitChip extends StatelessWidget {
  const _UnitChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String     label;
  final bool       selected;
  final VoidCallback onTap;
  final IconData?  icon;

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
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
            color: selected
                ? primary
                : theme.dividerColor,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size:  14,
                  color: selected ? primary : theme.hintColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color:      selected ? primary : theme.hintColor,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}