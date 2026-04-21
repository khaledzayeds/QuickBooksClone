using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace QuickBooksClone.SqlServerMigrations.Migrations
{
    /// <inheritdoc />
    public partial class AddSyncFoundationSqlServer : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "DeviceId",
                table: "vendor_payments",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "DocumentNo",
                table: "vendor_payments",
                type: "nvarchar(80)",
                maxLength: 80,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LastSyncAt",
                table: "vendor_payments",
                type: "datetimeoffset",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SyncError",
                table: "vendor_payments",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SyncStatus",
                table: "vendor_payments",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "DeviceId",
                table: "vendor_credit_activities",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "DocumentNo",
                table: "vendor_credit_activities",
                type: "nvarchar(80)",
                maxLength: 80,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LastSyncAt",
                table: "vendor_credit_activities",
                type: "datetimeoffset",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SyncError",
                table: "vendor_credit_activities",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SyncStatus",
                table: "vendor_credit_activities",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "DeviceId",
                table: "sales_returns",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "DocumentNo",
                table: "sales_returns",
                type: "nvarchar(80)",
                maxLength: 80,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LastSyncAt",
                table: "sales_returns",
                type: "datetimeoffset",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SyncError",
                table: "sales_returns",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SyncStatus",
                table: "sales_returns",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "DeviceId",
                table: "purchase_returns",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "DocumentNo",
                table: "purchase_returns",
                type: "nvarchar(80)",
                maxLength: 80,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LastSyncAt",
                table: "purchase_returns",
                type: "datetimeoffset",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SyncError",
                table: "purchase_returns",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SyncStatus",
                table: "purchase_returns",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "DeviceId",
                table: "purchase_orders",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "DocumentNo",
                table: "purchase_orders",
                type: "nvarchar(80)",
                maxLength: 80,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LastSyncAt",
                table: "purchase_orders",
                type: "datetimeoffset",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SyncError",
                table: "purchase_orders",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SyncStatus",
                table: "purchase_orders",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "DeviceId",
                table: "purchase_bills",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "DocumentNo",
                table: "purchase_bills",
                type: "nvarchar(80)",
                maxLength: 80,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LastSyncAt",
                table: "purchase_bills",
                type: "datetimeoffset",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SyncError",
                table: "purchase_bills",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SyncStatus",
                table: "purchase_bills",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "DeviceId",
                table: "payments",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "DocumentNo",
                table: "payments",
                type: "nvarchar(80)",
                maxLength: 80,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LastSyncAt",
                table: "payments",
                type: "datetimeoffset",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SyncError",
                table: "payments",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SyncStatus",
                table: "payments",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "DeviceId",
                table: "journal_entries",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "DocumentNo",
                table: "journal_entries",
                type: "nvarchar(80)",
                maxLength: 80,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LastSyncAt",
                table: "journal_entries",
                type: "datetimeoffset",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SyncError",
                table: "journal_entries",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SyncStatus",
                table: "journal_entries",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "DeviceId",
                table: "invoices",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "DocumentNo",
                table: "invoices",
                type: "nvarchar(80)",
                maxLength: 80,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LastSyncAt",
                table: "invoices",
                type: "datetimeoffset",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SyncError",
                table: "invoices",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SyncStatus",
                table: "invoices",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "DeviceId",
                table: "inventory_adjustments",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "DocumentNo",
                table: "inventory_adjustments",
                type: "nvarchar(80)",
                maxLength: 80,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LastSyncAt",
                table: "inventory_adjustments",
                type: "datetimeoffset",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SyncError",
                table: "inventory_adjustments",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SyncStatus",
                table: "inventory_adjustments",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "DeviceId",
                table: "customer_credit_activities",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "DocumentNo",
                table: "customer_credit_activities",
                type: "nvarchar(80)",
                maxLength: 80,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LastSyncAt",
                table: "customer_credit_activities",
                type: "datetimeoffset",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SyncError",
                table: "customer_credit_activities",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SyncStatus",
                table: "customer_credit_activities",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.Sql(
                """
                UPDATE invoices
                SET DeviceId = 'DEV01',
                    DocumentNo = COALESCE(NULLIF(InvoiceNumber, ''), CONCAT('DEV01-LEGACY-', LEFT(CONVERT(varchar(36), Id), 8))),
                    SyncStatus = 0
                WHERE ISNULL(DeviceId, '') = '' OR ISNULL(DocumentNo, '') = '';

                UPDATE payments
                SET DeviceId = 'DEV01',
                    DocumentNo = COALESCE(NULLIF(PaymentNumber, ''), CONCAT('DEV01-LEGACY-', LEFT(CONVERT(varchar(36), Id), 8))),
                    SyncStatus = 0
                WHERE ISNULL(DeviceId, '') = '' OR ISNULL(DocumentNo, '') = '';

                UPDATE purchase_bills
                SET DeviceId = 'DEV01',
                    DocumentNo = COALESCE(NULLIF(BillNumber, ''), CONCAT('DEV01-LEGACY-', LEFT(CONVERT(varchar(36), Id), 8))),
                    SyncStatus = 0
                WHERE ISNULL(DeviceId, '') = '' OR ISNULL(DocumentNo, '') = '';

                UPDATE purchase_orders
                SET DeviceId = 'DEV01',
                    DocumentNo = COALESCE(NULLIF(OrderNumber, ''), CONCAT('DEV01-LEGACY-', LEFT(CONVERT(varchar(36), Id), 8))),
                    SyncStatus = 0
                WHERE ISNULL(DeviceId, '') = '' OR ISNULL(DocumentNo, '') = '';

                UPDATE purchase_returns
                SET DeviceId = 'DEV01',
                    DocumentNo = COALESCE(NULLIF(ReturnNumber, ''), CONCAT('DEV01-LEGACY-', LEFT(CONVERT(varchar(36), Id), 8))),
                    SyncStatus = 0
                WHERE ISNULL(DeviceId, '') = '' OR ISNULL(DocumentNo, '') = '';

                UPDATE sales_returns
                SET DeviceId = 'DEV01',
                    DocumentNo = COALESCE(NULLIF(ReturnNumber, ''), CONCAT('DEV01-LEGACY-', LEFT(CONVERT(varchar(36), Id), 8))),
                    SyncStatus = 0
                WHERE ISNULL(DeviceId, '') = '' OR ISNULL(DocumentNo, '') = '';

                UPDATE inventory_adjustments
                SET DeviceId = 'DEV01',
                    DocumentNo = COALESCE(NULLIF(AdjustmentNumber, ''), CONCAT('DEV01-LEGACY-', LEFT(CONVERT(varchar(36), Id), 8))),
                    SyncStatus = 0
                WHERE ISNULL(DeviceId, '') = '' OR ISNULL(DocumentNo, '') = '';

                UPDATE journal_entries
                SET DeviceId = 'DEV01',
                    DocumentNo = COALESCE(NULLIF(EntryNumber, ''), CONCAT('DEV01-LEGACY-', LEFT(CONVERT(varchar(36), Id), 8))),
                    SyncStatus = 0
                WHERE ISNULL(DeviceId, '') = '' OR ISNULL(DocumentNo, '') = '';

                UPDATE customer_credit_activities
                SET DeviceId = 'DEV01',
                    DocumentNo = COALESCE(NULLIF(ReferenceNumber, ''), CONCAT('DEV01-LEGACY-', LEFT(CONVERT(varchar(36), Id), 8))),
                    SyncStatus = 0
                WHERE ISNULL(DeviceId, '') = '' OR ISNULL(DocumentNo, '') = '';

                UPDATE vendor_credit_activities
                SET DeviceId = 'DEV01',
                    DocumentNo = COALESCE(NULLIF(ReferenceNumber, ''), CONCAT('DEV01-LEGACY-', LEFT(CONVERT(varchar(36), Id), 8))),
                    SyncStatus = 0
                WHERE ISNULL(DeviceId, '') = '' OR ISNULL(DocumentNo, '') = '';

                UPDATE vendor_payments
                SET DeviceId = 'DEV01',
                    DocumentNo = COALESCE(NULLIF(PaymentNumber, ''), CONCAT('DEV01-LEGACY-', LEFT(CONVERT(varchar(36), Id), 8))),
                    SyncStatus = 0
                WHERE ISNULL(DeviceId, '') = '' OR ISNULL(DocumentNo, '') = '';
                """);

            migrationBuilder.CreateTable(
                name: "device_settings",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DeviceId = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    DeviceName = table.Column<string>(type: "nvarchar(120)", maxLength: 120, nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_device_settings", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "document_sequence_counters",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DeviceId = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    DocumentType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Year = table.Column<int>(type: "int", nullable: false),
                    NextSequence = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_document_sequence_counters", x => x.Id);
                });

            migrationBuilder.Sql(
                """
                IF NOT EXISTS (SELECT 1 FROM device_settings)
                BEGIN
                    INSERT INTO device_settings (Id, DeviceId, DeviceName, CreatedAt, UpdatedAt)
                    VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'DEV01', 'Primary Device', SYSUTCDATETIME(), SYSUTCDATETIME());
                END
                """);

            migrationBuilder.CreateIndex(
                name: "IX_vendor_payments_DeviceId",
                table: "vendor_payments",
                column: "DeviceId");

            migrationBuilder.CreateIndex(
                name: "IX_vendor_payments_DocumentNo",
                table: "vendor_payments",
                column: "DocumentNo",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_vendor_payments_SyncStatus",
                table: "vendor_payments",
                column: "SyncStatus");

            migrationBuilder.CreateIndex(
                name: "IX_vendor_credit_activities_DeviceId",
                table: "vendor_credit_activities",
                column: "DeviceId");

            migrationBuilder.CreateIndex(
                name: "IX_vendor_credit_activities_DocumentNo",
                table: "vendor_credit_activities",
                column: "DocumentNo",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_vendor_credit_activities_SyncStatus",
                table: "vendor_credit_activities",
                column: "SyncStatus");

            migrationBuilder.CreateIndex(
                name: "IX_sales_returns_DeviceId",
                table: "sales_returns",
                column: "DeviceId");

            migrationBuilder.CreateIndex(
                name: "IX_sales_returns_DocumentNo",
                table: "sales_returns",
                column: "DocumentNo",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_sales_returns_SyncStatus",
                table: "sales_returns",
                column: "SyncStatus");

            migrationBuilder.CreateIndex(
                name: "IX_purchase_returns_DeviceId",
                table: "purchase_returns",
                column: "DeviceId");

            migrationBuilder.CreateIndex(
                name: "IX_purchase_returns_DocumentNo",
                table: "purchase_returns",
                column: "DocumentNo",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_purchase_returns_SyncStatus",
                table: "purchase_returns",
                column: "SyncStatus");

            migrationBuilder.CreateIndex(
                name: "IX_purchase_orders_DeviceId",
                table: "purchase_orders",
                column: "DeviceId");

            migrationBuilder.CreateIndex(
                name: "IX_purchase_orders_DocumentNo",
                table: "purchase_orders",
                column: "DocumentNo",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_purchase_orders_SyncStatus",
                table: "purchase_orders",
                column: "SyncStatus");

            migrationBuilder.CreateIndex(
                name: "IX_purchase_bills_DeviceId",
                table: "purchase_bills",
                column: "DeviceId");

            migrationBuilder.CreateIndex(
                name: "IX_purchase_bills_DocumentNo",
                table: "purchase_bills",
                column: "DocumentNo",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_purchase_bills_SyncStatus",
                table: "purchase_bills",
                column: "SyncStatus");

            migrationBuilder.CreateIndex(
                name: "IX_payments_DeviceId",
                table: "payments",
                column: "DeviceId");

            migrationBuilder.CreateIndex(
                name: "IX_payments_DocumentNo",
                table: "payments",
                column: "DocumentNo",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_payments_SyncStatus",
                table: "payments",
                column: "SyncStatus");

            migrationBuilder.CreateIndex(
                name: "IX_journal_entries_DeviceId",
                table: "journal_entries",
                column: "DeviceId");

            migrationBuilder.CreateIndex(
                name: "IX_journal_entries_DocumentNo",
                table: "journal_entries",
                column: "DocumentNo",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_journal_entries_SyncStatus",
                table: "journal_entries",
                column: "SyncStatus");

            migrationBuilder.CreateIndex(
                name: "IX_invoices_DeviceId",
                table: "invoices",
                column: "DeviceId");

            migrationBuilder.CreateIndex(
                name: "IX_invoices_DocumentNo",
                table: "invoices",
                column: "DocumentNo",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_invoices_SyncStatus",
                table: "invoices",
                column: "SyncStatus");

            migrationBuilder.CreateIndex(
                name: "IX_inventory_adjustments_DeviceId",
                table: "inventory_adjustments",
                column: "DeviceId");

            migrationBuilder.CreateIndex(
                name: "IX_inventory_adjustments_DocumentNo",
                table: "inventory_adjustments",
                column: "DocumentNo",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_inventory_adjustments_SyncStatus",
                table: "inventory_adjustments",
                column: "SyncStatus");

            migrationBuilder.CreateIndex(
                name: "IX_customer_credit_activities_DeviceId",
                table: "customer_credit_activities",
                column: "DeviceId");

            migrationBuilder.CreateIndex(
                name: "IX_customer_credit_activities_DocumentNo",
                table: "customer_credit_activities",
                column: "DocumentNo",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_customer_credit_activities_SyncStatus",
                table: "customer_credit_activities",
                column: "SyncStatus");

            migrationBuilder.CreateIndex(
                name: "IX_device_settings_DeviceId",
                table: "device_settings",
                column: "DeviceId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_document_sequence_counters_DeviceId_DocumentType_Year",
                table: "document_sequence_counters",
                columns: new[] { "DeviceId", "DocumentType", "Year" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "device_settings");

            migrationBuilder.DropTable(
                name: "document_sequence_counters");

            migrationBuilder.DropIndex(
                name: "IX_vendor_payments_DeviceId",
                table: "vendor_payments");

            migrationBuilder.DropIndex(
                name: "IX_vendor_payments_DocumentNo",
                table: "vendor_payments");

            migrationBuilder.DropIndex(
                name: "IX_vendor_payments_SyncStatus",
                table: "vendor_payments");

            migrationBuilder.DropIndex(
                name: "IX_vendor_credit_activities_DeviceId",
                table: "vendor_credit_activities");

            migrationBuilder.DropIndex(
                name: "IX_vendor_credit_activities_DocumentNo",
                table: "vendor_credit_activities");

            migrationBuilder.DropIndex(
                name: "IX_vendor_credit_activities_SyncStatus",
                table: "vendor_credit_activities");

            migrationBuilder.DropIndex(
                name: "IX_sales_returns_DeviceId",
                table: "sales_returns");

            migrationBuilder.DropIndex(
                name: "IX_sales_returns_DocumentNo",
                table: "sales_returns");

            migrationBuilder.DropIndex(
                name: "IX_sales_returns_SyncStatus",
                table: "sales_returns");

            migrationBuilder.DropIndex(
                name: "IX_purchase_returns_DeviceId",
                table: "purchase_returns");

            migrationBuilder.DropIndex(
                name: "IX_purchase_returns_DocumentNo",
                table: "purchase_returns");

            migrationBuilder.DropIndex(
                name: "IX_purchase_returns_SyncStatus",
                table: "purchase_returns");

            migrationBuilder.DropIndex(
                name: "IX_purchase_orders_DeviceId",
                table: "purchase_orders");

            migrationBuilder.DropIndex(
                name: "IX_purchase_orders_DocumentNo",
                table: "purchase_orders");

            migrationBuilder.DropIndex(
                name: "IX_purchase_orders_SyncStatus",
                table: "purchase_orders");

            migrationBuilder.DropIndex(
                name: "IX_purchase_bills_DeviceId",
                table: "purchase_bills");

            migrationBuilder.DropIndex(
                name: "IX_purchase_bills_DocumentNo",
                table: "purchase_bills");

            migrationBuilder.DropIndex(
                name: "IX_purchase_bills_SyncStatus",
                table: "purchase_bills");

            migrationBuilder.DropIndex(
                name: "IX_payments_DeviceId",
                table: "payments");

            migrationBuilder.DropIndex(
                name: "IX_payments_DocumentNo",
                table: "payments");

            migrationBuilder.DropIndex(
                name: "IX_payments_SyncStatus",
                table: "payments");

            migrationBuilder.DropIndex(
                name: "IX_journal_entries_DeviceId",
                table: "journal_entries");

            migrationBuilder.DropIndex(
                name: "IX_journal_entries_DocumentNo",
                table: "journal_entries");

            migrationBuilder.DropIndex(
                name: "IX_journal_entries_SyncStatus",
                table: "journal_entries");

            migrationBuilder.DropIndex(
                name: "IX_invoices_DeviceId",
                table: "invoices");

            migrationBuilder.DropIndex(
                name: "IX_invoices_DocumentNo",
                table: "invoices");

            migrationBuilder.DropIndex(
                name: "IX_invoices_SyncStatus",
                table: "invoices");

            migrationBuilder.DropIndex(
                name: "IX_inventory_adjustments_DeviceId",
                table: "inventory_adjustments");

            migrationBuilder.DropIndex(
                name: "IX_inventory_adjustments_DocumentNo",
                table: "inventory_adjustments");

            migrationBuilder.DropIndex(
                name: "IX_inventory_adjustments_SyncStatus",
                table: "inventory_adjustments");

            migrationBuilder.DropIndex(
                name: "IX_customer_credit_activities_DeviceId",
                table: "customer_credit_activities");

            migrationBuilder.DropIndex(
                name: "IX_customer_credit_activities_DocumentNo",
                table: "customer_credit_activities");

            migrationBuilder.DropIndex(
                name: "IX_customer_credit_activities_SyncStatus",
                table: "customer_credit_activities");

            migrationBuilder.DropColumn(
                name: "DeviceId",
                table: "vendor_payments");

            migrationBuilder.DropColumn(
                name: "DocumentNo",
                table: "vendor_payments");

            migrationBuilder.DropColumn(
                name: "LastSyncAt",
                table: "vendor_payments");

            migrationBuilder.DropColumn(
                name: "SyncError",
                table: "vendor_payments");

            migrationBuilder.DropColumn(
                name: "SyncStatus",
                table: "vendor_payments");

            migrationBuilder.DropColumn(
                name: "DeviceId",
                table: "vendor_credit_activities");

            migrationBuilder.DropColumn(
                name: "DocumentNo",
                table: "vendor_credit_activities");

            migrationBuilder.DropColumn(
                name: "LastSyncAt",
                table: "vendor_credit_activities");

            migrationBuilder.DropColumn(
                name: "SyncError",
                table: "vendor_credit_activities");

            migrationBuilder.DropColumn(
                name: "SyncStatus",
                table: "vendor_credit_activities");

            migrationBuilder.DropColumn(
                name: "DeviceId",
                table: "sales_returns");

            migrationBuilder.DropColumn(
                name: "DocumentNo",
                table: "sales_returns");

            migrationBuilder.DropColumn(
                name: "LastSyncAt",
                table: "sales_returns");

            migrationBuilder.DropColumn(
                name: "SyncError",
                table: "sales_returns");

            migrationBuilder.DropColumn(
                name: "SyncStatus",
                table: "sales_returns");

            migrationBuilder.DropColumn(
                name: "DeviceId",
                table: "purchase_returns");

            migrationBuilder.DropColumn(
                name: "DocumentNo",
                table: "purchase_returns");

            migrationBuilder.DropColumn(
                name: "LastSyncAt",
                table: "purchase_returns");

            migrationBuilder.DropColumn(
                name: "SyncError",
                table: "purchase_returns");

            migrationBuilder.DropColumn(
                name: "SyncStatus",
                table: "purchase_returns");

            migrationBuilder.DropColumn(
                name: "DeviceId",
                table: "purchase_orders");

            migrationBuilder.DropColumn(
                name: "DocumentNo",
                table: "purchase_orders");

            migrationBuilder.DropColumn(
                name: "LastSyncAt",
                table: "purchase_orders");

            migrationBuilder.DropColumn(
                name: "SyncError",
                table: "purchase_orders");

            migrationBuilder.DropColumn(
                name: "SyncStatus",
                table: "purchase_orders");

            migrationBuilder.DropColumn(
                name: "DeviceId",
                table: "purchase_bills");

            migrationBuilder.DropColumn(
                name: "DocumentNo",
                table: "purchase_bills");

            migrationBuilder.DropColumn(
                name: "LastSyncAt",
                table: "purchase_bills");

            migrationBuilder.DropColumn(
                name: "SyncError",
                table: "purchase_bills");

            migrationBuilder.DropColumn(
                name: "SyncStatus",
                table: "purchase_bills");

            migrationBuilder.DropColumn(
                name: "DeviceId",
                table: "payments");

            migrationBuilder.DropColumn(
                name: "DocumentNo",
                table: "payments");

            migrationBuilder.DropColumn(
                name: "LastSyncAt",
                table: "payments");

            migrationBuilder.DropColumn(
                name: "SyncError",
                table: "payments");

            migrationBuilder.DropColumn(
                name: "SyncStatus",
                table: "payments");

            migrationBuilder.DropColumn(
                name: "DeviceId",
                table: "journal_entries");

            migrationBuilder.DropColumn(
                name: "DocumentNo",
                table: "journal_entries");

            migrationBuilder.DropColumn(
                name: "LastSyncAt",
                table: "journal_entries");

            migrationBuilder.DropColumn(
                name: "SyncError",
                table: "journal_entries");

            migrationBuilder.DropColumn(
                name: "SyncStatus",
                table: "journal_entries");

            migrationBuilder.DropColumn(
                name: "DeviceId",
                table: "invoices");

            migrationBuilder.DropColumn(
                name: "DocumentNo",
                table: "invoices");

            migrationBuilder.DropColumn(
                name: "LastSyncAt",
                table: "invoices");

            migrationBuilder.DropColumn(
                name: "SyncError",
                table: "invoices");

            migrationBuilder.DropColumn(
                name: "SyncStatus",
                table: "invoices");

            migrationBuilder.DropColumn(
                name: "DeviceId",
                table: "inventory_adjustments");

            migrationBuilder.DropColumn(
                name: "DocumentNo",
                table: "inventory_adjustments");

            migrationBuilder.DropColumn(
                name: "LastSyncAt",
                table: "inventory_adjustments");

            migrationBuilder.DropColumn(
                name: "SyncError",
                table: "inventory_adjustments");

            migrationBuilder.DropColumn(
                name: "SyncStatus",
                table: "inventory_adjustments");

            migrationBuilder.DropColumn(
                name: "DeviceId",
                table: "customer_credit_activities");

            migrationBuilder.DropColumn(
                name: "DocumentNo",
                table: "customer_credit_activities");

            migrationBuilder.DropColumn(
                name: "LastSyncAt",
                table: "customer_credit_activities");

            migrationBuilder.DropColumn(
                name: "SyncError",
                table: "customer_credit_activities");

            migrationBuilder.DropColumn(
                name: "SyncStatus",
                table: "customer_credit_activities");
        }
    }
}
