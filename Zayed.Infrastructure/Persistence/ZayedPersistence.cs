using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Zayed.Core.Accounting;
using Zayed.Core.Companies;
using Zayed.Core.Customers;
using Zayed.Core.Items;
using Zayed.Core.Modules;
using Zayed.Core.Security;
using Zayed.Core.Settings;
using Zayed.Core.Taxes;
using Zayed.Core.Vendors;
using Zayed.Infrastructure.Security;

namespace Zayed.Infrastructure.Persistence;

public static class ZayedPersistence
{
    private const string SqlServerMigrationsAssembly = "Zayed.SqlServerMigrations";

    public static IServiceCollection AddZayedPersistence(this IServiceCollection services, IConfiguration configuration)
    {
        var provider = configuration["Database:Provider"] ?? "Sqlite";
        var connectionString = configuration.GetConnectionString("Zayed")
            ?? "Data Source=zayed.db";

        services.AddDbContext<ZayedDbContext>((serviceProvider, options) =>
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

            var runtime = serviceProvider.GetRequiredService<ICompanyRuntimeService>().Current;
            var sqliteConnectionString = runtime.IsActive
                ? BuildSqliteConnectionString(runtime.DatabasePath)
                : connectionString;

            options
                .UseSqlite(sqliteConnectionString)
                .ConfigureWarnings(warnings => warnings.Ignore(RelationalEventId.PendingModelChangesWarning));
        });

