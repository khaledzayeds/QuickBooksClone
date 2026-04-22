using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Customers;
using QuickBooksClone.Core.Invoices;
using QuickBooksClone.Core.Items;
using QuickBooksClone.Core.SalesReturns;

namespace QuickBooksClone.Infrastructure.SalesReturns;

public sealed class SalesReturnPostingService : ISalesReturnPostingService
{
    private const string SalesReturnSourceEntityType = "SalesReturn";
    private const string SalesReturnReversalSourceEntityType = "SalesReturnReversal";

    private readonly ISalesReturnRepository _salesReturns;
    private readonly IInvoiceRepository _invoices;
    private readonly ICustomerRepository _customers;
    private readonly IItemRepository _items;
    private readonly IAccountRepository _accounts;
    private readonly IAccountingTransactionRepository _transactions;

    public SalesReturnPostingService(
        ISalesReturnRepository salesReturns,
        IInvoiceRepository invoices,
        ICustomerRepository customers,
        IItemRepository items,
        IAccountRepository accounts,
        IAccountingTransactionRepository transactions)
    {
        _salesReturns = salesReturns;
        _invoices = invoices;
        _customers = customers;
        _items = items;
        _accounts = accounts;
        _transactions = transactions;
    }

    public async Task<SalesReturnPostingResult> PostAsync(Guid salesReturnId, CancellationToken cancellationToken = default)
    {
        var salesReturn = await _salesReturns.GetByIdAsync(salesReturnId, cancellationToken);
        if (salesReturn is null)
        {
            return SalesReturnPostingResult.Failure("Sales return does not exist.");
        }

        if (salesReturn.Status == SalesReturnStatus.Void)
        {
            return SalesReturnPostingResult.Failure("Cannot post a void sales return.");
        }

        if (salesReturn.PostedTransactionId is not null)
        {
            return SalesReturnPostingResult.Success(salesReturn.PostedTransactionId.Value);
        }

        var existingTransaction = await _transactions.GetBySourceAsync(SalesReturnSourceEntityType, salesReturn.Id, cancellationToken);
        if (existingTransaction is not null)
        {
            await _salesReturns.MarkPostedAsync(salesReturn.Id, existingTransaction.Id, cancellationToken);
            return SalesReturnPostingResult.Success(existingTransaction.Id);
        }

        var invoice = await _invoices.GetByIdAsync(salesReturn.InvoiceId, cancellationToken);
        if (invoice is null)
        {
            return SalesReturnPostingResult.Failure("Invoice does not exist.");
        }

        if (invoice.Status is InvoiceStatus.Draft or InvoiceStatus.Void)
        {
            return SalesReturnPostingResult.Failure("Cannot return a draft or void invoice.");
        }

        if (invoice.PostedTransactionId is null)
        {
            return SalesReturnPostingResult.Failure("Invoice must be posted before it can be returned.");
        }

        if (invoice.CustomerId != salesReturn.CustomerId)
        {
            return SalesReturnPostingResult.Failure("Sales return customer does not match invoice customer.");
        }

        if (salesReturn.Lines.Count == 0)
        {
            return SalesReturnPostingResult.Failure("Sales return must have at least one line.");
        }

        var arAccount = await FindFirstAccountAsync(AccountType.AccountsReceivable, cancellationToken);
        if (arAccount is null)
        {
            return SalesReturnPostingResult.Failure("Accounts Receivable account is missing.");
        }

        var alreadyReturnedQuantities = await GetPostedReturnedQuantitiesAsync(salesReturn, cancellationToken);
        var returnLines = new List<(SalesReturnLine ReturnLine, InvoiceLine InvoiceLine, Item Item)>();
        foreach (var returnLine in salesReturn.Lines)
        {
            var invoiceLine = invoice.Lines.FirstOrDefault(line => line.Id == returnLine.InvoiceLineId);
            if (invoiceLine is null)
            {
                return SalesReturnPostingResult.Failure($"Invoice line does not exist: {returnLine.InvoiceLineId}");
            }

            if (invoiceLine.ItemId != returnLine.ItemId)
            {
                return SalesReturnPostingResult.Failure("Returned item does not match invoice line item.");
            }

            var alreadyReturnedQuantity = alreadyReturnedQuantities.GetValueOrDefault(invoiceLine.Id);
            if (alreadyReturnedQuantity + returnLine.Quantity > invoiceLine.Quantity)
            {
                return SalesReturnPostingResult.Failure($"Return quantity for '{invoiceLine.Description}' exceeds invoiced quantity. Available to return: {invoiceLine.Quantity - alreadyReturnedQuantity:N2}.");
            }

            var item = await _items.GetByIdAsync(returnLine.ItemId, cancellationToken);
            if (item is null)
            {
                return SalesReturnPostingResult.Failure($"Item does not exist: {returnLine.ItemId}");
            }

            if (item.IncomeAccountId is null)
            {
                return SalesReturnPostingResult.Failure($"Item '{item.Name}' is missing an income account.");
            }

            if (item.ItemType == ItemType.Inventory && (item.InventoryAssetAccountId is null || item.CogsAccountId is null))
            {
                return SalesReturnPostingResult.Failure($"Inventory item '{item.Name}' is missing COGS or inventory asset account.");
            }

            returnLines.Add((returnLine, invoiceLine, item));
        }

        var transaction = BuildAccountingTransaction(salesReturn, arAccount.Id, returnLines);
        var savedTransaction = await _transactions.AddAsync(transaction, cancellationToken);

        foreach (var (returnLine, _, item) in returnLines.Where(current => current.Item.ItemType == ItemType.Inventory))
        {
            await _items.IncreaseQuantityAsync(item.Id, returnLine.Quantity, cancellationToken);
        }

        await _invoices.ApplyReturnAsync(invoice.Id, salesReturn.TotalAmount, cancellationToken);
        await _customers.ApplySalesReturnAsync(invoice.CustomerId, salesReturn.TotalAmount, cancellationToken);
        await _salesReturns.MarkPostedAsync(salesReturn.Id, savedTransaction.Id, cancellationToken);
        return SalesReturnPostingResult.Success(savedTransaction.Id);
    }

