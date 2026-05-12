import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

import '../../../features/items/data/models/item_model.dart';
import '../../../features/items/providers/items_provider.dart';
import 'qb_item_cell.dart';

class PlutoInvoiceGridDemo extends ConsumerStatefulWidget {
  const PlutoInvoiceGridDemo({super.key});

  @override
  ConsumerState<PlutoInvoiceGridDemo> createState() =>
      _PlutoInvoiceGridDemoState();
}

class _PlutoInvoiceGridDemoState extends ConsumerState<PlutoInvoiceGridDemo> {
  late final PlutoGridStateManager stateManager;

  // دالة لإضافة سطر جديد
  void _addNewRow() {
    final newId = (stateManager.rows.length + 1).toString();
    stateManager.appendRows([
      PlutoRow(
        cells: {
          'id': PlutoCell(value: newId),
          'item': PlutoCell(value: ''),
          'description': PlutoCell(value: ''),
          'qty': PlutoCell(value: 0),
          'rate': PlutoCell(value: 0.0),
          'amount': PlutoCell(value: 0.0),
        },
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // 1. إحضار الأصناف الحقيقية من الـ API (التي قمت أنت ببرمجتها مسبقاً)
    final itemsAsync = ref.watch(itemsProvider);
    final itemsList = itemsAsync.value ?? [];

    // تعريف الأعمدة
    final List<PlutoColumn> columns = [
      PlutoColumn(
        title: '#',
        field: 'id',
        type: PlutoColumnType.text(),
        width: 60,
        readOnly: true,
        enableRowChecked: true,
        enableColumnDrag: false,
        enableContextMenu: false,
        textAlign: PlutoColumnTextAlign.center,
        titleTextAlign: PlutoColumnTextAlign.center,
      ),
      PlutoColumn(
        title: 'PRODUCT/SERVICE',
        field: 'item',
        type:
            PlutoColumnType.text(), // نوعه text عادي لكننا سنضع فيه ويدجت البحث
        width: 250,
        // 2. هنا نقوم بدمج (QbItemCell) الخاص بك داخل الـ PlutoGrid
        renderer: (rendererContext) {
          return QbItemCell(
            initialValue: rendererContext.cell.value.toString(),
            items: itemsList,
            loadingItems: itemsAsync.isLoading,
            compact: false,
            rateForItem: (ItemModel item) => item.salesPrice,
            onPicked: (ItemModel item) {
              final sm = rendererContext.stateManager;
              final row = rendererContext.row;

              // تحديث الخلية باسم الصنف
              sm.changeCellValue(rendererContext.cell, item.name);
              // تحديث الوصف والسعر بناءً على الصنف المختار من الـ API
              sm.changeCellValue(row.cells['description']!, item.name);
              sm.changeCellValue(row.cells['rate']!, item.salesPrice);

              // إذا كانت الكمية صفر، نجعلها 1 افتراضياً
              if ((row.cells['qty']!.value as num) == 0) {
                sm.changeCellValue(row.cells['qty']!, 1);
              }

              // إضافة سطر جديد تلقائياً لو تم الاختيار في السطر الأخير
              if (rendererContext.rowIdx == sm.rows.length - 1) {
                _addNewRow();
              }
            },
          );
        },
      ),
      PlutoColumn(
        title: 'DESCRIPTION',
        field: 'description',
        type: PlutoColumnType.text(),
        width: 300,
      ),
      PlutoColumn(
        title: 'QTY',
        field: 'qty',
        type: PlutoColumnType.number(),
        width: 80,
        textAlign: PlutoColumnTextAlign.center,
        titleTextAlign: PlutoColumnTextAlign.center,
      ),
      PlutoColumn(
        title: 'RATE',
        field: 'rate',
        type: PlutoColumnType.currency(symbol: ''),
        width: 120,
        textAlign: PlutoColumnTextAlign.right,
        titleTextAlign: PlutoColumnTextAlign.right,
      ),
      PlutoColumn(
        title: 'AMOUNT',
        field: 'amount',
        type: PlutoColumnType.currency(symbol: ''),
        width: 120,
        readOnly: true, // الحقل للقراءة فقط لأنه يحسب تلقائياً
        textAlign: PlutoColumnTextAlign.right,
        titleTextAlign: PlutoColumnTextAlign.right,
      ),
    ];

    // نبدأ بسطر واحد فارغ دائماً
    final List<PlutoRow> rows = [
      PlutoRow(
        cells: {
          'id': PlutoCell(value: '1'),
          'item': PlutoCell(value: ''),
          'description': PlutoCell(value: ''),
          'qty': PlutoCell(value: 0),
          'rate': PlutoCell(value: 0.0),
          'amount': PlutoCell(value: 0.0),
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 350,
          decoration: BoxDecoration(
            border: Border.all(color: cs.outlineVariant),
            borderRadius: BorderRadius.circular(4),
          ),
          child: PlutoGrid(
            columns: columns,
            rows: rows,
            onLoaded: (PlutoGridOnLoadedEvent event) {
              stateManager = event.stateManager;
              stateManager.setShowColumnFilter(false);
            },
            onChanged: (PlutoGridOnChangedEvent event) {
              // حساب الـ Amount تلقائياً بمجرد تغيير الكمية أو السعر
              if (event.column.field == 'qty' || event.column.field == 'rate') {
                final qty = event.row.cells['qty']!.value ?? 0;
                final rate = event.row.cells['rate']!.value ?? 0;
                stateManager.changeCellValue(
                  event.row.cells['amount']!,
                  qty * rate,
                );
              }
            },
            configuration: PlutoGridConfiguration(
              style: PlutoGridStyleConfig(
                gridBorderColor: Colors.transparent,
                gridBackgroundColor: cs.surface,
                rowColor: cs.surface,
                evenRowColor: cs.surfaceContainerLowest,
                activatedColor: cs.primaryContainer.withValues(alpha: 0.2),
                cellColorInEditState: cs.surface,
                cellTextStyle: theme.textTheme.bodyMedium!,
                columnTextStyle: theme.textTheme.labelSmall!.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  color: cs.onSurfaceVariant,
                ),
                columnHeight: 40,
                rowHeight: 40,
                enableColumnBorderVertical: false,
                enableColumnBorderHorizontal: true,
                borderColor: cs.outlineVariant,
                iconColor: cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _addNewRow,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add lines'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
