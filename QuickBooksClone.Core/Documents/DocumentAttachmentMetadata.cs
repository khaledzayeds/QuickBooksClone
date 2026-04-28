using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.Documents;

public sealed class DocumentAttachmentMetadata : EntityBase
{
    private DocumentAttachmentMetadata()
    {
        FileName = string.Empty;
        ContentType = string.Empty;
        StorageKey = string.Empty;
    }

    public DocumentAttachmentMetadata(string fileName, string? contentType, long fileSizeBytes, string storageKey)
    {
        FileName = NormalizeRequired(fileName, nameof(fileName), 260);
        ContentType = NormalizeOptional(contentType, 120) ?? "application/octet-stream";
        StorageKey = NormalizeRequired(storageKey, nameof(storageKey), 500);

        if (fileSizeBytes < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(fileSizeBytes), "File size cannot be negative.");
        }

        FileSizeBytes = fileSizeBytes;
        UploadedAt = DateTimeOffset.UtcNow;
    }

    public string FileName { get; private set; }
    public string ContentType { get; private set; }
    public long FileSizeBytes { get; private set; }
    public string StorageKey { get; private set; }
    public DateTimeOffset UploadedAt { get; private set; }

    private static string NormalizeRequired(string value, string parameterName, int maxLength)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException("Value is required.", parameterName);
        }

        var normalized = value.Trim();
        if (normalized.Length > maxLength)
        {
            throw new ArgumentOutOfRangeException(parameterName, $"Value must be {maxLength} characters or fewer.");
        }

        return normalized;
    }

    private static string? NormalizeOptional(string? value, int maxLength)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        var normalized = value.Trim();
        if (normalized.Length > maxLength)
        {
            throw new ArgumentOutOfRangeException(nameof(value), $"Value must be {maxLength} characters or fewer.");
        }

        return normalized;
    }
}
