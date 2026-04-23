using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace QuickBooksClone.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddSalesWorkflowLinks : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "EstimateId",
                table: "sales_orders",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "EstimateLineId",
                table: "sales_order_lines",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "SalesOrderId",
                table: "invoices",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "SalesOrderLineId",
                table: "invoice_lines",
                type: "TEXT",
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
