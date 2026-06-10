using System;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Zayed.Infrastructure.Persistence;

#nullable disable

namespace Zayed.SqlServerMigrations.Migrations
{
    [DbContext(typeof(ZayedDbContext))]
    [Migration("20260610113001_AddCompanyModulesSqlServer")]
    public partial class AddCompanyModulesSqlServer : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "modules",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Code = table.Column<string>(type: "nvarchar(80)", maxLength: 80, nullable: false),
                    Name = table.Column<string>(type: "nvarchar(150)", maxLength: 150, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true)
                },
                constraints: table => table.PrimaryKey("PK_modules", x => x.Id));

            migrationBuilder.CreateTable(
                name: "business_type_module_defaults",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    BusinessType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    ModuleId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    IsEnabledByDefault = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true)
                },
                constraints: table => table.PrimaryKey("PK_business_type_module_defaults", x => x.Id));

            migrationBuilder.CreateTable(
                name: "company_modules",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ModuleId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    IsEnabled = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true)
                },
                constraints: table => table.PrimaryKey("PK_company_modules", x => x.Id));

            migrationBuilder.CreateTable(
                name: "menu_items",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ModuleCode = table.Column<string>(type: "nvarchar(80)", maxLength: 80, nullable: false),
                    ParentId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    TitleAr = table.Column<string>(type: "nvarchar(150)", maxLength: 150, nullable: false),
                    TitleEn = table.Column<string>(type: "nvarchar(150)", maxLength: 150, nullable: false),
                    Route = table.Column<string>(type: "nvarchar(250)", maxLength: 250, nullable: true),
                    Icon = table.Column<string>(type: "nvarchar(80)", maxLength: 80, nullable: false),
                    SortOrder = table.Column<int>(type: "int", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true)
                },
                constraints: table => table.PrimaryKey("PK_menu_items", x => x.Id));

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
