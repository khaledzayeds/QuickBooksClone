namespace QuickBooksClone.Core.Estimates;

public interface IEstimateRepository
{
    Task<EstimateListResult> SearchAsync(EstimateSearch search, CancellationToken cancellationToken = default);
    Task<Estimate?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<Estimate> AddAsync(Estimate estimate, CancellationToken cancellationToken = default);
    Task<bool> MarkSentAsync(Guid id, CancellationToken cancellationToken = default);
    Task<bool> AcceptAsync(Guid id, CancellationToken cancellationToken = default);
    Task<bool> DeclineAsync(Guid id, CancellationToken cancellationToken = default);
    Task<bool> CancelAsync(Guid id, CancellationToken cancellationToken = default);
}
