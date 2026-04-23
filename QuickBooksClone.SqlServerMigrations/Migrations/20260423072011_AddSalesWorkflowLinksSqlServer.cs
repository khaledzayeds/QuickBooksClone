using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace QuickBooksClone.SqlServerMigrations.Migrations
{
    /// <inheritdoc />
    public partial class AddSalesWorkflowLinksSqlServer : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "EstimateId",
                table: "sales_orders",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "EstimateLineId",
                table: "sales_order_lines",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "SalesOrderId",
                table: "invoices",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "SalesOrderLineId",
                table: "invoice_lines",
                type: "uniqueidentifier",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "EstimateId",
                table: "sales_orders");

            migrationBuilder.DropColumn(
                name: "EstimateLineId",
                table: "sales_order_lines");

            migrationBuilder.DropColumn(
                name: "SalesOrderId",
                table: "invoices");

            migrationBuilder.DropColumn(
                name: "SalesOrderLineId",
                table: "invoice_lines");
        }
    }
}
