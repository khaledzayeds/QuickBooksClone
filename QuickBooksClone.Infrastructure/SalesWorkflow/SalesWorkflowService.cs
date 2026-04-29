using Microsoft.EntityFrameworkCore;
using QuickBooksClone.Core.Common;
using QuickBooksClone.Core.Estimates;
using QuickBooksClone.Core.Invoices;
using QuickBooksClone.Core.Items;
using QuickBooksClone.Core.Payments;
using QuickBooksClone.Core.SalesOrders;
using QuickBooksClone.Core.SalesWorkflow;
using QuickBooksClone.Infrastructure.Persistence;

namespace QuickBooksClone.Infrastructure.SalesWorkflow;

public sealed class SalesWorkflowService : ISalesWorkflowService
{
    private readonly QuickBooksCloneDbContext _db;
    private readonly IEstimateRepository _estimates;
    private readonly ISalesOrderRepository _orders;
    private readonly IInvoiceRepository _invoices;
    private readonly IItemRepository _items;
    private readonly ISalesInvoicePostingService _invoicePostingService;
    private readonly IDocumentNumberService _documentNumbers;

    public SalesWorkflowService(
        QuickBooksCloneDbContext db,
        IEstimateRepository estimates,
        ISalesOrderRepository orders,
        IInvoiceRepository invoices,
        IItemRepository items,
        ISalesInvoicePostingService invoicePostingService,
        IDocumentNumberService documentNumbers)
    {
        _db = db;
        _estimates = estimates;
        _orders = orders;
        _invoices = invoices;
        _items = items;
        _invoicePostingService = invoicePostingService;
        _documentNumbers = documentNumbers;
    }

    public async Task<EstimateSalesOrderPlan?> GetEstimateSalesOrderPlanAsync(Guid estimateId, CancellationToken cancellationToken = default)
    {
        var estimate = await _estimates.GetByIdAsync(estimateId, cancellationToken);
        if (estimate is null)
        {
            return null;
        }

        var orderedByLine = await _db.SalesOrders
            .AsNoTracking()
            .Where(order => order.EstimateId == estimate.Id && order.Status != SalesOrderStatus.Cancelled)
            .SelectMany(order => order.Lines)
            .Where(line => line.EstimateLineId.HasValue)
            .GroupBy(line => line.EstimateLineId!.Value)
            .ToDictionaryAsync(group => group.Key, group => group.Sum(line => line.Quantity), cancellationToken);

        var linkedOrders = await _db.SalesOrders
            .AsNoTracking()
            .Where(order => order.EstimateId == estimate.Id && order.Status != SalesOrderStatus.Cancelled)
            .OrderByDescending(order => order.OrderDate)
            .ThenByDescending(order => order.OrderNumber)
            .Select(order => new LinkedSalesOrderReference(
                order.Id,
                order.OrderNumber,
                order.OrderDate,
                order.Status))
            .ToListAsync(cancellationToken);

        var lines = estimate.Lines.Select(line =>
        {
            var ordered = orderedByLine.GetValueOrDefault(line.Id);
            var remaining = Math.Max(0m, line.Quantity - ordered);
            return new EstimateSalesOrderPlanLine(
                line.Id,
                line.ItemId,
                line.Description,
                line.Quantity,
                ordered,
                remaining,
                remaining,
                line.UnitPrice);
        }).ToList();

        var totalEstimated = lines.Sum(line => line.EstimatedQuantity);
        var totalOrdered = lines.Sum(line => line.OrderedQuantity);
        var totalRemaining = lines.Sum(line => line.RemainingQuantity);

        var canConvert = estimate.Status is not (EstimateStatus.Cancelled or EstimateStatus.Declined) && totalRemaining > 0m;

        return new EstimateSalesOrderPlan(
            estimate.Id,
            estimate.EstimateNumber,
            estimate.CustomerId,
            estimate.Status,
            canConvert,
            totalRemaining == 0m,
            totalEstimated,
            totalOrdered,
            totalRemaining,
            lines,
            linkedOrders);
    }

