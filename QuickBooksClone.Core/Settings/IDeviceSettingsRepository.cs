namespace QuickBooksClone.Core.Settings;

public interface IDeviceSettingsRepository
{
    Task<DeviceSettings?> GetAsync(CancellationToken cancellationToken = default);
    Task<DeviceSettings> GetOrCreateAsync(CancellationToken cancellationToken = default);
    Task<DeviceSettings> UpsertAsync(string deviceId, string? deviceName, CancellationToken cancellationToken = default);
}
