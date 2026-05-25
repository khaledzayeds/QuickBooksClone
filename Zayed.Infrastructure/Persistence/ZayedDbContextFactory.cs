using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;

namespace Zayed.Infrastructure.Persistence;

public sealed class ZayedDbContextFactory : IDesignTimeDbContextFactory<ZayedDbContext>
{
    private const string SqlServerMigrationsAssembly = "Zayed.SqlServerMigrations";

    public ZayedDbContext CreateDbContext(string[] args)
    {
        var basePath = Directory.GetCurrentDirectory();
        var apiSettingsPath = Path.GetFullPath(Path.Combine(basePath, "..", "Zayed.Api"));

        var configuration = new ConfigurationBuilder()
            .SetBasePath(Directory.Exists(apiSettingsPath) ? apiSettingsPath : basePath)
            .AddJsonFile("appsettings.json", optional: true)
            .AddJsonFile("appsettings.Development.json", optional: true)
            .AddJsonFile("appsettings.SqlServer.example.json", optional: true)
            .AddEnvironmentVariables()
            .Build();

        var provider =
            Environment.GetEnvironmentVariable("ZAYED_DESIGNTIME_PROVIDER")
            ?? configuration["Database:Provider"]
            ?? "Sqlite";
        var connectionString = configuration.GetConnectionString("Zayed")
            ?? "Data Source=zayed-dev.db";

        var optionsBuilder = new DbContextOptionsBuilder<ZayedDbContext>();
        if (provider.Equals("SqlServer", StringComparison.OrdinalIgnoreCase))
        {
            optionsBuilder.UseSqlServer(
                connectionString,
                sqlServerOptions =>
                {
                    sqlServerOptions.MigrationsAssembly(SqlServerMigrationsAssembly);
                    sqlServerOptions.EnableRetryOnFailure();
                });
        }
        else
        {
            optionsBuilder.UseSqlite(connectionString);
        }

        return new ZayedDbContext(optionsBuilder.Options);
    }
}
