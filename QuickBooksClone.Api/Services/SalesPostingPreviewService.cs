using QuickBooksClone.Api.Contracts.Invoices;
using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Customers;
using QuickBooksClone.Core.Invoices;
using QuickBooksClone.Core.Items;
using QuickBooksClone.Core.Settings;
using QuickBooksClone.Core.Taxes;

namespace QuickBooksClone.Api.Services;

public sealed class SalesPostingPreviewService
{
    private readonly ICustomerRepository _customers;
    private readonly IItemRepository _items;
    private readonly IAccountRepository _accounts;
    private readonly ICompanySettingsRepository _companySettings;
    private readonly ITaxCodeRepository _taxCodes;

    public SalesPostingPreviewService(
        ICustomerRepository customers,
        IItemRepository items,
        IAccountRepository accounts,
        ICompanySettingsRepository companySettings,
        ITaxCodeRepository taxCodes)
    {
        _customers = customers;
        _items = items;
        _accounts = accounts;
        _companySettings = companySettings;
        _taxCodes = taxCodes;
    }

    public async Task<(SalesPostingPreviewDto? Preview, string? Error)> PreviewInvoiceAsync(PreviewInvoiceRequest request, CancellationToken cancellationToken)
    {
        if (request.DueDate < request.InvoiceDate)
        {
            return (null, "Invoice due date cannot be before invoice date.");
        }

        return await BuildPreviewAsync(request.CustomerId, InvoicePaymentMode.Credit, null, null, request.Lines, cancellationToken);
    }

    public async Task<(SalesPostingPreviewDto? Preview, string? Error)> PreviewSalesReceiptAsync(PreviewSalesReceiptRequest request, CancellationToken cancellationToken)
    {
        if (request.DepositAccountId == Guid.Empty)
        {
            return (null, "Deposit account is required for sales receipts.");
        }

        var depositAccount = await _accounts.GetByIdAsync(request.DepositAccountId, cancellationToken);
        if (depositAccount is null)
        {
            return (null, "Deposit account does not exist.");
        }

        if (!depositAccount.IsActive)
        {
            return (null, "Deposit account is inactive.");
        }

        if (depositAccount.AccountType is not AccountType.Bank and not AccountType.OtherCurrentAsset)
        {
            return (null, "Deposit account must be a bank or other current asset account.");
        }

        return await BuildPreviewAsync(request.CustomerId, InvoicePaymentMode.Cash, depositAccount, request.PaymentMethod ?? "Cash", request.Lines, cancellationToken);
    }

