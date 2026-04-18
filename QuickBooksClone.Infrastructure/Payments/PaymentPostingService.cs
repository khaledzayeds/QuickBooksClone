using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Invoices;
using QuickBooksClone.Core.Payments;

namespace QuickBooksClone.Infrastructure.Payments;

public sealed class PaymentPostingService : IPaymentPostingService
{
    private const string PaymentSourceEntityType = "Payment";

    private readonly IPaymentRepository _payments;
    private readonly IInvoiceRepository _invoices;
    private readonly IAccountRepository _accounts;
    private readonly IAccountingTransactionRepository _transactions;

    public PaymentPostingService(
        IPaymentRepository payments,
        IInvoiceRepository invoices,
        IAccountRepository accounts,
        IAccountingTransactionRepository transactions)
    {
        _payments = payments;
        _invoices = invoices;
        _accounts = accounts;
        _transactions = transactions;
    }

    public async Task<PaymentPostingResult> PostAsync(Guid paymentId, CancellationToken cancellationToken = default)
    {
        var payment = await _payments.GetByIdAsync(paymentId, cancellationToken);
        if (payment is null)
        {
            return PaymentPostingResult.Failure("Payment does not exist.");
        }

        if (payment.PostedTransactionId is not null)
        {
            return PaymentPostingResult.Success(payment.PostedTransactionId.Value);
        }

        var existingTransaction = await _transactions.GetBySourceAsync(PaymentSourceEntityType, payment.Id, cancellationToken);
        if (existingTransaction is not null)
        {
            await _payments.MarkPostedAsync(payment.Id, existingTransaction.Id, cancellationToken);
            return PaymentPostingResult.Success(existingTransaction.Id);
        }

        var invoice = await _invoices.GetByIdAsync(payment.InvoiceId, cancellationToken);
        if (invoice is null)
        {
            return PaymentPostingResult.Failure("Invoice does not exist.");
        }

        if (invoice.Status is InvoiceStatus.Draft or InvoiceStatus.Void)
        {
            return PaymentPostingResult.Failure("Cannot receive a payment for a draft or void invoice.");
        }

        if (invoice.CustomerId != payment.CustomerId)
        {
            return PaymentPostingResult.Failure("Payment customer does not match invoice customer.");
        }

        if (payment.Amount > invoice.BalanceDue)
        {
            return PaymentPostingResult.Failure($"Payment amount exceeds invoice balance. Balance due: {invoice.BalanceDue:N2}.");
        }

        var depositAccount = await _accounts.GetByIdAsync(payment.DepositAccountId, cancellationToken);
        if (depositAccount is null)
        {
            return PaymentPostingResult.Failure("Deposit account does not exist.");
        }

        if (depositAccount.AccountType is not AccountType.Bank and not AccountType.OtherCurrentAsset)
        {
            return PaymentPostingResult.Failure("Deposit account must be a bank or other current asset account.");
        }

        var arAccount = await FindFirstAccountAsync(AccountType.AccountsReceivable, cancellationToken);
        if (arAccount is null)
        {
            return PaymentPostingResult.Failure("Accounts Receivable account is missing.");
        }

        var transaction = new AccountingTransaction(
            "Payment",
            payment.PaymentDate,
            payment.PaymentNumber,
            PaymentSourceEntityType,
            payment.Id);

        transaction.AddLine(new AccountingTransactionLine(
            payment.DepositAccountId,
            $"Receive payment {payment.PaymentNumber}",
            payment.Amount,
            0));

        transaction.AddLine(new AccountingTransactionLine(
            arAccount.Id,
            $"Apply payment to invoice {invoice.InvoiceNumber}",
            0,
            payment.Amount));

        var savedTransaction = await _transactions.AddAsync(transaction, cancellationToken);
        await _invoices.ApplyPaymentAsync(invoice.Id, payment.Amount, cancellationToken);
        await _payments.MarkPostedAsync(payment.Id, savedTransaction.Id, cancellationToken);
        return PaymentPostingResult.Success(savedTransaction.Id);
    }

    private async Task<Account?> FindFirstAccountAsync(AccountType accountType, CancellationToken cancellationToken)
    {
        var result = await _accounts.SearchAsync(new AccountSearch(null, accountType, false, 1, 1), cancellationToken);
        return result.Items.FirstOrDefault();
    }
}
