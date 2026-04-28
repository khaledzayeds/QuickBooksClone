using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using QuickBooksClone.Core.Accounting;
using QuickBooksClone.Core.Customers;
using QuickBooksClone.Core.Items;
using QuickBooksClone.Core.Security;
using QuickBooksClone.Core.Settings;
using QuickBooksClone.Core.Vendors;

namespace QuickBooksClone.Infrastructure.Persistence;

public static class QuickBooksClonePersistence
{
    private const string SqlServerMigrationsAssembly = "QuickBooksClone.SqlServerMigrations";

    public static IServiceCollection AddQuickBooksPersistence(this IServiceCollection services, IConfiguration configuration)
    {
        var provider = configuration["Database:Provider"] ?? "Sqlite";
        var connectionString = configuration.GetConnectionString("QuickBooksClone")
            ?? "Data Source=quickbooksclone.db";

        services.AddDbContext<QuickBooksCloneDbContext>(options =>
        {
            if (provider.Equals("SqlServer", StringComparison.OrdinalIgnoreCase))
            {
                options.UseSqlServer(
                    connectionString,
                    sqlServerOptions =>
                    {
                        sqlServerOptions.MigrationsAssembly(SqlServerMigrationsAssembly);
                        sqlServerOptions.EnableRetryOnFailure();
                    });
                return;
            }

            options.UseSqlite(connectionString);
        });

        return services;
    }

    public static async Task ApplyQuickBooksDatabaseMigrationsAsync(this IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<QuickBooksCloneDbContext>();
        await AdoptExistingSqliteSchemaAsync(dbContext);
        await dbContext.Database.MigrateAsync();
        await SeedDefaultsAsync(dbContext);
    }

    private static async Task AdoptExistingSqliteSchemaAsync(QuickBooksCloneDbContext dbContext)
    {
        if (dbContext.Database.ProviderName?.Contains("Sqlite", StringComparison.OrdinalIgnoreCase) != true)
        {
            return;
        }

        var connection = dbContext.Database.GetDbConnection();
        var shouldClose = connection.State == System.Data.ConnectionState.Closed;
        if (shouldClose)
        {
            await connection.OpenAsync();
        }

        try
        {
            var historyTableExists = await ExecuteScalarAsync<long>(
                connection,
                "SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' AND name = '__EFMigrationsHistory';") > 0;

            if (historyTableExists)
            {
                return;
            }

            var existingTableCount = await ExecuteScalarAsync<long>(
                connection,
                "SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%';");

            if (existingTableCount == 0)
            {
                return;
            }

            await ExecuteNonQueryAsync(
                connection,
                "CREATE TABLE IF NOT EXISTS \"__EFMigrationsHistory\" (\"MigrationId\" TEXT NOT NULL CONSTRAINT \"PK___EFMigrationsHistory\" PRIMARY KEY, \"ProductVersion\" TEXT NOT NULL);");

            await ExecuteNonQueryAsync(
                connection,
                "INSERT OR IGNORE INTO \"__EFMigrationsHistory\" (\"MigrationId\", \"ProductVersion\") VALUES ('20260419042720_InitialCreate', '10.0.5');");
        }
        finally
        {
            if (shouldClose)
            {
                await connection.CloseAsync();
            }
        }
    }

    private static async Task<T> ExecuteScalarAsync<T>(System.Data.Common.DbConnection connection, string commandText)
    {
        await using var command = connection.CreateCommand();
        command.CommandText = commandText;
        var value = await command.ExecuteScalarAsync();
        return (T)Convert.ChangeType(value!, typeof(T));
    }

    private static async Task ExecuteNonQueryAsync(System.Data.Common.DbConnection connection, string commandText)
    {
        await using var command = connection.CreateCommand();
        command.CommandText = commandText;
        await command.ExecuteNonQueryAsync();
    }

