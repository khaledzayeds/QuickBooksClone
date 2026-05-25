using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;
using Zayed.Infrastructure.Persistence;

namespace Zayed.SqlServerMigrations;

public sealed class ZayedSqlServerDbContextFactory : IDesignTimeDbContextFactory<ZayedDbContext>
{
    public ZayedDbContext CreateDbContext(string[] args)
    {
        var configuration = BuildConfiguration();
        var connectionString =
            configuration.GetConnectionString("Zayed")
            ?? Environment.GetEnvironmentVariable("QB_SQLSERVER_CONNECTION")
            ?? "Server=(localdb)\\MSSQLLocalDB;Database=Zayed_DesignTime;Trusted_Connection=True;TrustServerCertificate=True;";

        var optionsBuilder = new DbContextOptionsBuilder<ZayedDbContext>();
        optionsBuilder.UseSqlServer(
            connectionString,
            sqlServerOptions =>
            {
                sqlServerOptions.MigrationsAssembly(typeof(ZayedSqlServerDbContextFactory).Assembly.GetName().Name);
                sqlServerOptions.EnableRetryOnFailure();
            });

        return new ZayedDbContext(optionsBuilder.Options);
    }

    private static IConfiguration BuildConfiguration()
    {
        var currentDirectory = Directory.GetCurrentDirectory();
        var apiProjectDirectory = Path.GetFullPath(Path.Combine(currentDirectory, "..", "Zayed.Api"));

        return new ConfigurationBuilder()
            .SetBasePath(Directory.Exists(apiProjectDirectory) ? apiProjectDirectory : currentDirectory)
            .AddJsonFile("appsettings.json", optional: true)
            .AddJsonFile("appsettings.Development.json", optional: true)
            .AddJsonFile("appsettings.SqlServer.example.json", optional: true)
            .AddEnvironmentVariables()
            .Build();
    }
}
