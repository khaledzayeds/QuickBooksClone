using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.Invoices;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Api.Services;
using QuickBooksClone.Core.Customers;
using QuickBooksClone.Core.Invoices;
using QuickBooksClone.Core.Items;
using QuickBooksClone.Core.Settings;
using QuickBooksClone.Core.Taxes;
using QuickBooksClone.Infrastructure.Persistence;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/invoices")]
[RequirePermission("Sales.Invoice.Manage")]
public sealed class InvoiceDraftUpdatesController : ControllerBase
{
    private readonly IInvoiceRepository _invoices;
    private readonly ICustomerRepository _customers;
    private readonly IItemRepository _items;
    private readonly ICompanySettingsRepository _companySettings;
    private readonly ITaxCodeRepository _taxCodes;
    private readonly QuickBooksCloneDbContext _dbContext;

    public InvoiceDraftUpdatesController(
        IInvoiceRepository invoices,
        ICustomerRepository customers,
        IItemRepository items,
        ICompanySettingsRepository companySettings,
        ITaxCodeRepository taxCodes,
        QuickBooksCloneDbContext dbContext)
    {
        _invoices = invoices;
        _customers = customers;
        _items = items;
        _companySettings = companySettings;
        _taxCodes = taxCodes;
        _dbContext = dbContext;
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(InvoiceDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<InvoiceDto>> UpdateDraft(Guid id, UpdateInvoiceRequest request, CancellationToken cancellationToken = default)
    {
        var invoice = await _invoices.GetByIdAsync(id, cancellationToken);
        if (invoice is null || invoice.PaymentMode != InvoicePaymentMode.Credit)
        {
            return NotFound();
        }

        if (invoice.Status != InvoiceStatus.Draft)
        {
            return BadRequest("Only draft invoices can be edited.");
        }

        var customer = await _customers.GetByIdAsync(request.CustomerId, cancellationToken);
        if (customer is null)
        {
            return BadRequest("Customer does not exist.");
        }

        if (!customer.IsActive)
        {
            return BadRequest("Cannot use an inactive customer.");
        }

        if (request.DueDate < request.InvoiceDate)
        {
            return BadRequest("Invoice due date cannot be before invoice date.");
        }

        if (request.Lines.Count == 0)
        {
            return BadRequest("Invoice must have at least one line.");
        }

        var taxSettings = await _companySettings.GetAsync(cancellationToken);
        var lines = new List<InvoiceLine>();
        foreach (var line in request.Lines)
        {
            var (invoiceLine, error) = await BuildLineAsync(line, taxSettings, cancellationToken);
            if (error is not null)
            {
                return BadRequest(error);
            }

            lines.Add(invoiceLine!);
        }

        try
        {
            invoice.UpdateDraftHeader(request.CustomerId, request.InvoiceDate, request.DueDate);
            invoice.ReplaceDraftLines(lines);
            await _dbContext.SaveChangesAsync(cancellationToken);
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(exception.Message);
        }
        catch (ArgumentException exception)
        {
            return BadRequest(exception.Message);
        }

        var updated = await _invoices.GetByIdAsync(id, cancellationToken);
        return Ok(await ToDtoAsync(updated!, cancellationToken));
    }

    private async Task<(InvoiceLine? Line, string? Error)> BuildLineAsync(CreateInvoiceLineRequest line, CompanySettings? settings, CancellationToken cancellationToken)
    {
        if (line.ItemId == Guid.Empty)
        {
            return (null, "Line item is required.");
        }

        if (line.Quantity <= 0)
        {
            return (null, "Line quantity must be greater than zero.");
        }

        if (line.UnitPrice < 0)
        {
            return (null, "Line unit price cannot be negative.");
        }

        if (line.DiscountPercent is < 0 or > 100)
        {
            return (null, "Line discount percent must be between 0 and 100.");
        }

        var item = await _items.GetByIdAsync(line.ItemId, cancellationToken);
        if (item is null)
        {
            return (null, $"Item does not exist: {line.ItemId}");
        }

        if (!item.IsActive)
        {
            return (null, $"Cannot use inactive item on an invoice: {item.Name}");
        }

        if (item.ItemType == ItemType.Bundle)
        {
            return (null, $"Bundle item '{item.Name}' cannot be used until component posting is implemented.");
        }

        var unitPrice = line.UnitPrice > 0 ? line.UnitPrice : item.SalesPrice;
        var description = string.IsNullOrWhiteSpace(line.Description) ? item.Name : line.Description.Trim();

        try
        {
            var tax = await ResolveTaxAsync(line.TaxCodeId, settings, unitPrice, line.Quantity, line.DiscountPercent, cancellationToken);
            return (new InvoiceLine(item.Id, description, line.Quantity, tax.NetUnitPrice, line.DiscountPercent, taxCodeId: tax.TaxCodeId, taxRatePercent: tax.RatePercent, taxAmount: tax.TaxAmount), null);
        }
        catch (InvalidOperationException exception)
        {
            return (null, exception.Message);
        }
    }

    private async Task<TaxLineCalculation> ResolveTaxAsync(Guid? requestedTaxCodeId, CompanySettings? settings, decimal unitPrice, decimal quantity, decimal discountPercent, CancellationToken cancellationToken)
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
        var discount = grossLine * (Math.Clamp(discountPercent, 0, 100) / 100);
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

    private async Task<InvoiceDto> ToDtoAsync(Invoice invoice, CancellationToken cancellationToken)
    {
        var customer = await _customers.GetByIdAsync(invoice.CustomerId, cancellationToken);
        return new InvoiceDto(
            invoice.Id,
            invoice.InvoiceNumber,
            invoice.CustomerId,
            customer?.DisplayName,
            invoice.SalesOrderId,
            invoice.InvoiceDate,
            invoice.DueDate,
            invoice.PaymentMode,
            invoice.DepositAccountId,
            null,
            invoice.PaymentMethod,
            invoice.ReceiptPaymentId,
            invoice.Status,
            invoice.Subtotal,
            invoice.DiscountAmount,
            invoice.TaxAmount,
            invoice.TotalAmount,
            invoice.PaidAmount,
            invoice.CreditAppliedAmount,
            invoice.ReturnedAmount,
            invoice.BalanceDue,
            invoice.PostedTransactionId,
            invoice.PostedAt,
            invoice.ReversalTransactionId,
            invoice.VoidedAt,
            invoice.Lines.Select(line => new InvoiceLineDto(
                line.Id,
                line.ItemId,
                line.SalesOrderLineId,
                line.Description,
                line.Quantity,
                line.UnitPrice,
                line.DiscountPercent,
                line.TaxCodeId,
                line.TaxRatePercent,
                line.TaxAmount,
                line.LineTotal)).ToList());
    }

    private sealed record TaxLineCalculation(Guid? TaxCodeId, decimal RatePercent, decimal TaxAmount, decimal NetUnitPrice);
}
