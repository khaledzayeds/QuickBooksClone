using System.Text;
using System.Text.Json;
using Org.BouncyCastle.Crypto.Parameters;
using Org.BouncyCastle.Crypto.Signers;
using QuickBooksClone.Core.Licensing;

namespace QuickBooksClone.Infrastructure.Licensing;

public sealed class Ed25519LicensePackageSigningService : ILicensePackageSigningService
{
    private readonly byte[] _privateKey;

    public Ed25519LicensePackageSigningService(string privateKeyBase64)
    {
        if (string.IsNullOrWhiteSpace(privateKeyBase64))
        {
            throw new ArgumentException("License signing private key is not configured.", nameof(privateKeyBase64));
        }

        _privateKey = Convert.FromBase64String(privateKeyBase64);
        if (_privateKey.Length != Ed25519PrivateKeyParameters.KeySize)
        {
            throw new ArgumentException("Ed25519 private key must be 32 raw bytes encoded as base64.", nameof(privateKeyBase64));
        }
    }

    public string SignLicensePackage(LicenseIssueOptions options)
    {
        var issuedAt = DateTimeOffset.UtcNow;
        var payload = new SortedDictionary<string, object?>
        {
            ["licenseId"] = $"lic_{issuedAt:yyyyMMddHHmmss}",
            ["serial"] = options.Serial,
            ["customerName"] = options.CustomerName,
            ["edition"] = options.Edition,
            ["status"] = options.Status,
            ["maxUsers"] = options.MaxUsers,
            ["maxDevices"] = options.MaxDevices,
            ["offlineGraceDays"] = options.OfflineGraceDays,
            ["features"] = new SortedDictionary<string, object?>
            {
                ["localMode"] = options.Features.LocalMode,
                ["lanMode"] = options.Features.LanMode,
                ["hostedMode"] = options.Features.HostedMode,
                ["backupRestore"] = options.Features.BackupRestore,
                ["demoCompany"] = options.Features.DemoCompany,
                ["advancedInventory"] = options.Features.AdvancedInventory,
                ["payroll"] = options.Features.Payroll
            },
            ["issuedAt"] = issuedAt.ToString("O"),
            ["expiresAt"] = options.ExpiresAt?.ToString("O"),
            ["deviceId"] = options.DeviceFingerprint,
            ["activation"] = new SortedDictionary<string, object?>
            {
                ["mode"] = "online",
                ["appVersion"] = options.AppVersion
            }
        };

        var payloadJson = JsonSerializer.Serialize(payload, new JsonSerializerOptions
        {
            WriteIndented = false
        });
        var payloadBytes = Encoding.UTF8.GetBytes(payloadJson);
        var signature = SignEd25519(payloadBytes);

        return $"{Base64UrlEncode(payloadBytes)}.{Base64UrlEncode(signature)}";
    }

    private byte[] SignEd25519(byte[] payloadBytes)
    {
        var key = new Ed25519PrivateKeyParameters(_privateKey, 0);
        var signer = new Ed25519Signer();
        signer.Init(forSigning: true, parameters: key);
        signer.BlockUpdate(payloadBytes, 0, payloadBytes.Length);
        return signer.GenerateSignature();
    }

    private static string Base64UrlEncode(byte[] bytes) => Convert.ToBase64String(bytes)
        .TrimEnd('=')
        .Replace('+', '-')
        .Replace('/', '_');
}
