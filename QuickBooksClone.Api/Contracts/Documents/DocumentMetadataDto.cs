using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Api.Contracts.Documents;

public sealed record DocumentMetadataDto(
    Guid Id,
    string DocumentType,
    Guid DocumentId,
    string DocumentNo,
    string DeviceId,
    SyncStatus SyncStatus,
    long SyncVersion,
    DateTimeOffset LastModifiedAt,
    string? PublicMemo,
    string? InternalNote,
    string? ExternalReference,
    string? TemplateName,
    string? ShipToName,
    string? ShipToAddressLine1,
    string? ShipToAddressLine2,
    string? ShipToCity,
    string? ShipToRegion,
    string? ShipToPostalCode,
    string? ShipToCountry,
    IReadOnlyList<DocumentAttachmentDto> Attachments);

public sealed record DocumentAttachmentDto(
    Guid Id,
    string FileName,
    string ContentType,
    long FileSizeBytes,
    string StorageKey,
    DateTimeOffset UploadedAt);
