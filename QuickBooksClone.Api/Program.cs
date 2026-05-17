using QuickBooksClone.Api.Middleware;
using QuickBooksClone.Api.Services;
using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Common;
using QuickBooksClone.Core.Companies;
using QuickBooksClone.Core.CustomerCredits;
using QuickBooksClone.Core.Customers;
using QuickBooksClone.Core.Documents;
using QuickBooksClone.Core.Estimates;
using QuickBooksClone.Core.Invoices;
using QuickBooksClone.Core.InventoryAdjustments;
using QuickBooksClone.Core.Items;
using QuickBooksClone.Core.JournalEntries;
using QuickBooksClone.Core.Licensing;
using QuickBooksClone.Core.OpeningBalances;
using QuickBooksClone.Core.Payments;
using QuickBooksClone.Core.PrintTemplates;
using QuickBooksClone.Core.PurchaseBills;
using QuickBooksClone.Core.PurchaseOrders;
using QuickBooksClone.Core.PurchaseWorkflow;
using QuickBooksClone.Core.PurchaseReturns;
using QuickBooksClone.Core.ReceiveInventory;
using QuickBooksClone.Core.Reports;
using QuickBooksClone.Core.SalesOrders;
using QuickBooksClone.Core.SalesReturns;
using QuickBooksClone.Core.SalesWorkflow;
using QuickBooksClone.Core.Security;
using QuickBooksClone.Core.Settings;
using QuickBooksClone.Core.Sync;
using QuickBooksClone.Core.Taxes;
using QuickBooksClone.Core.Vendors;
using QuickBooksClone.Core.VendorCredits;
using QuickBooksClone.Core.VendorPayments;
using QuickBooksClone.Infrastructure.Accounting;
using QuickBooksClone.Infrastructure.Companies;
using QuickBooksClone.Infrastructure.CustomerCredits;
using QuickBooksClone.Infrastructure.Customers;
using QuickBooksClone.Infrastructure.Documents;
using QuickBooksClone.Infrastructure.Invoices;
using QuickBooksClone.Infrastructure.InventoryAdjustments;
using QuickBooksClone.Infrastructure.Items;
using QuickBooksClone.Infrastructure.JournalEntries;
using QuickBooksClone.Infrastructure.Licensing;
using QuickBooksClone.Infrastructure.OpeningBalances;
using QuickBooksClone.Infrastructure.Persistence;
using QuickBooksClone.Infrastructure.Payments;
using QuickBooksClone.Infrastructure.PrintTemplates;
using QuickBooksClone.Infrastructure.PurchaseBills;
using QuickBooksClone.Infrastructure.PurchaseWorkflow;
using QuickBooksClone.Infrastructure.PurchaseReturns;
using QuickBooksClone.Infrastructure.ReceiveInventory;
using QuickBooksClone.Infrastructure.Reports;
using QuickBooksClone.Infrastructure.SalesWorkflow;
using QuickBooksClone.Infrastructure.SalesReturns;
using QuickBooksClone.Infrastructure.Security;
using QuickBooksClone.Infrastructure.Sync;
using QuickBooksClone.Infrastructure.Taxes;
using QuickBooksClone.Infrastructure.Vendors;
using QuickBooksClone.Infrastructure.VendorCredits;
using QuickBooksClone.Infrastructure.VendorPayments;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Logging.ClearProviders();
builder.Logging.AddConsole();
builder.Logging.AddDebug();

