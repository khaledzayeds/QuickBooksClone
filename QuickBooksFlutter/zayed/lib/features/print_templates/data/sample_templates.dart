import 'models/print_element_model.dart';
import 'models/print_page_model.dart';
import 'models/print_template_model.dart';

class SamplePrintTemplates {
  static List<PrintTemplateModel> defaults() => [
    // BEGIN: [USER_REQUEST_REVENUE_TEMPLATES_DESIGN]
    professionalThermalInvoice(),
    professionalA4Invoice(),
    // END: [USER_REQUEST_REVENUE_TEMPLATES_DESIGN]
    arabicThermalSalesReceipt(),
    arabicA4Invoice(),
    classicA4Invoice(),
  ];

  // BEGIN: [USER_REQUEST_REVENUE_TEMPLATES_DESIGN]
  /// Professional thermal invoice template - matches the reference receipt image.
  /// Page: 80mm wide. Margin: 3mm each side. Usable area: 74mm (x: 3 → 77).
  /// Layout: Logo left (18mm) | Header right (54mm): number, date, user, customer
  ///         Separator | Table 74mm wide | Separator | Totals | Payment | Footer
  static PrintTemplateModel professionalThermalInvoice() {
    return PrintTemplateModel(
      id: 'invoice_thermal_ar_professional',
      name: 'فاتورة حرارية احترافية - عربي',
      documentType: 'invoice',
      isDefault: true,
      pageSize: 'Receipt 80mm',
      page: PrintPageModel.receipt80mm(),
      elements: const [
        // ─── Logo: x=3, w=18 → ends at 21mm ───
        PrintElementModel(
          id: 'logo',
          type: 'image',
          x: 3,
          y: 3,
          width: 18,
          height: 15,
          value: 'LOGO',
          style: PrintElementStyleModel(fontSize: 8, align: 'center'),
        ),
        // ─── Header info: x=23, w=54 → ends at 77mm ✓ ───
        PrintElementModel(
          id: 'header_info',
          type: 'text',
          x: 23,
          y: 3,
          width: 54,
          height: 30,
          value:
              'رقم الفاتورة: {{Invoice.Number}}\n'
              'التاريخ: {{Invoice.Date}}\n'
              'المستخدم: {{User.Name}}\n'
              'العميل: {{Customer.Name}}',
          style: PrintElementStyleModel(
            fontSize: 7.5,
            bold: true,
            align: 'right',
          ),
        ),
        // ─── Separator: x=3, w=74 → ends at 77mm ✓ ───
        PrintElementModel(
          id: 'dash_top',
          type: 'line',
          x: 3,
          y: 35,
          width: 74,
          height: 1,
          style: PrintElementStyleModel(borderWidth: 0.5, borderColor: '#888888'),
        ),
        // ─── Items Table: x=3, w=74 → ends at 77mm ✓ ───
        // Column widths sum: 15+14+12+33 = 74mm ✓
        PrintElementModel(
          id: 'items_table',
          type: 'table',
          x: 3,
          y: 39,
          width: 74,
          height: 80,
          binding: '{{Invoice.Lines}}',
          columns: [
            PrintTableColumnModel(
              title: 'الإجمالي',
              field: 'lineTotal',
              width: 15,
            ),
            PrintTableColumnModel(
              title: 'السعر',
              field: 'unitPrice',
              width: 14,
            ),
            PrintTableColumnModel(
              title: 'الكمية',
              field: 'quantity',
              width: 12,
            ),
            PrintTableColumnModel(
              title: 'اسم الصنف',
              field: 'itemName',
              width: 33,
            ),
          ],
          style: PrintElementStyleModel(
            fontSize: 7.5,
            bold: false,
            borderWidth: 0.35,
            align: 'center',
          ),
        ),
        // ─── Separator: x=3, w=74 ✓ ───
        PrintElementModel(
          id: 'dash_mid',
          type: 'line',
          x: 3,
          y: 124,
          width: 74,
          height: 1,
          style: PrintElementStyleModel(borderWidth: 0.5, borderColor: '#888888'),
        ),
        // ─── Subtotal row ───
        PrintElementModel(
          id: 'subtotal_row',
          type: 'text',
          x: 3,
          y: 129,
          width: 74,
          height: 8,
          value: 'قيمة الفاتورة: {{Invoice.Subtotal}}',
          style: PrintElementStyleModel(
            fontSize: 8.5,
            bold: true,
            align: 'right',
          ),
        ),
        // ─── Grand Total label ───
        PrintElementModel(
          id: 'total_label',
          type: 'text',
          x: 3,
          y: 139,
          width: 74,
          height: 8,
          value: 'الإجمالي:',
          style: PrintElementStyleModel(
            fontSize: 9,
            bold: true,
            align: 'right',
          ),
        ),
        // ─── Grand Total value (large) ───
        PrintElementModel(
          id: 'grand_total',
          type: 'field',
          x: 3,
          y: 148,
          width: 74,
          height: 14,
          binding: '{{Invoice.Total}}',
          style: PrintElementStyleModel(
            fontSize: 16,
            bold: true,
            align: 'left',
          ),
        ),
        // ─── Separator ───
        PrintElementModel(
          id: 'dash_totals',
          type: 'line',
          x: 3,
          y: 164,
          width: 74,
          height: 1,
          style: PrintElementStyleModel(borderWidth: 0.5, borderColor: '#888888'),
        ),
        // ─── Payment Method ───
        PrintElementModel(
          id: 'payment_method',
          type: 'field',
          x: 3,
          y: 168,
          width: 74,
          height: 8,
          binding: '{{Payment.Method}}',
          style: PrintElementStyleModel(
            fontSize: 9,
            bold: true,
            align: 'right',
          ),
        ),
        // ─── Separator before footer ───
        PrintElementModel(
          id: 'dash_footer',
          type: 'line',
          x: 3,
          y: 178,
          width: 74,
          height: 1,
          style: PrintElementStyleModel(borderWidth: 0.5, borderColor: '#888888'),
        ),
        // ─── Footer phone + address ───
        PrintElementModel(
          id: 'footer_phone',
          type: 'field',
          x: 3,
          y: 182,
          width: 74,
          height: 7,
          binding: '{{Company.Phone}}',
          style: PrintElementStyleModel(fontSize: 8, align: 'center'),
        ),
        PrintElementModel(
          id: 'footer_address',
          type: 'field',
          x: 3,
          y: 190,
          width: 74,
          height: 7,
          binding: '{{Company.Address}}',
          style: PrintElementStyleModel(fontSize: 8, align: 'center'),
        ),
      ],
    );
  }


