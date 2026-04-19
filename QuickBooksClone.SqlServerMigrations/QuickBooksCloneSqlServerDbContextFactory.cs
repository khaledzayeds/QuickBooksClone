using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;
using QuickBooksClone.Infrastructure.Persistence;

namespace QuickBooksClone.SqlServerMigrations;

public sealed class QuickBooksCloneSqlServerDbContextFactory : IDesignTimeDbContextFactory<QuickBooksCloneDbContext>
{
    public QuickBooksCloneDbContext CreateDbContext(string[] args)
    {
        var configuration = BuildConfiguration();
        var connectionString =
            configuration.GetConnectionString("QuickBooksClone")
            ?? Environment.GetEnvironmentVariable("QB_SQLSERVER_CONNECTION")
            ?? "Server=(localdb)\\MSSQLLocalDB;Database=QuickBooksClone_DesignTime;Trusted_Connection=True;TrustServerCertificate=True;";

        var optionsBuilder = new DbContextOptionsBuilder<QuickBooksCloneDbContext>();
        optionsBuilder.UseSqlServer(
            connectionString,
            sqlServerOptions =>
            {
                sqlServerOptions.MigrationsAssembly(typeof(QuickBooksCloneSqlServerDbContextFactory).Assembly.GetName().Name);
                sqlServerOptions.EnableRetryOnFailure();
            });

        return new QuickBooksCloneDbContext(optionsBuilder.Options);
    }

    private static IConfiguration BuildConfiguration()
    {
        var currentDirectory = Directory.GetCurrentDirectory();
        var apiProjectDirectory = Path.GetFullPath(Path.Combine(currentDirectory, "..", "QuickBooksClone.Api"));

        return new ConfigurationBuilder()
            .SetBasePath(Directory.Exists(apiProjectDirectory) ? apiProjectDirectory : currentDirectory)
            .AddJsonFile("appsettings.json", optional: true)
            .AddJsonFile("appsettings.Development.json", optional: true)
            .AddJsonFile("appsettings.SqlServer.example.json", optional: true)
            .AddEnvironmentVariables()
            .Build();
    }
}
