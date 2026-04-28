using Microsoft.EntityFrameworkCore;
using QuickBooksClone.Core.Documents;
using QuickBooksClone.Core.Settings;
using QuickBooksClone.Infrastructure.Persistence;

namespace QuickBooksClone.Infrastructure.Documents;

public sealed class DocumentMetadataService : IDocumentMetadataService
{
    private readonly QuickBooksCloneDbContext _db;
    private readonly IDeviceSettingsRepository _deviceSettings;

    public DocumentMetadataService(QuickBooksCloneDbContext db, IDeviceSettingsRepository deviceSettings)
    {
        _db = db;
        _deviceSettings = deviceSettings;
    }

    public async Task<DocumentMetadata> GetOrCreateAsync(string documentType, Guid documentId, CancellationToken cancellationToken = default)
    {
        var normalizedType = DocumentMetadata.NormalizeDocumentType(documentType);
        await EnsureDocumentExistsAsync(normalizedType, documentId, cancellationToken);

        var metadata = await LoadMetadataAsync(normalizedType, documentId, cancellationToken);
        if (metadata is not null)
        {
            return metadata;
        }

        metadata = new DocumentMetadata(normalizedType, documentId);
        var settings = await _deviceSettings.GetOrCreateAsync(cancellationToken);
        metadata.SetSyncIdentity(settings.DeviceId, $"META-{normalizedType.ToUpperInvariant()}-{documentId:N}");
        metadata.MarkPendingSync();
        _db.DocumentMetadata.Add(metadata);
        await _db.SaveChangesAsync(cancellationToken);
        return metadata;
    }

    public async Task<DocumentMetadata> UpdateAsync(
        string documentType,
        Guid documentId,
        string? publicMemo,
        string? internalNote,
        string? externalReference,
        string? templateName,
        string? shipToName,
        string? shipToAddressLine1,
        string? shipToAddressLine2,
        string? shipToCity,
        string? shipToRegion,
        string? shipToPostalCode,
        string? shipToCountry,
        CancellationToken cancellationToken = default)
    {
        var metadata = await GetOrCreateAsync(documentType, documentId, cancellationToken);
        metadata.UpdateDetails(
            publicMemo,
            internalNote,
            externalReference,
            templateName,
            shipToName,
            shipToAddressLine1,
            shipToAddressLine2,
            shipToCity,
            shipToRegion,
            shipToPostalCode,
            shipToCountry);

        await _db.SaveChangesAsync(cancellationToken);
        return metadata;
    }

    public async Task<DocumentAttachmentMetadata> AddAttachmentAsync(
        string documentType,
        Guid documentId,
        string fileName,
        string? contentType,
        long fileSizeBytes,
        string storageKey,
        CancellationToken cancellationToken = default)
    {
        var metadata = await GetOrCreateAsync(documentType, documentId, cancellationToken);
        var attachment = metadata.AddAttachment(fileName, contentType, fileSizeBytes, storageKey);
        await _db.SaveChangesAsync(cancellationToken);
        return attachment;
    }

    public async Task<bool> RemoveAttachmentAsync(string documentType, Guid documentId, Guid attachmentId, CancellationToken cancellationToken = default)
    {
        var normalizedType = DocumentMetadata.NormalizeDocumentType(documentType);
        var metadata = await LoadMetadataAsync(normalizedType, documentId, cancellationToken);
        if (metadata is null)
        {
            return false;
        }

        var removed = metadata.RemoveAttachment(attachmentId);
        if (!removed)
        {
            return false;
        }

        await _db.SaveChangesAsync(cancellationToken);
        return true;
    }

    private Task<DocumentMetadata?> LoadMetadataAsync(string documentType, Guid documentId, CancellationToken cancellationToken) =>
        _db.DocumentMetadata
            .Include(current => current.Attachments)
            .SingleOrDefaultAsync(current => current.DocumentType == documentType && current.DocumentId == documentId, cancellationToken);

    private async Task EnsureDocumentExistsAsync(string documentType, Guid documentId, CancellationToken cancellationToken)
    {
        bool exists;

        switch (documentType)
        {
            case "estimate":
                exists = await _db.Estimates.AnyAsync(current => current.Id == documentId, cancellationToken);
                break;
            case "sales-order":
                exists = await _db.SalesOrders.AnyAsync(current => current.Id == documentId, cancellationToken);
                break;
            case "invoice":
                exists = await _db.Invoices.AnyAsync(current => current.Id == documentId, cancellationToken);
                break;
            case "payment":
                exists = await _db.Payments.AnyAsync(current => current.Id == documentId, cancellationToken);
                break;
            case "purchase-order":
                exists = await _db.PurchaseOrders.AnyAsync(current => current.Id == documentId, cancellationToken);
                break;
            case "inventory-receipt":
                exists = await _db.InventoryReceipts.AnyAsync(current => current.Id == documentId, cancellationToken);
                break;
            case "purchase-bill":
                exists = await _db.PurchaseBills.AnyAsync(current => current.Id == documentId, cancellationToken);
                break;
            case "vendor-payment":
                exists = await _db.VendorPayments.AnyAsync(current => current.Id == documentId, cancellationToken);
                break;
            case "sales-return":
                exists = await _db.SalesReturns.AnyAsync(current => current.Id == documentId, cancellationToken);
                break;
            case "purchase-return":
                exists = await _db.PurchaseReturns.AnyAsync(current => current.Id == documentId, cancellationToken);
                break;
            case "customer-credit":
                exists = await _db.CustomerCreditActivities.AnyAsync(current => current.Id == documentId, cancellationToken);
                break;
            case "vendor-credit":
                exists = await _db.VendorCreditActivities.AnyAsync(current => current.Id == documentId, cancellationToken);
                break;
            case "journal-entry":
                exists = await _db.JournalEntries.AnyAsync(current => current.Id == documentId, cancellationToken);
                break;
            case "inventory-adjustment":
                exists = await _db.InventoryAdjustments.AnyAsync(current => current.Id == documentId, cancellationToken);
                break;
            default:
                throw new ArgumentOutOfRangeException(nameof(documentType), "Unsupported document type.");
        }

        if (!exists)
        {
            throw new KeyNotFoundException("Document was not found.");
        }
    }
}
