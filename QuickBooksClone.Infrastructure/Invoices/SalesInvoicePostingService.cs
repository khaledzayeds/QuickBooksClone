using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Customers;
using QuickBooksClone.Core.Invoices;
using QuickBooksClone.Core.Items;
using QuickBooksClone.Core.Taxes;

namespace QuickBooksClone.Infrastructure.Invoices;

public sealed class SalesInvoicePostingService : ISalesInvoicePostingService
{
    private const string InvoiceSourceEntityType = "Invoice";
    private const string InvoiceReversalSourceEntityType = "InvoiceReversal";

    private readonly IInvoiceRepository _invoices;
    private readonly ICustomerRepository _customers;
    private readonly IItemRepository _items;
    private readonly IAccountRepository _accounts;
    private readonly IAccountingTransactionRepository _transactions;
    private readonly ITaxCodeRepository _taxCodes;

    public SalesInvoicePostingService(
        IInvoiceRepository invoices,
        ICustomerRepository customers,
        IItemRepository items,
        IAccountRepository accounts,
        IAccountingTransactionRepository transactions,
        ITaxCodeRepository taxCodes)
    {
        _invoices = invoices;
        _customers = customers;
        _items = items;
        _accounts = accounts;
        _transactions = transactions;
        _taxCodes = taxCodes;
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

        var existingTransaction = await _transactions.GetBySourceAsync(InvoiceSourceEntityType, invoice.Id, cancellationToken);
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
        var taxCodesById = new Dictionary<Guid, TaxCode>();
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

            if (line.TaxAmount > 0)
            {
                if (line.TaxCodeId is null)
                {
                    return InvoicePostingResult.Failure("Taxed invoice lines must have a tax code.");
                }

                var taxCode = await _taxCodes.GetByIdAsync(line.TaxCodeId.Value, cancellationToken);
                if (taxCode is null || !taxCode.IsActive || !taxCode.CanApplyTo(TaxTransactionType.Sales))
                {
                    return InvoicePostingResult.Failure("Invoice tax code is missing, inactive, or not valid for sales.");
                }

                taxCodesById[taxCode.Id] = taxCode;
            }

            lineItems.Add((line, item));
        }

        var transaction = BuildAccountingTransaction(invoice, arAccount.Id, lineItems, taxCodesById);
        var savedTransaction = await _transactions.AddAsync(transaction, cancellationToken);

        foreach (var (line, item) in lineItems.Where(current => current.Item.ItemType == ItemType.Inventory))
        {
            await _items.DecreaseQuantityAsync(item.Id, line.Quantity, cancellationToken);
        }

        await _invoices.MarkPostedAsync(invoice.Id, savedTransaction.Id, cancellationToken);
        await _customers.ApplyInvoiceAsync(invoice.CustomerId, invoice.TotalAmount, cancellationToken);
        return InvoicePostingResult.Success(savedTransaction.Id);
    }

    public async Task<InvoicePostingResult> VoidAsync(Guid invoiceId, CancellationToken cancellationToken = default)
    {
        var invoice = await _invoices.GetByIdAsync(invoiceId, cancellationToken);
        if (invoice is null)
        {
            return InvoicePostingResult.Failure("Invoice does not exist.");
        }

        if (invoice.Status == InvoiceStatus.Void)
        {
            return InvoicePostingResult.Success(invoice.ReversalTransactionId);
        }

        if (invoice.PostedTransactionId is null)
        {
            await _invoices.VoidAsync(invoice.Id, null, cancellationToken);
            return InvoicePostingResult.Success();
        }

        if (invoice.PaidAmount > 0)
        {
            return InvoicePostingResult.Failure("Cannot void an invoice with applied payments. Void or reverse the payment first.");
        }

        var existingReversal = await _transactions.GetBySourceAsync(InvoiceReversalSourceEntityType, invoice.Id, cancellationToken);
        if (existingReversal is not null)
        {
            await _invoices.VoidAsync(invoice.Id, existingReversal.Id, cancellationToken);
            return InvoicePostingResult.Success(existingReversal.Id);
        }

        var originalTransaction = await _transactions.GetByIdAsync(invoice.PostedTransactionId.Value, cancellationToken);
        if (originalTransaction is null)
        {
            return InvoicePostingResult.Failure("Posted invoice transaction is missing.");
        }

        var inventoryItems = new List<(InvoiceLine Line, Item Item)>();
        foreach (var line in invoice.Lines)
        {
            var item = await _items.GetByIdAsync(line.ItemId, cancellationToken);
            if (item is null)
            {
                return InvoicePostingResult.Failure($"Item does not exist: {line.ItemId}");
            }

            if (item.ItemType == ItemType.Inventory)
            {
                inventoryItems.Add((line, item));
            }
        }

        var reversalTransaction = BuildReversalTransaction(invoice, originalTransaction);
        var savedReversal = await _transactions.AddAsync(reversalTransaction, cancellationToken);

        foreach (var (line, item) in inventoryItems)
        {
            await _items.IncreaseQuantityAsync(item.Id, line.Quantity, cancellationToken);
        }

        await _customers.ReverseInvoiceAsync(invoice.CustomerId, invoice.TotalAmount, cancellationToken);
        await _invoices.VoidAsync(invoice.Id, savedReversal.Id, cancellationToken);
        return InvoicePostingResult.Success(savedReversal.Id);
    }

    private static AccountingTransaction BuildAccountingTransaction(
        Invoice invoice,
        Guid accountsReceivableAccountId,
        IReadOnlyList<(InvoiceLine Line, Item Item)> lineItems,
        IReadOnlyDictionary<Guid, TaxCode> taxCodesById)
    {
        var transaction = new AccountingTransaction(
            "Invoice",
            invoice.InvoiceDate,
            invoice.InvoiceNumber,
            InvoiceSourceEntityType,
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

        foreach (var group in lineItems
            .Where(current => current.Line.TaxAmount > 0 && current.Line.TaxCodeId is not null)
            .GroupBy(current => current.Line.TaxCodeId!.Value))
        {
            var taxCode = taxCodesById[group.Key];
            transaction.AddLine(new AccountingTransactionLine(
                taxCode.TaxAccountId,
                $"Sales tax {taxCode.Code} - {invoice.InvoiceNumber}",
                0,
                group.Sum(current => current.Line.TaxAmount)));
        }

        return transaction;
    }

    private static AccountingTransaction BuildReversalTransaction(
        Invoice invoice,
        AccountingTransaction originalTransaction)
    {
        var transaction = new AccountingTransaction(
            "InvoiceReversal",
            DateOnly.FromDateTime(DateTime.UtcNow),
            $"{invoice.InvoiceNumber}-VOID",
            InvoiceReversalSourceEntityType,
            invoice.Id);

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
