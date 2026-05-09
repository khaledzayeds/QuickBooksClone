import 'package:flutter/material.dart';

class TablePlaygroundScreen extends StatelessWidget {
  const TablePlaygroundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Design Playground: Data Table'),
        backgroundColor: cs.surfaceContainerLowest,
        scrolledUnderElevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: cs.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header & Toolbar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text(
                      'Invoices',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 24),
                    SizedBox(
                      width: 250,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.filter_list, size: 18),
                      label: const Text('Filter'),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.file_download_outlined, size: 18),
                      label: const Text('Export'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Invoice'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Data Table
              Expanded(
                child: ListView(
                  children: [
                    DataTable(
                      headingRowColor: WidgetStatePropertyAll(cs.surfaceContainerHighest.withOpacity(0.5)),
                      dataRowMinHeight: 48,
                      dataRowMaxHeight: 48,
                      columns: const [
                        DataColumn(label: Text('DATE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(label: Text('NO.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(label: Text('CUSTOMER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(label: Text('AMOUNT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
                        DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(label: Text('ACTION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      ],
                      rows: [
                        _buildRow(context, '2026-05-01', 'INV-1001', 'Acme Corp', '1,250.00', 'Paid', Colors.green),
                        _buildRow(context, '2026-05-03', 'INV-1002', 'Global Tech', '4,500.00', 'Open', Colors.grey.shade600),
                        _buildRow(context, '2026-05-05', 'INV-1003', 'Stark Industries', '8,900.50', 'Overdue', Colors.red),
                        _buildRow(context, '2026-05-08', 'INV-1004', 'Wayne Enterprises', '3,200.00', 'Open', Colors.grey.shade600),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Pagination Footer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text('Rows per page: 10', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 24),
                    const Text('1-4 of 4', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 16),
                    IconButton(icon: const Icon(Icons.chevron_left), onPressed: null, splashRadius: 20),
                    IconButton(icon: const Icon(Icons.chevron_right), onPressed: null, splashRadius: 20),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, String date, String no, String customer, String amount, String status, Color statusColor) {
    return DataRow(
      cells: [
        DataCell(Text(date)),
        DataCell(Text(no, style: const TextStyle(fontWeight: FontWeight.w600))),
        DataCell(Text(customer)),
        DataCell(Text(amount, style: const TextStyle(fontWeight: FontWeight.w600))),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.5)),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        DataCell(
          TextButton(
            onPressed: () {},
            child: const Text('View'),
          ),
        ),
      ],
    );
  }
}
