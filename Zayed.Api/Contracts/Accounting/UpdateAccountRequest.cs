using System.ComponentModel.DataAnnotations;
using Zayed.Core.Accounting;

namespace Zayed.Api.Contracts.Accounting;

public sealed record UpdateAccountRequest(
    [Required, MaxLength(20)] string Code,
    [Required, MaxLength(150)] string Name,
    AccountType AccountType,
    [MaxLength(500)] string? Description,
    Guid? ParentId);
