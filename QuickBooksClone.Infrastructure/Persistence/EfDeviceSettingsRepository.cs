using Microsoft.EntityFrameworkCore;
using QuickBooksClone.Core.Settings;

namespace QuickBooksClone.Infrastructure.Persistence;

public sealed class EfDeviceSettingsRepository : IDeviceSettingsRepository
{
    private readonly QuickBooksCloneDbContext _db;

    public EfDeviceSettingsRepository(QuickBooksCloneDbContext db)
    {
        _db = db;
    }

    public Task<DeviceSettings?> GetAsync(CancellationToken cancellationToken = default) =>
        _db.DeviceSettings.AsNoTracking().AsSingleQuery().SingleOrDefaultAsync(cancellationToken);

    public async Task<DeviceSettings> GetOrCreateAsync(CancellationToken cancellationToken = default)
    {
        var settings = await GetAsync(cancellationToken);
        if (settings is not null)
        {
            return settings;
        }

        settings = new DeviceSettings("DEV01", Environment.MachineName);
        _db.DeviceSettings.Add(settings);
        await _db.SaveChangesAsync(cancellationToken);
        return settings;
    }

    public async Task<DeviceSettings> UpsertAsync(string deviceId, string? deviceName, CancellationToken cancellationToken = default)
    {
        var existing = await _db.DeviceSettings.SingleOrDefaultAsync(cancellationToken);
        if (existing is not null)
        {
            existing.Update(deviceId, deviceName);
            await _db.SaveChangesAsync(cancellationToken);
            return existing;
        }

        var validated = new DeviceSettings(deviceId, deviceName);
        _db.DeviceSettings.Add(validated);
        await _db.SaveChangesAsync(cancellationToken);
        return validated;
    }
}
