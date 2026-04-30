# LedgerFlow - Flutter Project Structure Generator
# Run from inside your Flutter project root (where pubspec.yaml is)

$base = "lib"

$files = @(
    # ── Root ──
    "main.dart",

    # ── App ──
    "app/app.dart",
    "app/router.dart",

    # ── Core / Constants ──
    "core/constants/app_constants.dart",
    "core/constants/api_enums.dart",

    # ── Core / API ──
    "core/api/api_client.dart",
    "core/api/api_result.dart",
    "core/api/api_interceptors.dart",

    # ── Core / Services ──
    "core/services/storage_service.dart",
    "core/services/connectivity_service.dart",

    # ── Core / Utils ──
    "core/utils/date_formatter.dart",
    "core/utils/error_handler.dart",
    "core/utils/validators.dart",

    # ── Core / Theme ──
    "core/theme/app_theme.dart",
    "core/theme/app_colors.dart",
    "core/theme/app_text_styles.dart",

    # ── Core / Widgets ──
    "core/widgets/responsive_scaffold.dart",
    "core/widgets/sidebar_menu.dart",
    "core/widgets/top_menu.dart",
    "core/widgets/app_button.dart",
    "core/widgets/app_text_field.dart",
    "core/widgets/app_data_table.dart",
    "core/widgets/loading_widget.dart",
    "core/widgets/empty_state_widget.dart",
    "core/widgets/confirm_dialog.dart",

    # ════════════════════════════════════════
    # SPRINT 1
    # ════════════════════════════════════════

    # ── Dashboard ──
    "features/dashboard/screens/dashboard_screen.dart",
    "features/dashboard/widgets/kpi_card.dart",
    "features/dashboard/widgets/recent_transactions_widget.dart",

    # ── Runtime ──
    "features/runtime/data/models/runtime_model.dart",
    "features/runtime/data/datasources/runtime_remote_datasource.dart",
    "features/runtime/data/repositories/runtime_repository.dart",
    "features/runtime/providers/runtime_provider.dart",

    # ════════════════════════════════════════
    # SPRINT 2
    # ════════════════════════════════════════

    # ── Accounts ──
    "features/accounts/data/models/account_model.dart",
    "features/accounts/data/datasources/accounts_remote_datasource.dart",
    "features/accounts/data/repositories/accounts_repository.dart",
    "features/accounts/providers/accounts_provider.dart",
    "features/accounts/screens/chart_of_accounts_screen.dart",
    "features/accounts/screens/account_form_screen.dart",
    "features/accounts/widgets/account_tree_widget.dart",
    "features/accounts/widgets/account_card.dart",

    # ── Customers ──
    "features/customers/data/models/customer_model.dart",
    "features/customers/data/datasources/customers_remote_datasource.dart",
    "features/customers/data/repositories/customers_repository.dart",
    "features/customers/providers/customers_provider.dart",
    "features/customers/screens/customer_list_screen.dart",
    "features/customers/screens/customer_form_screen.dart",
    "features/customers/screens/customer_details_screen.dart",
    "features/customers/widgets/customer_card.dart",
    "features/customers/widgets/customer_search_bar.dart",

    # ── Vendors ──
    "features/vendors/data/models/vendor_model.dart",
    "features/vendors/data/datasources/vendors_remote_datasource.dart",
    "features/vendors/data/repositories/vendors_repository.dart",
    "features/vendors/providers/vendors_provider.dart",
    "features/vendors/screens/vendor_list_screen.dart",
    "features/vendors/screens/vendor_form_screen.dart",
    "features/vendors/screens/vendor_details_screen.dart",
    "features/vendors/widgets/vendor_card.dart",
    "features/vendors/widgets/vendor_search_bar.dart",

    # ── Items ──
    "features/items/data/models/item_model.dart",
    "features/items/data/datasources/items_remote_datasource.dart",
    "features/items/data/repositories/items_repository.dart",
    "features/items/providers/items_provider.dart",
    "features/items/screens/item_list_screen.dart",
    "features/items/screens/item_form_screen.dart",
    "features/items/screens/item_details_screen.dart",
    "features/items/widgets/item_card.dart",
    "features/items/widgets/item_search_bar.dart",
    "features/items/widgets/item_unit_selector.dart",

    # ════════════════════════════════════════
    # SPRINT 3
    # ════════════════════════════════════════

    # ── Purchase Orders ──
    "features/purchase_orders/data/models/purchase_order_model.dart",
    "features/purchase_orders/data/datasources/purchase_orders_remote_datasource.dart",
    "features/purchase_orders/data/repositories/purchase_orders_repository.dart",
    "features/purchase_orders/providers/purchase_orders_provider.dart",
    "features/purchase_orders/screens/purchase_order_list_screen.dart",
    "features/purchase_orders/screens/purchase_order_form_screen.dart",
    "features/purchase_orders/screens/purchase_order_details_screen.dart",
    "features/purchase_orders/widgets/purchase_order_card.dart",
    "features/purchase_orders/widgets/purchase_order_line_widget.dart",

    # ── Receive Inventory ──
    "features/receive_inventory/data/models/receive_inventory_model.dart",
    "features/receive_inventory/data/datasources/receive_inventory_remote_datasource.dart",
    "features/receive_inventory/data/repositories/receive_inventory_repository.dart",
    "features/receive_inventory/providers/receive_inventory_provider.dart",
    "features/receive_inventory/screens/receive_inventory_list_screen.dart",
    "features/receive_inventory/screens/receive_inventory_form_screen.dart",
    "features/receive_inventory/screens/receive_inventory_details_screen.dart",
    "features/receive_inventory/widgets/receive_inventory_card.dart",
    "features/receive_inventory/widgets/receive_line_widget.dart",

    # ── Purchase Bills ──
    "features/purchase_bills/data/models/purchase_bill_model.dart",
    "features/purchase_bills/data/datasources/purchase_bills_remote_datasource.dart",
    "features/purchase_bills/data/repositories/purchase_bills_repository.dart",
    "features/purchase_bills/providers/purchase_bills_provider.dart",
    "features/purchase_bills/screens/purchase_bill_list_screen.dart",
    "features/purchase_bills/screens/purchase_bill_form_screen.dart",
    "features/purchase_bills/screens/purchase_bill_details_screen.dart",
    "features/purchase_bills/widgets/purchase_bill_card.dart",
    "features/purchase_bills/widgets/bill_line_widget.dart",

    # ── Purchase Returns ──
    "features/purchase_returns/data/models/purchase_return_model.dart",
    "features/purchase_returns/data/datasources/purchase_returns_remote_datasource.dart",
    "features/purchase_returns/data/repositories/purchase_returns_repository.dart",
    "features/purchase_returns/providers/purchase_returns_provider.dart",
    "features/purchase_returns/screens/purchase_return_list_screen.dart",
    "features/purchase_returns/screens/purchase_return_form_screen.dart",
    "features/purchase_returns/screens/purchase_return_details_screen.dart",
    "features/purchase_returns/widgets/purchase_return_card.dart",

    # ── Vendor Payments ──
    "features/vendor_payments/data/models/vendor_payment_model.dart",
    "features/vendor_payments/data/datasources/vendor_payments_remote_datasource.dart",
    "features/vendor_payments/data/repositories/vendor_payments_repository.dart",
    "features/vendor_payments/providers/vendor_payments_provider.dart",
    "features/vendor_payments/screens/vendor_payment_list_screen.dart",
    "features/vendor_payments/screens/vendor_payment_form_screen.dart",
    "features/vendor_payments/screens/vendor_payment_details_screen.dart",
    "features/vendor_payments/widgets/vendor_payment_card.dart",

    # ── Vendor Credits ──
    "features/vendor_credits/data/models/vendor_credit_model.dart",
    "features/vendor_credits/data/datasources/vendor_credits_remote_datasource.dart",
    "features/vendor_credits/data/repositories/vendor_credits_repository.dart",
    "features/vendor_credits/providers/vendor_credits_provider.dart",
    "features/vendor_credits/screens/vendor_credit_list_screen.dart",
    "features/vendor_credits/screens/vendor_credit_form_screen.dart",
    "features/vendor_credits/widgets/vendor_credit_card.dart",

    # ── Inventory Adjustments ──
    "features/inventory_adjustments/data/models/inventory_adjustment_model.dart",
    "features/inventory_adjustments/data/datasources/inventory_adjustments_remote_datasource.dart",
    "features/inventory_adjustments/data/repositories/inventory_adjustments_repository.dart",
    "features/inventory_adjustments/providers/inventory_adjustments_provider.dart",
    "features/inventory_adjustments/screens/inventory_adjustment_list_screen.dart",
    "features/inventory_adjustments/screens/inventory_adjustment_form_screen.dart",
    "features/inventory_adjustments/widgets/inventory_adjustment_card.dart",

    # ════════════════════════════════════════
    # SPRINT 4
    # ════════════════════════════════════════

    # ── Estimates ──
    "features/estimates/data/models/estimate_model.dart",
    "features/estimates/data/datasources/estimates_remote_datasource.dart",
    "features/estimates/data/repositories/estimates_repository.dart",
    "features/estimates/providers/estimates_provider.dart",
    "features/estimates/screens/estimate_list_screen.dart",
    "features/estimates/screens/estimate_form_screen.dart",
    "features/estimates/screens/estimate_details_screen.dart",
    "features/estimates/widgets/estimate_card.dart",
    "features/estimates/widgets/estimate_line_widget.dart",

    # ── Sales Orders ──
    "features/sales_orders/data/models/sales_order_model.dart",
    "features/sales_orders/data/datasources/sales_orders_remote_datasource.dart",
    "features/sales_orders/data/repositories/sales_orders_repository.dart",
    "features/sales_orders/providers/sales_orders_provider.dart",
    "features/sales_orders/screens/sales_order_list_screen.dart",
    "features/sales_orders/screens/sales_order_form_screen.dart",
    "features/sales_orders/screens/sales_order_details_screen.dart",
    "features/sales_orders/widgets/sales_order_card.dart",
    "features/sales_orders/widgets/sales_order_line_widget.dart",

    # ── Invoices ──
    "features/invoices/data/models/invoice_model.dart",
    "features/invoices/data/datasources/invoices_remote_datasource.dart",
    "features/invoices/data/repositories/invoices_repository.dart",
    "features/invoices/providers/invoices_provider.dart",
    "features/invoices/screens/invoice_list_screen.dart",
    "features/invoices/screens/invoice_form_screen.dart",
    "features/invoices/screens/invoice_details_screen.dart",
    "features/invoices/widgets/invoice_card.dart",
    "features/invoices/widgets/invoice_line_widget.dart",
    "features/invoices/widgets/invoice_summary_widget.dart",

    # ── Sales Receipts ──
    "features/sales_receipts/data/models/sales_receipt_model.dart",
    "features/sales_receipts/data/datasources/sales_receipts_remote_datasource.dart",
    "features/sales_receipts/data/repositories/sales_receipts_repository.dart",
    "features/sales_receipts/providers/sales_receipts_provider.dart",
    "features/sales_receipts/screens/sales_receipt_list_screen.dart",
    "features/sales_receipts/screens/sales_receipt_form_screen.dart",
    "features/sales_receipts/screens/sales_receipt_details_screen.dart",
    "features/sales_receipts/widgets/sales_receipt_card.dart",

    # ── Payments ──
    "features/payments/data/models/payment_model.dart",
    "features/payments/data/datasources/payments_remote_datasource.dart",
    "features/payments/data/repositories/payments_repository.dart",
    "features/payments/providers/payments_provider.dart",
    "features/payments/screens/payment_list_screen.dart",
    "features/payments/screens/payment_form_screen.dart",
    "features/payments/screens/payment_details_screen.dart",
    "features/payments/widgets/payment_card.dart",
    "features/payments/widgets/payment_method_selector.dart",

    # ── Sales Returns ──
    "features/sales_returns/data/models/sales_return_model.dart",
    "features/sales_returns/data/datasources/sales_returns_remote_datasource.dart",
    "features/sales_returns/data/repositories/sales_returns_repository.dart",
    "features/sales_returns/providers/sales_returns_provider.dart",
    "features/sales_returns/screens/sales_return_list_screen.dart",
    "features/sales_returns/screens/sales_return_form_screen.dart",
    "features/sales_returns/screens/sales_return_details_screen.dart",
    "features/sales_returns/widgets/sales_return_card.dart",

    # ── Customer Credits ──
    "features/customer_credits/data/models/customer_credit_model.dart",
    "features/customer_credits/data/datasources/customer_credits_remote_datasource.dart",
    "features/customer_credits/data/repositories/customer_credits_repository.dart",
    "features/customer_credits/providers/customer_credits_provider.dart",
    "features/customer_credits/screens/customer_credit_list_screen.dart",
    "features/customer_credits/screens/customer_credit_form_screen.dart",
    "features/customer_credits/widgets/customer_credit_card.dart",

    # ════════════════════════════════════════
    # SPRINT 5
    # ════════════════════════════════════════

    # ── Journal Entries ──
    "features/journal_entries/data/models/journal_entry_model.dart",
    "features/journal_entries/data/datasources/journal_entries_remote_datasource.dart",
    "features/journal_entries/data/repositories/journal_entries_repository.dart",
    "features/journal_entries/providers/journal_entries_provider.dart",
    "features/journal_entries/screens/journal_entry_list_screen.dart",
    "features/journal_entries/screens/journal_entry_form_screen.dart",
    "features/journal_entries/screens/journal_entry_details_screen.dart",
    "features/journal_entries/widgets/journal_entry_card.dart",
    "features/journal_entries/widgets/journal_entry_line_widget.dart",

    # ── Transactions ──
    "features/transactions/data/models/transaction_model.dart",
    "features/transactions/data/datasources/transactions_remote_datasource.dart",
    "features/transactions/data/repositories/transactions_repository.dart",
    "features/transactions/providers/transactions_provider.dart",
    "features/transactions/screens/transaction_list_screen.dart",
    "features/transactions/screens/transaction_details_screen.dart",
    "features/transactions/widgets/transaction_card.dart",
    "features/transactions/widgets/transaction_line_widget.dart",

    # ── Reports ──
    "features/reports/data/models/report_models.dart",
    "features/reports/data/datasources/reports_remote_datasource.dart",
    "features/reports/data/repositories/reports_repository.dart",
    "features/reports/providers/reports_provider.dart",
    "features/reports/screens/reports_screen.dart",
    "features/reports/screens/trial_balance_screen.dart",
    "features/reports/screens/profit_loss_screen.dart",
    "features/reports/screens/balance_sheet_screen.dart",
    "features/reports/screens/accounts_receivable_screen.dart",
    "features/reports/screens/accounts_payable_screen.dart",
    "features/reports/screens/inventory_report_screen.dart",
    "features/reports/screens/sales_report_screen.dart",
    "features/reports/screens/purchase_report_screen.dart",
    "features/reports/widgets/report_card.dart",
    "features/reports/widgets/report_filter_widget.dart",
    "features/reports/widgets/report_chart_widget.dart",

    # ── Sync ──
    "features/sync/data/models/sync_overview_model.dart",
    "features/sync/data/models/sync_document_model.dart",
    "features/sync/data/datasources/sync_remote_datasource.dart",
    "features/sync/data/repositories/sync_repository.dart",
    "features/sync/providers/sync_provider.dart",
    "features/sync/screens/sync_overview_screen.dart",
    "features/sync/screens/sync_documents_screen.dart",
    "features/sync/widgets/sync_status_badge.dart",

    # ── Settings ──
    "features/settings/data/models/settings_model.dart",
    "features/settings/data/datasources/settings_remote_datasource.dart",
    "features/settings/data/repositories/settings_repository.dart",
    "features/settings/providers/settings_provider.dart",
    "features/settings/screens/settings_screen.dart",
    "features/settings/screens/company_settings_screen.dart",
    "features/settings/screens/device_settings_screen.dart",
    "features/settings/screens/tax_settings_screen.dart",
    "features/settings/widgets/settings_tile.dart",
    "features/settings/widgets/settings_section_header.dart",

    # ── Database ──
    "features/database/data/models/backup_model.dart",
    "features/database/data/models/db_status_model.dart",
    "features/database/data/datasources/database_remote_datasource.dart",
    "features/database/data/repositories/database_repository.dart",
    "features/database/providers/database_state_provider.dart",
    "features/database/screens/database_screen.dart",
    "features/database/screens/backup_list_screen.dart",
    "features/database/widgets/backup_card.dart",
    "features/database/widgets/db_status_widget.dart"
)

