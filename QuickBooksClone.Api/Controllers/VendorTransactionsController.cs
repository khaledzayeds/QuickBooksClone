using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Core.PurchaseBills;
using QuickBooksClone.Core.VendorPayments;
using QuickBooksClone.Core.Vendors;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/vendors/{vendorId:guid}/transactions")]
[RequirePermission("Vendors.Manage")]
public sealed class VendorTransactionsController : ControllerBase
{
    private readonly IVendorRepository _vendors;
    private readonly IPurchaseBillRepository _purchaseBills;
    private readonly IVendorPaymentRepository _vendorPayments;

    public VendorTransactionsController(
        IVendorRepository vendors,
        IPurchaseBillRepository purchaseBills,
        IVendorPaymentRepository vendorPayments)
    {
        _vendors = vendors;
        _purchaseBills = purchaseBills;
        _vendorPayments = vendorPayments;
    }

    [HttpGet]
    [ProducesResponseType(typeof(List<VendorTransactionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<List<VendorTransactionDto>>> Get(
        Guid vendorId,
        [FromQuery] DateOnly? from,
        [FromQuery] DateOnly? to,
        [FromQuery] string? type,
        CancellationToken cancellationToken = default)
    {
        var vendor = await _vendors.GetByIdAsync(vendorId, cancellationToken);
        if (vendor is null)
        {
            return NotFound();
        }

        var requestedType = NormalizeType(type);
        var items = new List<VendorTransactionDto>();

        if (requestedType is null or "Bills")
        {
            var bills = await _purchaseBills.SearchAsync(
                new PurchaseBillSearch(null, vendorId, null, true, 1, 500),
                cancellationToken);

            items.AddRange(bills.Items.Select(bill => new VendorTransactionDto(
                bill.Id,
                "Bill",
                bill.BillNumber,
                bill.BillDate,
                bill.BalanceDue,
                bill.Status.ToString())));
        }

        if (requestedType is null or "Payments")
        {
            var payments = await _vendorPayments.SearchAsync(
                new VendorPaymentSearch(null, vendorId, null, true, 1, 500),
                cancellationToken);

            items.AddRange(payments.Items.Select(payment => new VendorTransactionDto(
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

    private static string? NormalizeType(string? type)
    {
        if (string.IsNullOrWhiteSpace(type) || type.Equals("All", StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }

        var normalized = type.Trim();
        return normalized.Equals("Bills", StringComparison.OrdinalIgnoreCase) ? "Bills"
            : normalized.Equals("Payments", StringComparison.OrdinalIgnoreCase) ? "Payments"
            : normalized.Equals("Credits", StringComparison.OrdinalIgnoreCase) ? "Credits"
            : normalized.Equals("Returns", StringComparison.OrdinalIgnoreCase) ? "Returns"
            : null;
    }

    public sealed record VendorTransactionDto(
        Guid Id,
        string Type,
        string Number,
        DateOnly Date,
        decimal Amount,
        string Status);
}
