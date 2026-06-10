namespace Zayed.Core.Companies;

public static class BusinessTypes
{
    public const string Retail = "retail";
    public const string HotelTourism = "hotel_tourism";
    public const string Services = "services";
    public const string Mixed = "mixed";

    public static readonly IReadOnlySet<string> Supported = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
    {
        Retail,
        HotelTourism,
        Services,
        Mixed
    };

    public static string NormalizeOrDefault(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return Retail;
        }

        var normalized = value.Trim().ToLowerInvariant();
        return Supported.Contains(normalized) ? normalized : throw new ArgumentException($"Unsupported business type '{value}'.", nameof(value));
    }

    public static bool IsSupported(string? value)
    {
        return !string.IsNullOrWhiteSpace(value) && Supported.Contains(value.Trim());
    }
}
