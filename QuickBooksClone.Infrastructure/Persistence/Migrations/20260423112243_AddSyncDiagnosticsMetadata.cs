using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace QuickBooksClone.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddSyncDiagnosticsMetadata : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LastModifiedAt",
                table: "vendor_payments",
                type: "TEXT",
                nullable: false,
                defaultValue: new DateTimeOffset(new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)));

            migrationBuilder.AddColumn<long>(
                name: "SyncVersion",
                table: "vendor_payments",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0L);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LastModifiedAt",
                table: "vendor_credit_activities",
                type: "TEXT",
                nullable: false,
                defaultValue: new DateTimeOffset(new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)));

            migrationBuilder.AddColumn<long>(
                name: "SyncVersion",
                table: "vendor_credit_activities",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0L);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LastModifiedAt",
                table: "sales_returns",
                type: "TEXT",
                nullable: false,
                defaultValue: new DateTimeOffset(new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)));

            migrationBuilder.AddColumn<long>(
                name: "SyncVersion",
                table: "sales_returns",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0L);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LastModifiedAt",
                table: "sales_orders",
                type: "TEXT",
                nullable: false,
                defaultValue: new DateTimeOffset(new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)));

            migrationBuilder.AddColumn<long>(
                name: "SyncVersion",
                table: "sales_orders",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0L);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LastModifiedAt",
                table: "purchase_returns",
                type: "TEXT",
                nullable: false,
                defaultValue: new DateTimeOffset(new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)));

            migrationBuilder.AddColumn<long>(
                name: "SyncVersion",
                table: "purchase_returns",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0L);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LastModifiedAt",
                table: "purchase_orders",
                type: "TEXT",
                nullable: false,
                defaultValue: new DateTimeOffset(new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)));

            migrationBuilder.AddColumn<long>(
                name: "SyncVersion",
                table: "purchase_orders",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0L);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LastModifiedAt",
                table: "purchase_bills",
                type: "TEXT",
                nullable: false,
                defaultValue: new DateTimeOffset(new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)));

            migrationBuilder.AddColumn<long>(
                name: "SyncVersion",
                table: "purchase_bills",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0L);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LastModifiedAt",
                table: "payments",
                type: "TEXT",
                nullable: false,
                defaultValue: new DateTimeOffset(new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)));

            migrationBuilder.AddColumn<long>(
                name: "SyncVersion",
                table: "payments",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0L);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LastModifiedAt",
                table: "journal_entries",
                type: "TEXT",
                nullable: false,
                defaultValue: new DateTimeOffset(new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)));

            migrationBuilder.AddColumn<long>(
                name: "SyncVersion",
                table: "journal_entries",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0L);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LastModifiedAt",
                table: "invoices",
                type: "TEXT",
                nullable: false,
                defaultValue: new DateTimeOffset(new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)));

            migrationBuilder.AddColumn<long>(
                name: "SyncVersion",
                table: "invoices",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0L);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LastModifiedAt",
                table: "inventory_receipts",
                type: "TEXT",
                nullable: false,
                defaultValue: new DateTimeOffset(new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)));

            migrationBuilder.AddColumn<long>(
                name: "SyncVersion",
                table: "inventory_receipts",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0L);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LastModifiedAt",
                table: "inventory_adjustments",
                type: "TEXT",
                nullable: false,
                defaultValue: new DateTimeOffset(new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)));

            migrationBuilder.AddColumn<long>(
                name: "SyncVersion",
                table: "inventory_adjustments",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0L);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LastModifiedAt",
                table: "estimates",
                type: "TEXT",
                nullable: false,
                defaultValue: new DateTimeOffset(new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)));

            migrationBuilder.AddColumn<long>(
                name: "SyncVersion",
                table: "estimates",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0L);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LastModifiedAt",
                table: "customer_credit_activities",
                type: "TEXT",
                nullable: false,
                defaultValue: new DateTimeOffset(new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)));

            migrationBuilder.AddColumn<long>(
                name: "SyncVersion",
                table: "customer_credit_activities",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0L);

            migrationBuilder.CreateIndex(
                name: "IX_vendor_payments_LastModifiedAt",
                table: "vendor_payments",
                column: "LastModifiedAt");

            migrationBuilder.CreateIndex(
                name: "IX_vendor_credit_activities_LastModifiedAt",
                table: "vendor_credit_activities",
                column: "LastModifiedAt");

            migrationBuilder.CreateIndex(
                name: "IX_sales_returns_LastModifiedAt",
                table: "sales_returns",
                column: "LastModifiedAt");

            migrationBuilder.CreateIndex(
                name: "IX_sales_orders_LastModifiedAt",
                table: "sales_orders",
                column: "LastModifiedAt");

            migrationBuilder.CreateIndex(
                name: "IX_purchase_returns_LastModifiedAt",
                table: "purchase_returns",
                column: "LastModifiedAt");

            migrationBuilder.CreateIndex(
                name: "IX_purchase_orders_LastModifiedAt",
                table: "purchase_orders",
                column: "LastModifiedAt");

            migrationBuilder.CreateIndex(
                name: "IX_purchase_bills_LastModifiedAt",
                table: "purchase_bills",
                column: "LastModifiedAt");

            migrationBuilder.CreateIndex(
                name: "IX_payments_LastModifiedAt",
                table: "payments",
                column: "LastModifiedAt");

            migrationBuilder.CreateIndex(
                name: "IX_journal_entries_LastModifiedAt",
                table: "journal_entries",
                column: "LastModifiedAt");

            migrationBuilder.CreateIndex(
                name: "IX_invoices_LastModifiedAt",
                table: "invoices",
                column: "LastModifiedAt");

            migrationBuilder.CreateIndex(
                name: "IX_inventory_receipts_LastModifiedAt",
                table: "inventory_receipts",
                column: "LastModifiedAt");

            migrationBuilder.CreateIndex(
                name: "IX_inventory_adjustments_LastModifiedAt",
                table: "inventory_adjustments",
                column: "LastModifiedAt");

            migrationBuilder.CreateIndex(
                name: "IX_estimates_LastModifiedAt",
                table: "estimates",
                column: "LastModifiedAt");

            migrationBuilder.CreateIndex(
                name: "IX_customer_credit_activities_LastModifiedAt",
                table: "customer_credit_activities",
                column: "LastModifiedAt");

            migrationBuilder.Sql("UPDATE customer_credit_activities SET LastModifiedAt = COALESCE(UpdatedAt, CreatedAt), SyncVersion = CASE WHEN SyncVersion = 0 THEN 1 ELSE SyncVersion END;");
            migrationBuilder.Sql("UPDATE estimates SET LastModifiedAt = COALESCE(UpdatedAt, CreatedAt), SyncVersion = CASE WHEN SyncVersion = 0 THEN 1 ELSE SyncVersion END;");
            migrationBuilder.Sql("UPDATE inventory_adjustments SET LastModifiedAt = COALESCE(UpdatedAt, CreatedAt), SyncVersion = CASE WHEN SyncVersion = 0 THEN 1 ELSE SyncVersion END;");
            migrationBuilder.Sql("UPDATE invoices SET LastModifiedAt = COALESCE(UpdatedAt, CreatedAt), SyncVersion = CASE WHEN SyncVersion = 0 THEN 1 ELSE SyncVersion END;");
            migrationBuilder.Sql("UPDATE journal_entries SET LastModifiedAt = COALESCE(UpdatedAt, CreatedAt), SyncVersion = CASE WHEN SyncVersion = 0 THEN 1 ELSE SyncVersion END;");
            migrationBuilder.Sql("UPDATE payments SET LastModifiedAt = COALESCE(UpdatedAt, CreatedAt), SyncVersion = CASE WHEN SyncVersion = 0 THEN 1 ELSE SyncVersion END;");
            migrationBuilder.Sql("UPDATE purchase_bills SET LastModifiedAt = COALESCE(UpdatedAt, CreatedAt), SyncVersion = CASE WHEN SyncVersion = 0 THEN 1 ELSE SyncVersion END;");
            migrationBuilder.Sql("UPDATE purchase_orders SET LastModifiedAt = COALESCE(UpdatedAt, CreatedAt), SyncVersion = CASE WHEN SyncVersion = 0 THEN 1 ELSE SyncVersion END;");
            migrationBuilder.Sql("UPDATE purchase_returns SET LastModifiedAt = COALESCE(UpdatedAt, CreatedAt), SyncVersion = CASE WHEN SyncVersion = 0 THEN 1 ELSE SyncVersion END;");
            migrationBuilder.Sql("UPDATE sales_orders SET LastModifiedAt = COALESCE(UpdatedAt, CreatedAt), SyncVersion = CASE WHEN SyncVersion = 0 THEN 1 ELSE SyncVersion END;");
            migrationBuilder.Sql("UPDATE sales_returns SET LastModifiedAt = COALESCE(UpdatedAt, CreatedAt), SyncVersion = CASE WHEN SyncVersion = 0 THEN 1 ELSE SyncVersion END;");
            migrationBuilder.Sql("UPDATE vendor_credit_activities SET LastModifiedAt = COALESCE(UpdatedAt, CreatedAt), SyncVersion = CASE WHEN SyncVersion = 0 THEN 1 ELSE SyncVersion END;");
            migrationBuilder.Sql("UPDATE vendor_payments SET LastModifiedAt = COALESCE(UpdatedAt, CreatedAt), SyncVersion = CASE WHEN SyncVersion = 0 THEN 1 ELSE SyncVersion END;");
            migrationBuilder.Sql("UPDATE inventory_receipts SET LastModifiedAt = COALESCE(UpdatedAt, CreatedAt), SyncVersion = CASE WHEN SyncVersion = 0 THEN 1 ELSE SyncVersion END;");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_vendor_payments_LastModifiedAt",
                table: "vendor_payments");

            migrationBuilder.DropIndex(
                name: "IX_vendor_credit_activities_LastModifiedAt",
                table: "vendor_credit_activities");

            migrationBuilder.DropIndex(
                name: "IX_sales_returns_LastModifiedAt",
                table: "sales_returns");

            migrationBuilder.DropIndex(
                name: "IX_sales_orders_LastModifiedAt",
                table: "sales_orders");

            migrationBuilder.DropIndex(
                name: "IX_purchase_returns_LastModifiedAt",
                table: "purchase_returns");

            migrationBuilder.DropIndex(
                name: "IX_purchase_orders_LastModifiedAt",
                table: "purchase_orders");

            migrationBuilder.DropIndex(
                name: "IX_purchase_bills_LastModifiedAt",
                table: "purchase_bills");

            migrationBuilder.DropIndex(
                name: "IX_payments_LastModifiedAt",
                table: "payments");

            migrationBuilder.DropIndex(
                name: "IX_journal_entries_LastModifiedAt",
                table: "journal_entries");

            migrationBuilder.DropIndex(
                name: "IX_invoices_LastModifiedAt",
                table: "invoices");

            migrationBuilder.DropIndex(
                name: "IX_inventory_receipts_LastModifiedAt",
                table: "inventory_receipts");

            migrationBuilder.DropIndex(
                name: "IX_inventory_adjustments_LastModifiedAt",
                table: "inventory_adjustments");

            migrationBuilder.DropIndex(
                name: "IX_estimates_LastModifiedAt",
                table: "estimates");

            migrationBuilder.DropIndex(
                name: "IX_customer_credit_activities_LastModifiedAt",
                table: "customer_credit_activities");

            migrationBuilder.DropColumn(
                name: "LastModifiedAt",
                table: "vendor_payments");

            migrationBuilder.DropColumn(
                name: "SyncVersion",
                table: "vendor_payments");

            migrationBuilder.DropColumn(
                name: "LastModifiedAt",
                table: "vendor_credit_activities");

            migrationBuilder.DropColumn(
                name: "SyncVersion",
                table: "vendor_credit_activities");

            migrationBuilder.DropColumn(
                name: "LastModifiedAt",
                table: "sales_returns");

            migrationBuilder.DropColumn(
                name: "SyncVersion",
                table: "sales_returns");

            migrationBuilder.DropColumn(
                name: "LastModifiedAt",
                table: "sales_orders");

            migrationBuilder.DropColumn(
                name: "SyncVersion",
                table: "sales_orders");

            migrationBuilder.DropColumn(
                name: "LastModifiedAt",
                table: "purchase_returns");

            migrationBuilder.DropColumn(
                name: "SyncVersion",
                table: "purchase_returns");

            migrationBuilder.DropColumn(
                name: "LastModifiedAt",
                table: "purchase_orders");

            migrationBuilder.DropColumn(
                name: "SyncVersion",
                table: "purchase_orders");

            migrationBuilder.DropColumn(
                name: "LastModifiedAt",
                table: "purchase_bills");

            migrationBuilder.DropColumn(
                name: "SyncVersion",
                table: "purchase_bills");

            migrationBuilder.DropColumn(
                name: "LastModifiedAt",
                table: "payments");

            migrationBuilder.DropColumn(
                name: "SyncVersion",
                table: "payments");

            migrationBuilder.DropColumn(
                name: "LastModifiedAt",
                table: "journal_entries");

            migrationBuilder.DropColumn(
                name: "SyncVersion",
                table: "journal_entries");

            migrationBuilder.DropColumn(
                name: "LastModifiedAt",
                table: "invoices");

            migrationBuilder.DropColumn(
                name: "SyncVersion",
                table: "invoices");

            migrationBuilder.DropColumn(
                name: "LastModifiedAt",
                table: "inventory_receipts");

            migrationBuilder.DropColumn(
                name: "SyncVersion",
                table: "inventory_receipts");

            migrationBuilder.DropColumn(
                name: "LastModifiedAt",
                table: "inventory_adjustments");

            migrationBuilder.DropColumn(
                name: "SyncVersion",
                table: "inventory_adjustments");

            migrationBuilder.DropColumn(
                name: "LastModifiedAt",
                table: "estimates");

            migrationBuilder.DropColumn(
                name: "SyncVersion",
                table: "estimates");

            migrationBuilder.DropColumn(
                name: "LastModifiedAt",
                table: "customer_credit_activities");

            migrationBuilder.DropColumn(
                name: "SyncVersion",
                table: "customer_credit_activities");
        }
    }
}
