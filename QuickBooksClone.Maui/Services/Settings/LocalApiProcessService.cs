using System.Diagnostics;

namespace QuickBooksClone.Maui.Services.Settings;

public sealed class LocalApiProcessService
{
    private Process? _process;
    private string? _resolvedProjectPath;
    private string? _lastError;

    public bool IsRunning => _process is { HasExited: false };
    public string? ResolvedProjectPath => _resolvedProjectPath;
    public string? LastError => _lastError;

    public async Task<bool> TryEnsureStartedAsync(ApiConnectionSettings settings, CancellationToken cancellationToken = default)
    {
        if (settings.StartupMode != ApiStartupMode.ManagedLocalApi || settings.StartupProfile != ApiConnectionMode.Local)
        {
            return false;
        }

        if (IsRunning)
        {
            return true;
        }

        var projectPath = ResolveProjectPath(settings.LocalApiProjectPath);
        if (projectPath is null)
        {
            _resolvedProjectPath = null;
            _lastError = "Could not locate QuickBooksClone.Api.csproj for managed local startup.";
            return false;
        }

        _resolvedProjectPath = projectPath;
        _lastError = null;

        var startInfo = new ProcessStartInfo
        {
            FileName = "dotnet",
            Arguments = $"run --project \"{projectPath}\" --urls \"{settings.LocalUrl}\"",
            WorkingDirectory = Path.GetDirectoryName(projectPath)!,
            UseShellExecute = false,
            RedirectStandardOutput = false,
            RedirectStandardError = false
        };
        startInfo.Environment["ASPNETCORE_ENVIRONMENT"] = "Development";
        startInfo.Environment["Logging__LogLevel__Default"] = "Warning";
        startInfo.Environment["Logging__LogLevel__Microsoft.AspNetCore"] = "Warning";

        try
        {
            _process = Process.Start(startInfo);
            await Task.Delay(1500, cancellationToken);
            if (_process is null || _process.HasExited)
            {
                _lastError = "Managed local API process exited before becoming ready.";
                return false;
            }

            return true;
        }
        catch (Exception exception)
        {
            _lastError = exception.Message;
            return false;
        }
    }

    public Task StopAsync()
    {
        try
        {
            if (_process is { HasExited: false })
            {
                _process.Kill(true);
                _process.WaitForExit(3000);
            }
        }
        catch (Exception exception)
        {
            _lastError = exception.Message;
        }
        finally
        {
            _process?.Dispose();
            _process = null;
        }

        return Task.CompletedTask;
    }

    private static string? ResolveProjectPath(string? configuredPath)
    {
        if (!string.IsNullOrWhiteSpace(configuredPath))
        {
            var fullPath = Path.IsPathRooted(configuredPath)
                ? configuredPath
                : Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, configuredPath));

            return File.Exists(fullPath) ? fullPath : null;
        }

        var candidates = new List<string>();
        var current = new DirectoryInfo(AppContext.BaseDirectory);
        while (current is not null)
        {
            candidates.Add(Path.Combine(current.FullName, "QuickBooksClone.Api", "QuickBooksClone.Api.csproj"));
            current = current.Parent;
        }

        var working = new DirectoryInfo(Directory.GetCurrentDirectory());
        while (working is not null)
        {
            candidates.Add(Path.Combine(working.FullName, "QuickBooksClone.Api", "QuickBooksClone.Api.csproj"));
            working = working.Parent;
        }

        return candidates.FirstOrDefault(File.Exists);
    }
}
