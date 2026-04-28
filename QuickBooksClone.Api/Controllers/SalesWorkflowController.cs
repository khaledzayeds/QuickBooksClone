using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Api.Contracts.Invoices;
using QuickBooksClone.Api.Contracts.Payments;
using QuickBooksClone.Api.Contracts.SalesOrders;
using QuickBooksClone.Api.Contracts.SalesWorkflow;
using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Customers;
using QuickBooksClone.Core.Estimates;
using QuickBooksClone.Core.Invoices;
using QuickBooksClone.Core.Payments;
using QuickBooksClone.Core.SalesOrders;
using QuickBooksClone.Core.SalesWorkflow;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api")]
public sealed class SalesWorkflowController : ControllerBase
{
    private readonly ISalesWorkflowService _workflow;
    private readonly ICustomerRepository _customers;
    private readonly IEstimateRepository _estimates;
    private readonly ISalesOrderRepository _salesOrders;
    private readonly IInvoiceRepository _invoices;
    private readonly IAccountRepository _accounts;

    public SalesWorkflowController(
        ISalesWorkflowService workflow,
        ICustomerRepository customers,
        IEstimateRepository estimates,
        ISalesOrderRepository salesOrders,
        IInvoiceRepository invoices,
        IAccountRepository accounts)
    {
        _workflow = workflow;
        _customers = customers;
        _estimates = estimates;
        _salesOrders = salesOrders;
        _invoices = invoices;
        _accounts = accounts;
    }

