using Microsoft.EntityFrameworkCore;
using QuickBooksClone.Core.Common;
using QuickBooksClone.Core.CustomerCredits;
using QuickBooksClone.Core.Documents;
using QuickBooksClone.Core.Estimates;
using QuickBooksClone.Core.InventoryAdjustments;
using QuickBooksClone.Core.Invoices;
using QuickBooksClone.Core.JournalEntries;
using QuickBooksClone.Core.Payments;
using QuickBooksClone.Core.PurchaseBills;
using QuickBooksClone.Core.PurchaseOrders;
using QuickBooksClone.Core.PurchaseReturns;
using QuickBooksClone.Core.ReceiveInventory;
using QuickBooksClone.Core.SalesOrders;
using QuickBooksClone.Core.SalesReturns;
using QuickBooksClone.Core.Sync;
using QuickBooksClone.Core.VendorCredits;
using QuickBooksClone.Core.VendorPayments;
using QuickBooksClone.Infrastructure.Persistence;

namespace QuickBooksClone.Infrastructure.Sync;

public sealed class SyncDiagnosticsService : ISyncDiagnosticsService
{
    private readonly QuickBooksCloneDbContext _db;

    public SyncDiagnosticsService(QuickBooksCloneDbContext db)
    {
        _db = db;
    }

    public async Task<SyncOverview> GetOverviewAsync(CancellationToken cancellationToken = default)
    {
        var summaries = new List<SyncDocumentTypeSummary>
        {
            await GetSummaryAsync<Estimate>("estimate", cancellationToken),
            await GetSummaryAsync<SalesOrder>("sales-order", cancellationToken),
            await GetSummaryAsync<Invoice>("invoice", cancellationToken),
            await GetSummaryAsync<Payment>("payment", cancellationToken),
            await GetSummaryAsync<PurchaseOrder>("purchase-order", cancellationToken),
            await GetSummaryAsync<InventoryReceipt>("inventory-receipt", cancellationToken),
            await GetSummaryAsync<PurchaseBill>("purchase-bill", cancellationToken),
            await GetSummaryAsync<VendorPayment>("vendor-payment", cancellationToken),
            await GetSummaryAsync<SalesReturn>("sales-return", cancellationToken),
            await GetSummaryAsync<PurchaseReturn>("purchase-return", cancellationToken),
            await GetSummaryAsync<CustomerCreditActivity>("customer-credit", cancellationToken),
            await GetSummaryAsync<VendorCreditActivity>("vendor-credit", cancellationToken),
            await GetSummaryAsync<JournalEntry>("journal-entry", cancellationToken),
            await GetSummaryAsync<InventoryAdjustment>("inventory-adjustment", cancellationToken),
            await GetSummaryAsync<DocumentMetadata>("document-metadata", cancellationToken)
        };

        return new SyncOverview(
            DateTimeOffset.UtcNow,
            summaries,
            summaries.Sum(current => current.TotalDocuments),
            summaries.Sum(current => current.LocalOnlyCount),
            summaries.Sum(current => current.PendingSyncCount),
            summaries.Sum(current => current.SyncedCount),
            summaries.Sum(current => current.SyncFailedCount));
    }

