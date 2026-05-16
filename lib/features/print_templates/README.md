# Print Template Designer MVP

Standalone Flutter module for designing print templates such as invoices, receipts, barcode labels, and statements.

This module is intentionally isolated and does not change existing app routing or backend behavior.

## Entry point

Use `PrintTemplateDesignerPage` from:

```dart
import 'features/print_templates/presentation/pages/print_template_designer_page.dart';
```

Then add it to your app router/menu when ready.

## Current MVP

- A4 invoice template rendered from JSON-like Dart models.
- Desktop-first designer layout: toolbox, canvas, properties panel.
- Supports text, field, rectangle, line, table, QR placeholder, barcode placeholder, and image placeholder.
- Element selection and basic property editing.

## Next steps

- Add drag/resize handles.
- Persist templates through ASP.NET API.
- Add PDF/print export.
- Add QR/barcode packages.
