using QuickBooksClone.Api.Contracts.Sales;
using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Customers;
using QuickBooksClone.Core.Estimates;
using QuickBooksClone.Core.Invoices;
using QuickBooksClone.Core.InventoryAdjustments;
using QuickBooksClone.Core.Items;
using QuickBooksClone.Core.PurchaseOrders;
using QuickBooksClone.Core.ReceiveInventory;
using QuickBooksClone.Core.SalesReturns;
using QuickBooksClone.Core.Settings;
using QuickBooksClone.Core.Vendors;

namespace QuickBooksClone.Api.Services;

public sealed class SalesPrintService
{
    private readonly IInvoiceRepository _invoices;
    private readonly ICustomerRepository _customers;
    private readonly IItemRepository _items;
    private readonly IAccountRepository _accounts;
    private readonly ICompanySettingsRepository _companySettings;
    private readonly IEstimateRepository _estimates;
    private readonly ISalesReturnRepository _salesReturns;
    private readonly IPurchaseOrderRepository _purchaseOrders;
    private readonly IInventoryReceiptRepository _inventoryReceipts;
    private readonly IInventoryAdjustmentRepository _inventoryAdjustments;
    private readonly IVendorRepository _vendors;

    public SalesPrintService(
        IInvoiceRepository invoices,
        ICustomerRepository customers,
        IItemRepository items,
        IAccountRepository accounts,
        ICompanySettingsRepository companySettings,
        IEstimateRepository estimates,
        ISalesReturnRepository salesReturns,
        IPurchaseOrderRepository purchaseOrders,
        IInventoryReceiptRepository inventoryReceipts,
        IInventoryAdjustmentRepository inventoryAdjustments,
        IVendorRepository vendors)
    {
        _invoices = invoices;
        _customers = customers;
        _items = items;
        _accounts = accounts;
        _companySettings = companySettings;
        _estimates = estimates;
        _salesReturns = salesReturns;
        _purchaseOrders = purchaseOrders;
        _inventoryReceipts = inventoryReceipts;
        _inventoryAdjustments = inventoryAdjustments;
        _vendors = vendors;
    }

    public async Task<(SalesPrintDataDto? Data, string? Error)> GetPrintDataAsync(Guid documentId, InvoicePaymentMode expectedMode, CancellationToken cancellationToken)
    {
        var invoice = await _invoices.GetByIdAsync(documentId, cancellationToken);
        if (invoice is null || invoice.PaymentMode != expectedMode)
        {
            return (null, "Sales document was not found.");
        }

        var company = await _companySettings.GetAsync(cancellationToken);
        var customer = await _customers.GetByIdAsync(invoice.CustomerId, cancellationToken);
        if (customer is null)
        {
            return (null, "Customer does not exist.");
        }

        var depositAccount = invoice.DepositAccountId is null
            ? null
            : await _accounts.GetByIdAsync(invoice.DepositAccountId.Value, cancellationToken);

        var lines = new List<SalesPrintLineDto>();
        var lineNumber = 1;
        foreach (var line in invoice.Lines)
        {
            var item = await _items.GetByIdAsync(line.ItemId, cancellationToken);
            lines.Add(new SalesPrintLineDto(
                lineNumber++,
                line.ItemId,
                item?.Name ?? "Item",
                line.Description,
                line.Quantity,
                line.UnitPrice,
                line.DiscountPercent,
                line.TaxRatePercent,
                line.TaxAmount,
                line.LineTotal));
        }

        var summary = BuildSummary(invoice);
        var documentType = invoice.PaymentMode == InvoicePaymentMode.Cash ? "Sales Receipt" : "Invoice";

        return (new SalesPrintDataDto(
            invoice.Id,
            documentType,
            invoice.InvoiceNumber,
            invoice.PaymentMode,
            invoice.Status.ToString(),
            new SalesPrintCompanyDto(
                company?.CompanyName ?? "Company",
                company?.LegalName,
                company?.Email,
                company?.Phone,
                company?.Currency ?? customer.Currency,
                company?.Country ?? "Egypt"),
            new SalesPrintCustomerDto(
                customer.Id,
                customer.DisplayName,
                customer.Email,
                customer.Phone,
                customer.Currency,
                customer.Balance,
                customer.CreditBalance),
            new SalesPrintPaymentDto(
                invoice.DepositAccountId,
                depositAccount?.Name,
                invoice.PaymentMethod,
                invoice.ReceiptPaymentId),
            invoice.InvoiceDate,
            invoice.DueDate,
            invoice.Subtotal,
            invoice.DiscountAmount,
            invoice.TaxAmount,
            invoice.TotalAmount,
            invoice.PaidAmount,
            invoice.CreditAppliedAmount,
            invoice.ReturnedAmount,
            invoice.BalanceDue,
            lines,
            summary,
            DateTimeOffset.UtcNow,
            Notes: null,
            Terms: invoice.PaymentMode == InvoicePaymentMode.Cash ? "Paid at sale" : null,
            PartyLabel: "Customer",
            PartyType: "Customer"), null);
    }

