using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.Sales;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Api.Services;
using QuickBooksClone.Core.Invoices;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/printing")]
[RequirePermission("Sales.Invoice.Manage")]
public sealed class PrintingController : ControllerBase
{
    private readonly SalesPrintService _salesPrintService;

    public PrintingController(SalesPrintService salesPrintService)
    {
        _salesPrintService = salesPrintService;
    }

    [HttpGet("documents/{documentType}/{id:guid}/data")]
    [ProducesResponseType(typeof(SalesPrintDataDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<SalesPrintDataDto>> GetDocumentPrintData(
        string documentType,
        Guid id,
        CancellationToken cancellationToken = default)
    {
        var (data, error) = await GetDataAsync(documentType, id, cancellationToken);
        return error is not null ? NotFound(error) : Ok(data);
    }

    private Task<(SalesPrintDataDto? Data, string? Error)> GetDataAsync(
        string documentType,
        Guid id,
        CancellationToken cancellationToken)
    {
        return documentType.Trim().ToLowerInvariant() switch
        {
            "invoice" => _salesPrintService.GetPrintDataAsync(id, InvoicePaymentMode.Credit, cancellationToken),
            "sales-receipt" or "salesreceipt" => _salesPrintService.GetPrintDataAsync(id, InvoicePaymentMode.Cash, cancellationToken),
            "estimate" => _salesPrintService.GetEstimatePrintDataAsync(id, cancellationToken),
            "sales-return" or "salesreturn" => _salesPrintService.GetSalesReturnPrintDataAsync(id, cancellationToken),
            "purchase-order" or "purchaseorder" => _salesPrintService.GetPurchaseOrderPrintDataAsync(id, cancellationToken),
            "receive-inventory" or "receiveinventory" or "inventory-receipt" or "inventoryreceipt" => _salesPrintService.GetInventoryReceiptPrintDataAsync(id, cancellationToken),
            "inventory-adjustment" or "inventoryadjustment" => _salesPrintService.GetInventoryAdjustmentPrintDataAsync(id, cancellationToken),
            _ => Task.FromResult<(SalesPrintDataDto? Data, string? Error)>((null, "Unsupported printable document type.")),
        };
    }
}
