using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace QuickBooksClone.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddInventoryReceipts : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "inventory_receipts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "TEXT", nullable: false),
                    CompanyId = table.Column<Guid>(type: "TEXT", nullable: false),
                    VendorId = table.Column<Guid>(type: "TEXT", nullable: false),
                    PurchaseOrderId = table.Column<Guid>(type: "TEXT", nullable: true),
                    ReceiptNumber = table.Column<string>(type: "TEXT", maxLength: 80, nullable: false),
                    ReceiptDate = table.Column<DateOnly>(type: "TEXT", nullable: false),
                    Status = table.Column<int>(type: "INTEGER", nullable: false),
                    PostedTransactionId = table.Column<Guid>(type: "TEXT", nullable: true),
                    PostedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: true),
                    ReversalTransactionId = table.Column<Guid>(type: "TEXT", nullable: true),
                    VoidedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: true),
                    DeviceId = table.Column<string>(type: "TEXT", maxLength: 20, nullable: false),
                    DocumentNo = table.Column<string>(type: "TEXT", maxLength: 80, nullable: false),
                    SyncStatus = table.Column<int>(type: "INTEGER", nullable: false),
                    LastSyncAt = table.Column<DateTimeOffset>(type: "TEXT", nullable: true),
                    SyncError = table.Column<string>(type: "TEXT", maxLength: 500, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_inventory_receipts", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "inventory_receipt_lines",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "TEXT", nullable: false),
                    ItemId = table.Column<Guid>(type: "TEXT", nullable: false),
                    PurchaseOrderLineId = table.Column<Guid>(type: "TEXT", nullable: true),
                    Description = table.Column<string>(type: "TEXT", maxLength: 300, nullable: false),
                    Quantity = table.Column<decimal>(type: "TEXT", precision: 18, scale: 4, nullable: false),
                    UnitCost = table.Column<decimal>(type: "TEXT", precision: 18, scale: 4, nullable: false),
                    InventoryReceiptId = table.Column<Guid>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_inventory_receipt_lines", x => x.Id);
                    table.ForeignKey(
                        name: "FK_inventory_receipt_lines_inventory_receipts_InventoryReceiptId",
                        column: x => x.InventoryReceiptId,
                        principalTable: "inventory_receipts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_inventory_receipt_lines_InventoryReceiptId",
                table: "inventory_receipt_lines",
                column: "InventoryReceiptId");

            migrationBuilder.CreateIndex(
                name: "IX_inventory_receipts_CompanyId",
                table: "inventory_receipts",
                column: "CompanyId");

            migrationBuilder.CreateIndex(
                name: "IX_inventory_receipts_DeviceId",
                table: "inventory_receipts",
                column: "DeviceId");

            migrationBuilder.CreateIndex(
                name: "IX_inventory_receipts_DocumentNo",
                table: "inventory_receipts",
                column: "DocumentNo",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_inventory_receipts_ReceiptNumber",
                table: "inventory_receipts",
                column: "ReceiptNumber",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_inventory_receipts_SyncStatus",
                table: "inventory_receipts",
                column: "SyncStatus");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "inventory_receipt_lines");

            migrationBuilder.DropTable(
                name: "inventory_receipts");
        }
    }
}
