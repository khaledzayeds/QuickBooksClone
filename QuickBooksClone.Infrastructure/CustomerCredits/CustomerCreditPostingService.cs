using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.CustomerCredits;
using QuickBooksClone.Core.Customers;
using QuickBooksClone.Core.Invoices;

namespace QuickBooksClone.Infrastructure.CustomerCredits;

public sealed class CustomerCreditPostingService : ICustomerCreditPostingService
{
    private const string CustomerCreditRefundSourceEntityType = "CustomerCreditRefund";

    private readonly ICustomerCreditActivityRepository _activities;
    private readonly ICustomerRepository _customers;
    private readonly IInvoiceRepository _invoices;
    private readonly IAccountRepository _accounts;
    private readonly IAccountingTransactionRepository _transactions;

    public CustomerCreditPostingService(
        ICustomerCreditActivityRepository activities,
        ICustomerRepository customers,
        IInvoiceRepository invoices,
        IAccountRepository accounts,
        IAccountingTransactionRepository transactions)
    {
        _activities = activities;
        _customers = customers;
        _invoices = invoices;
        _accounts = accounts;
        _transactions = transactions;
    }

    public async Task<CustomerCreditPostingResult> PostAsync(Guid activityId, CancellationToken cancellationToken = default)
    {
        var activity = await _activities.GetByIdAsync(activityId, cancellationToken);
        if (activity is null)
        {
            return CustomerCreditPostingResult.Failure("Customer credit activity does not exist.");
        }

        if (activity.Status == CustomerCreditStatus.Void)
        {
            return CustomerCreditPostingResult.Failure("Cannot post a void customer credit activity.");
        }

        if (activity.Status == CustomerCreditStatus.Posted)
        {
            return CustomerCreditPostingResult.Success(activity.PostedTransactionId);
        }

        var customer = await _customers.GetByIdAsync(activity.CustomerId, cancellationToken);
        if (customer is null)
        {
            return CustomerCreditPostingResult.Failure("Customer does not exist.");
        }

        if (activity.Amount > customer.CreditBalance)
        {
            return CustomerCreditPostingResult.Failure($"Customer credit amount exceeds available credit. Available credit: {customer.CreditBalance:N2}.");
        }

        return activity.Action switch
        {
            CustomerCreditAction.ApplyToInvoice => await ApplyCreditToInvoiceAsync(activity, cancellationToken),
            CustomerCreditAction.Refund => await RefundCreditAsync(activity, cancellationToken),
            _ => CustomerCreditPostingResult.Failure("Unsupported customer credit action.")
        };
    }

    private async Task<CustomerCreditPostingResult> ApplyCreditToInvoiceAsync(CustomerCreditActivity activity, CancellationToken cancellationToken)
    {
        if (activity.InvoiceId is null || activity.InvoiceId == Guid.Empty)
        {
            return CustomerCreditPostingResult.Failure("Invoice is required when applying customer credit.");
        }

        var invoice = await _invoices.GetByIdAsync(activity.InvoiceId.Value, cancellationToken);
        if (invoice is null)
        {
            return CustomerCreditPostingResult.Failure("Invoice does not exist.");
        }

        if (invoice.CustomerId != activity.CustomerId)
        {
            return CustomerCreditPostingResult.Failure("Invoice customer does not match credit customer.");
        }

        if (invoice.Status is InvoiceStatus.Draft or InvoiceStatus.Void)
        {
            return CustomerCreditPostingResult.Failure("Cannot apply customer credit to a draft or void invoice.");
        }

        if (activity.Amount > invoice.BalanceDue)
        {
            return CustomerCreditPostingResult.Failure($"Credit amount exceeds invoice balance. Balance due: {invoice.BalanceDue:N2}.");
        }

        await _invoices.ApplyCreditAsync(invoice.Id, activity.Amount, cancellationToken);
        await _customers.UseCreditAsync(activity.CustomerId, activity.Amount, cancellationToken);
        await _activities.MarkPostedAsync(activity.Id, null, cancellationToken);
        return CustomerCreditPostingResult.Success();
    }

    private async Task<CustomerCreditPostingResult> RefundCreditAsync(CustomerCreditActivity activity, CancellationToken cancellationToken)
    {
        if (activity.RefundAccountId is null || activity.RefundAccountId == Guid.Empty)
        {
            return CustomerCreditPostingResult.Failure("Refund account is required.");
        }

        var refundAccount = await _accounts.GetByIdAsync(activity.RefundAccountId.Value, cancellationToken);
        if (refundAccount is null)
        {
            return CustomerCreditPostingResult.Failure("Refund account does not exist.");
        }

        if (refundAccount.AccountType is not AccountType.Bank and not AccountType.OtherCurrentAsset)
        {
            return CustomerCreditPostingResult.Failure("Refund account must be a bank or other current asset account.");
        }

        var existingTransaction = await _transactions.GetBySourceAsync(CustomerCreditRefundSourceEntityType, activity.Id, cancellationToken);
        if (existingTransaction is not null)
        {
            await _customers.UseCreditAsync(activity.CustomerId, activity.Amount, cancellationToken);
            await _activities.MarkPostedAsync(activity.Id, existingTransaction.Id, cancellationToken);
            return CustomerCreditPostingResult.Success(existingTransaction.Id);
        }

        var arAccount = await FindFirstAccountAsync(AccountType.AccountsReceivable, cancellationToken);
        if (arAccount is null)
        {
            return CustomerCreditPostingResult.Failure("Accounts Receivable account is missing.");
        }

        var transaction = new AccountingTransaction(
            "CustomerCreditRefund",
            activity.ActivityDate,
            activity.ReferenceNumber,
            CustomerCreditRefundSourceEntityType,
            activity.Id);

        transaction.AddLine(new AccountingTransactionLine(
            arAccount.Id,
            $"Refund customer credit {activity.ReferenceNumber}",
            activity.Amount,
            0));

        transaction.AddLine(new AccountingTransactionLine(
            activity.RefundAccountId.Value,
            $"Refund paid from {refundAccount.Name}",
            0,
            activity.Amount));

        var savedTransaction = await _transactions.AddAsync(transaction, cancellationToken);
        await _customers.UseCreditAsync(activity.CustomerId, activity.Amount, cancellationToken);
        await _activities.MarkPostedAsync(activity.Id, savedTransaction.Id, cancellationToken);
        return CustomerCreditPostingResult.Success(savedTransaction.Id);
    }

    private async Task<Account?> FindFirstAccountAsync(AccountType accountType, CancellationToken cancellationToken)
    {
        var result = await _accounts.SearchAsync(new AccountSearch(null, accountType, false, 1, 1), cancellationToken);
        return result.Items.FirstOrDefault();
    }
}
