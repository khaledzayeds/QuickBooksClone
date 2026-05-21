import 'models/print_element_model.dart';
import 'models/print_page_model.dart';
import 'models/print_template_model.dart';

class SamplePrintTemplates {
  static List<PrintTemplateModel> defaults() => [
    arabicThermalSalesReceipt(),
    arabicA4Invoice(),
    classicA4Invoice(),
  ];

  static PrintTemplateModel arabicThermalSalesReceipt() {
    return PrintTemplateModel(
      id: 'sales_receipt_thermal_ar_default',
      name: 'إيصال حراري عربي - الافتراضي',
      documentType: 'sales-receipt',
      isDefault: true,
      pageSize: 'Receipt 80mm',
      page: PrintPageModel.receipt80mm(),
      elements: const [
        PrintElementModel(
          id: 'logo',
          type: 'image',
          x: 29,
          y: 4,
          width: 22,
          height: 18,
          value: 'LOGO',
          style: PrintElementStyleModel(fontSize: 9, align: 'center'),
        ),
        PrintElementModel(
          id: 'company_name',
          type: 'field',
          x: 5,
          y: 24,
          width: 70,
          height: 9,
          binding: '{{Company.Name}}',
          style: PrintElementStyleModel(
            fontSize: 15,
            bold: true,
            align: 'center',
          ),
        ),
        PrintElementModel(
          id: 'invoice_title',
          type: 'text',
          x: 5,
          y: 36,
          width: 70,
          height: 8,
          value: 'فاتورة بيع',
          style: PrintElementStyleModel(
            fontSize: 12,
            bold: true,
            align: 'center',
          ),
        ),
        PrintElementModel(
          id: 'meta',
          type: 'text',
          x: 5,
          y: 48,
          width: 70,
          height: 20,
          value:
              'رقم الفاتورة: {{Invoice.Number}}\nالتاريخ: {{Invoice.Date}}\nالمستخدم: {{Customer.Name}}',
          style: PrintElementStyleModel(
            fontSize: 8,
            bold: true,
            align: 'right',
          ),
        ),
        PrintElementModel(
          id: 'dash_1',
          type: 'line',
          x: 5,
          y: 72,
          width: 70,
          height: 1,
        ),
        PrintElementModel(
          id: 'items_table',
          type: 'table',
          x: 3,
          y: 77,
          width: 74,
          height: 68,
          binding: '{{Invoice.Lines}}',
          columns: [
            PrintTableColumnModel(
              title: 'الإجمالي',
              field: 'lineTotal',
              width: 18,
            ),
            PrintTableColumnModel(
              title: 'السعر',
              field: 'unitPrice',
              width: 16,
            ),
            PrintTableColumnModel(
              title: 'الكمية',
              field: 'quantity',
              width: 14,
            ),
            PrintTableColumnModel(
              title: 'اسم الصنف',
              field: 'itemName',
              width: 32,
            ),
          ],
          style: PrintElementStyleModel(
            fontSize: 8.5,
            borderWidth: .45,
            align: 'right',
          ),
        ),
        PrintElementModel(
          id: 'dash_2',
          type: 'line',
          x: 5,
          y: 150,
          width: 70,
          height: 1,
        ),
        PrintElementModel(
          id: 'subtotal',
          type: 'field',
          x: 5,
          y: 156,
          width: 70,
          height: 8,
          binding: '{{Invoice.Subtotal}}',
          style: PrintElementStyleModel(
            fontSize: 10,
            bold: true,
            align: 'center',
          ),
        ),
        PrintElementModel(
          id: 'grand_total',
          type: 'field',
          x: 5,
          y: 166,
          width: 70,
          height: 13,
          binding: '{{Invoice.Total}}',
          style: PrintElementStyleModel(
            fontSize: 17,
            bold: true,
            align: 'center',
          ),
        ),
        PrintElementModel(
          id: 'footer',
          type: 'text',
          x: 5,
          y: 186,
          width: 70,
          height: 18,
          value: 'شكراً لتعاملكم معنا\nنتمنى لكم يوماً سعيداً',
          style: PrintElementStyleModel(
            fontSize: 9,
            bold: true,
            align: 'center',
          ),
        ),
      ],
    );
  }

