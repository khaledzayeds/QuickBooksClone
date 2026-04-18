using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.PurchaseBills;
using QuickBooksClone.Core.VendorCredits;
using QuickBooksClone.Core.Vendors;

namespace QuickBooksClone.Infrastructure.VendorCredits;

public sealed class VendorCreditPostingService : IVendorCreditPostingService
{
    private const string VendorCreditRefundSourceEntityType = "VendorCreditRefund";

    private readonly IVendorCreditActivityRepository _activities;
    private readonly IVendorRepository _vendors;
    private readonly IPurchaseBillRepository _bills;
    private readonly IAccountRepository _accounts;
    private readonly IAccountingTransactionRepository _transactions;

    public VendorCreditPostingService(IVendorCreditActivityRepository activities, IVendorRepository vendors, IPurchaseBillRepository bills, IAccountRepository accounts, IAccountingTransactionRepository transactions)
    {
        _activities = activities;
        _vendors = vendors;
        _bills = bills;
        _accounts = accounts;
        _transactions = transactions;
    }

    public async Task<VendorCreditPostingResult> PostAsync(Guid activityId, CancellationToken cancellationToken = default)
    {
        var activity = await _activities.GetByIdAsync(activityId, cancellationToken);
        if (activity is null) return VendorCreditPostingResult.Failure("Vendor credit activity does not exist.");
        if (activity.Status == VendorCreditStatus.Void) return VendorCreditPostingResult.Failure("Cannot post a void vendor credit activity.");
        if (activity.Status == VendorCreditStatus.Posted) return VendorCreditPostingResult.Success(activity.PostedTransactionId);

        var vendor = await _vendors.GetByIdAsync(activity.VendorId, cancellationToken);
        if (vendor is null) return VendorCreditPostingResult.Failure("Vendor does not exist.");
        if (activity.Amount > vendor.CreditBalance) return VendorCreditPostingResult.Failure($"Vendor credit amount exceeds available credit. Available credit: {vendor.CreditBalance:N2}.");

        return activity.Action switch
        {
            VendorCreditAction.ApplyToBill => await ApplyCreditToBillAsync(activity, cancellationToken),
            VendorCreditAction.RefundReceipt => await ReceiveRefundAsync(activity, cancellationToken),
            _ => VendorCreditPostingResult.Failure("Unsupported vendor credit action.")
        };
    }

    private async Task<VendorCreditPostingResult> ApplyCreditToBillAsync(VendorCreditActivity activity, CancellationToken cancellationToken)
    {
        if (activity.PurchaseBillId is null || activity.PurchaseBillId == Guid.Empty) return VendorCreditPostingResult.Failure("Purchase bill is required when applying vendor credit.");
        var bill = await _bills.GetByIdAsync(activity.PurchaseBillId.Value, cancellationToken);
        if (bill is null) return VendorCreditPostingResult.Failure("Purchase bill does not exist.");
        if (bill.VendorId != activity.VendorId) return VendorCreditPostingResult.Failure("Purchase bill vendor does not match credit vendor.");
        if (bill.Status is PurchaseBillStatus.Draft or PurchaseBillStatus.Void) return VendorCreditPostingResult.Failure("Cannot apply vendor credit to a draft or void purchase bill.");
        if (activity.Amount > bill.BalanceDue) return VendorCreditPostingResult.Failure($"Credit amount exceeds purchase bill balance. Balance due: {bill.BalanceDue:N2}.");

        await _bills.ApplyCreditAsync(bill.Id, activity.Amount, cancellationToken);
        await _vendors.UseCreditAsync(activity.VendorId, activity.Amount, cancellationToken);
        await _activities.MarkPostedAsync(activity.Id, null, cancellationToken);
        return VendorCreditPostingResult.Success();
    }

    private async Task<VendorCreditPostingResult> ReceiveRefundAsync(VendorCreditActivity activity, CancellationToken cancellationToken)
    {
        if (activity.DepositAccountId is null || activity.DepositAccountId == Guid.Empty) return VendorCreditPostingResult.Failure("Deposit account is required.");
        var depositAccount = await _accounts.GetByIdAsync(activity.DepositAccountId.Value, cancellationToken);
        if (depositAccount is null) return VendorCreditPostingResult.Failure("Deposit account does not exist.");
        if (depositAccount.AccountType is not AccountType.Bank and not AccountType.OtherCurrentAsset) return VendorCreditPostingResult.Failure("Deposit account must be a bank or other current asset account.");

        var existingTransaction = await _transactions.GetBySourceAsync(VendorCreditRefundSourceEntityType, activity.Id, cancellationToken);
        if (existingTransaction is not null)
        {
            await _vendors.UseCreditAsync(activity.VendorId, activity.Amount, cancellationToken);
            await _activities.MarkPostedAsync(activity.Id, existingTransaction.Id, cancellationToken);
            return VendorCreditPostingResult.Success(existingTransaction.Id);
        }

        var apAccount = await FindFirstAccountAsync(AccountType.AccountsPayable, cancellationToken);
        if (apAccount is null) return VendorCreditPostingResult.Failure("Accounts Payable account is missing.");

        var transaction = new AccountingTransaction("VendorCreditRefund", activity.ActivityDate, activity.ReferenceNumber, VendorCreditRefundSourceEntityType, activity.Id);
        transaction.AddLine(new AccountingTransactionLine(activity.DepositAccountId.Value, $"Vendor refund receipt {activity.ReferenceNumber}", activity.Amount, 0));
        transaction.AddLine(new AccountingTransactionLine(apAccount.Id, $"Clear vendor credit {activity.ReferenceNumber}", 0, activity.Amount));

        var savedTransaction = await _transactions.AddAsync(transaction, cancellationToken);
        await _vendors.UseCreditAsync(activity.VendorId, activity.Amount, cancellationToken);
        await _activities.MarkPostedAsync(activity.Id, savedTransaction.Id, cancellationToken);
        return VendorCreditPostingResult.Success(savedTransaction.Id);
    }

    private async Task<Account?> FindFirstAccountAsync(AccountType accountType, CancellationToken cancellationToken)
    {
        var result = await _accounts.SearchAsync(new AccountSearch(null, accountType, false, 1, 1), cancellationToken);
        return result.Items.FirstOrDefault();
    }
}
