using Microsoft.Extensions.Logging;
using QuickBooksClone.Maui.Services.Accounting;
using QuickBooksClone.Maui.Services;
using QuickBooksClone.Maui.Services.Customers;
using QuickBooksClone.Maui.Services.Invoices;
using QuickBooksClone.Maui.Services.Items;
using QuickBooksClone.Maui.Services.Payments;
using QuickBooksClone.Maui.Services.PurchaseBills;
using QuickBooksClone.Maui.Services.Vendors;

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

        builder.Services.AddMauiBlazorWebView();
        builder.Services.AddSingleton(new ApiOptions());
        builder.Services.AddScoped(sp =>
        {
            var options = sp.GetRequiredService<ApiOptions>();
            return new HttpClient
            {
                BaseAddress = new Uri(options.BaseUrl)
            };
        });
        builder.Services.AddScoped<AccountsApiClient>();
        builder.Services.AddScoped<TransactionsApiClient>();
        builder.Services.AddScoped<CustomersApiClient>();
        builder.Services.AddScoped<ItemsApiClient>();
        builder.Services.AddScoped<InvoicesApiClient>();
        builder.Services.AddScoped<PaymentsApiClient>();
        builder.Services.AddScoped<PurchaseBillsApiClient>();
        builder.Services.AddScoped<VendorsApiClient>();

#if DEBUG
        builder.Services.AddBlazorWebViewDeveloperTools();
        builder.Logging.AddDebug();
#endif

        return builder.Build();
    }
}
