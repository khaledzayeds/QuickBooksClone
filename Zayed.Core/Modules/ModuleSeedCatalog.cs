using Zayed.Core.Companies;

namespace Zayed.Core.Modules;

public static class ModuleSeedCatalog
{
    public static IReadOnlyList<ModuleDefinition> Modules { get; } =
    [
        Module("00000000-0000-0000-0001-000000000001", ModuleCodes.CoreAccounting, "Core Accounting"),
        Module("00000000-0000-0000-0001-000000000002", ModuleCodes.Customers, "Customers"),
        Module("00000000-0000-0000-0001-000000000003", ModuleCodes.Vendors, "Vendors"),
        Module("00000000-0000-0000-0001-000000000004", ModuleCodes.UsersPermissions, "Users & Permissions"),
        Module("00000000-0000-0000-0001-000000000005", ModuleCodes.Reports, "Reports"),
        Module("00000000-0000-0000-0001-000000000006", ModuleCodes.Sales, "Sales"),
        Module("00000000-0000-0000-0001-000000000007", ModuleCodes.Purchases, "Purchases"),
        Module("00000000-0000-0000-0001-000000000008", ModuleCodes.Inventory, "Inventory"),
        Module("00000000-0000-0000-0001-000000000009", ModuleCodes.Products, "Products"),
        Module("00000000-0000-0000-0001-000000000010", ModuleCodes.Pos, "POS"),
        Module("00000000-0000-0000-0001-000000000011", ModuleCodes.Hotels, "Hotels"),
        Module("00000000-0000-0000-0001-000000000012", ModuleCodes.HotelContracts, "Hotel Contracts"),
        Module("00000000-0000-0000-0001-000000000013", ModuleCodes.HotelAllotment, "Hotel Allotment"),
        Module("00000000-0000-0000-0001-000000000014", ModuleCodes.HotelAgents, "Hotel Agents"),
        Module("00000000-0000-0000-0001-000000000015", ModuleCodes.HotelRoomTypes, "Hotel Room Types"),
        Module("00000000-0000-0000-0001-000000000016", ModuleCodes.HotelMealPlans, "Hotel Meal Plans"),
        Module("00000000-0000-0000-0001-000000000017", ModuleCodes.HotelReservations, "Hotel Reservations"),
        Module("00000000-0000-0000-0001-000000000018", ModuleCodes.HotelAvailability, "Hotel Availability"),
        Module("00000000-0000-0000-0001-000000000019", ModuleCodes.HotelOperationsReports, "Hotel Operations Reports"),
        Module("00000000-0000-0000-0001-000000000020", ModuleCodes.Services, "Services"),
        Module("00000000-0000-0000-0001-000000000021", ModuleCodes.ServiceInvoices, "Service Invoices"),
        Module("00000000-0000-0000-0001-000000000022", ModuleCodes.ServiceReports, "Service Reports")
    ];

    public static IReadOnlyDictionary<string, IReadOnlyList<string>> DefaultsByBusinessType { get; } =
        new Dictionary<string, IReadOnlyList<string>>(StringComparer.OrdinalIgnoreCase)
        {
            [BusinessTypes.Retail] =
            [
                ModuleCodes.CoreAccounting, ModuleCodes.Customers, ModuleCodes.Vendors, ModuleCodes.UsersPermissions,
                ModuleCodes.Reports, ModuleCodes.Sales, ModuleCodes.Purchases, ModuleCodes.Inventory,
                ModuleCodes.Products, ModuleCodes.Pos
            ],
            [BusinessTypes.HotelTourism] =
            [
                ModuleCodes.CoreAccounting, ModuleCodes.Customers, ModuleCodes.Vendors, ModuleCodes.UsersPermissions,
                ModuleCodes.Reports, ModuleCodes.Hotels, ModuleCodes.HotelContracts, ModuleCodes.HotelAllotment,
                ModuleCodes.HotelReservations, ModuleCodes.HotelAgents, ModuleCodes.HotelRoomTypes,
                ModuleCodes.HotelMealPlans, ModuleCodes.HotelAvailability, ModuleCodes.HotelOperationsReports
            ],
            [BusinessTypes.Services] =
            [
                ModuleCodes.CoreAccounting, ModuleCodes.Customers, ModuleCodes.Vendors, ModuleCodes.UsersPermissions,
                ModuleCodes.Reports, ModuleCodes.Services, ModuleCodes.ServiceInvoices, ModuleCodes.ServiceReports
            ],
            [BusinessTypes.Mixed] =
            [
                ModuleCodes.CoreAccounting, ModuleCodes.Customers, ModuleCodes.Vendors, ModuleCodes.UsersPermissions,
                ModuleCodes.Reports, ModuleCodes.Sales, ModuleCodes.Purchases, ModuleCodes.Inventory,
                ModuleCodes.Products, ModuleCodes.Pos, ModuleCodes.Hotels, ModuleCodes.HotelContracts,
                ModuleCodes.HotelAllotment, ModuleCodes.HotelReservations, ModuleCodes.HotelAgents,
                ModuleCodes.HotelRoomTypes, ModuleCodes.HotelMealPlans, ModuleCodes.HotelAvailability,
                ModuleCodes.HotelOperationsReports
            ]
        };

