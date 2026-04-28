namespace QuickBooksClone.Core.Documents;

public interface IDocumentMetadataService
{
    Task<DocumentMetadata> GetOrCreateAsync(string documentType, Guid documentId, CancellationToken cancellationToken = default);

    Task<DocumentMetadata> UpdateAsync(
        string documentType,
        Guid documentId,
        string? publicMemo,
        string? internalNote,
        string? externalReference,
        string? templateName,
        string? shipToName,
        string? shipToAddressLine1,
        string? shipToAddressLine2,
        string? shipToCity,
        string? shipToRegion,
        string? shipToPostalCode,
        string? shipToCountry,
        CancellationToken cancellationToken = default);

    Task<DocumentAttachmentMetadata> AddAttachmentAsync(
        string documentType,
        Guid documentId,
        string fileName,
        string? contentType,
        long fileSizeBytes,
        string storageKey,
        CancellationToken cancellationToken = default);

    Task<bool> RemoveAttachmentAsync(string documentType, Guid documentId, Guid attachmentId, CancellationToken cancellationToken = default);
}
