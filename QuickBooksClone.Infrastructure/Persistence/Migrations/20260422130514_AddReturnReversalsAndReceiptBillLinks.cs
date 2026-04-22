using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace QuickBooksClone.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddReturnReversalsAndReceiptBillLinks : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "ReversalTransactionId",
                table: "sales_returns",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "VoidedAt",
                table: "sales_returns",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "ReversalTransactionId",
                table: "purchase_returns",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "VoidedAt",
                table: "purchase_returns",
                type: "TEXT",
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
        }
    }
}
