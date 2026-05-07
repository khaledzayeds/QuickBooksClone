// Auto-generated integration surface for QuickBooksClone.Api controllers.
// Keep this file on the frontend side and update it whenever backend routes change.

export type HttpMethod = 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';

export type ApiEndpoint = {
  method: HttpMethod;
  path: string;
  auth: 'anonymous' | 'authenticated' | 'none' | string;
};

export const API_ENDPOINTS = {
  "Accounts.Create": { method: "POST", path: "/api/accounts", auth: "Accounting.Manage" },
  "Accounts.Get": { method: "GET", path: "/api/accounts/{id:guid}", auth: "Accounting.View" },
  "Accounts.Search": { method: "GET", path: "/api/accounts", auth: "Accounting.View" },
  "Accounts.SetActive": { method: "PATCH", path: "/api/accounts/{id:guid}/active", auth: "Accounting.Manage" },
  "Accounts.Update": { method: "PUT", path: "/api/accounts/{id:guid}", auth: "Accounting.Manage" },
  "Audit.Search": { method: "GET", path: "/api/audit", auth: "Audit.View" },
  "Auth.Login": { method: "POST", path: "/api/auth/login", auth: "anonymous" },
  "Auth.Logout": { method: "POST", path: "/api/auth/logout", auth: "authenticated" },
  "Auth.Me": { method: "GET", path: "/api/auth/me", auth: "authenticated" },
  "Auth.SetPassword": { method: "PUT", path: "/api/auth/users/{id:guid}/password", auth: "Users.Manage" },
  "Backups.CreateBackup": { method: "POST", path: "/api/backups", auth: "Settings.Manage" },
  "Backups.GetSettings": { method: "GET", path: "/api/backups/settings", auth: "authenticated" },
  "Backups.ImportBackup": { method: "POST", path: "/api/backups/import", auth: "Settings.Manage" },
  "Backups.ListBackups": { method: "GET", path: "/api/backups", auth: "authenticated" },
  "Backups.ListRestoreAudits": { method: "GET", path: "/api/backups/restore-audits", auth: "authenticated" },
  "Backups.RestoreBackup": { method: "POST", path: "/api/backups/restore", auth: "Settings.Manage" },
  "Backups.UpdateSettings": { method: "PUT", path: "/api/backups/settings", auth: "Settings.Manage" },
  "Banking.CreateCheck": { method: "POST", path: "/api/banking/checks", auth: "Accounting.Manage" },
  "Banking.CreateDeposit": { method: "POST", path: "/api/banking/deposits", auth: "Accounting.Manage" },
  "Banking.CreateTransfer": { method: "POST", path: "/api/banking/transfers", auth: "Accounting.Manage" },
  "Banking.GetBankAccounts": { method: "GET", path: "/api/banking/accounts", auth: "Accounting.View" },
  "Banking.GetRegister": { method: "GET", path: "/api/banking/register", auth: "Accounting.View" },
  "BankReconciliation.Preview": { method: "POST", path: "/api/banking/reconcile/preview", auth: "Accounting.Manage" },
  "Calendar.GetCalendar": { method: "GET", path: "/api/calendar", auth: "Reports.View" },
  "CashFlowHubReport.GetCashFlowHub": { method: "GET", path: "/api/reports/cash-flow-hub", auth: "Reports.View" },
  "CustomerCredits.Create": { method: "POST", path: "/api/customer-credits", auth: "Sales.Return.Manage" },
  "CustomerCredits.Get": { method: "GET", path: "/api/customer-credits/{id:guid}", auth: "Sales.Return.Manage" },
  "CustomerCredits.Post": { method: "POST", path: "/api/customer-credits/{id:guid}/post", auth: "Sales.Return.Manage" },
  "CustomerCredits.Search": { method: "GET", path: "/api/customer-credits", auth: "Sales.Return.Manage" },
  "Customers.Create": { method: "POST", path: "/api/customers", auth: "Customers.Manage" },
  "Customers.Get": { method: "GET", path: "/api/customers/{id:guid}", auth: "Customers.Manage" },
  "Customers.Search": { method: "GET", path: "/api/customers", auth: "Customers.Manage" },
  "Customers.SetActive": { method: "PATCH", path: "/api/customers/{id:guid}/active", auth: "Customers.Manage" },
  "Customers.Update": { method: "PUT", path: "/api/customers/{id:guid}", auth: "Customers.Manage" },
  "Database.CreateBackup": { method: "POST", path: "/api/database/backups", auth: "Data.BackupRestore" },
  "Database.GetMaintenanceSettings": { method: "GET", path: "/api/database/settings", auth: "Data.BackupRestore" },
  "Database.GetStatus": { method: "GET", path: "/api/database/status", auth: "Data.BackupRestore" },
  "Database.ImportBackup": { method: "POST", path: "/api/database/backups/import", auth: "Data.BackupRestore" },
  "Database.ListBackups": { method: "GET", path: "/api/database/backups", auth: "Data.BackupRestore" },
  "Database.ListRestoreAudits": { method: "GET", path: "/api/database/restore-audits", auth: "Data.BackupRestore" },
  "Database.RestoreBackup": { method: "POST", path: "/api/database/backups/restore", auth: "Data.BackupRestore" },
  "Database.UpdateMaintenanceSettings": { method: "PUT", path: "/api/database/settings", auth: "Data.BackupRestore" },
  "DocumentMetadata.AddAttachment": { method: "POST", path: "/api/documents/{documentType}/{documentId:guid}/metadata/attachments", auth: "Documents.Metadata.Manage" },
  "DocumentMetadata.Get": { method: "GET", path: "/api/documents/{documentType}/{documentId:guid}/metadata", auth: "Documents.Metadata.Manage" },
  "DocumentMetadata.RemoveAttachment": { method: "DELETE", path: "/api/documents/{documentType}/{documentId:guid}/metadata/attachments/{attachmentId:guid}", auth: "Documents.Metadata.Manage" },
  "DocumentMetadata.Update": { method: "PUT", path: "/api/documents/{documentType}/{documentId:guid}/metadata", auth: "Documents.Metadata.Manage" },
  "Estimates.Accept": { method: "POST", path: "/api/estimates/{id:guid}/accept", auth: "Sales.Estimate.Manage" },
  "Estimates.Cancel": { method: "PATCH", path: "/api/estimates/{id:guid}/cancel", auth: "Sales.Estimate.Manage" },
  "Estimates.Create": { method: "POST", path: "/api/estimates", auth: "Sales.Estimate.Manage" },
  "Estimates.Decline": { method: "POST", path: "/api/estimates/{id:guid}/decline", auth: "Sales.Estimate.Manage" },
  "Estimates.Get": { method: "GET", path: "/api/estimates/{id:guid}", auth: "Sales.Estimate.Manage" },
  "Estimates.Search": { method: "GET", path: "/api/estimates", auth: "Sales.Estimate.Manage" },
  "Estimates.Send": { method: "POST", path: "/api/estimates/{id:guid}/send", auth: "Sales.Estimate.Manage" },
  "Health.Get": { method: "GET", path: "/api/health", auth: "anonymous" },
  "InventoryAdjustments.Create": { method: "POST", path: "/api/inventory-adjustments", auth: "Inventory.Adjust.Manage" },
  "InventoryAdjustments.Get": { method: "GET", path: "/api/inventory-adjustments/{id:guid}", auth: "Inventory.Adjust.Manage" },
  "InventoryAdjustments.Search": { method: "GET", path: "/api/inventory-adjustments", auth: "Inventory.Adjust.Manage" },
  "InvoiceDraftUpdates.UpdateDraft": { method: "PUT", path: "/api/invoices/{id:guid}", auth: "Sales.Invoice.Manage" },
  "Invoices.Create": { method: "POST", path: "/api/invoices", auth: "Sales.Invoice.Manage" },
  "Invoices.Get": { method: "GET", path: "/api/invoices/{id:guid}", auth: "Sales.Invoice.Manage" },
  "Invoices.GetCustomerActivity": { method: "GET", path: "/api/invoices/customers/{customerId:guid}/activity", auth: "Sales.Invoice.Manage" },
  "Invoices.MarkSent": { method: "PATCH", path: "/api/invoices/{id:guid}/sent", auth: "Sales.Invoice.Manage" },
  "Invoices.Post": { method: "POST", path: "/api/invoices/{id:guid}/post", auth: "Sales.Invoice.Manage" },
  "Invoices.Preview": { method: "POST", path: "/api/invoices/preview", auth: "Sales.Invoice.Manage" },
  "Invoices.Search": { method: "GET", path: "/api/invoices", auth: "Sales.Invoice.Manage" },
  "Invoices.Void": { method: "PATCH", path: "/api/invoices/{id:guid}/void", auth: "Sales.Invoice.Manage" },
  "Items.AdjustQuantity": { method: "PATCH", path: "/api/items/{id:guid}/quantity", auth: "Inventory.Items.Manage" },
  "Items.Create": { method: "POST", path: "/api/items", auth: "Inventory.Items.Manage" },
  "Items.Get": { method: "GET", path: "/api/items/{id:guid}", auth: "Inventory.Items.Manage" },
  "Items.Search": { method: "GET", path: "/api/items", auth: "Inventory.Items.Manage" },
  "Items.SetActive": { method: "PATCH", path: "/api/items/{id:guid}/active", auth: "Inventory.Items.Manage" },
  "Items.Update": { method: "PUT", path: "/api/items/{id:guid}", auth: "Inventory.Items.Manage" },
  "JournalEntries.Create": { method: "POST", path: "/api/journal-entries", auth: "Accounting.Manage" },
  "JournalEntries.Get": { method: "GET", path: "/api/journal-entries/{id:guid}", auth: "Accounting.Manage" },
  "JournalEntries.Post": { method: "POST", path: "/api/journal-entries/{id:guid}/post", auth: "Accounting.Manage" },
  "JournalEntries.Search": { method: "GET", path: "/api/journal-entries", auth: "Accounting.Manage" },
  "JournalEntries.Void": { method: "PATCH", path: "/api/journal-entries/{id:guid}/void", auth: "Accounting.Manage" },
  "Licenses.Activate": { method: "POST", path: "/api/licenses/activate", auth: "anonymous" },
  "Licenses.GetStatus": { method: "GET", path: "/api/licenses/status", auth: "anonymous" },
  "Payments.Create": { method: "POST", path: "/api/payments", auth: "Sales.Payment.Manage" },
  "Payments.Get": { method: "GET", path: "/api/payments/{id:guid}", auth: "Sales.Payment.Manage" },
  "Payments.Search": { method: "GET", path: "/api/payments", auth: "Sales.Payment.Manage" },
  "Payments.Void": { method: "PATCH", path: "/api/payments/{id:guid}/void", auth: "Sales.Payment.Manage" },
  "Printing.GetDocumentPrintData": { method: "GET", path: "/api/printing/documents/{documentType}/{id:guid}/data", auth: "Sales.Invoice.Manage" },
  "PurchaseBills.Create": { method: "POST", path: "/api/purchase-bills", auth: "Purchases.Bill.Manage" },
  "PurchaseBills.Get": { method: "GET", path: "/api/purchase-bills/{id:guid}", auth: "Purchases.Bill.Manage" },
  "PurchaseBills.GetPaymentPlan": { method: "GET", path: "/api/purchase-bills/{id:guid}/payment-plan", auth: "Purchases.Bill.Manage" },
  "PurchaseBills.Post": { method: "POST", path: "/api/purchase-bills/{id:guid}/post", auth: "Purchases.Bill.Manage" },
  "PurchaseBills.Search": { method: "GET", path: "/api/purchase-bills", auth: "Purchases.Bill.Manage" },
  "PurchaseBills.Void": { method: "PATCH", path: "/api/purchase-bills/{id:guid}/void", auth: "Purchases.Bill.Manage" },
  "PurchaseOrderDraftUpdates.UpdateDraft": { method: "PUT", path: "/api/purchase-orders/{id:guid}", auth: "Purchases.Order.Manage" },
  "PurchaseOrders.Cancel": { method: "PATCH", path: "/api/purchase-orders/{id:guid}/cancel", auth: "Purchases.Order.Manage" },
  "PurchaseOrders.Close": { method: "POST", path: "/api/purchase-orders/{id:guid}/close", auth: "Purchases.Order.Manage" },
  "PurchaseOrders.Create": { method: "POST", path: "/api/purchase-orders", auth: "Purchases.Order.Manage" },
  "PurchaseOrders.Get": { method: "GET", path: "/api/purchase-orders/{id:guid}", auth: "Purchases.Order.Manage" },
  "PurchaseOrders.GetReceivingPlan": { method: "GET", path: "/api/purchase-orders/{id:guid}/receiving-plan", auth: "Purchases.Order.Manage" },
  "PurchaseOrders.Open": { method: "POST", path: "/api/purchase-orders/{id:guid}/open", auth: "Purchases.Order.Manage" },
  "PurchaseOrders.Search": { method: "GET", path: "/api/purchase-orders", auth: "Purchases.Order.Manage" },
  "PurchaseReturns.Create": { method: "POST", path: "/api/purchase-returns", auth: "Purchases.Return.Manage" },
  "PurchaseReturns.Get": { method: "GET", path: "/api/purchase-returns/{id:guid}", auth: "Purchases.Return.Manage" },
  "PurchaseReturns.Search": { method: "GET", path: "/api/purchase-returns", auth: "Purchases.Return.Manage" },
  "PurchaseReturns.Void": { method: "PATCH", path: "/api/purchase-returns/{id:guid}/void", auth: "Purchases.Return.Manage" },
  "ReceiveInventory.Create": { method: "POST", path: "/api/receive-inventory", auth: "Purchases.Receive.Manage" },
  "ReceiveInventory.Get": { method: "GET", path: "/api/receive-inventory/{id:guid}", auth: "Purchases.Receive.Manage" },
  "ReceiveInventory.GetBillingPlan": { method: "GET", path: "/api/receive-inventory/{id:guid}/billing-plan", auth: "Purchases.Receive.Manage" },
  "ReceiveInventory.Post": { method: "POST", path: "/api/receive-inventory/{id:guid}/post", auth: "Purchases.Receive.Manage" },
  "ReceiveInventory.Search": { method: "GET", path: "/api/receive-inventory", auth: "Purchases.Receive.Manage" },
  "ReceiveInventory.Void": { method: "PATCH", path: "/api/receive-inventory/{id:guid}/void", auth: "Purchases.Receive.Manage" },
  "Reports.GetAccountsPayableAging": { method: "GET", path: "/api/reports/accounts-payable-aging", auth: "Reports.View" },
  "Reports.GetAccountsReceivableAging": { method: "GET", path: "/api/reports/accounts-receivable-aging", auth: "Reports.View" },
  "Reports.GetBalanceSheet": { method: "GET", path: "/api/reports/balance-sheet", auth: "Reports.View" },
  "Reports.GetInventoryValuation": { method: "GET", path: "/api/reports/inventory-valuation", auth: "Reports.View" },
  "Reports.GetProfitAndLoss": { method: "GET", path: "/api/reports/profit-and-loss", auth: "Reports.View" },
  "Reports.GetTaxSummary": { method: "GET", path: "/api/reports/tax-summary", auth: "Reports.View" },
  "Reports.GetTrialBalance": { method: "GET", path: "/api/reports/trial-balance", auth: "Reports.View" },
  "SalesOrders.Cancel": { method: "PATCH", path: "/api/sales-orders/{id:guid}/cancel", auth: "Sales.Order.Manage" },
  "SalesOrders.Close": { method: "POST", path: "/api/sales-orders/{id:guid}/close", auth: "Sales.Order.Manage" },
  "SalesOrders.Create": { method: "POST", path: "/api/sales-orders", auth: "Sales.Order.Manage" },
  "SalesOrders.Get": { method: "GET", path: "/api/sales-orders/{id:guid}", auth: "Sales.Order.Manage" },
  "SalesOrders.Open": { method: "POST", path: "/api/sales-orders/{id:guid}/open", auth: "Sales.Order.Manage" },
  "SalesOrders.Search": { method: "GET", path: "/api/sales-orders", auth: "Sales.Order.Manage" },
  "SalesReceipts.Create": { method: "POST", path: "/api/sales-receipts", auth: "Sales.Invoice.Manage" },
  "SalesReceipts.Get": { method: "GET", path: "/api/sales-receipts/{id:guid}", auth: "Sales.Invoice.Manage" },
  "SalesReceipts.Preview": { method: "POST", path: "/api/sales-receipts/preview", auth: "Sales.Invoice.Manage" },
  "SalesReceipts.Search": { method: "GET", path: "/api/sales-receipts", auth: "Sales.Invoice.Manage" },
  "SalesReceipts.Void": { method: "PATCH", path: "/api/sales-receipts/{id:guid}/void", auth: "Sales.Invoice.Manage" },
  "SalesReturns.Create": { method: "POST", path: "/api/sales-returns", auth: "Sales.Return.Manage" },
  "SalesReturns.Get": { method: "GET", path: "/api/sales-returns/{id:guid}", auth: "Sales.Return.Manage" },
  "SalesReturns.Post": { method: "POST", path: "/api/sales-returns/{id:guid}/post", auth: "Sales.Return.Manage" },
  "SalesReturns.Search": { method: "GET", path: "/api/sales-returns", auth: "Sales.Return.Manage" },
  "SalesReturns.Void": { method: "PATCH", path: "/api/sales-returns/{id:guid}/void", auth: "Sales.Return.Manage" },
  "SalesWorkflow.ConvertEstimateToSalesOrder": { method: "POST", path: "/api/estimates/{id:guid}/convert-to-sales-order", auth: "Sales.Order.Manage" },
  "SalesWorkflow.ConvertSalesOrderToInvoice": { method: "POST", path: "/api/sales-orders/{id:guid}/convert-to-invoice", auth: "Sales.Invoice.Manage" },
  "SalesWorkflow.GetInvoicePlan": { method: "GET", path: "/api/sales-orders/{id:guid}/invoice-plan", auth: "Sales.Order.Manage" },
  "SalesWorkflow.GetPaymentPlan": { method: "GET", path: "/api/invoices/{id:guid}/payment-plan", auth: "Sales.Payment.Manage" },
  "SalesWorkflow.GetSalesOrderPlan": { method: "GET", path: "/api/estimates/{id:guid}/sales-order-plan", auth: "Sales.Estimate.Manage" },
  "Security.CreateRole": { method: "POST", path: "/api/security/roles", auth: "Users.Manage" },
  "Security.CreateUser": { method: "POST", path: "/api/security/users", auth: "Users.Manage" },
  "Security.GetPermissions": { method: "GET", path: "/api/security/permissions", auth: "anonymous" },
  "Security.GetRole": { method: "GET", path: "/api/security/roles/{id:guid}", auth: "Users.Manage" },
  "Security.GetUser": { method: "GET", path: "/api/security/users/{id:guid}", auth: "Users.Manage" },
  "Security.ReplaceRolePermissions": { method: "PUT", path: "/api/security/roles/{id:guid}/permissions", auth: "Users.Manage" },
  "Security.ReplaceUserRoles": { method: "PUT", path: "/api/security/users/{id:guid}/roles", auth: "Users.Manage" },
  "Security.SearchRoles": { method: "GET", path: "/api/security/roles", auth: "Users.Manage" },
  "Security.SearchUsers": { method: "GET", path: "/api/security/users", auth: "Users.Manage" },
  "Security.SetRoleActive": { method: "PATCH", path: "/api/security/roles/{id:guid}/active", auth: "Users.Manage" },
  "Security.SetUserActive": { method: "PATCH", path: "/api/security/users/{id:guid}/active", auth: "Users.Manage" },
  "Security.UpdateRole": { method: "PUT", path: "/api/security/roles/{id:guid}", auth: "Users.Manage" },
  "Security.UpdateUser": { method: "PUT", path: "/api/security/users/{id:guid}", auth: "Users.Manage" },
  "Settings.GetCompany": { method: "GET", path: "/api/settings/company", auth: "authenticated" },
  "Settings.GetDevice": { method: "GET", path: "/api/settings/device", auth: "authenticated" },
  "Settings.GetRuntime": { method: "GET", path: "/api/settings/runtime", auth: "anonymous" },
  "Settings.UpdateCompany": { method: "PUT", path: "/api/settings/company", auth: "Settings.Manage" },
  "Settings.UpdateDevice": { method: "PUT", path: "/api/settings/device", auth: "Settings.Manage" },
  "Setup.GetStatus": { method: "GET", path: "/api/setup/status", auth: "anonymous" },
  "Setup.InitializeCompany": { method: "POST", path: "/api/setup/initialize-company", auth: "anonymous" },
  "Setup.SeedDefaultAccounts": { method: "POST", path: "/api/setup/seed-default-accounts", auth: "anonymous" },
  "Sync.GetDocuments": { method: "GET", path: "/api/sync/documents", auth: "Data.Sync.Manage" },
  "Sync.GetOverview": { method: "GET", path: "/api/sync/overview", auth: "Data.Sync.Manage" },
  "Sync.MarkPending": { method: "POST", path: "/api/sync/documents/{documentType}/{id:guid}/mark-pending", auth: "Data.Sync.Manage" },
  "TaxCodes.Create": { method: "POST", path: "/api/tax-codes", auth: "Settings.Manage" },
  "TaxCodes.Get": { method: "GET", path: "/api/tax-codes/{id:guid}", auth: "Settings.Manage" },
  "TaxCodes.Search": { method: "GET", path: "/api/tax-codes", auth: "Settings.Manage" },
  "TaxCodes.SetActive": { method: "PATCH", path: "/api/tax-codes/{id:guid}/active", auth: "Settings.Manage" },
  "TaxCodes.Update": { method: "PUT", path: "/api/tax-codes/{id:guid}", auth: "Settings.Manage" },
  "TimeEntries.Approve": { method: "POST", path: "/api/time-entries/{id:guid}/approve", auth: "TimeTracking.Manage" },
  "TimeEntries.Create": { method: "POST", path: "/api/time-entries", auth: "TimeTracking.Manage" },
  "TimeEntries.Get": { method: "GET", path: "/api/time-entries/{id:guid}", auth: "TimeTracking.Manage" },
  "TimeEntries.MarkInvoiced": { method: "POST", path: "/api/time-entries/{id:guid}/mark-invoiced", auth: "TimeTracking.Manage" },
  "TimeEntries.Search": { method: "GET", path: "/api/time-entries", auth: "TimeTracking.Manage" },
  "TimeEntries.Update": { method: "PUT", path: "/api/time-entries/{id:guid}", auth: "TimeTracking.Manage" },
  "TimeEntries.Void": { method: "PATCH", path: "/api/time-entries/{id:guid}/void", auth: "TimeTracking.Manage" },
  "Transactions.Get": { method: "GET", path: "/api/transactions/{id:guid}", auth: "Accounting.View" },
  "Transactions.Search": { method: "GET", path: "/api/transactions", auth: "Accounting.View" },
  "VendorCredits.Create": { method: "POST", path: "/api/vendor-credits", auth: "Purchases.Return.Manage" },
  "VendorCredits.Get": { method: "GET", path: "/api/vendor-credits/{id:guid}", auth: "Purchases.Return.Manage" },
  "VendorCredits.Search": { method: "GET", path: "/api/vendor-credits", auth: "Purchases.Return.Manage" },
  "VendorPayments.Create": { method: "POST", path: "/api/vendor-payments", auth: "Purchases.Payment.Manage" },
  "VendorPayments.Get": { method: "GET", path: "/api/vendor-payments/{id:guid}", auth: "Purchases.Payment.Manage" },
  "VendorPayments.Search": { method: "GET", path: "/api/vendor-payments", auth: "Purchases.Payment.Manage" },
  "VendorPayments.Void": { method: "PATCH", path: "/api/vendor-payments/{id:guid}/void", auth: "Purchases.Payment.Manage" },
  "Vendors.Create": { method: "POST", path: "/api/vendors", auth: "Vendors.Manage" },
  "Vendors.Get": { method: "GET", path: "/api/vendors/{id:guid}", auth: "Vendors.Manage" },
  "Vendors.Search": { method: "GET", path: "/api/vendors", auth: "Vendors.Manage" },
  "Vendors.SetActive": { method: "PATCH", path: "/api/vendors/{id:guid}/active", auth: "Vendors.Manage" },
  "Vendors.Update": { method: "PUT", path: "/api/vendors/{id:guid}", auth: "Vendors.Manage" },
} as const satisfies Record<string, ApiEndpoint>;