    [HttpGet("estimates/{id:guid}/sales-order-plan")]
    [RequirePermission("Sales.Estimate.Manage")]
    [ProducesResponseType(typeof(EstimateSalesOrderPlanDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<EstimateSalesOrderPlanDto>> GetSalesOrderPlan(Guid id, CancellationToken cancellationToken = default)
    {
        var plan = await _workflow.GetEstimateSalesOrderPlanAsync(id, cancellationToken);
        if (plan is null)
        {
            return NotFound();
        }

        var customer = await _customers.GetByIdAsync(plan.CustomerId, cancellationToken);
        return Ok(new EstimateSalesOrderPlanDto(
            plan.EstimateId,
            plan.EstimateNumber,
            plan.CustomerId,
            customer?.DisplayName,
            plan.Status,
            plan.CanConvert,
            plan.IsFullyConverted,
            plan.TotalEstimatedQuantity,
            plan.TotalOrderedQuantity,
            plan.TotalRemainingQuantity,
            plan.Lines.Select(line => new EstimateSalesOrderPlanLineDto(
                line.EstimateLineId,
                line.ItemId,
                line.Description,
                line.EstimatedQuantity,
                line.OrderedQuantity,
                line.RemainingQuantity,
                line.SuggestedOrderQuantity,
                line.UnitPrice)).ToList(),
            plan.LinkedSalesOrders.Select(order => new LinkedSalesOrderReferenceDto(
                order.Id,
                order.OrderNumber,
                order.OrderDate,
                order.Status)).ToList()));
    }

    [HttpPost("estimates/{id:guid}/convert-to-sales-order")]
    [RequirePermission("Sales.Order.Manage")]
    [ProducesResponseType(typeof(SalesOrderDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<SalesOrderDto>> ConvertEstimateToSalesOrder(Guid id, ConvertEstimateToSalesOrderRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var order = await _workflow.ConvertEstimateToSalesOrderAsync(
                id,
                new ConvertEstimateToSalesOrderCommand(
                    request.OrderDate,
                    request.ExpectedDate,
                    request.SaveMode,
                    request.Lines.Select(line => new ConvertEstimateToSalesOrderLineCommand(line.EstimateLineId, line.Quantity)).ToList()),
                cancellationToken);

            if (order is null)
            {
                return NotFound();
            }

            return CreatedAtAction(nameof(SalesOrdersController.Get), "SalesOrders", new { id = order.Id }, await ToSalesOrderDtoAsync(order, cancellationToken));
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    [HttpGet("sales-orders/{id:guid}/invoice-plan")]
    [RequirePermission("Sales.Order.Manage")]
    [ProducesResponseType(typeof(SalesOrderInvoicePlanDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<SalesOrderInvoicePlanDto>> GetInvoicePlan(Guid id, CancellationToken cancellationToken = default)
    {
        var plan = await _workflow.GetSalesOrderInvoicePlanAsync(id, cancellationToken);
        if (plan is null)
        {
            return NotFound();
        }

        var customer = await _customers.GetByIdAsync(plan.CustomerId, cancellationToken);
        Estimate? estimate = null;
        if (plan.EstimateId is not null)
        {
            estimate = await _estimates.GetByIdAsync(plan.EstimateId.Value, cancellationToken);
        }

        return Ok(new SalesOrderInvoicePlanDto(
            plan.SalesOrderId,
            plan.OrderNumber,
            plan.CustomerId,
            customer?.DisplayName,
            plan.EstimateId,
            estimate?.EstimateNumber,
            plan.Status,
            plan.CanConvert,
            plan.IsFullyInvoiced,
            plan.TotalOrderedQuantity,
            plan.TotalInvoicedQuantity,
            plan.TotalRemainingQuantity,
            plan.Lines.Select(line => new SalesOrderInvoicePlanLineDto(
                line.SalesOrderLineId,
                line.ItemId,
                line.EstimateLineId,
                line.Description,
                line.OrderedQuantity,
                line.InvoicedQuantity,
                line.RemainingQuantity,
                line.SuggestedInvoiceQuantity,
                line.UnitPrice)).ToList(),
            plan.LinkedInvoices.Select(invoice => new LinkedInvoiceReferenceDto(
                invoice.Id,
                invoice.InvoiceNumber,
                invoice.InvoiceDate,
                invoice.Status)).ToList()));
    }

    [HttpPost("sales-orders/{id:guid}/convert-to-invoice")]
    [RequirePermission("Sales.Invoice.Manage")]
    [ProducesResponseType(typeof(InvoiceDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<InvoiceDto>> ConvertSalesOrderToInvoice(Guid id, ConvertSalesOrderToInvoiceRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var invoice = await _workflow.ConvertSalesOrderToInvoiceAsync(
                id,
                new ConvertSalesOrderToInvoiceCommand(
                    request.InvoiceDate,
                    request.DueDate,
                    request.SaveMode,
                    request.Lines.Select(line => new ConvertSalesOrderToInvoiceLineCommand(line.SalesOrderLineId, line.Quantity, line.DiscountPercent)).ToList()),
                cancellationToken);

            if (invoice is null)
            {
                return NotFound();
            }

            return CreatedAtAction(nameof(InvoicesController.Get), "Invoices", new { id = invoice.Id }, await ToInvoiceDtoAsync(invoice, cancellationToken));
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(exception.Message);
        }
    }

    [HttpGet("invoices/{id:guid}/payment-plan")]
    [RequirePermission("Sales.Payment.Manage")]
    [ProducesResponseType(typeof(InvoicePaymentPlanDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<InvoicePaymentPlanDto>> GetPaymentPlan(Guid id, CancellationToken cancellationToken = default)
    {
        var plan = await _workflow.GetInvoicePaymentPlanAsync(id, cancellationToken);
        if (plan is null)
        {
            return NotFound();
        }

        var customer = await _customers.GetByIdAsync(plan.CustomerId, cancellationToken);
        SalesOrder? order = null;
        if (plan.SalesOrderId is not null)
        {
            order = await _salesOrders.GetByIdAsync(plan.SalesOrderId.Value, cancellationToken);
        }

        return Ok(new InvoicePaymentPlanDto(
            plan.InvoiceId,
            plan.InvoiceNumber,
            plan.CustomerId,
            customer?.DisplayName,
            plan.SalesOrderId,
            order?.OrderNumber,
            plan.Status,
            plan.CanReceivePayment,
            plan.IsFullyPaid,
            plan.TotalAmount,
            plan.PaidAmount,
            plan.CreditAppliedAmount,
            plan.ReturnedAmount,
            plan.BalanceDue,
            plan.LinkedPayments.Select(payment => new LinkedPaymentReferenceDto(
                payment.Id,
                payment.PaymentNumber,
                payment.PaymentDate,
                payment.Status,
                payment.Amount)).ToList()));
    }

    private async Task<SalesOrderDto> ToSalesOrderDtoAsync(SalesOrder order, CancellationToken cancellationToken)
    {
        var customer = await _customers.GetByIdAsync(order.CustomerId, cancellationToken);
        return new SalesOrderDto(
            order.Id,
            order.OrderNumber,
            order.CustomerId,
            customer?.DisplayName,
            order.EstimateId,
            order.OrderDate,
            order.ExpectedDate,
            order.Status,
            order.TotalAmount,
            order.OpenedAt,
            order.ClosedAt,
            order.CancelledAt,
            order.Lines.Select(line => new SalesOrderLineDto(
                line.Id,
                line.ItemId,
                line.EstimateLineId,
                line.Description,
                line.Quantity,
                line.UnitPrice,
                line.LineTotal)).ToList());
    }

    private async Task<InvoiceDto> ToInvoiceDtoAsync(Invoice invoice, CancellationToken cancellationToken)
    {
        var customer = await _customers.GetByIdAsync(invoice.CustomerId, cancellationToken);
        var depositAccount = invoice.DepositAccountId is null
            ? null
            : await _accounts.GetByIdAsync(invoice.DepositAccountId.Value, cancellationToken);

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
            depositAccount?.Name,
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
                line.LineTotal)).ToList());
    }
}
