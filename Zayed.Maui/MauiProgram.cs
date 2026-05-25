using Microsoft.Extensions.Logging;
using Zayed.Maui.Services.Accounting;
using Zayed.Maui.Services;
using Zayed.Maui.Services.CustomerCredits;
using Zayed.Maui.Services.Customers;
using Zayed.Maui.Services.Estimates;
using Zayed.Maui.Services.Invoices;
using Zayed.Maui.Services.InventoryAdjustments;
using Zayed.Maui.Services.Items;
using Zayed.Maui.Services.JournalEntries;
using Zayed.Maui.Services.Payments;
using Zayed.Maui.Services.PurchaseBills;
using Zayed.Maui.Services.PurchaseOrders;
using Zayed.Maui.Services.PurchaseReturns;
using Zayed.Maui.Services.ReceiveInventory;
using Zayed.Maui.Services.Reports;
using Zayed.Maui.Services.SalesReturns;
using Zayed.Maui.Services.SalesReceipts;
using Zayed.Maui.Services.Settings;
using Zayed.Maui.Services.SalesOrders;
using Zayed.Maui.Services.Vendors;
using Zayed.Maui.Services.VendorCredits;
using Zayed.Maui.Services.VendorPayments;

namespace Zayed.Maui;

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
