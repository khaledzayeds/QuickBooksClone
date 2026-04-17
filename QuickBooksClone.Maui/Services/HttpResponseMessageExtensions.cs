using System.Net.Http.Json;
using System.Text.Json;

namespace QuickBooksClone.Maui.Services;

public static class HttpResponseMessageExtensions
{
    public static async Task EnsureQuickBooksSuccessAsync(this HttpResponseMessage response, CancellationToken cancellationToken = default)
    {
        if (response.IsSuccessStatusCode)
        {
            return;
        }

        var message = await ReadErrorMessageAsync(response, cancellationToken);
        throw new ApiClientException(message);
    }

    private static async Task<string> ReadErrorMessageAsync(HttpResponseMessage response, CancellationToken cancellationToken)
    {
        try
        {
            var problem = await response.Content.ReadFromJsonAsync<JsonElement>(cancellationToken);
            if (problem.TryGetProperty("errors", out var errors))
            {
                var messages = new List<string>();
                foreach (var property in errors.EnumerateObject())
                {
                    foreach (var message in property.Value.EnumerateArray())
                    {
                        var messageText = message.GetString();
                        if (!string.IsNullOrWhiteSpace(messageText))
                        {
                            messages.Add(messageText);
                        }
                    }
                }

                if (messages.Count > 0)
                {
                    return string.Join(" ", messages);
                }
            }

            if (problem.TryGetProperty("title", out var title))
            {
                var titleText = title.GetString();
                if (!string.IsNullOrWhiteSpace(titleText))
                {
                    return titleText;
                }
            }
        }
        catch
        {
            // Some API errors are plain text; fall back below.
        }

        var text = await response.Content.ReadAsStringAsync(cancellationToken);
        if (!string.IsNullOrWhiteSpace(text))
        {
            return text.Trim('"', ' ', '\r', '\n');
        }

        return $"Request failed with status {(int)response.StatusCode}.";
    }
}
