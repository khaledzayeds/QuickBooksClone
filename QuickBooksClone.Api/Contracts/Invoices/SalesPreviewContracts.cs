using QuickBooksClone.Core.Invoices;

namespace QuickBooksClone.Api.Contracts.Invoices;

public sealed record PreviewSalesLineRequest(
    Guid ItemId,
    string? Description,
    decimal Quantity,
    decimal UnitPrice,
    decimal DiscountPercent = 0,
    Guid? TaxCodeId = null);

public sealed record PreviewInvoiceRequest(
    Guid CustomerId,
    DateTime InvoiceDate,
    DateTime DueDate,
    IReadOnlyList<PreviewSalesLineRequest> Lines);

public sealed record PreviewSalesReceiptRequest(
    Guid CustomerId,
    DateTime ReceiptDate,
    Guid DepositAccountId,
    string? PaymentMethod,
    IReadOnlyList<PreviewSalesLineRequest> Lines);

public sealed record SalesPostingPreviewDto(
    InvoicePaymentMode PaymentMode,
    decimal Subtotal,
    decimal DiscountTotal,
    decimal TaxTotal,
    decimal Total,
    decimal PaidAmount,
    decimal BalanceDue,
    IReadOnlyList<SalesPostingPreviewLineDto> Lines,
    IReadOnlyList<SalesLedgerImpactDto> LedgerImpacts,
    IReadOnlyList<SalesInventoryImpactDto> InventoryImpacts,
    IReadOnlyList<string> Warnings);

public sealed record SalesPostingPreviewLineDto(
    Guid ItemId,
    string ItemName,
    string Description,
    decimal Quantity,
    decimal UnitPrice,
    decimal DiscountPercent,
    decimal DiscountAmount,
    decimal TaxRatePercent,
    decimal TaxAmount,
    decimal LineTotal,
    decimal? CurrentStock,
    decimal? ProjectedStock,
    decimal? UnitCost,
    decimal? GrossMargin,
    IReadOnlyList<string> Warnings);

public sealed record SalesLedgerImpactDto(
    string AccountRole,
    Guid? AccountId,
    string AccountName,
    decimal Debit,
    decimal Credit,
    string Memo);

public sealed record SalesInventoryImpactDto(
    Guid ItemId,
    string ItemName,
    decimal QuantityChange,
    decimal? CurrentStock,
    decimal? ProjectedStock,
    decimal? UnitCost,
    decimal? InventoryValueChange,
    string Memo);