    public async Task<SalesOrder?> ConvertEstimateToSalesOrderAsync(Guid estimateId, ConvertEstimateToSalesOrderCommand command, CancellationToken cancellationToken = default)
    {
        var plan = await GetEstimateSalesOrderPlanAsync(estimateId, cancellationToken);
        if (plan is null)
        {
            return null;
        }

        if (!plan.CanConvert)
        {
            throw new InvalidOperationException("Estimate cannot be converted to a sales order.");
        }

        var requestedLines = command.Lines.Count == 0
            ? plan.Lines.Where(line => line.RemainingQuantity > 0m)
                .Select(line => new ConvertEstimateToSalesOrderLineCommand(line.EstimateLineId, line.SuggestedOrderQuantity))
                .ToList()
            : command.Lines;

        if (requestedLines.Count == 0)
        {
            throw new InvalidOperationException("At least one estimate line with remaining quantity is required for conversion.");
        }

        var estimate = await _estimates.GetByIdAsync(estimateId, cancellationToken)
            ?? throw new InvalidOperationException("Estimate no longer exists.");

        var allocation = await _documentNumbers.AllocateAsync(DocumentTypes.SalesOrder, cancellationToken);
        var order = new SalesOrder(estimate.CustomerId, command.OrderDate, command.ExpectedDate, estimate.Id, allocation.DocumentNo);
        order.SetSyncIdentity(allocation.DeviceId, allocation.DocumentNo);

        foreach (var requestLine in requestedLines)
        {
            if (requestLine.Quantity <= 0m)
            {
                throw new InvalidOperationException("Converted quantity must be greater than zero.");
            }

            var planLine = plan.Lines.FirstOrDefault(line => line.EstimateLineId == requestLine.EstimateLineId)
                ?? throw new InvalidOperationException($"Estimate line does not exist on the source estimate: {requestLine.EstimateLineId}");

            if (requestLine.Quantity > planLine.RemainingQuantity)
            {
                throw new InvalidOperationException("Converted quantity cannot exceed the remaining estimate quantity.");
            }

            var item = await _items.GetByIdAsync(planLine.ItemId, cancellationToken)
                ?? throw new InvalidOperationException($"Item does not exist: {planLine.ItemId}");

            if (!item.IsActive)
            {
                throw new InvalidOperationException($"Cannot use inactive item on a sales order: {item.Name}");
            }

            var estimateLine = estimate.Lines.First(line => line.Id == planLine.EstimateLineId);
            var taxAmount = ProrateTax(estimateLine.TaxAmount, estimateLine.Quantity, requestLine.Quantity);
            order.AddLine(new SalesOrderLine(
                planLine.ItemId,
                planLine.Description,
                requestLine.Quantity,
                planLine.UnitPrice,
                planLine.EstimateLineId,
                estimateLine.TaxCodeId,
                estimateLine.TaxRatePercent,
                taxAmount));
        }

        await _orders.AddAsync(order, cancellationToken);

        if (command.SaveMode == SalesOrderSaveMode.SaveAsOpen)
        {
            await _orders.MarkOpenAsync(order.Id, cancellationToken);
            await _estimates.AcceptAsync(estimate.Id, cancellationToken);
        }

        return await _orders.GetByIdAsync(order.Id, cancellationToken);
    }

    public async Task<SalesOrderInvoicePlan?> GetSalesOrderInvoicePlanAsync(Guid salesOrderId, CancellationToken cancellationToken = default)
    {
        var order = await _orders.GetByIdAsync(salesOrderId, cancellationToken);
        if (order is null)
        {
            return null;
        }

        var invoicedByLine = await _db.Invoices
            .AsNoTracking()
            .Where(invoice => invoice.SalesOrderId == order.Id && invoice.PaymentMode == InvoicePaymentMode.Credit && invoice.Status != InvoiceStatus.Void)
            .SelectMany(invoice => invoice.Lines)
            .Where(line => line.SalesOrderLineId.HasValue)
            .GroupBy(line => line.SalesOrderLineId!.Value)
            .ToDictionaryAsync(group => group.Key, group => group.Sum(line => line.Quantity), cancellationToken);

        var linkedInvoices = await _db.Invoices
            .AsNoTracking()
            .Where(invoice => invoice.SalesOrderId == order.Id && invoice.PaymentMode == InvoicePaymentMode.Credit && invoice.Status != InvoiceStatus.Void)
            .OrderByDescending(invoice => invoice.InvoiceDate)
            .ThenByDescending(invoice => invoice.InvoiceNumber)
            .Select(invoice => new LinkedInvoiceReference(
                invoice.Id,
                invoice.InvoiceNumber,
                invoice.InvoiceDate,
                invoice.Status))
            .ToListAsync(cancellationToken);

        var lines = order.Lines.Select(line =>
        {
            var invoiced = invoicedByLine.GetValueOrDefault(line.Id);
            var remaining = Math.Max(0m, line.Quantity - invoiced);
            return new SalesOrderInvoicePlanLine(
                line.Id,
                line.ItemId,
                line.EstimateLineId,
                line.Description,
                line.Quantity,
                invoiced,
                remaining,
                remaining,
                line.UnitPrice);
        }).ToList();

        var totalOrdered = lines.Sum(line => line.OrderedQuantity);
        var totalInvoiced = lines.Sum(line => line.InvoicedQuantity);
        var totalRemaining = lines.Sum(line => line.RemainingQuantity);

        var canConvert = order.Status == SalesOrderStatus.Open && totalRemaining > 0m;

        return new SalesOrderInvoicePlan(
            order.Id,
            order.OrderNumber,
            order.CustomerId,
            order.EstimateId,
            order.Status,
            canConvert,
            totalRemaining == 0m,
            totalOrdered,
            totalInvoiced,
            totalRemaining,
            lines,
            linkedInvoices);
    }

