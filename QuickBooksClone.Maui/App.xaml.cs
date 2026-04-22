using Microsoft.Extensions.DependencyInjection;

namespace QuickBooksClone.Maui;

public partial class App : Application
{
    private readonly IServiceProvider _services;

    public App(IServiceProvider services)
    {
        _services = services;
        InitializeComponent();
    }

    protected override Window CreateWindow(IActivationState? activationState)
    {
        var mainPage = _services.GetRequiredService<MainPage>();
        return new Window(mainPage) { Title = "QuickBooksClone" };
    }
}
