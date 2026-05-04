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
        var mode = NormalizeDocumentType(documentType);
        if (mode is null)
        {
            return BadRequest("Unsupported printable document type.");
        }

        var (data, error) = await _salesPrintService.GetPrintDataAsync(id, mode.Value, cancellationToken);
        return error is not null ? NotFound(error) : Ok(data);
    }

    private static InvoicePaymentMode? NormalizeDocumentType(string documentType)
    {
        return documentType.Trim().ToLowerInvariant() switch
        {
            "invoice" => InvoicePaymentMode.Credit,
            "sales-receipt" => InvoicePaymentMode.Cash,
            "salesreceipt" => InvoicePaymentMode.Cash,
            _ => null,
        };
    }
}
