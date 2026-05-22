class TemplateFieldInfo {
  const TemplateFieldInfo({
    required this.key,
    required this.label,
    required this.group,
    this.sampleValue = '',
  });

  final String key;
  final String label;
  final String group;
  final String sampleValue;
}

class TemplateFieldRegistry {
  static const fields = <TemplateFieldInfo>[
    TemplateFieldInfo(
      key: '{{Company.Name}}',
      label: 'Company Name',
      group: 'Company',
      sampleValue: 'Khaled Trading',
    ),
    TemplateFieldInfo(
      key: '{{Company.LegalName}}',
      label: 'Company Legal Name',
      group: 'Company',
      sampleValue: 'Khaled Trading LLC',
    ),
    TemplateFieldInfo(
      key: '{{Company.Address}}',
      label: 'Company Address',
      group: 'Company',
      sampleValue: 'Damietta, Egypt',
    ),
    TemplateFieldInfo(
      key: '{{Company.Phone}}',
      label: 'Company Phone',
      group: 'Company',
      sampleValue: '01010444103',
    ),
    TemplateFieldInfo(
      key: '{{Company.Email}}',
      label: 'Company Email',
      group: 'Company',
      sampleValue: 'sales@example.com',
    ),
    TemplateFieldInfo(
      key: '{{Company.Currency}}',
      label: 'Currency',
      group: 'Company',
      sampleValue: 'EGP',
    ),
    TemplateFieldInfo(
      key: '{{Customer.Name}}',
      label: 'Customer Name',
      group: 'Customer',
      sampleValue: 'Ahmed Mohamed',
    ),
    TemplateFieldInfo(
      key: '{{Customer.Phone}}',
      label: 'Customer Phone',
      group: 'Customer',
      sampleValue: '01000000000',
    ),
    TemplateFieldInfo(
      key: '{{Customer.Email}}',
      label: 'Customer Email',
      group: 'Customer',
      sampleValue: 'customer@example.com',
    ),
    TemplateFieldInfo(
      key: '{{Customer.Balance}}',
      label: 'Customer Balance',
      group: 'Customer',
      sampleValue: '0.00 EGP',
    ),
    TemplateFieldInfo(
      key: '{{Party.Label}}',
      label: 'Party Label',
      group: 'Party',
      sampleValue: 'Customer',
    ),
    TemplateFieldInfo(
      key: '{{Party.Type}}',
      label: 'Party Type',
      group: 'Party',
      sampleValue: 'Customer',
    ),
    TemplateFieldInfo(
      key: '{{Party.Name}}',
      label: 'Party Name',
      group: 'Party',
      sampleValue: 'Ahmed Mohamed',
    ),
    TemplateFieldInfo(
      key: '{{Invoice.Number}}',
      label: 'Invoice Number',
      group: 'Document',
      sampleValue: '1001-000003',
    ),
    TemplateFieldInfo(
      key: '{{Invoice.Date}}',
      label: 'Invoice Date',
      group: 'Document',
      sampleValue: '20/05/2026',
    ),
    TemplateFieldInfo(
      key: '{{Invoice.DueDate}}',
      label: 'Due Date',
      group: 'Document',
      sampleValue: '20/05/2026',
    ),
    TemplateFieldInfo(
      key: '{{Invoice.Status}}',
      label: 'Status',
      group: 'Document',
      sampleValue: 'Paid',
    ),
    TemplateFieldInfo(
      key: '{{Invoice.Subtotal}}',
      label: 'Subtotal',
      group: 'Totals',
      sampleValue: '50.00 EGP',
    ),
    TemplateFieldInfo(
      key: '{{Invoice.Discount}}',
      label: 'Discount',
      group: 'Totals',
      sampleValue: '0.00 EGP',
    ),
    TemplateFieldInfo(
      key: '{{Invoice.Tax}}',
      label: 'Tax',
      group: 'Totals',
      sampleValue: '0.00 EGP',
    ),
    TemplateFieldInfo(
      key: '{{Invoice.Total}}',
      label: 'Total',
      group: 'Totals',
      sampleValue: '50.00 EGP',
    ),
    TemplateFieldInfo(
      key: '{{Invoice.Paid}}',
      label: 'Paid',
      group: 'Totals',
      sampleValue: '50.00 EGP',
    ),
    TemplateFieldInfo(
      key: '{{Invoice.Balance}}',
      label: 'Balance Due',
      group: 'Totals',
      sampleValue: '0.00 EGP',
    ),
    TemplateFieldInfo(
      key: '{{Payment.Method}}',
      label: 'Payment Method',
      group: 'Payment',
      sampleValue: 'Cash',
    ),
    TemplateFieldInfo(
      key: '{{Payment.DepositAccount}}',
      label: 'Deposit Account',
      group: 'Payment',
      sampleValue: 'Cash on hand',
    ),
    TemplateFieldInfo(
      key: '{{Invoice.Terms}}',
      label: 'Terms',
      group: 'Document',
      sampleValue: 'Net 30',
    ),
    TemplateFieldInfo(
      key: '{{Invoice.Notes}}',
      label: 'Notes',
      group: 'Document',
      sampleValue: 'شكراً لتعاملكم معنا',
    ),
    TemplateFieldInfo(
      key: '{{Invoice.QrPayload}}',
      label: 'QR Payload',
      group: 'Document',
      sampleValue: 'Khaled Trading|1001-000003|50.00',
    ),
    TemplateFieldInfo(
      key: '{{Invoice.Lines}}',
      label: 'Invoice Lines',
      group: 'Table',
      sampleValue: 'Lines Table',
    ),
  ];

  static String previewValue(String? binding, {String fallback = ''}) {
    if (binding == null || binding.isEmpty) return fallback;
    for (final field in fields) {
      if (field.key == binding) return field.sampleValue;
    }
    return binding;
  }

  static String interpolatePreview(String source) {
    return source.replaceAllMapped(RegExp(r'\{\{([^}]+)\}\}'), (match) {
      final token = match.group(0) ?? '';
      return previewValue(token, fallback: token);
    });
  }
}
