using System;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Zayed.Infrastructure.Persistence.Migrations
{
    [DbContext(typeof(ZayedDbContext))]
    [Migration("20260610113000_AddCompanyModules")]
    public partial class AddCompanyModules : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "modules",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "TEXT", nullable: false),
                    Code = table.Column<string>(type: "TEXT", maxLength: 80, nullable: false),
                    Name = table.Column<string>(type: "TEXT", maxLength: 150, nullable: false),
                    Description = table.Column<string>(type: "TEXT", maxLength: 500, nullable: true),
                    IsActive = table.Column<bool>(type: "INTEGER", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_modules", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "business_type_module_defaults",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "TEXT", nullable: false),
                    BusinessType = table.Column<string>(type: "TEXT", maxLength: 50, nullable: false),
                    ModuleId = table.Column<Guid>(type: "TEXT", nullable: false),
                    IsEnabledByDefault = table.Column<bool>(type: "INTEGER", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_business_type_module_defaults", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "company_modules",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "TEXT", nullable: false),
                    CompanyId = table.Column<Guid>(type: "TEXT", nullable: false),
                    ModuleId = table.Column<Guid>(type: "TEXT", nullable: false),
                    IsEnabled = table.Column<bool>(type: "INTEGER", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_company_modules", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "menu_items",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "TEXT", nullable: false),
                    ModuleCode = table.Column<string>(type: "TEXT", maxLength: 80, nullable: false),
                    ParentId = table.Column<Guid>(type: "TEXT", nullable: true),
                    TitleAr = table.Column<string>(type: "TEXT", maxLength: 150, nullable: false),
                    TitleEn = table.Column<string>(type: "TEXT", maxLength: 150, nullable: false),
                    Route = table.Column<string>(type: "TEXT", maxLength: 250, nullable: true),
                    Icon = table.Column<string>(type: "TEXT", maxLength: 80, nullable: false),
                    SortOrder = table.Column<int>(type: "INTEGER", nullable: false),
                    IsActive = table.Column<bool>(type: "INTEGER", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_menu_items", x => x.Id);
                });

            migrationBuilder.CreateIndex(name: "IX_modules_Code", table: "modules", column: "Code", unique: true);
            migrationBuilder.CreateIndex(name: "IX_business_type_module_defaults_BusinessType_ModuleId", table: "business_type_module_defaults", columns: new[] { "BusinessType", "ModuleId" }, unique: true);
            migrationBuilder.CreateIndex(name: "IX_company_modules_CompanyId", table: "company_modules", column: "CompanyId");
            migrationBuilder.CreateIndex(name: "IX_company_modules_CompanyId_ModuleId", table: "company_modules", columns: new[] { "CompanyId", "ModuleId" }, unique: true);
            migrationBuilder.CreateIndex(name: "IX_menu_items_ModuleCode", table: "menu_items", column: "ModuleCode");
            migrationBuilder.CreateIndex(name: "IX_menu_items_ParentId", table: "menu_items", column: "ParentId");
            migrationBuilder.CreateIndex(name: "IX_menu_items_Route", table: "menu_items", column: "Route");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(name: "business_type_module_defaults");
            migrationBuilder.DropTable(name: "company_modules");
            migrationBuilder.DropTable(name: "menu_items");
            migrationBuilder.DropTable(name: "modules");
        }
    }
}