export type ApiEndpointKey = keyof typeof API_ENDPOINTS;

export type ApiRequestOptions = {
  params?: Record<string, string | number | boolean | null | undefined>;
  query?: Record<string, string | number | boolean | Date | null | undefined | Array<string | number | boolean | Date>>;
  body?: unknown;
  headers?: HeadersInit;
  signal?: AbortSignal;
};

export type ApiClientOptions = {
  baseUrl: string;
  token?: string | null;
  getToken?: () => string | null | undefined | Promise<string | null | undefined>;
  onUnauthorized?: () => void;
};

export class ApiError extends Error {
  readonly status: number;
  readonly problem: unknown;

  constructor(status: number, message: string, problem: unknown) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.problem = problem;
  }
}

export class QuickBooksApiClient {
  private readonly baseUrl: string;
  private token: string | null;
  private readonly getToken?: ApiClientOptions['getToken'];
  private readonly onUnauthorized?: () => void;

  constructor(options: ApiClientOptions) {
    this.baseUrl = options.baseUrl.replace(/\/+$/, '');
    this.token = options.token ?? null;
    this.getToken = options.getToken;
    this.onUnauthorized = options.onUnauthorized;
  }

  setToken(token: string | null): void {
    this.token = token;
  }

  async call<TResponse = unknown>(key: ApiEndpointKey, options: ApiRequestOptions = {}): Promise<TResponse> {
    const endpoint = API_ENDPOINTS[key];
    return this.request<TResponse>(endpoint.method, endpoint.path, options);
  }

