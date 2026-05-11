using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Api.Contracts.Customers;
using QuickBooksClone.Core.Customers;
using QuickBooksClone.Core.Invoices;
using QuickBooksClone.Core.OpeningBalances;
using QuickBooksClone.Core.Payments;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/customers")]
[RequirePermission("Customers.Manage")]
public sealed class CustomersController : ControllerBase
{
    private readonly ICustomerRepository _customers;
    private readonly IOpeningBalancePostingService _openingBalances;
    private readonly IInvoiceRepository _invoices;
    private readonly IPaymentRepository _payments;

    public CustomersController(
        ICustomerRepository customers,
        IOpeningBalancePostingService openingBalances,
        IInvoiceRepository invoices,
        IPaymentRepository payments)
    {
        _customers = customers;
        _openingBalances = openingBalances;
        _invoices = invoices;
        _payments = payments;
    }

    [HttpGet]
    [ProducesResponseType(typeof(CustomerListResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<CustomerListResponse>> Search(
        [FromQuery] string? search,
        [FromQuery] bool includeInactive = false,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 25,
        CancellationToken cancellationToken = default)
    {
        var result = await _customers.SearchAsync(new CustomerSearch(search, includeInactive, page, pageSize), cancellationToken);

        return Ok(new CustomerListResponse(
            result.Items.Select(ToDto).ToList(),
            result.TotalCount,
            result.Page,
            result.PageSize));
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(CustomerDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CustomerDto>> Get(Guid id, CancellationToken cancellationToken = default)
    {
        var customer = await _customers.GetByIdAsync(id, cancellationToken);
        return customer is null ? NotFound() : Ok(ToDto(customer));
    }

    [HttpGet("{id:guid}/transactions")]
    [ProducesResponseType(typeof(List<CustomerTransactionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<List<CustomerTransactionDto>>> GetTransactions(
        Guid id,
        [FromQuery] DateOnly? from,
        [FromQuery] DateOnly? to,
        [FromQuery] string? type,
        CancellationToken cancellationToken = default)
    {
        var customer = await _customers.GetByIdAsync(id, cancellationToken);
        if (customer is null)
        {
            return NotFound();
        }

        var requestedType = NormalizeType(type);
        var items = new List<CustomerTransactionDto>();

        if (requestedType is null or "Invoices" or "Receipts")
        {
            var invoiceSearch = new InvoiceSearch(
                Search: null,
                CustomerId: id,
                PaymentMode: requestedType == "Receipts" ? InvoicePaymentMode.Cash : requestedType == "Invoices" ? InvoicePaymentMode.Credit : null,
                IncludeVoid: true,
                Page: 1,
                PageSize: 500);

            var invoices = await _invoices.SearchAsync(invoiceSearch, cancellationToken);
            items.AddRange(invoices.Items.Select(invoice => new CustomerTransactionDto(
                invoice.Id,
                invoice.PaymentMode == InvoicePaymentMode.Cash ? "Receipt" : "Invoice",
                invoice.InvoiceNumber,
                invoice.InvoiceDate,
                invoice.PaymentMode == InvoicePaymentMode.Cash ? invoice.TotalAmount : invoice.BalanceDue,
                invoice.Status.ToString())));
        }

        if (requestedType is null or "Payments")
        {
            var payments = await _payments.SearchAsync(new PaymentSearch(null, id, null, true, 1, 500), cancellationToken);
            items.AddRange(payments.Items.Select(payment => new CustomerTransactionDto(
                payment.Id,
                "Payment",
                payment.PaymentNumber,
                payment.PaymentDate,
                payment.Amount,
                payment.Status.ToString())));
        }

        var filtered = items
            .Where(item => from is null || item.Date >= from.Value)
            .Where(item => to is null || item.Date <= to.Value)
            .OrderByDescending(item => item.Date)
            .ThenByDescending(item => item.Number)
            .ToList();

        return Ok(filtered);
    }

    [HttpPost]
    [ProducesResponseType(typeof(CustomerDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<CustomerDto>> Create(CreateCustomerRequest request, CancellationToken cancellationToken = default)
    {
        var duplicateValidation = await ValidateUniqueCustomerAsync(request.DisplayName, request.Email, null, cancellationToken);
        if (duplicateValidation is not null)
        {
            return Conflict(duplicateValidation);
        }

        var customer = new Customer(
            request.DisplayName,
            request.CompanyName,
            request.Email,
            request.Phone,
            request.Currency ?? "EGP",
            request.OpeningBalance);

        await _customers.AddAsync(customer, cancellationToken);
        var openingBalanceResult = await _openingBalances.PostCustomerOpeningBalanceAsync(customer, cancellationToken);
        if (!openingBalanceResult.Succeeded)
        {
            return BadRequest(openingBalanceResult.ErrorMessage);
        }

        return CreatedAtAction(nameof(Get), new { id = customer.Id }, ToDto(customer));
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(CustomerDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<CustomerDto>> Update(Guid id, UpdateCustomerRequest request, CancellationToken cancellationToken = default)
    {
        var duplicateValidation = await ValidateUniqueCustomerAsync(request.DisplayName, request.Email, id, cancellationToken);
        if (duplicateValidation is not null)
        {
            return Conflict(duplicateValidation);
        }

        var customer = await _customers.UpdateAsync(
            id,
            request.DisplayName,
            request.CompanyName,
            request.Email,
            request.Phone,
            request.Currency ?? "EGP",
            cancellationToken);

        return customer is null ? NotFound() : Ok(ToDto(customer));
    }

    [HttpPatch("{id:guid}/active")]
    [ProducesResponseType(typeof(CustomerDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CustomerDto>> SetActive(Guid id, SetCustomerActiveRequest request, CancellationToken cancellationToken = default)
    {
        var updated = await _customers.SetActiveAsync(id, request.IsActive, cancellationToken);
        if (!updated)
        {
            return NotFound();
        }

        var customer = await _customers.GetByIdAsync(id, cancellationToken);
        return customer is null ? NotFound() : Ok(ToDto(customer));
    }

    private static string? NormalizeType(string? type)
    {
        if (string.IsNullOrWhiteSpace(type) || type.Equals("All", StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }

        var normalized = type.Trim();
        return normalized.Equals("Receipts", StringComparison.OrdinalIgnoreCase) ? "Receipts"
            : normalized.Equals("Payments", StringComparison.OrdinalIgnoreCase) ? "Payments"
            : normalized.Equals("Invoices", StringComparison.OrdinalIgnoreCase) ? "Invoices"
            : normalized.Equals("Credits", StringComparison.OrdinalIgnoreCase) ? "Credits"
            : normalized.Equals("Returns", StringComparison.OrdinalIgnoreCase) ? "Returns"
            : null;
    }

    private async Task<string?> ValidateUniqueCustomerAsync(
        string displayName,
        string? email,
        Guid? excludingId,
        CancellationToken cancellationToken)
    {
        if (await _customers.DisplayNameExistsAsync(displayName, excludingId, cancellationToken))
        {
            return "Customer display name already exists.";
        }

        if (!string.IsNullOrWhiteSpace(email) && await _customers.EmailExistsAsync(email, excludingId, cancellationToken))
        {
            return "Customer email already exists.";
        }

        return null;
    }

    private static CustomerDto ToDto(Customer customer)
    {
        return new CustomerDto(
            customer.Id,
            customer.DisplayName,
            customer.CompanyName,
            customer.Email,
            customer.Phone,
            customer.Currency,
            customer.Balance,
            customer.CreditBalance,
            customer.IsActive);
    }

    public sealed record CustomerTransactionDto(
        Guid Id,
        string Type,
        string Number,
        DateOnly Date,
        decimal Amount,
        string Status);
}
