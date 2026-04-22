using QuickBooksClone.Api.Middleware;
using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Common;
using QuickBooksClone.Core.CustomerCredits;
using QuickBooksClone.Core.Customers;
using QuickBooksClone.Core.Invoices;
using QuickBooksClone.Core.InventoryAdjustments;
using QuickBooksClone.Core.Items;
using QuickBooksClone.Core.JournalEntries;
using QuickBooksClone.Core.OpeningBalances;
using QuickBooksClone.Core.Payments;
using QuickBooksClone.Core.PurchaseBills;
using QuickBooksClone.Core.PurchaseOrders;
using QuickBooksClone.Core.PurchaseReturns;
using QuickBooksClone.Core.ReceiveInventory;
using QuickBooksClone.Core.Reports;
using QuickBooksClone.Core.SalesReturns;
using QuickBooksClone.Core.Settings;
using QuickBooksClone.Core.Vendors;
using QuickBooksClone.Core.VendorCredits;
using QuickBooksClone.Core.VendorPayments;
using QuickBooksClone.Infrastructure.Accounting;
using QuickBooksClone.Infrastructure.CustomerCredits;
using QuickBooksClone.Infrastructure.Customers;
using QuickBooksClone.Infrastructure.Invoices;
using QuickBooksClone.Infrastructure.InventoryAdjustments;
using QuickBooksClone.Infrastructure.Items;
using QuickBooksClone.Infrastructure.JournalEntries;
using QuickBooksClone.Infrastructure.OpeningBalances;
using QuickBooksClone.Infrastructure.Persistence;
using QuickBooksClone.Infrastructure.Payments;
using QuickBooksClone.Infrastructure.PurchaseBills;
using QuickBooksClone.Infrastructure.PurchaseReturns;
using QuickBooksClone.Infrastructure.ReceiveInventory;
using QuickBooksClone.Infrastructure.Reports;
using QuickBooksClone.Infrastructure.SalesReturns;
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
builder.Services.AddScoped<IDatabaseMaintenanceService, SqliteDatabaseMaintenanceService>();
builder.Services.AddScoped<IAccountRepository, EfAccountRepository>();
builder.Services.AddScoped<IAccountingTransactionRepository, EfAccountingTransactionRepository>();
builder.Services.AddScoped<ICompanySettingsRepository, EfCompanySettingsRepository>();
builder.Services.AddScoped<IDeviceSettingsRepository, EfDeviceSettingsRepository>();
builder.Services.AddScoped<IDocumentNumberService, DocumentNumberService>();
builder.Services.AddScoped<ICustomerCreditActivityRepository, EfCustomerCreditActivityRepository>();
builder.Services.AddScoped<ICustomerCreditPostingService, CustomerCreditPostingService>();
builder.Services.AddScoped<ICustomerRepository, EfCustomerRepository>();
builder.Services.AddScoped<IItemRepository, EfItemRepository>();
builder.Services.AddScoped<IInvoiceRepository, EfInvoiceRepository>();
builder.Services.AddScoped<ISalesInvoicePostingService, SalesInvoicePostingService>();
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
builder.Services.AddScoped<IPurchaseBillPostingService, PurchaseBillPostingService>();
builder.Services.AddScoped<IInventoryReceiptPostingService, InventoryReceiptPostingService>();
builder.Services.AddScoped<IFinancialReportService, FinancialReportService>();
builder.Services.AddScoped<IPurchaseReturnRepository, EfPurchaseReturnRepository>();
builder.Services.AddScoped<IPurchaseReturnPostingService, PurchaseReturnPostingService>();
builder.Services.AddScoped<IOpeningBalancePostingService, OpeningBalancePostingService>();
builder.Services.AddScoped<IVendorPaymentRepository, EfVendorPaymentRepository>();
builder.Services.AddScoped<IVendorPaymentPostingService, VendorPaymentPostingService>();
builder.Services.AddScoped<IVendorCreditActivityRepository, EfVendorCreditActivityRepository>();
builder.Services.AddScoped<IVendorCreditPostingService, VendorCreditPostingService>();
builder.Services.AddScoped<ISalesReturnRepository, EfSalesReturnRepository>();
builder.Services.AddScoped<ISalesReturnPostingService, SalesReturnPostingService>();
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

app.UseMiddleware<TransactionalWriteMiddleware>();

app.UseAuthorization();

app.MapControllers();

await app.Services.ApplyQuickBooksDatabaseMigrationsAsync();

app.Run();