  static PrintTemplateModel arabicA4Invoice() {
    return classicA4Invoice().copyWith(
      id: 'invoice_ar_a4_default',
      name: 'فاتورة A4 عربية - الافتراضي',
      isDefault: true,
      elements: [
        ...classicA4Invoice().elements.where((e) => e.id != 'invoice_title'),
        const PrintElementModel(
          id: 'invoice_title',
          type: 'text',
          x: 145,
          y: 12,
          width: 52,
          height: 12,
          value: 'فاتورة بيع',
          style: PrintElementStyleModel(
            fontSize: 20,
            bold: true,
            align: 'right',
          ),
        ),
      ],
    );
  }

  static PrintTemplateModel classicA4Invoice() {
    return PrintTemplateModel(
      id: 'invoice_classic_a4',
      name: 'Classic A4 Invoice',
      documentType: 'invoice',
      isDefault: true,
      pageSize: 'A4',
      page: PrintPageModel.a4Portrait(),
      elements: const [
        PrintElementModel(
          id: 'company_name',
          type: 'field',
          x: 12,
          y: 12,
          width: 92,
          height: 10,
          binding: '{{Company.Name}}',
          style: PrintElementStyleModel(fontSize: 18, bold: true),
        ),
        PrintElementModel(
          id: 'company_address',
          type: 'field',
          x: 12,
          y: 25,
          width: 100,
          height: 8,
          binding: '{{Company.Address}}',
          style: PrintElementStyleModel(fontSize: 9),
        ),
        PrintElementModel(
          id: 'invoice_title',
          type: 'text',
          x: 145,
          y: 12,
          width: 52,
          height: 12,
          value: 'INVOICE',
          style: PrintElementStyleModel(
            fontSize: 20,
            bold: true,
            align: 'right',
          ),
        ),
        PrintElementModel(
          id: 'invoice_number',
          type: 'field',
          x: 148,
          y: 28,
          width: 48,
          height: 8,
          binding: '{{Invoice.Number}}',
          style: PrintElementStyleModel(
            fontSize: 10,
            bold: true,
            align: 'right',
          ),
        ),
        PrintElementModel(
          id: 'customer_name',
          type: 'field',
          x: 12,
          y: 58,
          width: 88,
          height: 8,
          binding: '{{Customer.Name}}',
          style: PrintElementStyleModel(fontSize: 11, bold: true),
        ),
        PrintElementModel(
          id: 'items_table',
          type: 'table',
          x: 10,
          y: 78,
          width: 190,
          height: 126,
          binding: '{{Invoice.Lines}}',
          columns: [
            PrintTableColumnModel(title: 'Item', field: 'itemName', width: 78),
            PrintTableColumnModel(title: 'Qty', field: 'quantity', width: 22),
            PrintTableColumnModel(
              title: 'Price',
              field: 'unitPrice',
              width: 35,
            ),
            PrintTableColumnModel(
              title: 'Total',
              field: 'lineTotal',
              width: 35,
            ),
          ],
          style: PrintElementStyleModel(fontSize: 9, borderWidth: 0.4),
        ),
        PrintElementModel(
          id: 'grand_total_box',
          type: 'rectangle',
          x: 138,
          y: 230,
          width: 62,
          height: 18,
          style: PrintElementStyleModel(
            borderWidth: 0.6,
            backgroundColor: '#F3F4F6',
          ),
        ),
        PrintElementModel(
          id: 'grand_total',
          type: 'field',
          x: 145,
          y: 235,
          width: 50,
          height: 9,
          binding: '{{Invoice.Total}}',
          style: PrintElementStyleModel(
            fontSize: 13,
            bold: true,
            align: 'right',
          ),
        ),
        PrintElementModel(
          id: 'qr_code',
          type: 'qr',
          x: 12,
          y: 226,
          width: 28,
          height: 28,
          value: '{{Invoice.QrPayload}}',
        ),
        PrintElementModel(
          id: 'footer_note',
          type: 'text',
          x: 10,
          y: 275,
          width: 190,
          height: 8,
          value: 'Thank you for your business.',
          style: PrintElementStyleModel(fontSize: 9, align: 'center'),
        ),
      ],
    );
  }
}
