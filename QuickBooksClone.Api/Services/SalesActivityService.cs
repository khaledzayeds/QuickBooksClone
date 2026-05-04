using QuickBooksClone.Api.Contracts.Sales;
using QuickBooksClone.Core.Customers;
using QuickBooksClone.Core.Invoices;
using QuickBooksClone.Core.Payments;

namespace QuickBooksClone.Api.Services;

public sealed class SalesActivityService
{
    private readonly ICustomerRepository _customers;
    private readonly IInvoiceRepository _invoices;
    private readonly IPaymentRepository _payments;

    public SalesActivityService(
        ICustomerRepository customers,
        IInvoiceRepository invoices,
        IPaymentRepository payments)
    {
        _customers = customers;
        _invoices = invoices;
        _payments = payments;
    }

    public async Task<(CustomerSalesActivityDto? Activity, string? Error)> GetCustomerActivityAsync(
        Guid customerId,
        int limit,
        CancellationToken cancellationToken)
    {
        if (customerId == Guid.Empty)
        {
            return (null, "Customer is required.");
        }

        var customer = await _customers.GetByIdAsync(customerId, cancellationToken);
        if (customer is null)
        {
            return (null, "Customer does not exist.");
        }

        var pageSize = Math.Clamp(limit, 1, 20);
        var invoiceResult = await _invoices.SearchAsync(
            new InvoiceSearch(null, customerId, InvoicePaymentMode.Credit, true, 1, pageSize),
            cancellationToken);
        var receiptResult = await _invoices.SearchAsync(
            new InvoiceSearch(null, customerId, InvoicePaymentMode.Cash, true, 1, pageSize),
            cancellationToken);
        var paymentResult = await _payments.SearchAsync(
            new PaymentSearch(null, customerId, null, true, 1, pageSize),
            cancellationToken);

        var warnings = new List<string>();
        if (!customer.IsActive)
        {
            warnings.Add("Customer is inactive.");
        }

        if (customer.Balance > 0)
        {
            warnings.Add("Customer has open balance.");
        }

        if (customer.CreditBalance > 0)
        {
            warnings.Add("Customer has available credits.");
        }

        var activity = new CustomerSalesActivityDto(
            customer.Id,
            customer.DisplayName,
            customer.Currency,
            customer.Balance,
            customer.CreditBalance,
            invoiceResult.Items.Select(ToSalesActivityItem).ToList(),
            receiptResult.Items.Select(ToSalesActivityItem).ToList(),
            paymentResult.Items.Select(ToPaymentActivityItem).ToList(),
            warnings);

        return (activity, null);
    }

    private static CustomerSalesActivityItemDto ToSalesActivityItem(Invoice invoice)
    {
        return new CustomerSalesActivityItemDto(
            invoice.Id,
            invoice.InvoiceNumber,
            invoice.InvoiceDate,
            invoice.DueDate,
            invoice.Status,
            invoice.TotalAmount,
            invoice.PaidAmount,
            invoice.CreditAppliedAmount,
            invoice.ReturnedAmount,
            invoice.BalanceDue);
    }

    private static CustomerPaymentActivityItemDto ToPaymentActivityItem(Payment payment)
    {
        return new CustomerPaymentActivityItemDto(
            payment.Id,
            payment.PaymentNumber,
            payment.InvoiceId,
            payment.PaymentDate,
            payment.Status,
            payment.Amount,
            payment.PaymentMethod);
    }
}
