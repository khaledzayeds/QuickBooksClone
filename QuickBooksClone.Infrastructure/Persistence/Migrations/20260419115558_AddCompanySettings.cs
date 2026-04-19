using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace QuickBooksClone.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddCompanySettings : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "company_settings",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "TEXT", nullable: false),
                    CompanyId = table.Column<Guid>(type: "TEXT", nullable: false),
                    CompanyName = table.Column<string>(type: "TEXT", maxLength: 200, nullable: false),
                    LegalName = table.Column<string>(type: "TEXT", maxLength: 200, nullable: true),
                    Email = table.Column<string>(type: "TEXT", maxLength: 250, nullable: true),
                    Phone = table.Column<string>(type: "TEXT", maxLength: 50, nullable: true),
                    Currency = table.Column<string>(type: "TEXT", maxLength: 10, nullable: false),
                    Country = table.Column<string>(type: "TEXT", maxLength: 120, nullable: false),
                    TimeZoneId = table.Column<string>(type: "TEXT", maxLength: 120, nullable: false),
                    DefaultLanguage = table.Column<string>(type: "TEXT", maxLength: 10, nullable: false),
                    TaxRegistrationNumber = table.Column<string>(type: "TEXT", maxLength: 100, nullable: true),
                    AddressLine1 = table.Column<string>(type: "TEXT", maxLength: 200, nullable: true),
                    AddressLine2 = table.Column<string>(type: "TEXT", maxLength: 200, nullable: true),
                    City = table.Column<string>(type: "TEXT", maxLength: 120, nullable: true),
                    Region = table.Column<string>(type: "TEXT", maxLength: 120, nullable: true),
                    PostalCode = table.Column<string>(type: "TEXT", maxLength: 40, nullable: true),
                    FiscalYearStartMonth = table.Column<int>(type: "INTEGER", nullable: false),
                    FiscalYearStartDay = table.Column<int>(type: "INTEGER", nullable: false),
                    DefaultSalesTaxRate = table.Column<decimal>(type: "TEXT", precision: 18, scale: 4, nullable: false),
                    DefaultPurchaseTaxRate = table.Column<decimal>(type: "TEXT", precision: 18, scale: 4, nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_company_settings", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_company_settings_CompanyId",
                table: "company_settings",
                column: "CompanyId",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "company_settings");
        }
    }
}
