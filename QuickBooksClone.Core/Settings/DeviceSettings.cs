using QuickBooksClone.Core.Common;

namespace QuickBooksClone.Core.Settings;

public sealed class DeviceSettings : EntityBase
{
    public DeviceSettings()
    {
        DeviceId = "DEV01";
        DeviceName = "Primary Device";
    }

    public DeviceSettings(string deviceId, string? deviceName = null)
    {
        Update(deviceId, deviceName);
    }

    public string DeviceId { get; private set; } = string.Empty;
    public string DeviceName { get; private set; } = string.Empty;

    public void Update(string deviceId, string? deviceName)
    {
        DeviceId = NormalizeDeviceId(deviceId);
        DeviceName = string.IsNullOrWhiteSpace(deviceName) ? DeviceId : deviceName.Trim();
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    private static string NormalizeDeviceId(string value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException("Device ID is required.", nameof(value));
        }

        var normalized = value.Trim().ToUpperInvariant();
        if (normalized.Length > 20)
        {
            throw new ArgumentOutOfRangeException(nameof(value), "Device ID must be 20 characters or fewer.");
        }

        foreach (var current in normalized)
        {
            if (!char.IsLetterOrDigit(current) && current != '-')
            {
                throw new ArgumentException("Device ID may contain only letters, digits, and dashes.", nameof(value));
            }
        }

        return normalized;
    }
}
