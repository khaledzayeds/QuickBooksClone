using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.Settings;

public sealed class DocumentSequenceCounter : EntityBase
{
    private DocumentSequenceCounter()
    {
        DeviceId = string.Empty;
        DocumentType = string.Empty;
    }

    public DocumentSequenceCounter(string deviceId, string documentType, int year, int nextSequence = 1)
    {
        DeviceId = NormalizeRequired(deviceId, nameof(deviceId)).ToUpperInvariant();
        DocumentType = NormalizeRequired(documentType, nameof(documentType)).ToUpperInvariant();
        Year = year;
        NextSequence = nextSequence < 1 ? 1 : nextSequence;
    }

    public string DeviceId { get; private set; }
    public string DocumentType { get; private set; }
    public int Year { get; private set; }
    public int NextSequence { get; private set; }

    public int ReserveNext()
    {
        var current = NextSequence;
        NextSequence++;
        UpdatedAt = DateTimeOffset.UtcNow;
        return current;
    }

    private static string NormalizeRequired(string value, string parameterName)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException("Value is required.", parameterName);
        }

        return value.Trim();
    }
}
