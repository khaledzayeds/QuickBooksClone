namespace QuickBooksClone.Maui.Services;

public sealed class ConfigurableApiMessageHandler : DelegatingHandler
{
    private readonly ApiConnectionSettingsStore _settingsStore;

    public ConfigurableApiMessageHandler(ApiConnectionSettingsStore settingsStore)
    {
        _settingsStore = settingsStore;
    }

    protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
    {
        if (request.RequestUri is not null)
        {
            var activeBaseUrl = _settingsStore.CurrentBaseUrl;
            if (!string.IsNullOrWhiteSpace(activeBaseUrl))
            {
                var baseUri = new Uri($"{activeBaseUrl}/", UriKind.Absolute);
                var targetPath = request.RequestUri.IsAbsoluteUri
                    ? request.RequestUri.PathAndQuery.TrimStart('/')
                    : request.RequestUri.OriginalString.TrimStart('/');

                request.RequestUri = new Uri(baseUri, targetPath);
            }
        }

        return base.SendAsync(request, cancellationToken);
    }
}
