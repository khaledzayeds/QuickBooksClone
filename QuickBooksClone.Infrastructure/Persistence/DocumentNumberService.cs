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

        var documentNo = $"{settings.DeviceId}-{year:D4}-{sequence:D5}";
        return new DocumentNumberAllocation(settings.DeviceId, documentNo, normalizedDocumentType, year, sequence);
    }
}
