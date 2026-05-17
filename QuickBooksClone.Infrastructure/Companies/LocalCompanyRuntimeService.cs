using Microsoft.Extensions.Configuration;
using QuickBooksClone.Core.Companies;

namespace QuickBooksClone.Infrastructure.Companies;

public sealed class LocalCompanyRuntimeService : ICompanyRuntimeService
{
    private readonly object _gate = new();
    private readonly string _fallbackDatabasePath;
    private readonly HashSet<Guid> _initializedCompanies = [];
    private ActiveCompanyRuntime? _active;

    public LocalCompanyRuntimeService(IConfiguration configuration)
    {
        _fallbackDatabasePath = configuration.GetConnectionString("LedgerFlow")
            ?? configuration.GetConnectionString("QuickBooksClone")
            ?? "Data Source=ledgerflow.db";
    }

    public ActiveCompanyRuntime Current
    {
        get
        {
            lock (_gate)
            {
                return BuildInactiveRuntime();
            }
        }
    }

    public Task<ActiveCompanyRuntime> GetActiveAsync(CancellationToken cancellationToken = default)
    {
        lock (_gate)
        {
            return Task.FromResult(BuildInactiveRuntime());
        }
    }

    public Task<ActiveCompanyRuntime> OpenAsync(
        Guid companyId,
        string companyName,
        string databasePath,
        CancellationToken cancellationToken = default)
    {
        if (companyId == Guid.Empty)
        {
            throw new ArgumentException("Company id is required.", nameof(companyId));
        }

        if (string.IsNullOrWhiteSpace(companyName))
        {
            throw new ArgumentException("Company name is required.", nameof(companyName));
        }

        if (string.IsNullOrWhiteSpace(databasePath))
        {
            throw new ArgumentException("Database path is required.", nameof(databasePath));
        }

        lock (_gate)
        {
            _active = new ActiveCompanyRuntime(
                companyId,
                companyName.Trim(),
                NormalizeDatabasePath(databasePath),
                IsActive: true,
                OpenedAtUtc: DateTimeOffset.UtcNow,
                IsSetupInitialized: _initializedCompanies.Contains(companyId));

            return Task.FromResult(_active);
        }
    }

    public Task<ActiveCompanyRuntime> CloseAsync(CancellationToken cancellationToken = default)
    {
        lock (_gate)
        {
            _active = null;
            return Task.FromResult(BuildInactiveRuntime());
        }
    }

    public Task<ActiveCompanyRuntime> MarkSetupInitializedAsync(CancellationToken cancellationToken = default)
    {
        lock (_gate)
        {
            if (_active?.CompanyId is not Guid companyId || !_active.IsActive)
            {
                throw new InvalidOperationException("No active company is open.");
            }

            _initializedCompanies.Add(companyId);
            _active = _active with { IsSetupInitialized = true };
            return Task.FromResult(_active);
        }
    }

    private static string NormalizeDatabasePath(string value)
    {
        var trimmed = value.Trim();
        const string prefix = "Data Source=";
        return trimmed.StartsWith(prefix, StringComparison.OrdinalIgnoreCase)
            ? trimmed[prefix.Length..]
            : trimmed;
    }

    private ActiveCompanyRuntime BuildInactiveRuntime()
    {
        return _active ?? new ActiveCompanyRuntime(
            CompanyId: null,
            CompanyName: null,
            DatabasePath: NormalizeDatabasePath(_fallbackDatabasePath),
            IsActive: false,
            OpenedAtUtc: null,
            IsSetupInitialized: false);
    }
}