builder.Services.AddControllers();
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();
builder.Services.AddQuickBooksPersistence(builder.Configuration);
builder.Services.AddSingleton<ICompanyRuntimeService, LocalCompanyRuntimeService>();
builder.Services.AddScoped<IDatabaseMaintenanceService, SqliteDatabaseMaintenanceService>();
builder.Services.AddScoped<IAccountRepository, EfAccountRepository>();
builder.Services.AddScoped<IDefaultAccountsSeeder, DefaultAccountsSeeder>();
builder.Services.AddScoped<IAccountingTransactionRepository, EfAccountingTransactionRepository>();
builder.Services.AddScoped<ICompanySettingsRepository, EfCompanySettingsRepository>();
builder.Services.AddScoped<IDeviceSettingsRepository, EfDeviceSettingsRepository>();
builder.Services.AddScoped<IDocumentNumberService, DocumentNumberService>();
builder.Services.AddScoped<ISyncDiagnosticsService, SyncDiagnosticsService>();
builder.Services.AddScoped<ITaxCodeRepository, EfTaxCodeRepository>();
builder.Services.AddScoped<ICustomerCreditActivityRepository, EfCustomerCreditActivityRepository>();
builder.Services.AddScoped<ICustomerCreditPostingService, CustomerCreditPostingService>();
builder.Services.AddScoped<ICustomerRepository, EfCustomerRepository>();
builder.Services.AddScoped<IDocumentMetadataService, DocumentMetadataService>();
builder.Services.AddScoped<IEstimateRepository, EfEstimateRepository>();
builder.Services.AddScoped<IItemRepository, EfItemRepository>();
builder.Services.AddScoped<IInvoiceRepository, EfInvoiceRepository>();
builder.Services.AddScoped<ISalesInvoicePostingService, SalesInvoicePostingService>();
builder.Services.AddScoped<SalesPostingPreviewService>();
builder.Services.AddScoped<SalesActivityService>();
builder.Services.AddScoped<SalesPrintService>();
builder.Services.AddScoped<IPrintTemplateRepository, EfPrintTemplateRepository>();
builder.Services.AddScoped<IInventoryAdjustmentRepository, EfInventoryAdjustmentRepository>();
builder.Services.AddScoped<IInventoryAdjustmentPostingService, InventoryAdjustmentPostingService>();
builder.Services.AddScoped<IJournalEntryRepository, EfJournalEntryRepository>();
builder.Services.AddScoped<IJournalEntryPostingService, JournalEntryPostingService>();
builder.Services.AddScoped<IPaymentRepository, EfPaymentRepository>();
builder.Services.AddScoped<IPaymentPostingService, PaymentPostingService>();
builder.Services.AddScoped<IVendorRepository, EfVendorRepository>();
builder.Services.AddScoped<IPurchaseBillRepository, EfPurchaseBillRepository>();
builder.Services.AddScoped<IInventoryReceiptRepository, EfInventoryReceiptRepository>();
builder.Services.AddScoped<IPurchaseOrderRepository, EfPurchaseOrderRepository>();
builder.Services.AddScoped<IPurchaseWorkflowService, PurchaseWorkflowService>();
builder.Services.AddScoped<IPurchaseBillPostingService, PurchaseBillPostingService>();
builder.Services.AddScoped<IInventoryReceiptPostingService, InventoryReceiptPostingService>();
builder.Services.AddScoped<IFinancialReportService, FinancialReportService>();
builder.Services.AddScoped<ISalesOrderRepository, EfSalesOrderRepository>();
builder.Services.AddScoped<ISalesWorkflowService, SalesWorkflowService>();
builder.Services.AddScoped<IPurchaseReturnRepository, EfPurchaseReturnRepository>();
builder.Services.AddScoped<IPurchaseReturnPostingService, PurchaseReturnPostingService>();
builder.Services.AddScoped<IOpeningBalancePostingService, OpeningBalancePostingService>();
builder.Services.AddScoped<IVendorPaymentRepository, EfVendorPaymentRepository>();
builder.Services.AddScoped<IVendorPaymentPostingService, VendorPaymentPostingService>();
builder.Services.AddScoped<IVendorCreditActivityRepository, EfVendorCreditActivityRepository>();
builder.Services.AddScoped<IVendorCreditPostingService, VendorCreditPostingService>();
builder.Services.AddScoped<ISalesReturnRepository, EfSalesReturnRepository>();
builder.Services.AddScoped<ISalesReturnPostingService, SalesReturnPostingService>();
builder.Services.AddScoped<ISecurityRepository, EfSecurityRepository>();
builder.Services.AddScoped<IAuditLogRepository, EfAuditLogRepository>();
builder.Services.AddScoped<IPasswordHasher, PasswordHasher>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<ILicenseFeatureAccessService, ConfigurationLicenseFeatureAccessService>();
builder.Services.AddScoped<ILicenseActivationService, ConfigurationLicenseActivationService>();
builder.Services.AddSingleton<ILicensePackageSigningService>(_ =>
{
    var privateKey = builder.Configuration["Licensing:PrivateKey"]
        ?? Environment.GetEnvironmentVariable("LEDGERFLOW_LICENSE_PRIVATE_KEY")
        ?? string.Empty;
    return new Ed25519LicensePackageSigningService(privateKey);
});
builder.Services.AddCors(options =>
{
    options.AddPolicy("DesktopClient", policy =>
    {
        policy
            .AllowAnyOrigin()
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseCors("DesktopClient");

app.UseRouting();
app.UseMiddleware<ApiExceptionHandlingMiddleware>();
app.UseMiddleware<LicenseFeatureMiddleware>();
app.UseMiddleware<PermissionAuthorizationMiddleware>();
app.UseMiddleware<TransactionalWriteMiddleware>();

app.UseAuthorization();

app.MapControllers();

await app.Services.ApplyQuickBooksDatabaseMigrationsAsync();

app.Run();
