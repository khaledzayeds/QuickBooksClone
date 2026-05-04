using QuickBooksClone.Api.Contracts.Sales;
using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Customers;
using QuickBooksClone.Core.Invoices;
using QuickBooksClone.Core.Items;
using QuickBooksClone.Core.Settings;

namespace QuickBooksClone.Api.Services;

public sealed class SalesPrintService
{
    private readonly IInvoiceRepository _invoices;
    private readonly ICustomerRepository _customers;
    private readonly IItemRepository _items;
    private readonly IAccountRepository _accounts;
    private readonly ICompanySettingsRepository _companySettings;

    public SalesPrintService(
        IInvoiceRepository invoices,
        ICustomerRepository customers,
        IItemRepository items,
        IAccountRepository accounts,
        ICompanySettingsRepository companySettings)
    {
        _invoices = invoices;
        _customers = customers;
        _items = items;
        _accounts = accounts;
        _companySettings = companySettings;
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
            Terms: invoice.PaymentMode == InvoicePaymentMode.Cash ? "Paid at sale" : null), null);
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
}
