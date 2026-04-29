using System.ComponentModel.DataAnnotations;
using QuickBooksClone.Core.Taxes;

namespace QuickBooksClone.Api.Contracts.Taxes;

public sealed record TaxCodeDto(
    Guid Id,
    string Code,
    string Name,
    TaxCodeScope Scope,
    decimal RatePercent,
    Guid TaxAccountId,
    string? Description,
    bool IsActive);

public sealed record TaxCodeListResponse(IReadOnlyList<TaxCodeDto> Items, int TotalCount, int Page, int PageSize);

public sealed record CreateTaxCodeRequest(
    [Required, MaxLength(40)] string Code,
    [Required, MaxLength(120)] string Name,
    TaxCodeScope Scope,
    [Range(0, 100)] decimal RatePercent,
    Guid TaxAccountId,
    [MaxLength(500)] string? Description);

public sealed record UpdateTaxCodeRequest(
    [Required, MaxLength(40)] string Code,
    [Required, MaxLength(120)] string Name,
    TaxCodeScope Scope,
    [Range(0, 100)] decimal RatePercent,
    Guid TaxAccountId,
    [MaxLength(500)] string? Description);

public sealed record SetTaxCodeActiveRequest(bool IsActive);
