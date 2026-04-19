using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Customers;
using QuickBooksClone.Core.Items;
using QuickBooksClone.Core.Vendors;

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
        await SeedDefaultsAsync(dbContext);
    }

    private static async Task SeedDefaultsAsync(QuickBooksCloneDbContext dbContext)
    {
        var cashAccountId = Guid.Parse("10000000-0000-0000-0000-000000000001");
        var arAccountId = Guid.Parse("10000000-0000-0000-0000-000000000002");
        var inventoryAccountId = Guid.Parse("10000000-0000-0000-0000-000000000003");
        var apAccountId = Guid.Parse("10000000-0000-0000-0000-000000000004");
        var equityAccountId = Guid.Parse("10000000-0000-0000-0000-000000000005");
        var incomeAccountId = Guid.Parse("10000000-0000-0000-0000-000000000006");
        var cogsAccountId = Guid.Parse("10000000-0000-0000-0000-000000000007");
        var expenseAccountId = Guid.Parse("10000000-0000-0000-0000-000000000008");

        if (!await dbContext.Accounts.AnyAsync())
        {
            dbContext.Accounts.AddRange(
                new Account("1000", "Cash on Hand", AccountType.Bank) { Id = cashAccountId },
                new Account("1100", "Accounts Receivable", AccountType.AccountsReceivable) { Id = arAccountId },
                new Account("1200", "Inventory Asset", AccountType.InventoryAsset) { Id = inventoryAccountId },
                new Account("2000", "Accounts Payable", AccountType.AccountsPayable) { Id = apAccountId },
                new Account("3000", "Owner Equity", AccountType.Equity) { Id = equityAccountId },
                new Account("4000", "Sales Income", AccountType.Income) { Id = incomeAccountId },
                new Account("5000", "Cost of Goods Sold", AccountType.CostOfGoodsSold) { Id = cogsAccountId },
                new Account("6000", "General Expenses", AccountType.Expense) { Id = expenseAccountId });
        }

        if (!await dbContext.Customers.AnyAsync())
        {
            dbContext.Customers.AddRange(
                new Customer("Ahmed Mohamed", "Solution SA", "ahmed@solution.sa", "+966 123 50 4567", "EGP", 0),
                new Customer("Sara Ali", "Horizon International", "s.ali@horizon.com", "+966 456 888 2121", "EGP", 0),
                new Customer("Khaled Mansour", "Mansour Stores", "k.mansour@shop.sa", "+966 565 990 1010", "EGP", 0));
        }

        if (!await dbContext.Vendors.AnyAsync())
        {
            dbContext.Vendors.AddRange(
                new Vendor("Cairo Office Supplies", "Cairo Office Supplies LLC", "orders@cairo-office.example", "+20 100 111 2222", "EGP", 0),
                new Vendor("Delta Hardware", "Delta Hardware Co.", "sales@delta-hardware.example", "+20 100 333 4444", "EGP", 0));
        }

        if (!await dbContext.Items.AnyAsync())
        {
            dbContext.Items.AddRange(
                new Item("Consulting Hour", ItemType.Service, "SERV-001", null, 750, 0, 0, "hour", incomeAccountId, null, null, expenseAccountId),
                new Item("Receipt Printer", ItemType.Inventory, "INV-PRN-001", "622100000001", 4200, 3100, 0, "pcs", incomeAccountId, inventoryAccountId, cogsAccountId, expenseAccountId),
                new Item("Setup Fee", ItemType.NonInventory, "FEE-SETUP", null, 1500, 0, 0, "each", incomeAccountId, null, null, expenseAccountId));
        }

        await dbContext.SaveChangesAsync();
    }
}
