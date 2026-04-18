using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.PurchaseBills;
using QuickBooksClone.Core.VendorPayments;
using QuickBooksClone.Core.Vendors;

namespace QuickBooksClone.Infrastructure.VendorPayments;

public sealed class VendorPaymentPostingService : IVendorPaymentPostingService
{
    private const string VendorPaymentSourceEntityType = "VendorPayment";
    private const string VendorPaymentReversalSourceEntityType = "VendorPaymentReversal";

    private readonly IVendorPaymentRepository _payments;
    private readonly IPurchaseBillRepository _bills;
    private readonly IVendorRepository _vendors;
    private readonly IAccountRepository _accounts;
    private readonly IAccountingTransactionRepository _transactions;

    public VendorPaymentPostingService(
        IVendorPaymentRepository payments,
        IPurchaseBillRepository bills,
        IVendorRepository vendors,
        IAccountRepository accounts,
        IAccountingTransactionRepository transactions)
    {
        _payments = payments;
        _bills = bills;
        _vendors = vendors;
        _accounts = accounts;
        _transactions = transactions;
    }

    public async Task<VendorPaymentPostingResult> PostAsync(Guid vendorPaymentId, CancellationToken cancellationToken = default)
    {
        var payment = await _payments.GetByIdAsync(vendorPaymentId, cancellationToken);
        if (payment is null)
        {
            return VendorPaymentPostingResult.Failure("Vendor payment does not exist.");
        }

        if (payment.Status == VendorPaymentStatus.Void)
        {
            return VendorPaymentPostingResult.Failure("Cannot post a void vendor payment.");
        }

        if (payment.PostedTransactionId is not null)
        {
            return VendorPaymentPostingResult.Success(payment.PostedTransactionId.Value);
        }

        var existingTransaction = await _transactions.GetBySourceAsync(VendorPaymentSourceEntityType, payment.Id, cancellationToken);
        if (existingTransaction is not null)
        {
            await _payments.MarkPostedAsync(payment.Id, existingTransaction.Id, cancellationToken);
            return VendorPaymentPostingResult.Success(existingTransaction.Id);
        }

        var bill = await _bills.GetByIdAsync(payment.PurchaseBillId, cancellationToken);
        if (bill is null)
        {
            return VendorPaymentPostingResult.Failure("Purchase bill does not exist.");
        }

        if (bill.Status is PurchaseBillStatus.Draft or PurchaseBillStatus.Void)
        {
            return VendorPaymentPostingResult.Failure("Cannot pay a draft or void purchase bill.");
        }

        if (bill.VendorId != payment.VendorId)
        {
            return VendorPaymentPostingResult.Failure("Vendor payment does not match purchase bill vendor.");
        }

        if (payment.Amount > bill.BalanceDue)
        {
            return VendorPaymentPostingResult.Failure($"Vendor payment exceeds purchase bill balance. Balance due: {bill.BalanceDue:N2}.");
        }

        var vendor = await _vendors.GetByIdAsync(payment.VendorId, cancellationToken);
        if (vendor is null)
        {
            return VendorPaymentPostingResult.Failure("Vendor does not exist.");
        }

        if (payment.Amount > vendor.Balance)
        {
            return VendorPaymentPostingResult.Failure("Vendor payment amount exceeds vendor balance.");
        }

        var paymentAccount = await _accounts.GetByIdAsync(payment.PaymentAccountId, cancellationToken);
        if (paymentAccount is null)
        {
            return VendorPaymentPostingResult.Failure("Payment account does not exist.");
        }

        if (paymentAccount.AccountType is not AccountType.Bank and not AccountType.OtherCurrentAsset)
        {
            return VendorPaymentPostingResult.Failure("Payment account must be a bank or other current asset account.");
        }

        var apAccount = await FindFirstAccountAsync(AccountType.AccountsPayable, cancellationToken);
        if (apAccount is null)
        {
            return VendorPaymentPostingResult.Failure("Accounts Payable account is missing.");
        }

        var transaction = new AccountingTransaction(
            "VendorPayment",
            payment.PaymentDate,
            payment.PaymentNumber,
            VendorPaymentSourceEntityType,
            payment.Id);

        transaction.AddLine(new AccountingTransactionLine(
            apAccount.Id,
            $"Pay vendor bill {bill.BillNumber}",
            payment.Amount,
            0));

        transaction.AddLine(new AccountingTransactionLine(
            payment.PaymentAccountId,
            $"Vendor payment {payment.PaymentNumber}",
            0,
            payment.Amount));

        var savedTransaction = await _transactions.AddAsync(transaction, cancellationToken);
        await _bills.ApplyPaymentAsync(bill.Id, payment.Amount, cancellationToken);
        await _vendors.ApplyPaymentAsync(vendor.Id, payment.Amount, cancellationToken);
        await _payments.MarkPostedAsync(payment.Id, savedTransaction.Id, cancellationToken);
        return VendorPaymentPostingResult.Success(savedTransaction.Id);
    }