  async request<TResponse = unknown>(method: HttpMethod, pathTemplate: string, options: ApiRequestOptions = {}): Promise<TResponse> {
    const path = buildPath(pathTemplate, options.params);
    const url = new URL(this.baseUrl + path);
    appendQuery(url, options.query);

    const headers = new Headers(options.headers);
    const token = this.getToken ? await this.getToken() : this.token;
    if (token) {
      headers.set('Authorization', `Bearer ${token}`);
    }

    const hasBody = options.body !== undefined && options.body !== null;
    if (hasBody && !headers.has('Content-Type')) {
      headers.set('Content-Type', 'application/json');
    }

    const response = await fetch(url, {
      method,
      headers,
      body: hasBody ? JSON.stringify(options.body) : undefined,
      signal: options.signal
    });

    if (response.status === 401) {
      this.onUnauthorized?.();
    }

    if (!response.ok) {
      const problem = await readResponse(response);
      const message = extractErrorMessage(problem) ?? response.statusText ?? 'Request failed';
      throw new ApiError(response.status, message, problem);
    }

    if (response.status === 204) {
      return undefined as TResponse;
    }

    return await readResponse(response) as TResponse;
  }
}

export function buildPath(template: string, params: ApiRequestOptions['params'] = {}): string {
  return template.replace(/\{([^}:]+)(?::[^}]+)?\}/g, (_, rawName: string) => {
    const value = params?.[rawName];
    if (value === undefined || value === null || value === '') {
      throw new Error(`Missing route parameter: ${rawName}`);
    }

    return encodeURIComponent(String(value));
  });
}

