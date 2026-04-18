using QuickBooksClone.Core.Customers;
using QuickBooksClone.Core.Items;
using QuickBooksClone.Core.Vendors;

namespace QuickBooksClone.Core.OpeningBalances;

public interface IOpeningBalancePostingService
{
    Task<OpeningBalancePostingResult> PostCustomerOpeningBalanceAsync(Customer customer, CancellationToken cancellationToken = default);
    Task<OpeningBalancePostingResult> PostVendorOpeningBalanceAsync(Vendor vendor, CancellationToken cancellationToken = default);
    Task<OpeningBalancePostingResult> PostItemOpeningBalanceAsync(Item item, CancellationToken cancellationToken = default);
}