    public async Task<Invoice?> ConvertSalesOrderToInvoiceAsync(Guid salesOrderId, ConvertSalesOrderToInvoiceCommand command, CancellationToken cancellationToken = default)
    {
        var plan = await GetSalesOrderInvoicePlanAsync(salesOrderId, cancellationToken);
        if (plan is null)
        {
            return null;
        }

        if (!plan.CanConvert)
        {
            throw new InvalidOperationException("Sales order cannot be converted to an invoice.");
        }

        var requestedLines = command.Lines.Count == 0
            ? plan.Lines.Where(line => line.RemainingQuantity > 0m)
                .Select(line => new ConvertSalesOrderToInvoiceLineCommand(line.SalesOrderLineId, line.SuggestedInvoiceQuantity))
                .ToList()
            : command.Lines;

        if (requestedLines.Count == 0)
        {
            throw new InvalidOperationException("At least one sales-order line with remaining quantity is required for conversion.");
        }

        var order = await _orders.GetByIdAsync(salesOrderId, cancellationToken)
            ?? throw new InvalidOperationException("Sales order no longer exists.");

        var allocation = await _documentNumbers.AllocateAsync(DocumentTypes.Invoice, cancellationToken);
        var invoice = new Invoice(order.CustomerId, command.InvoiceDate, command.DueDate, order.Id, allocation.DocumentNo);
        invoice.SetSyncIdentity(allocation.DeviceId, allocation.DocumentNo);

        foreach (var requestLine in requestedLines)
        {
            if (requestLine.Quantity <= 0m)
            {
                throw new InvalidOperationException("Converted quantity must be greater than zero.");
            }

            var planLine = plan.Lines.FirstOrDefault(line => line.SalesOrderLineId == requestLine.SalesOrderLineId)
                ?? throw new InvalidOperationException($"Sales order line does not exist on the source order: {requestLine.SalesOrderLineId}");

            if (requestLine.Quantity > planLine.RemainingQuantity)
            {
                throw new InvalidOperationException("Converted quantity cannot exceed the remaining sales-order quantity.");
            }

            var item = await _items.GetByIdAsync(planLine.ItemId, cancellationToken)
                ?? throw new InvalidOperationException($"Item does not exist: {planLine.ItemId}");

            var orderLine = order.Lines.First(line => line.Id == planLine.SalesOrderLineId);
            var taxAmount = ProrateTax(orderLine.TaxAmount, orderLine.Quantity, requestLine.Quantity);
            invoice.AddLine(new InvoiceLine(
                planLine.ItemId,
                planLine.Description,
                requestLine.Quantity,
                planLine.UnitPrice,
                requestLine.DiscountPercent,
                planLine.SalesOrderLineId,
                orderLine.TaxCodeId,
                orderLine.TaxRatePercent,
                taxAmount));
        }

        await _invoices.AddAsync(invoice, cancellationToken);

        if (command.SaveMode == InvoiceSaveMode.SaveAndPost)
        {
            var postingResult = await _invoicePostingService.PostAsync(invoice.Id, cancellationToken);
            if (!postingResult.Succeeded)
            {
                throw new InvalidOperationException(postingResult.ErrorMessage ?? "Could not post converted invoice.");
            }
        }

        var refreshedPlan = await GetSalesOrderInvoicePlanAsync(order.Id, cancellationToken)
            ?? throw new InvalidOperationException("Sales order plan could not be reloaded.");
        if (refreshedPlan.TotalRemainingQuantity == 0m)
        {
            await _orders.CloseAsync(order.Id, cancellationToken);
        }

        return await _invoices.GetByIdAsync(invoice.Id, cancellationToken);
    }

    public async Task<InvoicePaymentPlan?> GetInvoicePaymentPlanAsync(Guid invoiceId, CancellationToken cancellationToken = default)
    {
        var invoice = await _invoices.GetByIdAsync(invoiceId, cancellationToken);
        if (invoice is null || invoice.PaymentMode != InvoicePaymentMode.Credit)
        {
            return null;
        }

        var linkedPayments = await _db.Payments
            .AsNoTracking()
            .Where(payment => payment.InvoiceId == invoice.Id && payment.Status != PaymentStatus.Void)
            .OrderByDescending(payment => payment.PaymentDate)
            .ThenByDescending(payment => payment.PaymentNumber)
            .Select(payment => new LinkedPaymentReference(
                payment.Id,
                payment.PaymentNumber,
                payment.PaymentDate,
                payment.Status,
                payment.Amount))
            .ToListAsync(cancellationToken);

        return new InvoicePaymentPlan(
            invoice.Id,
            invoice.InvoiceNumber,
            invoice.CustomerId,
            invoice.SalesOrderId,
            invoice.Status,
            (invoice.Status is InvoiceStatus.Posted or InvoiceStatus.PartiallyPaid) && invoice.BalanceDue > 0m,
            invoice.BalanceDue == 0m,
            invoice.TotalAmount,
            invoice.PaidAmount,
            invoice.CreditAppliedAmount,
            invoice.ReturnedAmount,
            invoice.BalanceDue,
            linkedPayments);
    }

    private static decimal ProrateTax(decimal sourceTaxAmount, decimal sourceQuantity, decimal targetQuantity)
    {
        if (sourceTaxAmount == 0m || sourceQuantity <= 0m)
        {
            return 0m;
        }

        return Math.Round(sourceTaxAmount * targetQuantity / sourceQuantity, 2, MidpointRounding.AwayFromZero);
    }
}