    public async Task<SalesReturnPostingResult> VoidAsync(Guid salesReturnId, CancellationToken cancellationToken = default)
    {
        var salesReturn = await _salesReturns.GetByIdAsync(salesReturnId, cancellationToken);
        if (salesReturn is null)
        {
            return SalesReturnPostingResult.Failure("Sales return does not exist.");
        }

        if (salesReturn.Status == SalesReturnStatus.Void)
        {
            return SalesReturnPostingResult.Success(salesReturn.ReversalTransactionId);
        }

        if (salesReturn.PostedTransactionId is null)
        {
            await _salesReturns.VoidAsync(salesReturn.Id, null, cancellationToken);
            return SalesReturnPostingResult.Success();
        }

        var invoice = await _invoices.GetByIdAsync(salesReturn.InvoiceId, cancellationToken);
        if (invoice is null)
        {
            return SalesReturnPostingResult.Failure("Invoice does not exist.");
        }

        var customer = await _customers.GetByIdAsync(salesReturn.CustomerId, cancellationToken);
        if (customer is null)
        {
            return SalesReturnPostingResult.Failure("Customer does not exist.");
        }

        var existingReversal = await _transactions.GetBySourceAsync(SalesReturnReversalSourceEntityType, salesReturn.Id, cancellationToken);
        if (existingReversal is not null)
        {
            await _salesReturns.VoidAsync(salesReturn.Id, existingReversal.Id, cancellationToken);
            return SalesReturnPostingResult.Success(existingReversal.Id);
        }

        var originalTransaction = await _transactions.GetByIdAsync(salesReturn.PostedTransactionId.Value, cancellationToken);
        if (originalTransaction is null)
        {
            return SalesReturnPostingResult.Failure("Posted sales return transaction is missing.");
        }

        foreach (var line in salesReturn.Lines)
        {
            var item = await _items.GetByIdAsync(line.ItemId, cancellationToken);
            if (item is null)
            {
                return SalesReturnPostingResult.Failure($"Item does not exist: {line.ItemId}");
            }

            if (item.ItemType != ItemType.Inventory)
            {
                continue;
            }

            if (item.QuantityOnHand < line.Quantity)
            {
                return SalesReturnPostingResult.Failure($"Cannot void sales return because '{item.Name}' has only {item.QuantityOnHand:N2} on hand, but {line.Quantity:N2} must be removed.");
            }
        }

        var reversal = BuildReversalTransaction(salesReturn, originalTransaction);
        var savedReversal = await _transactions.AddAsync(reversal, cancellationToken);

        foreach (var line in salesReturn.Lines)
        {
            var item = await _items.GetByIdAsync(line.ItemId, cancellationToken);
            if (item?.ItemType == ItemType.Inventory)
            {
                await _items.DecreaseQuantityAsync(item.Id, line.Quantity, cancellationToken);
            }
        }

        await _invoices.ReverseReturnAsync(invoice.Id, salesReturn.TotalAmount, cancellationToken);
        await _customers.ReverseSalesReturnAsync(customer.Id, salesReturn.TotalAmount, cancellationToken);
        await _salesReturns.VoidAsync(salesReturn.Id, savedReversal.Id, cancellationToken);
        return SalesReturnPostingResult.Success(savedReversal.Id);
    }

