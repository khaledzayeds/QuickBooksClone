using Zayed.Core.Customers;
using Zayed.Core.Items;
using Zayed.Core.Vendors;

namespace Zayed.Core.OpeningBalances;

public interface IOpeningBalancePostingService
{
    Task<OpeningBalancePostingResult> PostCustomerOpeningBalanceAsync(Customer customer, CancellationToken cancellationToken = default);
    Task<OpeningBalancePostingResult> PostVendorOpeningBalanceAsync(Vendor vendor, CancellationToken cancellationToken = default);
    Task<OpeningBalancePostingResult> PostItemOpeningBalanceAsync(Item item, CancellationToken cancellationToken = default);
}
