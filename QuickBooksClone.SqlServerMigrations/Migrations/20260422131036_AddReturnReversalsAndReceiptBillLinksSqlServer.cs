using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace QuickBooksClone.SqlServerMigrations.Migrations
{
    /// <inheritdoc />
    public partial class AddReturnReversalsAndReceiptBillLinksSqlServer : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "ReversalTransactionId",
                table: "sales_returns",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "VoidedAt",
                table: "sales_returns",
                type: "datetimeoffset",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "ReversalTransactionId",
                table: "purchase_returns",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "VoidedAt",
                table: "purchase_returns",
                type: "datetimeoffset",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "InventoryReceiptId",
                table: "purchase_bills",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "InventoryReceiptLineId",
                table: "purchase_bill_lines",
                type: "uniqueidentifier",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ReversalTransactionId",
                table: "sales_returns");

            migrationBuilder.DropColumn(
                name: "VoidedAt",
                table: "sales_returns");

            migrationBuilder.DropColumn(
                name: "ReversalTransactionId",
                table: "purchase_returns");

            migrationBuilder.DropColumn(
                name: "VoidedAt",
                table: "purchase_returns");

            migrationBuilder.DropColumn(
                name: "InventoryReceiptId",
                table: "purchase_bills");

            migrationBuilder.DropColumn(
                name: "InventoryReceiptLineId",
                table: "purchase_bill_lines");
        }
    }
}