    private static async Task SeedDefaultsAsync(QuickBooksCloneDbContext dbContext)
    {
        var cashAccountId = Guid.Parse("10000000-0000-0000-0000-000000000001");
        var arAccountId = Guid.Parse("10000000-0000-0000-0000-000000000002");
        var inventoryAccountId = Guid.Parse("10000000-0000-0000-0000-000000000003");
        var apAccountId = Guid.Parse("10000000-0000-0000-0000-000000000004");
        var grniAccountId = Guid.Parse("10000000-0000-0000-0000-000000000009");
        var equityAccountId = Guid.Parse("10000000-0000-0000-0000-000000000005");
        var incomeAccountId = Guid.Parse("10000000-0000-0000-0000-000000000006");
        var cogsAccountId = Guid.Parse("10000000-0000-0000-0000-000000000007");
        var expenseAccountId = Guid.Parse("10000000-0000-0000-0000-000000000008");

        if (!await dbContext.DeviceSettings.AnyAsync())
        {
            dbContext.DeviceSettings.Add(new DeviceSettings("DEV01", Environment.MachineName));
        }

        if (!await dbContext.Accounts.AnyAsync())
        {
            dbContext.Accounts.AddRange(
                new Account("1000", "Cash on Hand", AccountType.Bank) { Id = cashAccountId },
                new Account("1100", "Accounts Receivable", AccountType.AccountsReceivable) { Id = arAccountId },
                new Account("1200", "Inventory Asset", AccountType.InventoryAsset) { Id = inventoryAccountId },
                new Account("2000", "Accounts Payable", AccountType.AccountsPayable) { Id = apAccountId },
                new Account("2050", "Inventory Received Not Billed", AccountType.OtherCurrentLiability) { Id = grniAccountId },
                new Account("3000", "Owner Equity", AccountType.Equity) { Id = equityAccountId },
                new Account("4000", "Sales Income", AccountType.Income) { Id = incomeAccountId },
                new Account("5000", "Cost of Goods Sold", AccountType.CostOfGoodsSold) { Id = cogsAccountId },
                new Account("6000", "General Expenses", AccountType.Expense) { Id = expenseAccountId });
        }
        else
        {
            await EnsureAccountAsync(dbContext, grniAccountId, "2050", "Inventory Received Not Billed", AccountType.OtherCurrentLiability);
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

        if (!await dbContext.CompanySettings.AnyAsync())
        {
            dbContext.CompanySettings.Add(new CompanySettings(
                companyName: "QuickBooksClone Demo Company",
                currency: "EGP",
                country: "Egypt",
                timeZoneId: "Africa/Cairo",
                defaultLanguage: "ar",
                legalName: "QuickBooksClone Demo Company LLC",
                email: "admin@quickbooksclone.local",
                phone: "+20 100 000 0000",
                fiscalYearStartMonth: 1,
                fiscalYearStartDay: 1,
                defaultSalesTaxRate: 0,
                defaultPurchaseTaxRate: 0));
        }

        await SeedSecurityAsync(dbContext);

        await dbContext.SaveChangesAsync();
    }

    private static async Task SeedSecurityAsync(QuickBooksCloneDbContext dbContext)
    {
        var roles = new[]
        {
            new { Key = "ADMIN", Name = "Administrator", Description = "Full system access." },
            new { Key = "MANAGER", Name = "Manager", Description = "Operational management access except user administration." },
            new { Key = "ACCOUNTANT", Name = "Accountant", Description = "Accounting, reports, sales, and purchase workflow access." },
            new { Key = "CASHIER", Name = "Cashier", Description = "Sales, payments, and customer-facing workflow access." },
            new { Key = "INVENTORY", Name = "Inventory", Description = "Items, receiving, inventory adjustments, and stock reporting." },
            new { Key = "READONLY", Name = "Read Only", Description = "Read-only accounting and report access." }
        };

        foreach (var seed in roles)
        {
            var role = await dbContext.SecurityRoles
                .Include(current => current.Permissions)
                .FirstOrDefaultAsync(current => current.RoleKey == seed.Key);

            if (role is null)
            {
                role = new SecurityRole(seed.Key, seed.Name, seed.Description, isSystem: true);
                role.ReplacePermissions(PermissionCatalog.ForRole(seed.Key));
                dbContext.SecurityRoles.Add(role);
                continue;
            }

            role.Update(seed.Name, seed.Description);
            role.ReplacePermissions(PermissionCatalog.ForRole(seed.Key));
        }

        await dbContext.SaveChangesAsync();

        if (!await dbContext.SecurityUsers.AnyAsync())
        {
            var adminRole = await dbContext.SecurityRoles.FirstOrDefaultAsync(role => role.RoleKey == "ADMIN");
            var admin = new SecurityUser("admin", "System Administrator", "admin@quickbooksclone.local");
            dbContext.SecurityUsers.Add(admin);
            await dbContext.SaveChangesAsync();

            if (adminRole is not null)
            {
                dbContext.UserRoleAssignments.Add(new UserRoleAssignment(admin.Id, adminRole.Id));
            }
        }
    }

    private static async Task EnsureAccountAsync(
        QuickBooksCloneDbContext dbContext,
        Guid id,
        string code,
        string name,
        AccountType accountType)
    {
        var exists = await dbContext.Accounts.AnyAsync(account =>
            account.Code == code || account.Name == name);

        if (exists)
        {
            return;
        }

        dbContext.Accounts.Add(new Account(code, name, accountType) { Id = id });
    }
}
