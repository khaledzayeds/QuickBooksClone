using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Invoices;
using QuickBooksClone.Core.Items;

namespace QuickBooksClone.Infrastructure.Invoices;

public sealed class SalesInvoicePostingService : ISalesInvoicePostingService
{
    private readonly IInvoiceRepository _invoices;
    private readonly IItemRepository _items;
    private readonly IAccountRepository _accounts;
    private readonly IAccountingTransactionRepository _transactions;

    public SalesInvoicePostingService(
        IInvoiceRepository invoices,
        IItemRepository items,
        IAccountRepository accounts,
        IAccountingTransactionRepository transactions)
    {
        _invoices = invoices;
        _items = items;
        _accounts = accounts;
        _transactions = transactions;
    }

    public async Task<InvoicePostingResult> PostAsync(Guid invoiceId, CancellationToken cancellationToken = default)
    {
        var invoice = await _invoices.GetByIdAsync(invoiceId, cancellationToken);
        if (invoice is null)
        {
            return InvoicePostingResult.Failure("Invoice does not exist.");
        }

        if (invoice.PostedTransactionId is not null)
        {
            return InvoicePostingResult.Success(invoice.PostedTransactionId.Value);
        }

        if (invoice.Status == InvoiceStatus.Void)
        {
            return InvoicePostingResult.Failure("Cannot post a void invoice.");
        }

        var existingTransaction = await _transactions.GetBySourceAsync("Invoice", invoice.Id, cancellationToken);
        if (existingTransaction is not null)
        {
            await _invoices.MarkPostedAsync(invoice.Id, existingTransaction.Id, cancellationToken);
            return InvoicePostingResult.Success(existingTransaction.Id);
        }

        if (invoice.Lines.Count == 0)
        {
            return InvoicePostingResult.Failure("Invoice must have at least one line.");
        }

        var arAccount = await FindFirstAccountAsync(AccountType.AccountsReceivable, cancellationToken);
        if (arAccount is null)
        {
            return InvoicePostingResult.Failure("Accounts Receivable account is missing.");
        }

        var lineItems = new List<(InvoiceLine Line, Item Item)>();
        foreach (var line in invoice.Lines)
        {
            var item = await _items.GetByIdAsync(line.ItemId, cancellationToken);
            if (item is null)
            {
                return InvoicePostingResult.Failure($"Item does not exist: {line.ItemId}");
            }

            if (item.IncomeAccountId is null)
            {
                return InvoicePostingResult.Failure($"Item '{item.Name}' is missing an income account.");
            }

            if (item.ItemType == ItemType.Inventory)
            {
                if (item.CogsAccountId is null || item.InventoryAssetAccountId is null)
                {
                    return InvoicePostingResult.Failure($"Inventory item '{item.Name}' is missing COGS or inventory asset account.");
                }

                if (item.QuantityOnHand < line.Quantity)
                {
                    return InvoicePostingResult.Failure($"Not enough stock for '{item.Name}'. Available: {item.QuantityOnHand:N2}, required: {line.Quantity:N2}.");
                }
            }

            lineItems.Add((line, item));
        }

        var transaction = BuildAccountingTransaction(invoice, arAccount.Id, lineItems);
        var savedTransaction = await _transactions.AddAsync(transaction, cancellationToken);

        foreach (var (line, item) in lineItems.Where(current => current.Item.ItemType == ItemType.Inventory))
        {
            await _items.DecreaseQuantityAsync(item.Id, line.Quantity, cancellationToken);
        }

        await _invoices.MarkPostedAsync(invoice.Id, savedTransaction.Id, cancellationToken);
        return InvoicePostingResult.Success(savedTransaction.Id);
    }

    private static AccountingTransaction BuildAccountingTransaction(
        Invoice invoice,
        Guid accountsReceivableAccountId,
        IReadOnlyList<(InvoiceLine Line, Item Item)> lineItems)
    {
        var transaction = new AccountingTransaction(
            "Invoice",
            invoice.InvoiceDate,
            invoice.InvoiceNumber,
            "Invoice",
            invoice.Id);

        transaction.AddLine(new AccountingTransactionLine(
            accountsReceivableAccountId,
            $"Invoice {invoice.InvoiceNumber}",
            invoice.TotalAmount,
            0));

        foreach (var (line, item) in lineItems)
        {
            transaction.AddLine(new AccountingTransactionLine(
                item.IncomeAccountId!.Value,
                line.Description,
                0,
                line.LineTotal));

            if (item.ItemType != ItemType.Inventory)
            {
                continue;
            }

            var costAmount = item.PurchasePrice * line.Quantity;
            if (costAmount <= 0)
            {
                continue;
            }

            transaction.AddLine(new AccountingTransactionLine(
                item.CogsAccountId!.Value,
                $"COGS - {line.Description}",
                costAmount,
                0));

            transaction.AddLine(new AccountingTransactionLine(
                item.InventoryAssetAccountId!.Value,
                $"Inventory relief - {line.Description}",
                0,
                costAmount));
        }

        return transaction;
    }

    private async Task<Account?> FindFirstAccountAsync(AccountType accountType, CancellationToken cancellationToken)
    {
        var result = await _accounts.SearchAsync(new AccountSearch(null, accountType, false, 1, 1), cancellationToken);
        return result.Items.FirstOrDefault();
    }
}
