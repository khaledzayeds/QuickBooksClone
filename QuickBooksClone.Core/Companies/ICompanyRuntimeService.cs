namespace QuickBooksClone.Core.Companies;

public interface ICompanyRuntimeService
{
    Task<ActiveCompanyRuntime> GetActiveAsync(CancellationToken cancellationToken = default);

    Task<ActiveCompanyRuntime> OpenAsync(
        Guid companyId,
        string companyName,
        string databasePath,
        CancellationToken cancellationToken = default);

    Task<ActiveCompanyRuntime> CloseAsync(CancellationToken cancellationToken = default);
}
