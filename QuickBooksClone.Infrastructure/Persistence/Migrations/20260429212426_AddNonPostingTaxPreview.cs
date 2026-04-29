using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace QuickBooksClone.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddNonPostingTaxPreview : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<decimal>(
                name: "TaxAmount",
                table: "sales_order_lines",
                type: "TEXT",
                precision: 18,
                scale: 4,
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<Guid>(
                name: "TaxCodeId",
                table: "sales_order_lines",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "TaxRatePercent",
                table: "sales_order_lines",
                type: "TEXT",
                precision: 18,
                scale: 4,
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<decimal>(
                name: "TaxAmount",
                table: "purchase_order_lines",
                type: "TEXT",
                precision: 18,
                scale: 4,
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<Guid>(
                name: "TaxCodeId",
                table: "purchase_order_lines",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "TaxRatePercent",
                table: "purchase_order_lines",
                type: "TEXT",
                precision: 18,
                scale: 4,
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<decimal>(
                name: "TaxAmount",
                table: "estimate_lines",
                type: "TEXT",
                precision: 18,
                scale: 4,
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<Guid>(
                name: "TaxCodeId",
                table: "estimate_lines",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "TaxRatePercent",
                table: "estimate_lines",
                type: "TEXT",
                precision: 18,
                scale: 4,
                nullable: false,
                defaultValue: 0m);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "TaxAmount",
                table: "sales_order_lines");

            migrationBuilder.DropColumn(
                name: "TaxCodeId",
                table: "sales_order_lines");

            migrationBuilder.DropColumn(
                name: "TaxRatePercent",
                table: "sales_order_lines");

            migrationBuilder.DropColumn(
                name: "TaxAmount",
                table: "purchase_order_lines");

            migrationBuilder.DropColumn(
                name: "TaxCodeId",
                table: "purchase_order_lines");

            migrationBuilder.DropColumn(
                name: "TaxRatePercent",
                table: "purchase_order_lines");

            migrationBuilder.DropColumn(
                name: "TaxAmount",
                table: "estimate_lines");

            migrationBuilder.DropColumn(
                name: "TaxCodeId",
                table: "estimate_lines");

            migrationBuilder.DropColumn(
                name: "TaxRatePercent",
                table: "estimate_lines");
        }
    }
}