    public async Task<IReadOnlyList<SyncDocumentSnapshot>> ListDocumentsAsync(
        SyncStatus? status = null,
        string? documentType = null,
        int take = 200,
        CancellationToken cancellationToken = default)
    {
        var normalizedType = NormalizeDocumentType(documentType);
        var limit = Math.Clamp(take, 1, 500);
        var snapshots = new List<SyncDocumentSnapshot>();

        await AppendDocumentsAsync<Estimate>(snapshots, "estimate", normalizedType, status, cancellationToken);
        await AppendDocumentsAsync<SalesOrder>(snapshots, "sales-order", normalizedType, status, cancellationToken);
        await AppendDocumentsAsync<Invoice>(snapshots, "invoice", normalizedType, status, cancellationToken);
        await AppendDocumentsAsync<Payment>(snapshots, "payment", normalizedType, status, cancellationToken);
        await AppendDocumentsAsync<PurchaseOrder>(snapshots, "purchase-order", normalizedType, status, cancellationToken);
        await AppendDocumentsAsync<InventoryReceipt>(snapshots, "inventory-receipt", normalizedType, status, cancellationToken);
        await AppendDocumentsAsync<PurchaseBill>(snapshots, "purchase-bill", normalizedType, status, cancellationToken);
        await AppendDocumentsAsync<VendorPayment>(snapshots, "vendor-payment", normalizedType, status, cancellationToken);
        await AppendDocumentsAsync<SalesReturn>(snapshots, "sales-return", normalizedType, status, cancellationToken);
        await AppendDocumentsAsync<PurchaseReturn>(snapshots, "purchase-return", normalizedType, status, cancellationToken);
        await AppendDocumentsAsync<CustomerCreditActivity>(snapshots, "customer-credit", normalizedType, status, cancellationToken);
        await AppendDocumentsAsync<VendorCreditActivity>(snapshots, "vendor-credit", normalizedType, status, cancellationToken);
        await AppendDocumentsAsync<JournalEntry>(snapshots, "journal-entry", normalizedType, status, cancellationToken);
        await AppendDocumentsAsync<InventoryAdjustment>(snapshots, "inventory-adjustment", normalizedType, status, cancellationToken);
        await AppendDocumentsAsync<DocumentMetadata>(snapshots, "document-metadata", normalizedType, status, cancellationToken);

        return snapshots
            .OrderByDescending(current => current.LastModifiedAt)
            .ThenBy(current => current.DocumentType)
            .Take(limit)
            .ToList();
    }

    public async Task<bool> MarkPendingAsync(string documentType, Guid id, CancellationToken cancellationToken = default)
    {
        var normalizedType = NormalizeDocumentType(documentType)
            ?? throw new ArgumentException("Document type is required.", nameof(documentType));

        SyncDocumentBase? document = normalizedType switch
        {
            "estimate" => await _db.Estimates.SingleOrDefaultAsync(current => current.Id == id, cancellationToken),
            "sales-order" => await _db.SalesOrders.SingleOrDefaultAsync(current => current.Id == id, cancellationToken),
            "invoice" => await _db.Invoices.SingleOrDefaultAsync(current => current.Id == id, cancellationToken),
            "payment" => await _db.Payments.SingleOrDefaultAsync(current => current.Id == id, cancellationToken),
            "purchase-order" => await _db.PurchaseOrders.SingleOrDefaultAsync(current => current.Id == id, cancellationToken),
            "inventory-receipt" => await _db.InventoryReceipts.SingleOrDefaultAsync(current => current.Id == id, cancellationToken),
            "purchase-bill" => await _db.PurchaseBills.SingleOrDefaultAsync(current => current.Id == id, cancellationToken),
            "vendor-payment" => await _db.VendorPayments.SingleOrDefaultAsync(current => current.Id == id, cancellationToken),
            "sales-return" => await _db.SalesReturns.SingleOrDefaultAsync(current => current.Id == id, cancellationToken),
            "purchase-return" => await _db.PurchaseReturns.SingleOrDefaultAsync(current => current.Id == id, cancellationToken),
            "customer-credit" => await _db.CustomerCreditActivities.SingleOrDefaultAsync(current => current.Id == id, cancellationToken),
            "vendor-credit" => await _db.VendorCreditActivities.SingleOrDefaultAsync(current => current.Id == id, cancellationToken),
            "journal-entry" => await _db.JournalEntries.SingleOrDefaultAsync(current => current.Id == id, cancellationToken),
            "inventory-adjustment" => await _db.InventoryAdjustments.SingleOrDefaultAsync(current => current.Id == id, cancellationToken),
            "document-metadata" => await _db.DocumentMetadata.SingleOrDefaultAsync(current => current.Id == id, cancellationToken),
            _ => throw new ArgumentOutOfRangeException(nameof(documentType), "Unsupported document type.")
        };

        if (document is null)
        {
            return false;
        }

        document.MarkPendingSync();
        await _db.SaveChangesAsync(cancellationToken);
        return true;
    }

