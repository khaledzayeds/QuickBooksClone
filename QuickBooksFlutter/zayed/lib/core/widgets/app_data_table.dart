// app_data_table.dart

import 'package:flutter/material.dart';

class AppDataTable<T> extends StatelessWidget {
  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.rowBuilder,
    this.onRowTap,
    this.emptyMessage = 'لا توجد بيانات',
  });

  final List<String> columns;
  final List<T> rows;
  final List<DataCell> Function(T item) rowBuilder;
  final void Function(T item)? onRowTap;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            emptyMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
        dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.hovered)) {
            return theme.colorScheme.primary.withValues(alpha: 0.04);
          }
          return theme.colorScheme.surface;
        }),
        dividerThickness: 1,
        showBottomBorder: true,
        border: TableBorder(
          horizontalInside: BorderSide(color: theme.dividerColor, width: 1),
          bottom: BorderSide(color: theme.dividerColor, width: 1),
          top: BorderSide(color: theme.dividerColor, width: 1),
        ),
        columns: columns
            .map((c) => DataColumn(
                  label: Text(
                    c,
                    style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                  ),
                ))
            .toList(),
        rows: rows
            .map((item) => DataRow(
                  onSelectChanged:
                      onRowTap != null ? (_) => onRowTap!(item) : null,
                  cells: rowBuilder(item),
                ))
            .toList(),
      ),
    );
  }
}