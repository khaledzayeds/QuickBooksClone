namespace QuickBooksClone.Maui.Services;

public sealed class ApiConnectionSettings
{
    public ApiConnectionMode StartupProfile { get; set; } = ApiConnectionMode.Local;
    public string LocalUrl { get; set; } = "http://localhost:5014";
    public string LanUrl { get; set; } = "http://192.168.1.10:5014";
    public string HostedUrl { get; set; } = "https://api.example.com";

    public string GetActiveBaseUrl() =>
        StartupProfile switch
        {
            ApiConnectionMode.Local => LocalUrl,
            ApiConnectionMode.Lan => LanUrl,
            ApiConnectionMode.Hosted => HostedUrl,
            _ => LocalUrl
        };
}