    public async Task<(SalesPrintDataDto? Data, string? Error)> GetEstimatePrintDataAsync(Guid documentId, CancellationToken cancellationToken)
    {
        var estimate = await _estimates.GetByIdAsync(documentId, cancellationToken);
        if (estimate is null)
        {
            return (null, "Estimate was not found.");
        }

        var customer = await _customers.GetByIdAsync(estimate.CustomerId, cancellationToken);
        if (customer is null)
        {
            return (null, "Customer does not exist.");
        }

        var lines = new List<SalesPrintLineDto>();
        var lineNumber = 1;
        foreach (var line in estimate.Lines)
        {
            lines.Add(new SalesPrintLineDto(
                lineNumber++,
                line.ItemId,
                await ItemNameAsync(line.ItemId, cancellationToken),
                line.Description,
                line.Quantity,
                line.UnitPrice,
                0,
                line.TaxRatePercent,
                line.TaxAmount,
                line.LineTotal));
        }

        return (new SalesPrintDataDto(
            estimate.Id,
            "Estimate",
            estimate.EstimateNumber,
            InvoicePaymentMode.Credit,
            estimate.Status.ToString(),
            await CompanyAsync(customer.Currency, cancellationToken),
            new SalesPrintCustomerDto(customer.Id, customer.DisplayName, customer.Email, customer.Phone, customer.Currency, customer.Balance, customer.CreditBalance),
            null,
            estimate.EstimateDate,
            estimate.ExpirationDate,
            estimate.Subtotal,
            0,
            estimate.TaxAmount,
            estimate.TotalAmount,
            0,
            0,
            0,
            estimate.TotalAmount,
            lines,
            BuildSummary("Subtotal", estimate.Subtotal, estimate.TaxAmount, estimate.TotalAmount),
            DateTimeOffset.UtcNow,
            Terms: "Estimate valid until expiration date",
            PartyLabel: "Customer",
            PartyType: "Customer"), null);
    }

    public async Task<(SalesPrintDataDto? Data, string? Error)> GetSalesReturnPrintDataAsync(Guid documentId, CancellationToken cancellationToken)
    {
        var salesReturn = await _salesReturns.GetByIdAsync(documentId, cancellationToken);
        if (salesReturn is null)
        {
            return (null, "Sales return was not found.");
        }

        var customer = await _customers.GetByIdAsync(salesReturn.CustomerId, cancellationToken);
        if (customer is null)
        {
            return (null, "Customer does not exist.");
        }

        var lines = new List<SalesPrintLineDto>();
        var lineNumber = 1;
        foreach (var line in salesReturn.Lines)
        {
            lines.Add(new SalesPrintLineDto(
                lineNumber++,
                line.ItemId,
                await ItemNameAsync(line.ItemId, cancellationToken),
                line.Description,
                line.Quantity,
                line.UnitPrice,
                line.DiscountPercent,
                0,
                0,
                line.LineTotal));
        }

        return (new SalesPrintDataDto(
            salesReturn.Id,
            "Sales Return",
            salesReturn.ReturnNumber,
            InvoicePaymentMode.Credit,
            salesReturn.Status.ToString(),
            await CompanyAsync(customer.Currency, cancellationToken),
            new SalesPrintCustomerDto(customer.Id, customer.DisplayName, customer.Email, customer.Phone, customer.Currency, customer.Balance, customer.CreditBalance),
            null,
            salesReturn.ReturnDate,
            salesReturn.ReturnDate,
            salesReturn.TotalAmount,
            0,
            0,
            salesReturn.TotalAmount,
            0,
            0,
            salesReturn.TotalAmount,
            0,
            lines,
            BuildSummary("Returned Total", salesReturn.TotalAmount, 0, salesReturn.TotalAmount),
            DateTimeOffset.UtcNow,
            Terms: "Posted sales return",
            PartyLabel: "Customer",
            PartyType: "Customer"), null);
    }

