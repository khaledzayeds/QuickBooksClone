using Microsoft.Extensions.Logging;
using QuickBooksClone.Maui.Services.Accounting;
using QuickBooksClone.Maui.Services;
using QuickBooksClone.Maui.Services.CustomerCredits;
using QuickBooksClone.Maui.Services.Customers;
using QuickBooksClone.Maui.Services.Estimates;
using QuickBooksClone.Maui.Services.Invoices;
using QuickBooksClone.Maui.Services.InventoryAdjustments;
using QuickBooksClone.Maui.Services.Items;
using QuickBooksClone.Maui.Services.JournalEntries;
using QuickBooksClone.Maui.Services.Payments;
using QuickBooksClone.Maui.Services.PurchaseBills;
using QuickBooksClone.Maui.Services.PurchaseOrders;
using QuickBooksClone.Maui.Services.PurchaseReturns;
using QuickBooksClone.Maui.Services.ReceiveInventory;
using QuickBooksClone.Maui.Services.Reports;
using QuickBooksClone.Maui.Services.SalesReturns;
using QuickBooksClone.Maui.Services.SalesReceipts;
using QuickBooksClone.Maui.Services.Settings;
using QuickBooksClone.Maui.Services.SalesOrders;
using QuickBooksClone.Maui.Services.Vendors;
using QuickBooksClone.Maui.Services.VendorCredits;
using QuickBooksClone.Maui.Services.VendorPayments;

namespace QuickBooksClone.Maui;

public static class MauiProgram
{
    public static MauiApp CreateMauiApp()
    {
        var builder = MauiApp.CreateBuilder();
        builder
            .UseMauiApp<App>()
            .ConfigureFonts(fonts =>
            {
                fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
            });

        builder.Services.AddTransient<MainPage>();
        builder.Services.AddMauiBlazorWebView();
        builder.Services.AddSingleton<ApiConnectionSettingsStore>();
        builder.Services.AddSingleton<LocalApiProcessService>();
        builder.Services.AddSingleton<AppStartupCoordinator>();
        builder.Services.AddTransient<ConfigurableApiMessageHandler>();
        builder.Services.AddScoped(sp =>
        {
            var handler = ActivatorUtilities.CreateInstance<ConfigurableApiMessageHandler>(sp);
            handler.InnerHandler = new HttpClientHandler();
            return new HttpClient(handler)
            {
                BaseAddress = new Uri("http://placeholder/")
            };
        });
        builder.Services.AddScoped<AccountsApiClient>();
        builder.Services.AddScoped<TransactionsApiClient>();
        builder.Services.AddScoped<CustomerCreditsApiClient>();
        builder.Services.AddScoped<CustomersApiClient>();
        builder.Services.AddScoped<EstimatesApiClient>();
        builder.Services.AddScoped<ItemsApiClient>();
        builder.Services.AddScoped<InvoicesApiClient>();
        builder.Services.AddScoped<InventoryAdjustmentsApiClient>();
        builder.Services.AddScoped<JournalEntriesApiClient>();
        builder.Services.AddScoped<PaymentsApiClient>();
        builder.Services.AddScoped<PurchaseBillsApiClient>();
        builder.Services.AddScoped<PurchaseOrdersApiClient>();
        builder.Services.AddScoped<PurchaseReturnsApiClient>();
        builder.Services.AddScoped<InventoryReceiptsApiClient>();
        builder.Services.AddScoped<ReportsApiClient>();
        builder.Services.AddScoped<SalesOrdersApiClient>();
        builder.Services.AddScoped<SalesReceiptsApiClient>();
        builder.Services.AddScoped<SalesReturnsApiClient>();
        builder.Services.AddScoped<ApiConnectivityService>();
        builder.Services.AddScoped<SettingsApiClient>();
        builder.Services.AddScoped<VendorsApiClient>();
        builder.Services.AddScoped<VendorCreditsApiClient>();
        builder.Services.AddScoped<VendorPaymentsApiClient>();

#if DEBUG
        builder.Services.AddBlazorWebViewDeveloperTools();
        builder.Logging.AddDebug();
#endif

        return builder.Build();
    }
}