function appendQuery(url: URL, query: ApiRequestOptions['query'] = {}): void {
  for (const [key, value] of Object.entries(query ?? {})) {
    if (value === undefined || value === null || value === '') {
      continue;
    }

    const values = Array.isArray(value) ? value : [value];
    for (const item of values) {
      if (item === undefined || item === null || item === '') {
        continue;
      }

      url.searchParams.append(key, item instanceof Date ? item.toISOString() : String(item));
    }
  }
}

async function readResponse(response: Response): Promise<unknown> {
  const text = await response.text();
  if (!text) {
    return undefined;
  }

  const contentType = response.headers.get('Content-Type') ?? '';
  if (contentType.includes('application/json') || contentType.includes('application/problem+json')) {
    return JSON.parse(text);
  }

  return text;
}

function extractErrorMessage(problem: unknown): string | undefined {
  if (typeof problem === 'string') {
    return problem;
  }

  if (problem && typeof problem === 'object') {
    const record = problem as Record<string, unknown>;
    return typeof record.detail === 'string'
      ? record.detail
      : typeof record.title === 'string'
        ? record.title
        : undefined;
  }

  return undefined;
}

export const createQuickBooksApi = (baseUrl: string, token?: string | null): QuickBooksApiClient =>
  new QuickBooksApiClient({ baseUrl, token });
