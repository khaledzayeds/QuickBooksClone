using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.Documents;

public sealed class DocumentMetadata : SyncDocumentBase, ITenantEntity
{
    private readonly List<DocumentAttachmentMetadata> _attachments = [];

    private DocumentMetadata()
    {
        CompanyId = Guid.Empty;
        DocumentType = string.Empty;
    }

    public DocumentMetadata(string documentType, Guid documentId, Guid? companyId = null)
    {
        if (documentId == Guid.Empty)
        {
            throw new ArgumentException("Document is required.", nameof(documentId));
        }

        CompanyId = companyId ?? Guid.Parse("11111111-1111-1111-1111-111111111111");
        DocumentType = NormalizeDocumentType(documentType);
        DocumentId = documentId;
    }

    public Guid CompanyId { get; }
    public string DocumentType { get; private set; }
    public Guid DocumentId { get; private set; }
    public string? PublicMemo { get; private set; }
    public string? InternalNote { get; private set; }
    public string? ExternalReference { get; private set; }
    public string? TemplateName { get; private set; }
    public string? ShipToName { get; private set; }
    public string? ShipToAddressLine1 { get; private set; }
    public string? ShipToAddressLine2 { get; private set; }
    public string? ShipToCity { get; private set; }
    public string? ShipToRegion { get; private set; }
    public string? ShipToPostalCode { get; private set; }
    public string? ShipToCountry { get; private set; }
    public IReadOnlyList<DocumentAttachmentMetadata> Attachments => _attachments;

    public void UpdateDetails(
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
        string? shipToCountry)
    {
        PublicMemo = NormalizeOptional(publicMemo, 1_000);
        InternalNote = NormalizeOptional(internalNote, 2_000);
        ExternalReference = NormalizeOptional(externalReference, 120);
        TemplateName = NormalizeOptional(templateName, 120);
        ShipToName = NormalizeOptional(shipToName, 200);
        ShipToAddressLine1 = NormalizeOptional(shipToAddressLine1, 200);
        ShipToAddressLine2 = NormalizeOptional(shipToAddressLine2, 200);
        ShipToCity = NormalizeOptional(shipToCity, 120);
        ShipToRegion = NormalizeOptional(shipToRegion, 120);
        ShipToPostalCode = NormalizeOptional(shipToPostalCode, 40);
        ShipToCountry = NormalizeOptional(shipToCountry, 120);
        TouchForLocalChange();
    }

    public DocumentAttachmentMetadata AddAttachment(string fileName, string? contentType, long fileSizeBytes, string storageKey)
    {
        var attachment = new DocumentAttachmentMetadata(fileName, contentType, fileSizeBytes, storageKey);
        _attachments.Add(attachment);
        TouchForLocalChange();
        return attachment;
    }

    public bool RemoveAttachment(Guid attachmentId)
    {
        var attachment = _attachments.SingleOrDefault(current => current.Id == attachmentId);
        if (attachment is null)
        {
            return false;
        }

        _attachments.Remove(attachment);
        TouchForLocalChange();
        return true;
    }

    public static string NormalizeDocumentType(string documentType)
    {
        if (string.IsNullOrWhiteSpace(documentType))
        {
            throw new ArgumentException("Document type is required.", nameof(documentType));
        }

        var normalized = documentType.Trim().ToLowerInvariant() switch
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
            _ => throw new ArgumentOutOfRangeException(nameof(documentType), "Unsupported document type.")
        };

        return normalized;
    }

    private static string? NormalizeOptional(string? value, int maxLength)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        var normalized = value.Trim();
        if (normalized.Length > maxLength)
        {
            throw new ArgumentOutOfRangeException(nameof(value), $"Value must be {maxLength} characters or fewer.");
        }

        return normalized;
    }
}