  /// Professional A4 invoice template with Arabic RTL layout:
  /// Logo + company name top-left | Invoice title + number top-right
  /// Customer block | Full items table | Totals box | QR code | Footer
  static PrintTemplateModel professionalA4Invoice() {
    return PrintTemplateModel(
      id: 'invoice_a4_ar_professional',
      name: 'فاتورة A4 احترافية - عربي',
      documentType: 'invoice',
      isDefault: true,
      pageSize: 'A4',
      page: PrintPageModel.a4Portrait(),
      elements: const [
        // ─── Logo (top-left) ───
        PrintElementModel(
          id: 'logo',
          type: 'image',
          x: 12,
          y: 10,
          width: 30,
          height: 24,
          value: 'LOGO',
          style: PrintElementStyleModel(fontSize: 9, align: 'center'),
        ),
        // ─── Company name (below logo) ───
        PrintElementModel(
          id: 'company_name',
          type: 'field',
          x: 12,
          y: 36,
          width: 90,
          height: 9,
          binding: '{{Company.Name}}',
          style: PrintElementStyleModel(fontSize: 16, bold: true),
        ),
        PrintElementModel(
          id: 'company_phone',
          type: 'field',
          x: 12,
          y: 47,
          width: 90,
          height: 7,
          binding: '{{Company.Phone}}',
          style: PrintElementStyleModel(fontSize: 8.5),
        ),
        PrintElementModel(
          id: 'company_address',
          type: 'field',
          x: 12,
          y: 55,
          width: 90,
          height: 7,
          binding: '{{Company.Address}}',
          style: PrintElementStyleModel(fontSize: 8.5),
        ),
        // ─── Invoice title (top-right) ───
        PrintElementModel(
          id: 'invoice_title',
          type: 'text',
          x: 140,
          y: 10,
          width: 58,
          height: 14,
          value: 'فاتورة بيع',
          style: PrintElementStyleModel(
            fontSize: 22,
            bold: true,
            align: 'right',
          ),
        ),
        PrintElementModel(
          id: 'invoice_number',
          type: 'field',
          x: 140,
          y: 26,
          width: 58,
          height: 8,
          binding: '{{Invoice.Number}}',
          style: PrintElementStyleModel(
            fontSize: 10,
            bold: true,
            align: 'right',
            color: '#374151',
          ),
        ),
        PrintElementModel(
          id: 'invoice_date',
          type: 'field',
          x: 140,
          y: 36,
          width: 58,
          height: 7,
          binding: '{{Invoice.Date}}',
          style: PrintElementStyleModel(fontSize: 9, align: 'right'),
        ),
        PrintElementModel(
          id: 'invoice_due_date',
          type: 'field',
          x: 140,
          y: 44,
          width: 58,
          height: 7,
          binding: '{{Invoice.DueDate}}',
          style: PrintElementStyleModel(fontSize: 9, align: 'right', color: '#DC2626'),
        ),
        // ─── Divider ───
        PrintElementModel(
          id: 'header_line',
          type: 'line',
          x: 10,
          y: 68,
          width: 190,
          height: 1,
          style: PrintElementStyleModel(borderWidth: 0.5),
        ),
        // ─── Customer block ───
        PrintElementModel(
          id: 'customer_label',
          type: 'text',
          x: 12,
          y: 73,
          width: 40,
          height: 7,
          value: 'العميل:',
          style: PrintElementStyleModel(fontSize: 9, bold: true, color: '#6B7280'),
        ),
        PrintElementModel(
          id: 'customer_name',
          type: 'field',
          x: 12,
          y: 81,
          width: 90,
          height: 9,
          binding: '{{Customer.Name}}',
          style: PrintElementStyleModel(fontSize: 13, bold: true),
        ),
        PrintElementModel(
          id: 'customer_phone',
          type: 'field',
          x: 12,
          y: 91,
          width: 90,
          height: 7,
          binding: '{{Customer.Phone}}',
          style: PrintElementStyleModel(fontSize: 8.5, color: '#4B5563'),
        ),
        // ─── Status badge ───
        PrintElementModel(
          id: 'invoice_status',
          type: 'field',
          x: 148,
          y: 55,
          width: 50,
          height: 8,
          binding: '{{Invoice.Status}}',
          style: PrintElementStyleModel(
            fontSize: 9,
            bold: true,
            align: 'right',
            color: '#059669',
          ),
        ),
        // ─── Items Table ───
        PrintElementModel(
          id: 'items_table',
          type: 'table',
          x: 10,
          y: 105,
          width: 190,
          height: 130,
          binding: '{{Invoice.Lines}}',
          columns: [
            PrintTableColumnModel(title: 'اسم الصنف', field: 'itemName', width: 80),
            PrintTableColumnModel(title: 'الكمية', field: 'quantity', width: 25),
            PrintTableColumnModel(title: 'السعر', field: 'unitPrice', width: 40),
            PrintTableColumnModel(title: 'الإجمالي', field: 'lineTotal', width: 45),
          ],
          style: PrintElementStyleModel(
            fontSize: 9,
            borderWidth: 0.35,
            align: 'right',
          ),
        ),
        // ─── Totals box ───
        PrintElementModel(
          id: 'totals_box',
          type: 'rectangle',
          x: 128,
          y: 238,
          width: 72,
          height: 46,
          style: PrintElementStyleModel(
            borderWidth: 0.5,
            backgroundColor: '#F9FAFB',
          ),
        ),
        PrintElementModel(
          id: 'subtotal_label',
          type: 'text',
          x: 130,
          y: 241,
          width: 68,
          height: 7,
          value: 'قيمة الفاتورة:',
          style: PrintElementStyleModel(fontSize: 8.5, align: 'right', color: '#6B7280'),
        ),
        PrintElementModel(
          id: 'subtotal_value',
          type: 'field',
          x: 130,
          y: 249,
          width: 68,
          height: 7,
          binding: '{{Invoice.Subtotal}}',
          style: PrintElementStyleModel(fontSize: 9, bold: true, align: 'right'),
        ),
        PrintElementModel(
          id: 'tax_label',
          type: 'text',
          x: 130,
          y: 257,
          width: 68,
          height: 7,
          value: 'الضريبة:',
          style: PrintElementStyleModel(fontSize: 8.5, align: 'right', color: '#6B7280'),
        ),
        PrintElementModel(
          id: 'tax_value',
          type: 'field',
          x: 130,
          y: 265,
          width: 68,
          height: 7,
          binding: '{{Invoice.Tax}}',
          style: PrintElementStyleModel(fontSize: 9, bold: true, align: 'right'),
        ),
        PrintElementModel(
          id: 'total_label',
          type: 'text',
          x: 130,
          y: 273,
          width: 68,
          height: 7,
          value: 'الإجمالي:',
          style: PrintElementStyleModel(fontSize: 10, bold: true, align: 'right'),
        ),
        PrintElementModel(
          id: 'grand_total',
          type: 'field',
          x: 130,
          y: 281,
          width: 68,
          height: 10,
          binding: '{{Invoice.Total}}',
          style: PrintElementStyleModel(
            fontSize: 14,
            bold: true,
            align: 'right',
            color: '#1D4ED8',
          ),
        ),
        // ─── Notes ───
        PrintElementModel(
          id: 'notes',
          type: 'field',
          x: 10,
          y: 240,
          width: 108,
          height: 30,
          binding: '{{Invoice.Notes}}',
          style: PrintElementStyleModel(fontSize: 8.5, color: '#6B7280'),
        ),
        // ─── QR Code ───
        PrintElementModel(
          id: 'qr_code',
          type: 'qr',
          x: 10,
          y: 272,
          width: 22,
          height: 22,
          value: '{{Invoice.QrPayload}}',
        ),
        // ─── Bottom line + Footer ───
        PrintElementModel(
          id: 'footer_line',
          type: 'line',
          x: 10,
          y: 296,
          width: 190,
          height: 1,
          style: PrintElementStyleModel(borderWidth: 0.4),
        ),
      ],
    );
  }
  // END: [USER_REQUEST_REVENUE_TEMPLATES_DESIGN]

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

