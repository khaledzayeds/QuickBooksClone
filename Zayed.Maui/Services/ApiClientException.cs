namespace Zayed.Maui.Services;

public sealed class ApiClientException : Exception
{
    public ApiClientException(string message)
        : base(message)
    {
    }
}
