using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Customers;
using QuickBooksClone.Core.Invoices;
using QuickBooksClone.Core.Items;
using QuickBooksClone.Core.OpeningBalances;
using QuickBooksClone.Core.Payments;
using QuickBooksClone.Core.PurchaseBills;
using QuickBooksClone.Core.SalesReturns;
using QuickBooksClone.Core.Vendors;
using QuickBooksClone.Core.VendorPayments;
using QuickBooksClone.Infrastructure.Accounting;
using QuickBooksClone.Infrastructure.Customers;
using QuickBooksClone.Infrastructure.Invoices;
using QuickBooksClone.Infrastructure.Items;
using QuickBooksClone.Infrastructure.OpeningBalances;
using QuickBooksClone.Infrastructure.Payments;
using QuickBooksClone.Infrastructure.PurchaseBills;
using QuickBooksClone.Infrastructure.SalesReturns;
using QuickBooksClone.Infrastructure.Vendors;
using QuickBooksClone.Infrastructure.VendorPayments;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Logging.ClearProviders();
builder.Logging.AddConsole();
builder.Logging.AddDebug();

builder.Services.AddControllers();
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();
builder.Services.AddSingleton<IAccountRepository, InMemoryAccountRepository>();
builder.Services.AddSingleton<IAccountingTransactionRepository, InMemoryAccountingTransactionRepository>();
builder.Services.AddSingleton<ICustomerRepository, InMemoryCustomerRepository>();
builder.Services.AddSingleton<IItemRepository, InMemoryItemRepository>();
builder.Services.AddSingleton<IInvoiceRepository, InMemoryInvoiceRepository>();
builder.Services.AddSingleton<ISalesInvoicePostingService, SalesInvoicePostingService>();
builder.Services.AddSingleton<IPaymentRepository, InMemoryPaymentRepository>();
builder.Services.AddSingleton<IPaymentPostingService, PaymentPostingService>();
builder.Services.AddSingleton<IVendorRepository, InMemoryVendorRepository>();
builder.Services.AddSingleton<IPurchaseBillRepository, InMemoryPurchaseBillRepository>();
builder.Services.AddSingleton<IPurchaseBillPostingService, PurchaseBillPostingService>();
builder.Services.AddSingleton<IOpeningBalancePostingService, OpeningBalancePostingService>();
builder.Services.AddSingleton<IVendorPaymentRepository, InMemoryVendorPaymentRepository>();
builder.Services.AddSingleton<IVendorPaymentPostingService, VendorPaymentPostingService>();
builder.Services.AddSingleton<ISalesReturnRepository, InMemorySalesReturnRepository>();
builder.Services.AddSingleton<ISalesReturnPostingService, SalesReturnPostingService>();
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

app.UseAuthorization();

app.MapControllers();

app.Run();
