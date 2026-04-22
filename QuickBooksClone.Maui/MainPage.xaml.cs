using QuickBooksClone.Maui.Services.Settings;

namespace QuickBooksClone.Maui;

public partial class MainPage : ContentPage
{
    private readonly AppStartupCoordinator _startupCoordinator;

    public MainPage(AppStartupCoordinator startupCoordinator)
    {
        _startupCoordinator = startupCoordinator;
        InitializeComponent();
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();

        try
        {
            await _startupCoordinator.EnsureReadyAsync();
        }
        catch
        {
            // Home renders the startup/offline state, so the shell can stay alive here.
        }
    }
}