  // BEGIN: [USER_REQUEST_REVENUE_TEMPLATES_DESIGN]
  static PrintTemplateModel fallbackFor(String documentType, String pageKind) {
    final source = pageKind.toLowerCase() == 'a4'
        ? arabicA4Invoice()
        : arabicThermalSalesReceipt();

    final adjustedElements = source.elements.map((e) {
      var val = e.value;
      var bind = e.binding;

      if (e.id == 'invoice_title' || e.id == 'receipt_title') {
        val = source.name.contains('عربية') || source.name.contains('عربي')
            ? _arabicDocumentLabel(documentType)
            : _englishDocumentLabel(documentType);
      }

      if (e.id == 'meta' && val.isNotEmpty) {
        val = val
            .replaceAll('رقم الفاتورة', 'رقم ${_arabicDocumentLabel(documentType)}')
            .replaceAll('Invoice Number', '${_englishDocumentLabel(documentType)} Number');
      }

      final prefix = _bindingPrefixFor(documentType);
      if (bind != null && bind.contains('Invoice.')) {
        bind = bind.replaceAll('Invoice.', '$prefix.');
      } else if (bind != null && bind.contains('SalesReceipt.')) {
        bind = bind.replaceAll('SalesReceipt.', '$prefix.');
      }
      if (val.contains('{{Invoice.')) {
        val = val.replaceAll('{{Invoice.', '{{$prefix.');
      } else if (val.contains('{{SalesReceipt.')) {
        val = val.replaceAll('{{SalesReceipt.', '{{$prefix.');
      }

      return e.copyWith(value: val, binding: bind);
    }).toList();

    return source.copyWith(
      id: '${documentType}_${pageKind}_default',
      documentType: documentType,
      name: '${_documentLabel(documentType)} - ${source.pageSize} الافتراضي',
      backendId: '',
      isDefault: true,
      elements: adjustedElements,
    );
  }

