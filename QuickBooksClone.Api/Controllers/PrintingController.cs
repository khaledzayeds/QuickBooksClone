using Microsoft.AspNetCore.Mvc;
using QuickBooksClone.Api.Contracts.Sales;
using QuickBooksClone.Api.Middleware;
using QuickBooksClone.Api.Security;
using QuickBooksClone.Api.Services;
using QuickBooksClone.Core.Invoices;

namespace QuickBooksClone.Api.Controllers;

[ApiController]
[Route("api/printing")]
[RequireAuthenticated]
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
        var normalizedDocumentType = NormalizeDocumentType(documentType);
        var requiredPermission = RequiredPermissionFor(normalizedDocumentType);
        if (requiredPermission is null)
        {
            return BadRequest("Unsupported printable document type.");
        }

        if (!CurrentUserHasPermission(requiredPermission))
        {
            return StatusCode(StatusCodes.Status403Forbidden, $"Missing permission: {requiredPermission}.");
        }

        string? createdByName = null;
        if (HttpContext.Items[PermissionAuthorizationMiddleware.CurrentUserItemKey] is CurrentUserContext currentUser)
        {
            createdByName = currentUser.DisplayName ?? currentUser.UserName;
        }

        var (data, error) = await GetDataAsync(normalizedDocumentType, id, createdByName, cancellationToken);
        return error is not null ? NotFound(error) : Ok(data);
    }

    private Task<(SalesPrintDataDto? Data, string? Error)> GetDataAsync(
        string documentType,
        Guid id,
        string? createdByName,
        CancellationToken cancellationToken)
    {
        return documentType switch
        {
            "invoice" => _salesPrintService.GetPrintDataAsync(id, InvoicePaymentMode.Credit, createdByName, cancellationToken),
            "sales-receipt" => _salesPrintService.GetPrintDataAsync(id, InvoicePaymentMode.Cash, createdByName, cancellationToken),
            "estimate" => _salesPrintService.GetEstimatePrintDataAsync(id, createdByName, cancellationToken),
            "sales-return" => _salesPrintService.GetSalesReturnPrintDataAsync(id, createdByName, cancellationToken),
            "purchase-order" => _salesPrintService.GetPurchaseOrderPrintDataAsync(id, createdByName, cancellationToken),
            "receive-inventory" => _salesPrintService.GetInventoryReceiptPrintDataAsync(id, createdByName, cancellationToken),
            "inventory-adjustment" => _salesPrintService.GetInventoryAdjustmentPrintDataAsync(id, createdByName, cancellationToken),
            _ => Task.FromResult<(SalesPrintDataDto? Data, string? Error)>((null, "Unsupported printable document type.")),
        };
    }

    private bool CurrentUserHasPermission(string permission)
    {
        if (HttpContext.Items[PermissionAuthorizationMiddleware.CurrentUserItemKey] is not CurrentUserContext currentUser)
        {
            return false;
        }

        return currentUser.Permissions.Contains(permission, StringComparer.OrdinalIgnoreCase);
    }

    private static string NormalizeDocumentType(string documentType)
    {
        return documentType.Trim().ToLowerInvariant() switch
        {
            "salesreceipt" => "sales-receipt",
            "salesreturn" => "sales-return",
            "purchaseorder" => "purchase-order",
            "receiveinventory" or "inventory-receipt" or "inventoryreceipt" => "receive-inventory",
            "inventoryadjustment" => "inventory-adjustment",
            var value => value,
        };
    }

    private static string? RequiredPermissionFor(string documentType)
    {
        return documentType switch
        {
            "invoice" or "sales-receipt" => "Sales.Invoice.Manage",
            "estimate" => "Sales.Estimate.Manage",
            "sales-return" => "Sales.Return.Manage",
            "purchase-order" => "Purchases.Order.Manage",
            "receive-inventory" => "Purchases.Receive.Manage",
            "inventory-adjustment" => "Inventory.Adjust.Manage",
            _ => null,
        };
    }
}
