import 'package:flutter/material.dart';

import 'invoice_form_page_shell.dart';

class InvoiceFormPage extends StatelessWidget {
  const InvoiceFormPage({super.key, this.id});

  final String? id;

  @override
  Widget build(BuildContext context) {
    return InvoiceFormPageShell(id: id);
  }
}
