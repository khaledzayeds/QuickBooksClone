class TemplateFieldInfo {
  const TemplateFieldInfo({required this.key, required this.label, required this.group, this.sampleValue = ''});

  final String key;
  final String label;
  final String group;
  final String sampleValue;
}

class TemplateFieldRegistry {
  static const fields = <TemplateFieldInfo>[
    TemplateFieldInfo(key: '{{Company.Name}}', label: 'Company Name', group: 'Company', sampleValue: 'Khaled Trading'),
    TemplateFieldInfo(key: '{{Company.Address}}', label: 'Company Address', group: 'Company', sampleValue: 'Damietta, Egypt'),
    TemplateFieldInfo(key: '{{Company.Phone}}', label: 'Company Phone', group: 'Company', sampleValue: '01010444103'),
    TemplateFieldInfo(key: '{{Customer.Name}}', label: 'Customer Name', group: 'Customer', sampleValue: 'Ahmed Mohamed'),
    TemplateFieldInfo(key: '{{Customer.Phone}}', label: 'Customer Phone', group: 'Customer', sampleValue: '01000000000'),
    TemplateFieldInfo(key: '{{Invoice.Number}}', label: 'Invoice Number', group: 'Invoice', sampleValue: 'INV-1001'),
    TemplateFieldInfo(key: '{{Invoice.Date}}', label: 'Invoice Date', group: 'Invoice', sampleValue: '2026-05-16'),
    TemplateFieldInfo(key: '{{Invoice.Subtotal}}', label: 'Subtotal', group: 'Invoice', sampleValue: '1,250.00'),
    TemplateFieldInfo(key: '{{Invoice.Total}}', label: 'Total', group: 'Invoice', sampleValue: '1,375.00'),
    TemplateFieldInfo(key: '{{Invoice.QrPayload}}', label: 'QR Payload', group: 'Invoice', sampleValue: 'INV-1001|1375.00'),
    TemplateFieldInfo(key: '{{Invoice.Lines}}', label: 'Invoice Lines', group: 'Table', sampleValue: 'Lines Table'),
  ];

  static String previewValue(String? binding, {String fallback = ''}) {
    if (binding == null || binding.isEmpty) return fallback;
    for (final field in fields) {
      if (field.key == binding) return field.sampleValue;
    }
    return binding;
  }
}
