using System.Text;
using Microsoft.EntityFrameworkCore;
using QuickBooksClone.Core.Common;
using QuickBooksClone.Core.Settings;

namespace QuickBooksClone.Infrastructure.Persistence;

public sealed class DocumentNumberService : IDocumentNumberService
{
    private readonly QuickBooksCloneDbContext _db;
    private readonly IDeviceSettingsRepository _deviceSettings;

    public DocumentNumberService(QuickBooksCloneDbContext db, IDeviceSettingsRepository deviceSettings)
    {
        _db = db;
        _deviceSettings = deviceSettings;
    }

    public async Task<DocumentNumberAllocation> AllocateAsync(string documentType, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(documentType))
        {
            throw new ArgumentException("Document type is required.", nameof(documentType));
        }

        var settings = await _deviceSettings.GetOrCreateAsync(cancellationToken);
        var normalizedDocumentType = documentType.Trim().ToUpperInvariant();
        var year = DateTime.UtcNow.Year;

        var counter = await _db.DocumentSequenceCounters
            .SingleOrDefaultAsync(
                current => current.DeviceId == settings.DeviceId
                    && current.DocumentType == normalizedDocumentType
                    && current.Year == year,
                cancellationToken);

        int sequence;
        if (counter is null)
        {
            sequence = 1;
            counter = new DocumentSequenceCounter(settings.DeviceId, normalizedDocumentType, year, 2);
            _db.DocumentSequenceCounters.Add(counter);
        }
        else
        {
            sequence = counter.ReserveNext();
        }

        await _db.SaveChangesAsync(cancellationToken);

        var typeCode = GetDocumentTypeCode(normalizedDocumentType);
        var deviceCode = NormalizeDeviceCode(settings.DeviceId);
        var documentNo = $"{typeCode}{deviceCode}-{sequence:D6}";

        return new DocumentNumberAllocation(settings.DeviceId, documentNo, normalizedDocumentType, year, sequence);
    }

    private static string GetDocumentTypeCode(string documentType) => documentType switch
    {
        DocumentTypes.Invoice => "1",
        DocumentTypes.SalesReceipt => "2",
        DocumentTypes.PurchaseOrder => "3",
        DocumentTypes.InventoryReceipt => "4",
        DocumentTypes.PurchaseBill => "5",
        DocumentTypes.VendorPayment => "6",
        DocumentTypes.Payment => "7",
        DocumentTypes.SalesReturn => "8",
        DocumentTypes.PurchaseReturn => "9",
        DocumentTypes.Estimate => "10",
        DocumentTypes.SalesOrder => "11",
        DocumentTypes.CustomerCredit => "12",
        DocumentTypes.VendorCredit => "13",
        DocumentTypes.JournalEntry => "14",
        DocumentTypes.InventoryAdjustment => "15",
        _ => "99"
    };

    private static string NormalizeDeviceCode(string? deviceId)
    {
        if (string.IsNullOrWhiteSpace(deviceId))
        {
            return "000";
        }

        var digits = new StringBuilder();
        foreach (var ch in deviceId)
        {
            if (char.IsDigit(ch))
            {
                digits.Append(ch);
            }
        }

        var numeric = digits.ToString();
        if (string.IsNullOrWhiteSpace(numeric))
        {
            return "000";
        }

        if (numeric.Length > 3)
        {
            numeric = numeric[^3..];
        }

        return numeric.PadLeft(3, '0');
    }
}