    public async Task<(SalesPrintDataDto? Data, string? Error)> GetPurchaseOrderPrintDataAsync(Guid documentId, CancellationToken cancellationToken)
    {
        var order = await _purchaseOrders.GetByIdAsync(documentId, cancellationToken);
        if (order is null)
        {
            return (null, "Purchase order was not found.");
        }

        var vendor = await _vendors.GetByIdAsync(order.VendorId, cancellationToken);
        if (vendor is null)
        {
            return (null, "Vendor does not exist.");
        }

        var lines = new List<SalesPrintLineDto>();
        var lineNumber = 1;
        foreach (var line in order.Lines)
        {
            lines.Add(new SalesPrintLineDto(
                lineNumber++,
                line.ItemId,
                await ItemNameAsync(line.ItemId, cancellationToken),
                line.Description,
                line.Quantity,
                line.UnitCost,
                0,
                line.TaxRatePercent,
                line.TaxAmount,
                line.LineTotal));
        }

        return (new SalesPrintDataDto(
            order.Id,
            "Purchase Order",
            order.OrderNumber,
            InvoicePaymentMode.Credit,
            order.Status.ToString(),
            await CompanyAsync(vendor.Currency, cancellationToken),
            VendorParty(vendor),
            null,
            order.OrderDate,
            order.ExpectedDate,
            order.Subtotal,
            0,
            order.TaxAmount,
            order.TotalAmount,
            0,
            0,
            0,
            order.TotalAmount,
            lines,
            BuildSummary("Subtotal", order.Subtotal, order.TaxAmount, order.TotalAmount),
            DateTimeOffset.UtcNow,
            Terms: "Purchase order",
            PartyLabel: "Vendor",
            PartyType: "Vendor"), null);
    }

    public async Task<(SalesPrintDataDto? Data, string? Error)> GetInventoryReceiptPrintDataAsync(Guid documentId, CancellationToken cancellationToken)
    {
        var receipt = await _inventoryReceipts.GetByIdAsync(documentId, cancellationToken);
        if (receipt is null)
        {
            return (null, "Inventory receipt was not found.");
        }

        var vendor = await _vendors.GetByIdAsync(receipt.VendorId, cancellationToken);
        if (vendor is null)
        {
            return (null, "Vendor does not exist.");
        }

        var lines = new List<SalesPrintLineDto>();
        var lineNumber = 1;
        foreach (var line in receipt.Lines)
        {
            lines.Add(new SalesPrintLineDto(
                lineNumber++,
                line.ItemId,
                await ItemNameAsync(line.ItemId, cancellationToken),
                line.Description,
                line.Quantity,
                line.UnitCost,
                0,
                0,
                0,
                line.LineTotal));
        }

        return (new SalesPrintDataDto(
            receipt.Id,
            "Receive Inventory",
            receipt.ReceiptNumber,
            InvoicePaymentMode.Credit,
            receipt.Status.ToString(),
            await CompanyAsync(vendor.Currency, cancellationToken),
            VendorParty(vendor),
            null,
            receipt.ReceiptDate,
            receipt.ReceiptDate,
            receipt.TotalAmount,
            0,
            0,
            receipt.TotalAmount,
            0,
            0,
            0,
            receipt.TotalAmount,
            lines,
            BuildSummary("Receipt Total", receipt.TotalAmount, 0, receipt.TotalAmount),
            DateTimeOffset.UtcNow,
            Terms: receipt.PurchaseOrderId is null ? "Manual receive inventory" : $"PO {receipt.PurchaseOrderId}",
            PartyLabel: "Vendor",
            PartyType: "Vendor"), null);
    }