    public static IReadOnlyList<MenuItemDefinition> MenuItems { get; } =
    [
        Menu("00000000-0000-0000-0002-000000000001", ModuleCodes.CoreAccounting, null, "الرئيسية", "Home", "/", "home", 10),
        Menu("00000000-0000-0000-0002-000000000002", ModuleCodes.CoreAccounting, null, "شركتي", "My Company", "/settings/company", "business", 20),
        Menu("00000000-0000-0000-0002-000000000003", ModuleCodes.CoreAccounting, null, "التدفق النقدي", "Cash Flow", "/cash-flow", "wallet", 30),
        Menu("00000000-0000-0000-0002-000000000004", ModuleCodes.Sales, null, "الفواتير", "Invoices", "/sales/invoices", "invoice", 100),
        Menu("00000000-0000-0000-0002-000000000005", ModuleCodes.Sales, null, "إيصالات البيع", "Sales Receipts", "/sales/receipts", "pos", 110),
        Menu("00000000-0000-0000-0002-000000000006", ModuleCodes.Sales, null, "مرتجعات البيع", "Sales Returns", "/sales/returns", "return", 120),
        Menu("00000000-0000-0000-0002-000000000007", ModuleCodes.Purchases, null, "فواتير الشراء", "Bills", "/purchases/bills", "receipt", 200),
        Menu("00000000-0000-0000-0002-000000000008", ModuleCodes.Purchases, null, "أوامر الشراء", "Purchase Orders", "/purchases/orders", "order", 210),
        Menu("00000000-0000-0000-0002-000000000009", ModuleCodes.Purchases, null, "استلام مخزون", "Receive Inventory", "/purchases/receive", "inventory", 220),
        Menu("00000000-0000-0000-0002-000000000010", ModuleCodes.Purchases, null, "مرتجعات الشراء", "Purchase Returns", "/purchases/returns", "return", 230),
        Menu("00000000-0000-0000-0002-000000000011", ModuleCodes.Products, null, "الأصناف والخدمات", "Items", "/master/items", "inventory", 300),
        Menu("00000000-0000-0000-0002-000000000012", ModuleCodes.Customers, null, "العملاء", "Customers", "/master/customers", "customers", 310),
        Menu("00000000-0000-0000-0002-000000000013", ModuleCodes.Vendors, null, "الموردين", "Vendors", "/master/vendors", "vendors", 320),
        Menu("00000000-0000-0000-0002-000000000014", ModuleCodes.CoreAccounting, null, "دليل الحسابات", "Chart of Accounts", "/master/coa", "accounts", 400),
        Menu("00000000-0000-0000-0002-000000000015", ModuleCodes.Reports, null, "التقارير", "Reports", "/reports", "reports", 500),
        Menu("00000000-0000-0000-0002-000000000016", ModuleCodes.Hotels, null, "الفنادق", "Hotels", "/hotels", "hotel", 600),
        Menu("00000000-0000-0000-0002-000000000017", ModuleCodes.HotelContracts, null, "عقود الفنادق", "Hotel Contracts", "/hotels/contracts", "contract", 610),
        Menu("00000000-0000-0000-0002-000000000018", ModuleCodes.HotelAllotment, null, "300 - حصة الفندق", "300 - Hotel Allotment", "/hotels/allotment/hotel", "hotel", 620),
        Menu("00000000-0000-0000-0002-000000000019", ModuleCodes.HotelAllotment, null, "301 - حصة الوكيل", "301 - Agent Allotment", "/hotels/allotment/agent", "agent", 621),
        Menu("00000000-0000-0000-0002-000000000020", ModuleCodes.HotelAllotment, null, "302 - زيادة حصة الفندق", "302 - Hotel Over Allotment", "/hotels/over-allotment/hotel", "hotel", 622),
        Menu("00000000-0000-0000-0002-000000000021", ModuleCodes.HotelAllotment, null, "303 - زيادة حصة الوكيل", "303 - Agent Over Allotment", "/hotels/over-allotment/agent", "agent", 623),
        Menu("00000000-0000-0000-0002-000000000022", ModuleCodes.HotelReservations, null, "400 - حجز فردي", "400 - Individual Reservation", "/hotels/reservations/individual", "calendar", 700),
        Menu("00000000-0000-0000-0002-000000000023", ModuleCodes.HotelReservations, null, "403 - تعديل الحجوزات", "403 - Edit Reservations", "/hotels/reservations/edit", "edit", 703),
        Menu("00000000-0000-0000-0002-000000000024", ModuleCodes.HotelAvailability, null, "700 - الإتاحة", "700 - Availability", "/hotels/reports/availability", "availability", 800),
        Menu("00000000-0000-0000-0002-000000000025", ModuleCodes.HotelOperationsReports, null, "7011 - الوصول خلال فترة", "7011 - Arrivals during period", "/hotels/reports/operations/arrivals", "arrivals", 811),
        Menu("00000000-0000-0000-0002-000000000026", ModuleCodes.HotelOperationsReports, null, "7012 - المغادرة خلال فترة", "7012 - Departures during period", "/hotels/reports/operations/departures", "departures", 812),
        Menu("00000000-0000-0000-0002-000000000027", ModuleCodes.HotelOperationsReports, null, "7013 - المقيمون خلال فترة", "7013 - In House During Period", "/hotels/reports/operations/in-house", "rooms", 813),
        Menu("00000000-0000-0000-0002-000000000028", ModuleCodes.HotelOperationsReports, null, "7014 - وصول + مقيم", "7014 - Arrival + In House", "/hotels/reports/operations/arrival-in-house", "reports", 814)
    ];