    public async Task<VendorPaymentPostingResult> VoidAsync(Guid vendorPaymentId, CancellationToken cancellationToken = default)
    {
        var payment = await _payments.GetByIdAsync(vendorPaymentId, cancellationToken);
        if (payment is null)
        {
            return VendorPaymentPostingResult.Failure("Vendor payment does not exist.");
        }

        if (payment.Status == VendorPaymentStatus.Void)
        {
            return VendorPaymentPostingResult.Success(payment.ReversalTransactionId);
        }

        if (payment.PostedTransactionId is null)
        {
            await _payments.VoidAsync(payment.Id, null, cancellationToken);
            return VendorPaymentPostingResult.Success();
        }

        var bill = await _bills.GetByIdAsync(payment.PurchaseBillId, cancellationToken);
        if (bill is null)
        {
            return VendorPaymentPostingResult.Failure("Purchase bill does not exist.");
        }

        var vendor = await _vendors.GetByIdAsync(payment.VendorId, cancellationToken);
        if (vendor is null)
        {
            return VendorPaymentPostingResult.Failure("Vendor does not exist.");
        }

        var existingReversal = await _transactions.GetBySourceAsync(VendorPaymentReversalSourceEntityType, payment.Id, cancellationToken);
        if (existingReversal is not null)
        {
            await _payments.VoidAsync(payment.Id, existingReversal.Id, cancellationToken);
            return VendorPaymentPostingResult.Success(existingReversal.Id);
        }

        var originalTransaction = await _transactions.GetByIdAsync(payment.PostedTransactionId.Value, cancellationToken);
        if (originalTransaction is null)
        {
            return VendorPaymentPostingResult.Failure("Posted vendor payment transaction is missing.");
        }

        if (payment.Amount > bill.PaidAmount)
        {
            return VendorPaymentPostingResult.Failure("Vendor payment reversal amount exceeds purchase bill paid amount.");
        }

        var reversalTransaction = BuildReversalTransaction(payment, originalTransaction);
        var savedReversal = await _transactions.AddAsync(reversalTransaction, cancellationToken);

        await _bills.ReversePaymentAsync(bill.Id, payment.Amount, cancellationToken);
        await _vendors.ReversePaymentAsync(vendor.Id, payment.Amount, cancellationToken);
        await _payments.VoidAsync(payment.Id, savedReversal.Id, cancellationToken);
        return VendorPaymentPostingResult.Success(savedReversal.Id);
    }

    private static AccountingTransaction BuildReversalTransaction(
        VendorPayment payment,
        AccountingTransaction originalTransaction)
    {
        var transaction = new AccountingTransaction(
            "VendorPaymentReversal",
            DateOnly.FromDateTime(DateTime.UtcNow),
            $"{payment.PaymentNumber}-VOID",
            VendorPaymentReversalSourceEntityType,
            payment.Id);

        foreach (var line in originalTransaction.Lines)
        {
            transaction.AddLine(new AccountingTransactionLine(
                line.AccountId,
                $"Reversal - {line.Description}",
                line.Credit,
                line.Debit));
        }

        return transaction;
    }

    private async Task<Account?> FindFirstAccountAsync(AccountType accountType, CancellationToken cancellationToken)
    {
        var result = await _accounts.SearchAsync(new AccountSearch(null, accountType, false, 1, 1), cancellationToken);
        return result.Items.FirstOrDefault();
    }
}