    public async Task<(SalesPrintDataDto? Data, string? Error)> GetInventoryAdjustmentPrintDataAsync(Guid documentId, CancellationToken cancellationToken)
    {
        var adjustment = await _inventoryAdjustments.GetByIdAsync(documentId, cancellationToken);
        if (adjustment is null)
        {
            return (null, "Inventory adjustment was not found.");
        }

        var itemName = await ItemNameAsync(adjustment.ItemId, cancellationToken);
        var account = await _accounts.GetByIdAsync(adjustment.AdjustmentAccountId, cancellationToken);
        var company = await CompanyAsync("EGP", cancellationToken);
        var line = new SalesPrintLineDto(
            1,
            adjustment.ItemId,
            itemName,
            adjustment.Reason,
            adjustment.QuantityChange,
            adjustment.UnitCost,
            0,
            0,
            0,
            adjustment.TotalCost);

        return (new SalesPrintDataDto(
            adjustment.Id,
            "Inventory Adjustment",
            adjustment.AdjustmentNumber,
            InvoicePaymentMode.Credit,
            adjustment.Status.ToString(),
            company,
            new SalesPrintCustomerDto(Guid.Empty, account?.Name ?? "Adjustment Account", null, null, company.Currency, 0, 0),
            null,
            adjustment.AdjustmentDate,
            adjustment.AdjustmentDate,
            adjustment.TotalCost,
            0,
            0,
            adjustment.TotalCost,
            0,
            0,
            0,
            adjustment.TotalCost,
            new List<SalesPrintLineDto> { line },
            BuildSummary("Adjustment Value", adjustment.TotalCost, 0, adjustment.TotalCost),
            DateTimeOffset.UtcNow,
            Notes: adjustment.Reason,
            Terms: account?.Name,
            PartyLabel: "Account",
            PartyType: "Account"), null);
    }

    private static IReadOnlyList<SalesPrintSummaryRowDto> BuildSummary(Invoice invoice)
    {
        var rows = new List<SalesPrintSummaryRowDto>
        {
            new("Subtotal", invoice.Subtotal),
        };

        if (invoice.DiscountAmount != 0)
        {
            rows.Add(new("Discount", -invoice.DiscountAmount));
        }

        if (invoice.TaxAmount != 0)
        {
            rows.Add(new("Tax", invoice.TaxAmount));
        }

        rows.Add(new("Total", invoice.TotalAmount, true));

        if (invoice.PaidAmount != 0)
        {
            rows.Add(new("Paid", -invoice.PaidAmount));
        }

        if (invoice.CreditAppliedAmount != 0)
        {
            rows.Add(new("Credits", -invoice.CreditAppliedAmount));
        }

        if (invoice.ReturnedAmount != 0)
        {
            rows.Add(new("Returns", -invoice.ReturnedAmount));
        }

        rows.Add(new("Balance Due", invoice.BalanceDue, true));
        return rows;
    }

    private async Task<string> ItemNameAsync(Guid itemId, CancellationToken cancellationToken)
    {
        var item = await _items.GetByIdAsync(itemId, cancellationToken);
        return item?.Name ?? "Item";
    }

    private async Task<SalesPrintCompanyDto> CompanyAsync(string fallbackCurrency, CancellationToken cancellationToken)
    {
        var company = await _companySettings.GetAsync(cancellationToken);
        return new SalesPrintCompanyDto(
            company?.CompanyName ?? "Company",
            company?.LegalName,
            company?.Email,
            company?.Phone,
            company?.Currency ?? fallbackCurrency,
            company?.Country ?? "Egypt");
    }

    private static SalesPrintCustomerDto VendorParty(Vendor vendor)
    {
        return new SalesPrintCustomerDto(
            vendor.Id,
            vendor.DisplayName,
            vendor.Email,
            vendor.Phone,
            vendor.Currency,
            vendor.Balance,
            vendor.CreditBalance);
    }

    private static IReadOnlyList<SalesPrintSummaryRowDto> BuildSummary(string subtotalLabel, decimal subtotal, decimal taxAmount, decimal total)
    {
        var rows = new List<SalesPrintSummaryRowDto>
        {
            new(subtotalLabel, subtotal),
        };
        if (taxAmount != 0)
        {
            rows.Add(new("Tax", taxAmount));
        }
        rows.Add(new("Total", total, true));
        return rows;
    }
}
