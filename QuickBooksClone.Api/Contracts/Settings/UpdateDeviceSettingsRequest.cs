namespace QuickBooksClone.Api.Contracts.Settings;

public sealed record UpdateDeviceSettingsRequest(string DeviceId, string? DeviceName);