    private async Task<(SalesPostingPreviewDto? Preview, string? Error)> BuildPreviewAsync(
        Guid customerId,
        InvoicePaymentMode paymentMode,
        Account? depositAccount,
        string? paymentMethod,
        IReadOnlyList<PreviewSalesLineRequest> requestLines,
        CancellationToken cancellationToken)
    {
        var customer = await _customers.GetByIdAsync(customerId, cancellationToken);
        if (customer is null)
        {
            return (null, "Customer does not exist.");
        }

        if (!customer.IsActive)
        {
            return (null, paymentMode == InvoicePaymentMode.Cash
                ? "Cannot create a sales receipt for an inactive customer."
                : "Cannot create an invoice for an inactive customer.");
        }

        if (requestLines.Count == 0)
        {
            return (null, paymentMode == InvoicePaymentMode.Cash
                ? "Sales receipt must have at least one line."
                : "Invoice must have at least one line.");
        }

        var settings = await _companySettings.GetAsync(cancellationToken);
        var warnings = new List<string>();
        var previewLines = new List<SalesPostingPreviewLineDto>();
        var ledgerImpacts = new List<SalesLedgerImpactDto>();
        var inventoryImpacts = new List<SalesInventoryImpactDto>();

        decimal subtotal = 0;
        decimal discountTotal = 0;
        decimal taxTotal = 0;
        decimal inventoryCostTotal = 0;

        foreach (var requestLine in requestLines)
        {
            var lineValidation = ValidateSalesLine(requestLine.ItemId, requestLine.Quantity, requestLine.UnitPrice, requestLine.DiscountPercent);
            if (lineValidation is not null)
            {
                return (null, lineValidation);
            }

            var item = await _items.GetByIdAsync(requestLine.ItemId, cancellationToken);
            if (item is null)
            {
                return (null, $"Item does not exist: {requestLine.ItemId}");
            }

            var lineWarnings = new List<string>();
            if (!item.IsActive)
            {
                return (null, $"Cannot use inactive item on sales transaction: {item.Name}");
            }

            if (item.ItemType == ItemType.Bundle)
            {
                return (null, $"Bundle item '{item.Name}' cannot be used until component posting is implemented.");
            }

            var unitPrice = requestLine.UnitPrice > 0 ? requestLine.UnitPrice : item.SalesPrice;
            var description = string.IsNullOrWhiteSpace(requestLine.Description) ? item.Name : requestLine.Description.Trim();
            var grossLine = unitPrice * requestLine.Quantity;
            var discountAmount = grossLine * requestLine.DiscountPercent / 100;
            var tax = await ResolveTaxAsync(requestLine.TaxCodeId, settings, unitPrice, requestLine.Quantity, requestLine.DiscountPercent, cancellationToken);
            var lineTotal = grossLine - discountAmount + tax.TaxAmount;

            subtotal += grossLine;
            discountTotal += discountAmount;
            taxTotal += tax.TaxAmount;

            decimal? projectedStock = null;
            decimal? unitCost = null;
            decimal? grossMargin = null;
            if (item.ItemType == ItemType.Inventory)
            {
                projectedStock = item.QuantityOnHand - requestLine.Quantity;
                unitCost = item.PurchasePrice;
                var cost = item.PurchasePrice * requestLine.Quantity;
                inventoryCostTotal += cost;
                grossMargin = lineTotal - cost;

                if (projectedStock < 0)
                {
                    lineWarnings.Add("This sale will make inventory stock negative.");
                }

                if (item.InventoryAssetAccountId is null)
                {
                    lineWarnings.Add("Inventory asset account is missing.");
                }

                if (item.CogsAccountId is null)
                {
                    lineWarnings.Add("COGS account is missing.");
                }

                inventoryImpacts.Add(new SalesInventoryImpactDto(
                    item.Id,
                    item.Name,
                    -requestLine.Quantity,
                    item.QuantityOnHand,
                    projectedStock,
                    item.PurchasePrice,
                    -cost,
                    "Inventory relief on sales posting."));
            }

            if (item.IncomeAccountId is null)
            {
                lineWarnings.Add("Income account is missing.");
            }

            if (unitPrice < item.PurchasePrice && item.PurchasePrice > 0)
            {
                lineWarnings.Add("Sales price is below purchase cost.");
            }

            warnings.AddRange(lineWarnings.Select(warning => $"{item.Name}: {warning}"));

            previewLines.Add(new SalesPostingPreviewLineDto(
                item.Id,
                item.Name,
                description,
                requestLine.Quantity,
                tax.NetUnitPrice,
                requestLine.DiscountPercent,
                discountAmount,
                tax.RatePercent,
                tax.TaxAmount,
                lineTotal,
                item.ItemType == ItemType.Inventory ? item.QuantityOnHand : null,
                projectedStock,
                unitCost,
                grossMargin,
                lineWarnings));
        }

        var total = subtotal - discountTotal + taxTotal;
        var paid = paymentMode == InvoicePaymentMode.Cash ? total : 0;
        var balanceDue = paymentMode == InvoicePaymentMode.Cash ? 0 : total;

        if (paymentMode == InvoicePaymentMode.Cash && depositAccount is not null)
        {
            ledgerImpacts.Add(new SalesLedgerImpactDto("Deposit", depositAccount.Id, depositAccount.Name, total, 0, $"Sales receipt payment via {paymentMethod ?? "Cash"}."));
        }
        else
        {
            ledgerImpacts.Add(new SalesLedgerImpactDto("Accounts Receivable", null, "Accounts Receivable", total, 0, "Invoice increases customer receivable."));
        }

        ledgerImpacts.Add(new SalesLedgerImpactDto("Income", null, "Item income accounts", 0, subtotal - discountTotal, "Sales income per line item account."));

        if (taxTotal > 0)
        {
            ledgerImpacts.Add(new SalesLedgerImpactDto("Sales Tax Payable", settings?.SalesTaxPayableAccountId, "Sales Tax Payable", 0, taxTotal, "Sales tax collected."));
        }

        if (inventoryCostTotal > 0)
        {
            ledgerImpacts.Add(new SalesLedgerImpactDto("COGS", null, "Item COGS accounts", inventoryCostTotal, 0, "Cost of goods sold for inventory items."));
            ledgerImpacts.Add(new SalesLedgerImpactDto("Inventory Asset", null, "Item inventory asset accounts", 0, inventoryCostTotal, "Inventory asset relief for sold stock."));
        }

        return (new SalesPostingPreviewDto(
            paymentMode,
            subtotal,
            discountTotal,
            taxTotal,
            total,
            paid,
            balanceDue,
            previewLines,
            ledgerImpacts,
            inventoryImpacts,
            warnings.Distinct().ToList()), null);
    }

