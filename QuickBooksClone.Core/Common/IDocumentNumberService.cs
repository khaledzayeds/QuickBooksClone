namespace QuickBooksClone.Core.Common;

public interface IDocumentNumberService
{
    Task<DocumentNumberAllocation> AllocateAsync(string documentType, CancellationToken cancellationToken = default);
}
