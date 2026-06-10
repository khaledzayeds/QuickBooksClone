using Zayed.Api.Middleware;
using Zayed.Api.Services;
using Zayed.Core.Accounting;
using Zayed.Core.Common;
using Zayed.Core.Companies;
using Zayed.Core.CustomerCredits;
using Zayed.Core.Customers;
using Zayed.Core.Documents;
using Zayed.Core.Estimates;
using Zayed.Core.Invoices;
using Zayed.Core.InventoryAdjustments;
using Zayed.Core.Items;
using Zayed.Core.JournalEntries;
using Zayed.Core.Licensing;
using Zayed.Core.Modules;
using Zayed.Core.OpeningBalances;
using Zayed.Core.Payments;
using Zayed.Core.PrintTemplates;
using Zayed.Core.PurchaseBills;
using Zayed.Core.PurchaseOrders;
using Zayed.Core.PurchaseWorkflow;
using Zayed.Core.PurchaseReturns;
using Zayed.Core.ReceiveInventory;
using Zayed.Core.Reports;
using Zayed.Core.SalesOrders;
using Zayed.Core.SalesReturns;
using Zayed.Core.SalesWorkflow;
using Zayed.Core.Security;
using Zayed.Core.Settings;
using Zayed.Core.Sync;
using Zayed.Core.Taxes;
using Zayed.Core.Vendors;
using Zayed.Core.VendorCredits;
using Zayed.Core.VendorPayments;
using Zayed.Infrastructure.Accounting;
using Zayed.Infrastructure.Companies;
using Zayed.Infrastructure.CustomerCredits;
using Zayed.Infrastructure.Customers;
using Zayed.Infrastructure.Documents;
using Zayed.Infrastructure.Invoices;
using Zayed.Infrastructure.InventoryAdjustments;
using Zayed.Infrastructure.Items;
using Zayed.Infrastructure.JournalEntries;
using Zayed.Infrastructure.Licensing;
using Zayed.Infrastructure.Modules;
using Zayed.Infrastructure.OpeningBalances;
using Zayed.Infrastructure.Persistence;
using Zayed.Infrastructure.Payments;
using Zayed.Infrastructure.PrintTemplates;
using Zayed.Infrastructure.PurchaseBills;
using Zayed.Infrastructure.PurchaseWorkflow;
using Zayed.Infrastructure.PurchaseReturns;
using Zayed.Infrastructure.ReceiveInventory;
using Zayed.Infrastructure.Reports;
using Zayed.Infrastructure.SalesWorkflow;
using Zayed.Infrastructure.SalesReturns;
using Zayed.Infrastructure.Security;
using Zayed.Infrastructure.Sync;
using Zayed.Infrastructure.Taxes;
using Zayed.Infrastructure.Vendors;
using Zayed.Infrastructure.VendorCredits;
using Zayed.Infrastructure.VendorPayments;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Logging.ClearProviders();
builder.Logging.AddConsole();
builder.Logging.AddDebug();

builder.Services.AddControllers();
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();
builder.Services.AddZayedPersistence(builder.Configuration);
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
builder.Services.AddScoped<ICompanyModuleAccessService, CompanyModuleAccessService>();
builder.Services.AddSingleton<ILicensePackageSigningService>(_ =>
{
    var privateKey = builder.Configuration["Licensing:PrivateKey"]
        ?? Environment.GetEnvironmentVariable("ZAYED_LICENSE_PRIVATE_KEY")
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
app.UseMiddleware<ActiveCompanyRequiredMiddleware>();
app.UseMiddleware<LicenseFeatureMiddleware>();
app.UseMiddleware<PermissionAuthorizationMiddleware>();
app.UseMiddleware<TransactionalWriteMiddleware>();

app.UseAuthorization();

app.MapControllers();

app.Run();