    private static string? ValidateSalesLine(Guid itemId, decimal quantity, decimal unitPrice, decimal discountPercent)
    {
        if (itemId == Guid.Empty)
        {
            return "Line item is required.";
        }

        if (quantity <= 0)
        {
            return "Line quantity must be greater than zero.";
        }

        if (unitPrice < 0)
        {
            return "Line unit price cannot be negative.";
        }

        if (discountPercent is < 0 or > 100)
        {
            return "Line discount percent must be between 0 and 100.";
        }

        return null;
    }

    private async Task<TaxLineCalculation> ResolveTaxAsync(
        Guid? requestedTaxCodeId,
        CompanySettings? settings,
        decimal unitPrice,
        decimal quantity,
        decimal discountPercent,
        CancellationToken cancellationToken)
    {
        if (settings?.TaxesEnabled != true)
        {
            return new TaxLineCalculation(null, 0, 0, unitPrice);
        }

        var taxCodeId = requestedTaxCodeId == Guid.Empty ? null : requestedTaxCodeId;
        taxCodeId ??= settings.DefaultSalesTaxCodeId;
        if (taxCodeId is null)
        {
            return new TaxLineCalculation(null, 0, 0, unitPrice);
        }

        var taxCode = await _taxCodes.GetByIdAsync(taxCodeId.Value, cancellationToken)
            ?? throw new InvalidOperationException("Tax code does not exist.");
        if (!taxCode.IsActive || !taxCode.CanApplyTo(TaxTransactionType.Sales))
        {
            throw new InvalidOperationException("Tax code is not active or cannot be applied to sales.");
        }

        var rate = taxCode.RatePercent;
        var grossLine = unitPrice * quantity;
        var discount = grossLine * discountPercent / 100;
        var taxableAmount = grossLine - discount;
        var netUnitPrice = unitPrice;

        if (settings.PricesIncludeTax && rate > 0)
        {
            var netLine = taxableAmount / (1 + rate / 100);
            netUnitPrice = quantity == 0 ? unitPrice : netLine / quantity;
            taxableAmount = netLine;
        }

        var taxAmount = Math.Round(taxableAmount * (rate / 100), 2, MidpointRounding.AwayFromZero);
        return new TaxLineCalculation(taxCode.Id, rate, taxAmount, netUnitPrice);
    }

    private sealed record TaxLineCalculation(Guid? TaxCodeId, decimal RatePercent, decimal TaxAmount, decimal NetUnitPrice);
}
