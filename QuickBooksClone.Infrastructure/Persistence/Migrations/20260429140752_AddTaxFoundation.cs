using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace QuickBooksClone.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddTaxFoundation : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<decimal>(
                name: "TaxAmount",
                table: "purchase_bills",
                type: "TEXT",
                precision: 18,
                scale: 4,
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<decimal>(
                name: "TaxAmount",
                table: "purchase_bill_lines",
                type: "TEXT",
                precision: 18,
                scale: 4,
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<Guid>(
                name: "TaxCodeId",
                table: "purchase_bill_lines",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "TaxRatePercent",
                table: "purchase_bill_lines",
                type: "TEXT",
                precision: 18,
                scale: 4,
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<decimal>(
                name: "TaxAmount",
                table: "invoice_lines",
                type: "TEXT",
                precision: 18,
                scale: 4,
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<Guid>(
                name: "TaxCodeId",
                table: "invoice_lines",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "TaxRatePercent",
                table: "invoice_lines",
                type: "TEXT",
                precision: 18,
                scale: 4,
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<Guid>(
                name: "DefaultPurchaseTaxCodeId",
                table: "company_settings",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "DefaultPurchaseTaxReceivableAccountId",
                table: "company_settings",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "DefaultSalesTaxCodeId",
                table: "company_settings",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "DefaultSalesTaxPayableAccountId",
                table: "company_settings",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "PricesIncludeTax",
                table: "company_settings",
                type: "INTEGER",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<int>(
                name: "TaxRoundingMode",
                table: "company_settings",
                type: "INTEGER",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<bool>(
                name: "TaxesEnabled",
                table: "company_settings",
                type: "INTEGER",
                nullable: false,
                defaultValue: false);

            migrationBuilder.CreateTable(
                name: "tax_codes",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "TEXT", nullable: false),
                    CompanyId = table.Column<Guid>(type: "TEXT", nullable: false),
                    Code = table.Column<string>(type: "TEXT", maxLength: 40, nullable: false),
                    Name = table.Column<string>(type: "TEXT", maxLength: 120, nullable: false),
                    Scope = table.Column<int>(type: "INTEGER", nullable: false),
                    RatePercent = table.Column<decimal>(type: "TEXT", precision: 18, scale: 4, nullable: false),
                    TaxAccountId = table.Column<Guid>(type: "TEXT", nullable: false),
                    Description = table.Column<string>(type: "TEXT", maxLength: 500, nullable: true),
                    IsActive = table.Column<bool>(type: "INTEGER", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_tax_codes", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_tax_codes_Code",
                table: "tax_codes",
                column: "Code",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_tax_codes_CompanyId",
                table: "tax_codes",
                column: "CompanyId");

            migrationBuilder.CreateIndex(
                name: "IX_tax_codes_Scope",
                table: "tax_codes",
                column: "Scope");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "TaxAmount",
                table: "purchase_bills");

            migrationBuilder.DropTable(
                name: "tax_codes");

            migrationBuilder.DropColumn(
                name: "TaxAmount",
                table: "purchase_bill_lines");

            migrationBuilder.DropColumn(
                name: "TaxCodeId",
                table: "purchase_bill_lines");

            migrationBuilder.DropColumn(
                name: "TaxRatePercent",
                table: "purchase_bill_lines");

            migrationBuilder.DropColumn(
                name: "TaxAmount",
                table: "invoice_lines");

            migrationBuilder.DropColumn(
                name: "TaxCodeId",
                table: "invoice_lines");

            migrationBuilder.DropColumn(
                name: "TaxRatePercent",
                table: "invoice_lines");

            migrationBuilder.DropColumn(
                name: "DefaultPurchaseTaxCodeId",
                table: "company_settings");

            migrationBuilder.DropColumn(
                name: "DefaultPurchaseTaxReceivableAccountId",
                table: "company_settings");

            migrationBuilder.DropColumn(
                name: "DefaultSalesTaxCodeId",
                table: "company_settings");

            migrationBuilder.DropColumn(
                name: "DefaultSalesTaxPayableAccountId",
                table: "company_settings");

            migrationBuilder.DropColumn(
                name: "PricesIncludeTax",
                table: "company_settings");

            migrationBuilder.DropColumn(
                name: "TaxRoundingMode",
                table: "company_settings");

            migrationBuilder.DropColumn(
                name: "TaxesEnabled",
                table: "company_settings");
        }
    }
}