  static String _arabicDocumentLabel(String documentType) {
    switch (documentType) {
      case 'invoice':
        return 'فاتورة بيع';
      case 'sales-receipt':
        return 'إيصال بيع';
      case 'estimate':
        return 'عرض سعر';
      case 'sales-return':
        return 'مرتجع مبيعات';
      case 'purchase-order':
        return 'أمر شراء';
      case 'receive-inventory':
        return 'إذن استلام مخزني';
      case 'inventory-adjustment':
        return 'تسوية مخزنية';
      default:
        return 'مستند';
    }
  }

  static String _englishDocumentLabel(String documentType) {
    switch (documentType) {
      case 'invoice':
        return 'INVOICE';
      case 'sales-receipt':
        return 'RECEIPT';
      case 'estimate':
        return 'ESTIMATE';
      case 'sales-return':
        return 'SALES RETURN';
      case 'purchase-order':
        return 'PURCHASE ORDER';
      case 'receive-inventory':
        return 'RECEIVE INVENTORY';
      case 'inventory-adjustment':
        return 'INVENTORY ADJUSTMENT';
      default:
        return 'DOCUMENT';
    }
  }

  static String _bindingPrefixFor(String documentType) {
    switch (documentType) {
      case 'invoice':
        return 'Invoice';
      case 'sales-receipt':
        return 'SalesReceipt';
      case 'estimate':
        return 'Estimate';
      case 'sales-return':
        return 'SalesReturn';
      case 'purchase-order':
        return 'PurchaseOrder';
      case 'receive-inventory':
        return 'ReceiveInventory';
      case 'inventory-adjustment':
        return 'InventoryAdjustment';
      default:
        return 'Document';
    }
  }

  static String _documentLabel(String documentType) {
    return documentType
        .split('-')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
  // END: [USER_REQUEST_REVENUE_TEMPLATES_DESIGN]
}