$created  = 0
$skipped  = 0
$errors   = 0

Write-Host ""
Write-Host "  LedgerFlow - Flutter Structure Generator" -ForegroundColor Cyan
Write-Host "  ===========================================" -ForegroundColor Cyan
Write-Host ""

foreach ($relativePath in $files) {
    $fullPath = Join-Path $base $relativePath

    if (Test-Path $fullPath) {
        Write-Host "  [SKIP]  $relativePath" -ForegroundColor DarkGray
        $skipped++
        continue
    }

    $dir = Split-Path $fullPath -Parent
    if (-not (Test-Path $dir)) {
        try {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        } catch {
            Write-Host "  [ERR ]  Cannot create dir: $dir" -ForegroundColor Red
            $errors++
            continue
        }
    }

    $fileName = Split-Path $relativePath -Leaf
    $comment  = "// $fileName"

    try {
        Set-Content -Path $fullPath -Value $comment -Encoding UTF8
        Write-Host "  [OK  ]  $relativePath" -ForegroundColor Green
        $created++
    } catch {
        Write-Host "  [ERR ]  $relativePath" -ForegroundColor Red
        $errors++
    }
}

Write-Host ""
Write-Host "  ═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Done!" -ForegroundColor Cyan
Write-Host "  Created : $created files" -ForegroundColor Green
Write-Host "  Skipped : $skipped files (already exist)" -ForegroundColor DarkGray
if ($errors -gt 0) {
    Write-Host "  Errors  : $errors files" -ForegroundColor Red
}
Write-Host ""
