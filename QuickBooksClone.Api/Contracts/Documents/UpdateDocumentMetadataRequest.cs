using System.ComponentModel.DataAnnotations;

namespace QuickBooksClone.Api.Contracts.Documents;

public sealed record UpdateDocumentMetadataRequest(
    [MaxLength(1000)] string? PublicMemo,
    [MaxLength(2000)] string? InternalNote,
    [MaxLength(120)] string? ExternalReference,
    [MaxLength(120)] string? TemplateName,
    [MaxLength(200)] string? ShipToName,
    [MaxLength(200)] string? ShipToAddressLine1,
    [MaxLength(200)] string? ShipToAddressLine2,
    [MaxLength(120)] string? ShipToCity,
    [MaxLength(120)] string? ShipToRegion,
    [MaxLength(40)] string? ShipToPostalCode,
    [MaxLength(120)] string? ShipToCountry);
