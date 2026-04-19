using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace QuickBooksClone.Infrastructure.Persistence;

public static class QuickBooksClonePersistence
{
    public static IServiceCollection AddQuickBooksPersistence(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("QuickBooksClone")
            ?? "Data Source=quickbooksclone.db";

        services.AddDbContext<QuickBooksCloneDbContext>(options =>
        {
            options.UseSqlite(connectionString);
        });

        return services;
    }

    public static async Task EnsureQuickBooksDatabaseCreatedAsync(this IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<QuickBooksCloneDbContext>();
        await dbContext.Database.EnsureCreatedAsync();
    }
}