    private static ModuleDefinition Module(string id, string code, string name)
        => new(Guid.Parse(id), code, name);

    private static MenuItemDefinition Menu(string id, string moduleCode, Guid? parentId, string titleAr, string titleEn, string? route, string icon, int sortOrder)
        => new(Guid.Parse(id), moduleCode, parentId, titleAr, titleEn, route, icon, sortOrder);
}

public static class ModuleCodes
{
    public const string CoreAccounting = "core_accounting";
    public const string Customers = "customers";
    public const string Vendors = "vendors";
    public const string UsersPermissions = "users_permissions";
    public const string Reports = "reports";
    public const string Sales = "sales";
    public const string Purchases = "purchases";
    public const string Inventory = "inventory";
    public const string Products = "products";
    public const string Pos = "pos";
    public const string Hotels = "hotels";
    public const string HotelContracts = "hotel_contracts";
    public const string HotelAllotment = "hotel_allotment";
    public const string HotelAgents = "hotel_agents";
    public const string HotelRoomTypes = "hotel_room_types";
    public const string HotelMealPlans = "hotel_meal_plans";
    public const string HotelReservations = "hotel_reservations";
    public const string HotelAvailability = "hotel_availability";
    public const string HotelOperationsReports = "hotel_operations_reports";
    public const string Services = "services";
    public const string ServiceInvoices = "service_invoices";
    public const string ServiceReports = "service_reports";
}
