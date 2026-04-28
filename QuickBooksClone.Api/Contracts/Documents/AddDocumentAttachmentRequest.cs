using System.ComponentModel.DataAnnotations;

namespace QuickBooksClone.Api.Contracts.Documents;

public sealed record AddDocumentAttachmentRequest(
    [Required, MaxLength(260)] string FileName,
    [MaxLength(120)] string? ContentType,
    [Range(0, long.MaxValue)] long FileSizeBytes,
    [Required, MaxLength(500)] string StorageKey);
