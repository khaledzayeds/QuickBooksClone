using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;

namespace QuickBooksClone.Infrastructure.Persistence;

public sealed class QuickBooksCloneDbContextFactory : IDesignTimeDbContextFactory<QuickBooksCloneDbContext>
{
    public QuickBooksCloneDbContext CreateDbContext(string[] args)
    {
        var basePath = Directory.GetCurrentDirectory();
        var apiSettingsPath = Path.GetFullPath(Path.Combine(basePath, "..", "QuickBooksClone.Api"));

        var configuration = new ConfigurationBuilder()
            .SetBasePath(Directory.Exists(apiSettingsPath) ? apiSettingsPath : basePath)
            .AddJsonFile("appsettings.json", optional: true)
            .AddJsonFile("appsettings.Development.json", optional: true)
            .Build();

        var provider = configuration["Database:Provider"] ?? "Sqlite";
        var connectionString = configuration.GetConnectionString("QuickBooksClone")
            ?? "Data Source=quickbooksclone-dev.db";

        var optionsBuilder = new DbContextOptionsBuilder<QuickBooksCloneDbContext>();
        if (provider.Equals("SqlServer", StringComparison.OrdinalIgnoreCase))
        {
            optionsBuilder.UseSqlServer(connectionString);
        }
        else
        {
            optionsBuilder.UseSqlite(connectionString);
        }

        return new QuickBooksCloneDbContext(optionsBuilder.Options);
    }
}
