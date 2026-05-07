namespace QuickBooksClone.Core.Security;

public static class PermissionCatalog
{
    private static readonly PermissionDefinition[] Permissions =
    [
        new("Settings.Manage", "Settings", "Manage settings", "Change company, device, backup, and runtime settings."),
        new("Users.Manage", "Security", "Manage users", "Create users, roles, and permission assignments."),
        new("Audit.View", "Security", "View audit trail", "View user activity and protected business action history."),
        new("Reports.View", "Reports", "View reports", "View accounting, inventory, and aging reports."),
        new("Accounting.View", "Accounting", "View accounting", "View chart of accounts and transactions."),
        new("Accounting.Manage", "Accounting", "Manage accounting", "Create and manage accounts, journal entries, and adjustments."),
        new("TimeTracking.Manage", "Time Tracking", "Manage time entries", "Create, update, approve, invoice, and void time entries."),
        new("Payroll.Manage", "Payroll", "Manage payroll", "Configure payroll setup, employees, earnings, deductions, and payroll runs."),
        new("Customers.Manage", "Customers", "Manage customers", "View, create, and update customer records."),
        new("Vendors.Manage", "Vendors", "Manage vendors", "View, create, and update vendor records."),
        new("Sales.Estimate.Manage", "Sales", "Manage estimates", "Create, edit, accept, decline, and cancel estimates."),
        new("Sales.Order.Manage", "Sales", "Manage sales orders", "Create, edit, close, and cancel sales orders."),
        new("Sales.Invoice.Manage", "Sales", "Manage invoices", "Create, edit, send, post, void, and convert invoices."),
        new("Sales.Payment.Manage", "Sales", "Manage customer payments", "Receive and void customer payments."),
        new("Sales.Return.Manage", "Sales", "Manage sales returns", "Create and reverse customer-side returns and credits."),
        new("Purchases.Order.Manage", "Purchases", "Manage purchase orders", "Create, edit, open, close, and cancel purchase orders."),
        new("Purchases.Receive.Manage", "Purchases", "Manage receiving", "Receive inventory and void eligible receipts."),
        new("Purchases.Bill.Manage", "Purchases", "Manage bills", "Create, edit, post, and void purchase bills."),
        new("Purchases.Payment.Manage", "Purchases", "Manage vendor payments", "Pay and void vendor payments."),
        new("Purchases.Return.Manage", "Purchases", "Manage purchase returns", "Create and reverse vendor-side returns and credits."),
        new("Inventory.Items.Manage", "Inventory", "Manage items", "Create and update products, services, and item accounts."),
        new("Inventory.Adjust.Manage", "Inventory", "Manage inventory adjustments", "Create, post, and void inventory adjustments."),
        new("Data.BackupRestore", "Data", "Backup and restore", "Create backups, restore data, and view restore metadata."),
        new("Data.Sync.Manage", "Data", "Manage sync", "View sync diagnostics and mark records for sync."),
        new("Documents.Metadata.Manage", "Documents", "Manage document metadata", "Edit document notes, ship-to fields, templates, and attachment references.")
    ];

    public static IReadOnlyList<PermissionDefinition> All => Permissions;

    public static bool IsKnown(string key) =>
        Permissions.Any(permission => string.Equals(permission.Key, key?.Trim(), StringComparison.OrdinalIgnoreCase));

    public static IReadOnlyCollection<string> NormalizeMany(IEnumerable<string> permissions)
    {
        var normalized = permissions
            .Where(permission => !string.IsNullOrWhiteSpace(permission))
            .Select(permission => permission.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        var unknown = normalized.FirstOrDefault(permission => !IsKnown(permission));
        if (unknown is not null)
        {
            throw new ArgumentOutOfRangeException(nameof(permissions), $"Unknown permission '{unknown}'.");
        }

        return normalized
            .Select(permission => Permissions.Single(definition => string.Equals(definition.Key, permission, StringComparison.OrdinalIgnoreCase)).Key)
            .OrderBy(permission => permission, StringComparer.OrdinalIgnoreCase)
            .ToList();
    }

    public static IReadOnlyCollection<string> ForRole(string roleKey)
    {
        var all = Permissions.Select(permission => permission.Key).ToList();
        return NormalizeRoleKey(roleKey) switch
        {
            "ADMIN" => all,
            "MANAGER" => all.Where(permission => permission != "Users.Manage").ToList(),
            "ACCOUNTANT" => all.Where(permission =>
                permission.StartsWith("Accounting.", StringComparison.Ordinal) ||
                permission.StartsWith("Reports.", StringComparison.Ordinal) ||
                permission.StartsWith("Audit.", StringComparison.Ordinal) ||
                permission.StartsWith("TimeTracking.", StringComparison.Ordinal) ||
                permission.StartsWith("Payroll.", StringComparison.Ordinal) ||
                permission.StartsWith("Customers.", StringComparison.Ordinal) ||
                permission.StartsWith("Vendors.", StringComparison.Ordinal) ||
                permission.StartsWith("Sales.", StringComparison.Ordinal) ||
                permission.StartsWith("Purchases.", StringComparison.Ordinal) ||
                permission.StartsWith("Documents.", StringComparison.Ordinal)).ToList(),
            "CASHIER" =>
            [
                "Sales.Invoice.Manage",
                "Sales.Payment.Manage",
                "Sales.Return.Manage",
                "Customers.Manage",
                "Inventory.Items.Manage",
                "Documents.Metadata.Manage"
            ],
            "INVENTORY" =>
            [
                "Inventory.Items.Manage",
                "Inventory.Adjust.Manage",
                "Vendors.Manage",
                "Purchases.Order.Manage",
                "Purchases.Receive.Manage",
                "Reports.View",
                "Documents.Metadata.Manage"
            ],
            "READONLY" => ["Reports.View", "Accounting.View"],
            _ => []
        };
    }

    public static string NormalizeRoleKey(string roleKey)
    {
        if (string.IsNullOrWhiteSpace(roleKey))
        {
            throw new ArgumentException("Role key is required.", nameof(roleKey));
        }

        return roleKey.Trim().ToUpperInvariant();
    }
}
