import 'package:excel/excel.dart';

const itemImportHeaders = [
  'Name',
  'Type',
  'Barcode',
  'Unit',
  'Sales Price',
  'Purchase Cost',
  'Qty on Hand',
  'Part No. (optional)',
  'Income Account',
  'Inventory Asset Account',
  'COGS Account',
  'Expense Account',
  'Active',
];

const itemAllowedTypes = [
  'Inventory Part',
  'Non-inventory Part',
  'Service',
  'Inventory Assembly',
  'Fixed Asset',
  'Other Charge',
  'Subtotal',
  'Group',
  'Discount',
  'Payment',
  'Bundle',
];

List<int> buildItemImportTemplateBytes() {
  final excel = Excel.createExcel();
  final items = excel['Items'];
  final instructions = excel['Instructions'];
  final allowedValues = excel['Allowed Values'];
  excel.delete('Sheet1');

  _writeHeader(items, itemImportHeaders, '#1F7A1F');
  _writeRows(items, [
    [
      'Thermal Printer',
      'Inventory Part',
      '6221000000001',
      'pcs',
      '1500.00',
      '1200.00',
      '5',
      'INV-001',
      'Sales Income',
      'Inventory Asset',
      'Cost of Goods Sold',
      '',
      'Yes',
    ],
    [
      'Maintenance Service',
      'Service',
      '',
      'hr',
      '250.00',
      '0.00',
      '0',
      'SRV-001',
      'Service Income',
      '',
      '',
      'Service Expense',
      'Yes',
    ],
    [
      'Office Supplies',
      'Non-inventory Part',
      '',
      'pcs',
      '50.00',
      '35.00',
      '0',
      'SUP-001',
      'Sales Income',
      '',
      '',
      'Office Supplies Expense',
      'Yes',
    ],
  ]);
  _setWidths(items, [24, 22, 20, 12, 16, 16, 14, 20, 24, 24, 24, 24, 12]);

  _writeHeader(instructions, ['Field', 'Required', 'Notes'], '#1565C0');
  _writeRows(instructions, [
    ['Name', 'Yes', 'Unique item name shown in invoices and purchases.'],
    [
      'Type',
      'Recommended',
      'Use one of the values in the Allowed Values sheet. Blank defaults to Inventory Part.',
    ],
    ['Barcode', 'No', 'Leave blank if the item does not use barcodes.'],
    ['Unit', 'No', 'Examples: pcs, kg, box, hr.'],
    ['Sales Price', 'No', 'Numbers only. Use dot for decimals.'],
    ['Purchase Cost', 'No', 'Numbers only. Use dot for decimals.'],
    ['Qty on Hand', 'No', 'Opening quantity for inventory items.'],
    [
      'Part No. (optional)',
      'No',
      'SKU, manufacturer part number, or internal code.',
    ],
    ['Accounts', 'No', 'Use account names exactly as configured when needed.'],
    ['Active', 'No', 'Yes or No. Blank means Yes.'],
  ]);
  _setWidths(instructions, [24, 16, 80]);

  _writeHeader(allowedValues, ['Type', 'Unit examples', 'Active'], '#6A4FB3');
  for (var i = 0; i < itemAllowedTypes.length; i++) {
    _writeRow(allowedValues, i + 1, [
      itemAllowedTypes[i],
      i == 0
          ? 'pcs, box, kg, liter'
          : i == 2
          ? 'hr, visit, day'
          : '',
      i < 2 ? 'Yes, No' : '',
    ]);
  }
  _setWidths(allowedValues, [28, 30, 18]);

  final bytes = excel.encode();
  if (bytes == null) {
    throw StateError('Could not build item import template workbook.');
  }
  return bytes;
}

List<int> buildItemExportWorkbookBytes(List<Map<String, dynamic>> rows) {
  final excel = Excel.createExcel();
  final sheet = excel['Items'];
  excel.delete('Sheet1');

  _writeHeader(sheet, itemImportHeaders, '#1565C0');
  for (var r = 0; r < rows.length; r++) {
    final row = rows[r];
    _writeRow(sheet, r + 1, [
      row['name']?.toString() ?? '',
      _itemTypeLabel(row['itemType']),
      row['barcode']?.toString() ?? '',
      row['unit']?.toString() ?? '',
      row['salesPrice']?.toString() ?? '0',
      row['purchasePrice']?.toString() ?? '0',
      row['quantityOnHand']?.toString() ?? '0',
      row['sku']?.toString() ?? '',
      row['incomeAccountName']?.toString() ?? '',
      row['inventoryAssetAccountName']?.toString() ?? '',
      row['cogsAccountName']?.toString() ?? '',
      row['expenseAccountName']?.toString() ?? '',
      row['isActive'] == true ? 'Yes' : 'No',
    ]);
  }
  _setWidths(sheet, [24, 22, 20, 12, 16, 16, 14, 20, 24, 24, 24, 24, 12]);

  final bytes = excel.encode();
  if (bytes == null) {
    throw StateError('Could not build item export workbook.');
  }
  return bytes;
}

void _writeHeader(Sheet sheet, List<String> headers, String colorHex) {
  for (var i = 0; i < headers.length; i++) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
    );
    cell.value = TextCellValue(headers[i]);
    cell.cellStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString(colorHex),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );
  }
}

void _writeRows(Sheet sheet, List<List<String>> rows) {
  for (var i = 0; i < rows.length; i++) {
    _writeRow(sheet, i + 1, rows[i]);
  }
}

void _writeRow(Sheet sheet, int rowIndex, List<String> values) {
  for (var i = 0; i < values.length; i++) {
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex))
        .value = TextCellValue(
      values[i],
    );
  }
}

void _setWidths(Sheet sheet, List<double> widths) {
  for (var i = 0; i < widths.length; i++) {
    sheet.setColumnWidth(i, widths[i]);
  }
}

String _itemTypeLabel(dynamic raw) {
  final value = int.tryParse(raw?.toString() ?? '') ?? 1;
  return switch (value) {
    1 => 'Inventory Part',
    2 => 'Non-inventory Part',
    3 => 'Service',
    4 => 'Bundle',
    5 => 'Inventory Assembly',
    6 => 'Fixed Asset',
    7 => 'Other Charge',
    8 => 'Subtotal',
    9 => 'Group',
    10 => 'Discount',
    11 => 'Payment',
    _ => raw?.toString() ?? 'Inventory Part',
  };
}