    private async Task<SyncDocumentTypeSummary> GetSummaryAsync<TDocument>(string documentType, CancellationToken cancellationToken)
        where TDocument : SyncDocumentBase
    {
        var query = _db.Set<TDocument>().AsNoTracking();
        var total = await query.CountAsync(cancellationToken);
        var localOnly = await query.CountAsync(current => current.SyncStatus == SyncStatus.LocalOnly, cancellationToken);
        var pending = await query.CountAsync(current => current.SyncStatus == SyncStatus.PendingSync, cancellationToken);
        var synced = await query.CountAsync(current => current.SyncStatus == SyncStatus.Synced, cancellationToken);
        var failed = await query.CountAsync(current => current.SyncStatus == SyncStatus.SyncFailed, cancellationToken);
        var lastModifiedCandidates = await query
            .Select(current => current.LastModifiedAt)
            .ToListAsync(cancellationToken);
        DateTimeOffset? lastModified = lastModifiedCandidates.Count == 0
            ? null
            : lastModifiedCandidates.Max();

        return new SyncDocumentTypeSummary(documentType, total, localOnly, pending, synced, failed, lastModified);
    }

    private async Task AppendDocumentsAsync<TDocument>(
        ICollection<SyncDocumentSnapshot> snapshots,
        string documentType,
        string? requestedType,
        SyncStatus? status,
        CancellationToken cancellationToken)
        where TDocument : SyncDocumentBase
    {
        if (requestedType is not null && requestedType != documentType)
        {
            return;
        }

        var query = _db.Set<TDocument>().AsNoTracking();
        if (status.HasValue)
        {
            query = query.Where(current => current.SyncStatus == status.Value);
        }

        var documents = await query
            .Select(current => new SyncDocumentSnapshot(
                documentType,
                current.Id,
                current.DocumentNo,
                current.DeviceId,
                current.SyncStatus,
                current.SyncVersion,
                current.CreatedAt,
                current.LastModifiedAt,
                current.LastSyncAt,
                current.SyncError))
            .ToListAsync(cancellationToken);

        foreach (var document in documents)
        {
            snapshots.Add(document);
        }
    }

    private static string? NormalizeDocumentType(string? documentType)
    {
        if (string.IsNullOrWhiteSpace(documentType))
        {
            return null;
        }

        return documentType.Trim().ToLowerInvariant() switch
        {
            "estimate" or "estimates" => "estimate",
            "sales-order" or "salesorder" or "salesorders" => "sales-order",
            "invoice" or "invoices" => "invoice",
            "payment" or "payments" => "payment",
            "purchase-order" or "purchaseorder" or "purchaseorders" => "purchase-order",
            "inventory-receipt" or "inventoryreceipt" or "inventoryreceipts" or "receive-inventory" => "inventory-receipt",
            "purchase-bill" or "purchasebill" or "purchasebills" or "bill" or "bills" => "purchase-bill",
            "vendor-payment" or "vendorpayment" or "vendorpayments" => "vendor-payment",
            "sales-return" or "salesreturn" or "salesreturns" => "sales-return",
            "purchase-return" or "purchasereturn" or "purchasereturns" => "purchase-return",
            "customer-credit" or "customercredit" or "customercredits" => "customer-credit",
            "vendor-credit" or "vendorcredit" or "vendorcredits" => "vendor-credit",
            "journal-entry" or "journalentry" or "journalentries" => "journal-entry",
            "inventory-adjustment" or "inventoryadjustment" or "inventoryadjustments" => "inventory-adjustment",
            "document-metadata" or "documentmetadata" => "document-metadata",
            _ => throw new ArgumentOutOfRangeException(nameof(documentType), "Unsupported document type.")
        };
    }
}