    private async Task<Dictionary<Guid, decimal>> GetPostedReturnedQuantitiesAsync(SalesReturn currentReturn, CancellationToken cancellationToken)
    {
        var result = await _salesReturns.SearchAsync(new SalesReturnSearch(InvoiceId: currentReturn.InvoiceId, IncludeVoid: false, PageSize: 200), cancellationToken);
        return result.Items
            .Where(salesReturn => salesReturn.Id != currentReturn.Id && salesReturn.Status == SalesReturnStatus.Posted)
            .SelectMany(salesReturn => salesReturn.Lines)
            .GroupBy(line => line.InvoiceLineId)
            .ToDictionary(group => group.Key, group => group.Sum(line => line.Quantity));
    }

    private static AccountingTransaction BuildAccountingTransaction(
        SalesReturn salesReturn,
        Guid accountsReceivableAccountId,
        IReadOnlyList<(SalesReturnLine ReturnLine, InvoiceLine InvoiceLine, Item Item)> returnLines)
    {
        var transaction = new AccountingTransaction(
            "SalesReturn",
            salesReturn.ReturnDate,
            salesReturn.ReturnNumber,
            SalesReturnSourceEntityType,
            salesReturn.Id);

        foreach (var (returnLine, _, item) in returnLines)
        {
            transaction.AddLine(new AccountingTransactionLine(
                item.IncomeAccountId!.Value,
                $"Sales return - {returnLine.Description}",
                returnLine.LineTotal,
                0));
        }

        transaction.AddLine(new AccountingTransactionLine(
            accountsReceivableAccountId,
            $"Credit memo {salesReturn.ReturnNumber}",
            0,
            salesReturn.TotalAmount));

        foreach (var (returnLine, _, item) in returnLines)
        {
            if (item.ItemType != ItemType.Inventory)
            {
                continue;
            }

            var costAmount = item.PurchasePrice * returnLine.Quantity;
            if (costAmount <= 0)
            {
                continue;
            }

            transaction.AddLine(new AccountingTransactionLine(
                item.InventoryAssetAccountId!.Value,
                $"Return inventory - {returnLine.Description}",
                costAmount,
                0));

            transaction.AddLine(new AccountingTransactionLine(
                item.CogsAccountId!.Value,
                $"Reverse COGS - {returnLine.Description}",
                0,
                costAmount));
        }

        return transaction;
    }

    private static AccountingTransaction BuildReversalTransaction(SalesReturn salesReturn, AccountingTransaction originalTransaction)
    {
        var transaction = new AccountingTransaction(
            "SalesReturnReversal",
            DateOnly.FromDateTime(DateTime.UtcNow),
            $"{salesReturn.ReturnNumber}-VOID",
            SalesReturnReversalSourceEntityType,
            salesReturn.Id);

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
