using Microsoft.AspNetCore.Http;

namespace Zayed.Api.Contracts.Database;

public sealed class ImportDatabaseBackupRequest
{
    public IFormFile? File { get; init; }
    public string? Label { get; init; }
    public string? RequestedBy { get; init; }
    public string? Reason { get; init; }
}