        return services;
    }

    public static async Task ApplyZayedDatabaseMigrationsAsync(this IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var runtime = scope.ServiceProvider.GetRequiredService<ICompanyRuntimeService>().Current;
        if (!runtime.IsActive)
        {
            return;
        }

        var configuration = scope.ServiceProvider.GetRequiredService<IConfiguration>();
        var seedDemoData = bool.TryParse(configuration["Database:SeedDemoData"], out var configuredSeedDemoData) &&
            configuredSeedDemoData;
        var dbContext = scope.ServiceProvider.GetRequiredService<ZayedDbContext>();
        await AdoptExistingSqliteSchemaAsync(dbContext);
        await dbContext.Database.MigrateAsync();
        await SeedDefaultsAsync(dbContext, runtime.CompanyId, runtime.BusinessType, seedDemoData);
    }

    public static async Task ApplyCurrentCompanyDatabaseAsync(this IServiceProvider services, bool seedDefaults = true, CancellationToken cancellationToken = default)
    {
        var configuration = services.GetRequiredService<IConfiguration>();
        var runtime = services.GetRequiredService<ICompanyRuntimeService>().Current;
        if (!runtime.IsActive)
        {
            throw new InvalidOperationException("No active company is open.");
        }

        var seedDemoData = bool.TryParse(configuration["Database:SeedDemoData"], out var configuredSeedDemoData) &&
            configuredSeedDemoData;

        if (!await SqliteDatabaseHasUserTablesAsync(runtime.DatabasePath, cancellationToken))
        {
            if (!seedDefaults)
            {
                return;
            }

            await using var createdDbContext = CreateSqliteDbContext(runtime.DatabasePath);
            await createdDbContext.Database.EnsureCreatedAsync(cancellationToken);
            if (seedDefaults)
            {
                await SeedDefaultsAsync(createdDbContext, runtime.CompanyId, runtime.BusinessType, seedDemoData);
            }
            return;
        }

        if (!await RequiredSetupTablesExistAsync(runtime.DatabasePath, cancellationToken))
        {
            if (!seedDefaults)
            {
                return;
            }

            await ResetIncompleteDatabaseInPlaceAsync(runtime.DatabasePath, cancellationToken);
            await using var repairedDbContext = CreateSqliteDbContext(runtime.DatabasePath);
            await repairedDbContext.Database.EnsureCreatedAsync(cancellationToken);
            if (seedDefaults)
            {
                await SeedDefaultsAsync(repairedDbContext, runtime.CompanyId, runtime.BusinessType, seedDemoData);
            }
            return;
        }

        await using var dbContext = CreateSqliteDbContext(runtime.DatabasePath);
        await AdoptExistingSqliteSchemaAsync(dbContext);
        await dbContext.Database.MigrateAsync(cancellationToken);
        if (seedDefaults)
        {
            await SeedDefaultsAsync(dbContext, runtime.CompanyId, runtime.BusinessType, seedDemoData);
        }
    }

    public static async Task<bool> CurrentCompanyDatabaseIsInitializedAsync(this IServiceProvider services, CancellationToken cancellationToken = default)
    {
        var runtime = services.GetRequiredService<ICompanyRuntimeService>().Current;
        if (!runtime.IsActive)
        {
            return false;
        }

        await using var connection = new SqliteConnection(BuildSqliteConnectionString(runtime.DatabasePath));
        await connection.OpenAsync(cancellationToken);
        var hasCompanySettings = await SqliteTableHasRowsAsync(connection, "company_settings", cancellationToken);
        if (!hasCompanySettings)
        {
            return false;
        }

        return await SqliteTableHasRowsAsync(connection, "security_users", cancellationToken);
    }

    private static ZayedDbContext CreateSqliteDbContext(string databasePath)
    {
        var options = new DbContextOptionsBuilder<ZayedDbContext>()
            .UseSqlite(CreateOpenSqliteConnection(BuildSqliteConnectionString(databasePath)), contextOwnsConnection: true)
            .ConfigureWarnings(warnings => warnings.Ignore(RelationalEventId.PendingModelChangesWarning))
            .Options;
        return new ZayedDbContext(options);
    }

    private static SqliteConnection CreateOpenSqliteConnection(string connectionString)
    {
        var connection = new SqliteConnection(connectionString);
        connection.Open();
        return connection;
    }

    private static string BuildSqliteConnectionString(string databasePath)
    {
        var fullPath = Path.GetFullPath(databasePath);
        var directory = Path.GetDirectoryName(fullPath);
        if (!string.IsNullOrWhiteSpace(directory))
        {
            Directory.CreateDirectory(directory);
        }

        return new SqliteConnectionStringBuilder
        {
            DataSource = fullPath,
            Pooling = false
        }.ToString();
    }

    private static async Task ResetIncompleteDatabaseInPlaceAsync(string databasePath, CancellationToken cancellationToken)
    {
        SqliteConnection.ClearAllPools();
        var tableNames = new List<string>();

        await using (var connection = new SqliteConnection(BuildSqliteConnectionString(databasePath)))
        {
            await connection.OpenAsync(cancellationToken);
            await using var listTables = connection.CreateCommand();
            listTables.CommandText = "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%';";
            await using var reader = await listTables.ExecuteReaderAsync(cancellationToken);
            while (await reader.ReadAsync(cancellationToken))
            {
                tableNames.Add(reader.GetString(0));
            }
        }

        for (var attempt = 1; attempt <= 8; attempt++)
        {
            try
            {
                await using var connection = new SqliteConnection(BuildSqliteConnectionString(databasePath));
                await connection.OpenAsync(cancellationToken);

                await using (var busyTimeout = connection.CreateCommand())
                {
                    busyTimeout.CommandText = "PRAGMA busy_timeout = 5000;";
                    await busyTimeout.ExecuteNonQueryAsync(cancellationToken);
                }

                await using (var disableForeignKeys = connection.CreateCommand())
                {
                    disableForeignKeys.CommandText = "PRAGMA foreign_keys = OFF;";
                    await disableForeignKeys.ExecuteNonQueryAsync(cancellationToken);
                }

                foreach (var tableName in tableNames)
                {
                    await using var dropTable = connection.CreateCommand();
                    dropTable.CommandText = $"DROP TABLE IF EXISTS \"{tableName.Replace("\"", "\"\"")}\";";
                    await dropTable.ExecuteNonQueryAsync(cancellationToken);
                }

                await using (var enableForeignKeys = connection.CreateCommand())
                {
                    enableForeignKeys.CommandText = "PRAGMA foreign_keys = ON;";
                    await enableForeignKeys.ExecuteNonQueryAsync(cancellationToken);
                }

                return;
            }
            catch (SqliteException exception) when (IsSqliteBusy(exception) && attempt < 8)
            {
                SqliteConnection.ClearAllPools();
                await Task.Delay(TimeSpan.FromMilliseconds(250 * attempt), cancellationToken);
            }
        }
    }

    private static bool IsSqliteBusy(SqliteException exception) =>
        exception.SqliteErrorCode is 5 or 6;

    private static async Task<bool> SqliteDatabaseHasUserTablesAsync(string databasePath, CancellationToken cancellationToken)
    {
        await using var connection = new SqliteConnection(BuildSqliteConnectionString(databasePath));
        await connection.OpenAsync(cancellationToken);
        await using var command = connection.CreateCommand();
        command.CommandText = "SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%';";
        var value = await command.ExecuteScalarAsync(cancellationToken);
        return Convert.ToInt64(value) > 0;
    }

    private static async Task<bool> RequiredSetupTablesExistAsync(string databasePath, CancellationToken cancellationToken)
    {
        await using var connection = new SqliteConnection(BuildSqliteConnectionString(databasePath));
        await connection.OpenAsync(cancellationToken);
        return await SqliteTableExistsAsync(connection, "company_settings", cancellationToken) &&
            await SqliteTableExistsAsync(connection, "security_roles", cancellationToken) &&
            await SqliteTableExistsAsync(connection, "security_users", cancellationToken) &&
            await SqliteTableExistsAsync(connection, "user_role_assignments", cancellationToken);
    }

    private static async Task<bool> SqliteTableExistsAsync(SqliteConnection connection, string tableName, CancellationToken cancellationToken)
    {
        await using var command = connection.CreateCommand();
        command.CommandText = "SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' AND name = $tableName;";
        command.Parameters.AddWithValue("$tableName", tableName);
        return Convert.ToInt64(await command.ExecuteScalarAsync(cancellationToken)) > 0;
    }

    private static async Task<bool> SqliteTableHasRowsAsync(SqliteConnection connection, string tableName, CancellationToken cancellationToken)
    {
        if (!await SqliteTableExistsAsync(connection, tableName, cancellationToken))
        {
            return false;
        }

        await using var rowsCommand = connection.CreateCommand();
        rowsCommand.CommandText = $"SELECT EXISTS(SELECT 1 FROM \"{tableName}\" LIMIT 1);";
        return Convert.ToInt64(await rowsCommand.ExecuteScalarAsync(cancellationToken)) > 0;
    }

    private static async Task AdoptExistingSqliteSchemaAsync(ZayedDbContext dbContext)
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

    private static async Task SeedDefaultsAsync(ZayedDbContext dbContext, Guid? companyId, string businessType, bool seedDemoData)
    {
        var cashAccountId = Guid.Parse("10000000-0000-0000-0000-000000000001");
        var arAccountId = Guid.Parse("10000000-0000-0000-0000-000000000002");
        var inventoryAccountId = Guid.Parse("10000000-0000-0000-0000-000000000003");
        var apAccountId = Guid.Parse("10000000-0000-0000-0000-000000000004");
        var grniAccountId = Guid.Parse("10000000-0000-0000-0000-000000000009");
        var salesTaxPayableAccountId = Guid.Parse("10000000-0000-0000-0000-000000000010");
        var purchaseTaxReceivableAccountId = Guid.Parse("10000000-0000-0000-0000-000000000011");
        var salesVat14Id = Guid.Parse("20000000-0000-0000-0000-000000000001");
        var purchaseVat14Id = Guid.Parse("20000000-0000-0000-0000-000000000002");
        var equityAccountId = Guid.Parse("10000000-0000-0000-0000-000000000005");
        var incomeAccountId = Guid.Parse("10000000-0000-0000-0000-000000000006");
        var cogsAccountId = Guid.Parse("10000000-0000-0000-0000-000000000007");
        var expenseAccountId = Guid.Parse("10000000-0000-0000-0000-000000000008");
        var hotelRoomRevenueAccountId = Guid.Parse("10000000-0000-0000-0000-000000000020");
        var hotelMealRevenueAccountId = Guid.Parse("10000000-0000-0000-0000-000000000021");
        var hotelServiceRevenueAccountId = Guid.Parse("10000000-0000-0000-0000-000000000022");
        var tourismPackageRevenueAccountId = Guid.Parse("10000000-0000-0000-0000-000000000023");
        var hotelCancellationFeesRevenueAccountId = Guid.Parse("10000000-0000-0000-0000-000000000024");
        var hotelRoomCostAccountId = Guid.Parse("10000000-0000-0000-0000-000000000025");
        var hotelMealCostAccountId = Guid.Parse("10000000-0000-0000-0000-000000000026");
        var hotelContractCostAccountId = Guid.Parse("10000000-0000-0000-0000-000000000027");
        var tourismPackageCostAccountId = Guid.Parse("10000000-0000-0000-0000-000000000028");
        var hotelAgentsReceivableAccountId = Guid.Parse("10000000-0000-0000-0000-000000000029");
        var hotelGuestReceivableAccountId = Guid.Parse("10000000-0000-0000-0000-000000000030");
        var hotelSuppliersPayableAccountId = Guid.Parse("10000000-0000-0000-0000-000000000031");
        var hotelAccruedPayablesAccountId = Guid.Parse("10000000-0000-0000-0000-000000000032");
        var customerAdvanceDepositsAccountId = Guid.Parse("10000000-0000-0000-0000-000000000033");
        var hotelAdvancePaymentsAccountId = Guid.Parse("10000000-0000-0000-0000-000000000034");
        var deferredHotelRevenueAccountId = Guid.Parse("10000000-0000-0000-0000-000000000035");

        if (!await dbContext.DeviceSettings.AnyAsync())
        {
            dbContext.DeviceSettings.Add(new DeviceSettings("DEV01", Environment.MachineName));
        }

        await SeedModulesAsync(dbContext, companyId, businessType);

        if (!await dbContext.Accounts.AnyAsync())
        {
            dbContext.Accounts.AddRange(
                new Account("1000", "Cash on Hand", AccountType.Bank) { Id = cashAccountId },
                new Account("1100", "Accounts Receivable", AccountType.AccountsReceivable) { Id = arAccountId },
                new Account("1200", "Inventory Asset", AccountType.InventoryAsset) { Id = inventoryAccountId },
                new Account("2000", "Accounts Payable", AccountType.AccountsPayable) { Id = apAccountId },
                new Account("2050", "Inventory Received Not Billed", AccountType.OtherCurrentLiability) { Id = grniAccountId },
                new Account("2100", "Sales Tax Payable", AccountType.OtherCurrentLiability) { Id = salesTaxPayableAccountId },
                new Account("1300", "Input VAT Receivable", AccountType.OtherCurrentAsset) { Id = purchaseTaxReceivableAccountId },
                new Account("3000", "Owner Equity", AccountType.Equity) { Id = equityAccountId },
                new Account("4000", "Sales Income", AccountType.Income) { Id = incomeAccountId },
                new Account("5000", "Cost of Goods Sold", AccountType.CostOfGoodsSold) { Id = cogsAccountId },
                new Account("6000", "General Expenses", AccountType.Expense) { Id = expenseAccountId });
        }
        else
        {
            await EnsureAccountAsync(dbContext, grniAccountId, "2050", "Inventory Received Not Billed", AccountType.OtherCurrentLiability);
            await EnsureAccountAsync(dbContext, salesTaxPayableAccountId, "2100", "Sales Tax Payable", AccountType.OtherCurrentLiability);
            await EnsureAccountAsync(dbContext, purchaseTaxReceivableAccountId, "1300", "Input VAT Receivable", AccountType.OtherCurrentAsset);
        }

        if (ShouldSeedHotelAccounts(businessType))
        {
            await EnsureAccountAsync(dbContext, hotelAgentsReceivableAccountId, "1110", "Hotel Agents Receivable", AccountType.AccountsReceivable);
            await EnsureAccountAsync(dbContext, hotelGuestReceivableAccountId, "1120", "Hotel Guest Receivable", AccountType.AccountsReceivable);
            await EnsureAccountAsync(dbContext, hotelAdvancePaymentsAccountId, "1310", "Hotel Advance Payments", AccountType.OtherCurrentAsset);
            await EnsureAccountAsync(dbContext, hotelSuppliersPayableAccountId, "2010", "Hotel Suppliers Payable", AccountType.AccountsPayable);
            await EnsureAccountAsync(dbContext, hotelAccruedPayablesAccountId, "2060", "Hotel Accrued Payables", AccountType.OtherCurrentLiability);
            await EnsureAccountAsync(dbContext, customerAdvanceDepositsAccountId, "2200", "Customer Advance Deposits", AccountType.OtherCurrentLiability);
            await EnsureAccountAsync(dbContext, deferredHotelRevenueAccountId, "2300", "Deferred Hotel Revenue", AccountType.OtherCurrentLiability);
            await EnsureAccountAsync(dbContext, hotelRoomRevenueAccountId, "4100", "Hotel Room Revenue", AccountType.Income);
            await EnsureAccountAsync(dbContext, hotelMealRevenueAccountId, "4110", "Hotel Meal Revenue", AccountType.Income);
            await EnsureAccountAsync(dbContext, hotelServiceRevenueAccountId, "4120", "Hotel Service Revenue", AccountType.Income);
            await EnsureAccountAsync(dbContext, tourismPackageRevenueAccountId, "4130", "Tourism Package Revenue", AccountType.Income);
            await EnsureAccountAsync(dbContext, hotelCancellationFeesRevenueAccountId, "4140", "Cancellation Fees Revenue", AccountType.OtherIncome);
            await EnsureAccountAsync(dbContext, hotelRoomCostAccountId, "5100", "Hotel Room Cost", AccountType.CostOfGoodsSold);
            await EnsureAccountAsync(dbContext, hotelMealCostAccountId, "5110", "Hotel Meal Cost", AccountType.CostOfGoodsSold);
            await EnsureAccountAsync(dbContext, hotelContractCostAccountId, "5120", "Hotel Contract Cost", AccountType.CostOfGoodsSold);
            await EnsureAccountAsync(dbContext, tourismPackageCostAccountId, "5130", "Tourism Package Cost", AccountType.CostOfGoodsSold);
        }

        if (!await dbContext.TaxCodes.AnyAsync())
        {
            dbContext.TaxCodes.AddRange(
                new TaxCode("VAT14-S", "VAT 14% Sales", TaxCodeScope.Sales, 14, salesTaxPayableAccountId, "Default sales VAT code.") { Id = salesVat14Id },
                new TaxCode("VAT14-P", "VAT 14% Purchase", TaxCodeScope.Purchase, 14, purchaseTaxReceivableAccountId, "Default purchase VAT code.") { Id = purchaseVat14Id });
        }

        if (seedDemoData && !await dbContext.Customers.AnyAsync())
        {
            dbContext.Customers.AddRange(
                new Customer("Ahmed Mohamed", "Solution SA", "ahmed@solution.sa", "+966 123 50 4567", "EGP", 0),
                new Customer("Sara Ali", "Horizon International", "s.ali@horizon.com", "+966 456 888 2121", "EGP", 0),
                new Customer("Khaled Mansour", "Mansour Stores", "k.mansour@shop.sa", "+966 565 990 1010", "EGP", 0));
        }

        if (seedDemoData && !await dbContext.Vendors.AnyAsync())
        {
            dbContext.Vendors.AddRange(
                new Vendor("Cairo Office Supplies", "Cairo Office Supplies LLC", "orders@cairo-office.example", "+20 100 111 2222", "EGP", 0),
                new Vendor("Delta Hardware", "Delta Hardware Co.", "sales@delta-hardware.example", "+20 100 333 4444", "EGP", 0));
        }

        if (seedDemoData && !await dbContext.Items.AnyAsync())
        {
            dbContext.Items.AddRange(
                new Item("Consulting Hour", ItemType.Service, "SERV-001", null, 750, 0, 0, "hour", incomeAccountId, null, null, expenseAccountId),
                new Item("Receipt Printer", ItemType.Inventory, "INV-PRN-001", "622100000001", 4200, 3100, 0, "pcs", incomeAccountId, inventoryAccountId, cogsAccountId, expenseAccountId),
                new Item("Setup Fee", ItemType.NonInventory, "FEE-SETUP", null, 1500, 0, 0, "each", incomeAccountId, null, null, expenseAccountId));
        }

        if (seedDemoData && !await dbContext.CompanySettings.AnyAsync())
        {
            dbContext.CompanySettings.Add(new CompanySettings(
                companyName: "Zayed Demo Company",
                currency: "EGP",
                country: "Egypt",
                timeZoneId: "Africa/Cairo",
                defaultLanguage: "ar",
                legalName: "Zayed Demo Company LLC",
                email: "admin@zayed.local",
                phone: "+20 100 000 0000",
                fiscalYearStartMonth: 1,
                fiscalYearStartDay: 1,
                defaultSalesTaxRate: 0,
                defaultPurchaseTaxRate: 0,
                taxesEnabled: false,
                defaultSalesTaxCodeId: salesVat14Id,
                defaultPurchaseTaxCodeId: purchaseVat14Id,
                pricesIncludeTax: false,
                taxRoundingMode: TaxRoundingMode.PerLine,
                defaultSalesTaxPayableAccountId: salesTaxPayableAccountId,
                defaultPurchaseTaxReceivableAccountId: purchaseTaxReceivableAccountId));
        }

        await SeedSecurityAsync(dbContext, seedDemoData);

        await dbContext.SaveChangesAsync();
    }

    private static bool ShouldSeedHotelAccounts(string businessType)
    {
        var normalized = BusinessTypes.NormalizeOrDefault(businessType);
        return normalized is BusinessTypes.HotelTourism or BusinessTypes.Mixed;
    }

    private static async Task SeedModulesAsync(ZayedDbContext dbContext, Guid? companyId, string businessType)
    {
        foreach (var module in ModuleSeedCatalog.Modules)
        {
            if (!await dbContext.Modules.AnyAsync(current => current.Code == module.Code))
            {
                dbContext.Modules.Add(module);
            }
        }

        foreach (var defaults in ModuleSeedCatalog.DefaultsByBusinessType)
        {
            foreach (var moduleCode in defaults.Value)
            {
                var module = ModuleSeedCatalog.Modules.First(current => current.Code == moduleCode);
                if (!await dbContext.BusinessTypeModuleDefaults.AnyAsync(current =>
                    current.BusinessType == defaults.Key && current.ModuleId == module.Id))
                {
                    dbContext.BusinessTypeModuleDefaults.Add(new BusinessTypeModuleDefault(defaults.Key, module.Id, isEnabledByDefault: true));
                }
            }
        }

        foreach (var menuItem in ModuleSeedCatalog.MenuItems)
        {
            var existing = await dbContext.MenuItems.FirstOrDefaultAsync(current => current.Id == menuItem.Id);
            if (existing is null)
            {
                dbContext.MenuItems.Add(menuItem);
                continue;
            }

            if (MenuItemChanged(existing, menuItem))
            {
                existing.UpdateDefinition(
                    menuItem.ModuleCode,
                    menuItem.ParentId,
                    menuItem.TitleAr,
                    menuItem.TitleEn,
                    menuItem.Route,
                    menuItem.Icon,
                    menuItem.SortOrder,
                    menuItem.IsActive);
            }
        }

        if (companyId is not Guid activeCompanyId || activeCompanyId == Guid.Empty)
        {
            return;
        }

        if (await dbContext.CompanyModules.AnyAsync(current => current.CompanyId == activeCompanyId))
        {
            return;
        }

        var normalizedBusinessType = BusinessTypes.NormalizeOrDefault(businessType);
        var enabledModuleCodes = ModuleSeedCatalog.DefaultsByBusinessType.TryGetValue(normalizedBusinessType, out var configuredDefaults)
            ? configuredDefaults
            : ModuleSeedCatalog.DefaultsByBusinessType[BusinessTypes.Retail];

        foreach (var module in ModuleSeedCatalog.Modules.Where(current => enabledModuleCodes.Contains(current.Code)))
        {
            dbContext.CompanyModules.Add(new CompanyModule(activeCompanyId, module.Id, isEnabled: true));
        }
    }

    private static bool MenuItemChanged(MenuItemDefinition current, MenuItemDefinition seed)
    {
        return current.ModuleCode != seed.ModuleCode
            || current.ParentId != seed.ParentId
            || current.TitleAr != seed.TitleAr
            || current.TitleEn != seed.TitleEn
            || current.Route != seed.Route
            || current.Icon != seed.Icon
            || current.SortOrder != seed.SortOrder
            || current.IsActive != seed.IsActive;
    }

    private static async Task SeedSecurityAsync(ZayedDbContext dbContext, bool seedDemoData)
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

        if (seedDemoData && !await dbContext.SecurityUsers.AnyAsync())
        {
            var adminRole = await dbContext.SecurityRoles.FirstOrDefaultAsync(role => role.RoleKey == "ADMIN");
            var admin = new SecurityUser(
                "admin",
                "System Administrator",
                "admin@zayed.local",
                new PasswordHasher().HashPassword("admin"));
            dbContext.SecurityUsers.Add(admin);
            await dbContext.SaveChangesAsync();

            if (adminRole is not null)
            {
                dbContext.UserRoleAssignments.Add(new UserRoleAssignment(admin.Id, adminRole.Id));
            }
        }
    }

    private static async Task EnsureAccountAsync(
        ZayedDbContext dbContext,
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
